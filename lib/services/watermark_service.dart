import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class WatermarkService {
  static const String _defaultFont = 'Roboto';
  
  // Cache location to avoid repeated GPS calls
  static String? _cachedLocation;
  static DateTime? _locationCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  /// Add timestamp and location watermark to an image
  static Future<File> addWatermarkToImage(File imageFile) async {
    print('🔍 DEBUG: Starting watermark process for: ${imageFile.path}');
    print('🔍 DEBUG: Original file exists: ${await imageFile.exists()}');
    print('🔍 DEBUG: Original file size: ${await imageFile.length()} bytes');
    
    try {
      // Validate input file
      if (!await imageFile.exists()) {
        print('🚨 ERROR: Input image file does not exist');
        throw Exception('Input image file does not exist');
      }
      
      // Get current timestamp
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      final timestamp = dateFormatter.format(now);
      print('🔍 DEBUG: Timestamp created: $timestamp');
      
      // Get current location with caching to avoid repeated GPS calls
      String locationText;
      try {
        // Check if we have valid cached location
        if (_cachedLocation != null && 
            _locationCacheTime != null && 
            DateTime.now().difference(_locationCacheTime!).compareTo(_cacheValidDuration) < 0) {
          locationText = _cachedLocation!;
          print('🔍 DEBUG: Using cached location: $locationText');
        } else {
          print('🔍 DEBUG: Cache expired or empty, getting fresh location...');
          locationText = await _getCurrentLocation().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('🚨 WARNING: Location timeout after 10 seconds, using default');
              return 'Lokasi tidak tersedia';
            },
          );
          
          // Cache the location if it's valid
          if (locationText != 'Lokasi tidak tersedia' && 
              locationText != 'Izin lokasi ditolak' && 
              locationText != 'Izin lokasi ditolak permanen') {
            _cachedLocation = locationText;
            _locationCacheTime = DateTime.now();
            print('🔍 DEBUG: Location cached for future use');
          }
        }
      } catch (e) {
        print('🚨 WARNING: Location error: $e, using cached or default');
        locationText = _cachedLocation ?? 'Lokasi tidak tersedia';
      }
      print('🔍 DEBUG: Final location text: $locationText');
      
      // Combine timestamp and location
      final watermarkText = '$timestamp\n$locationText';
      print('🔍 DEBUG: Watermark text prepared: $watermarkText');
      
      // Read the original image
      print('🔍 DEBUG: Reading image bytes...');
      final imageBytes = await imageFile.readAsBytes();
      print('🔍 DEBUG: Image bytes read: ${imageBytes.length} bytes');
      
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        print('🚨 ERROR: Failed to decode image');
        throw Exception('Failed to decode image');
      }
      print('🔍 DEBUG: Image decoded successfully: ${originalImage.width}x${originalImage.height}');
      
      // Create watermark
      print('🔍 DEBUG: Adding text watermark...');
      final watermarkedImage = await _addTextWatermark(
        originalImage, 
        watermarkText,
      );
      print('🔍 DEBUG: Text watermark added successfully');
      
      // Save the watermarked image
      final tempDir = await getTemporaryDirectory();
      final watermarkedFile = File('${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg');
      print('🔍 DEBUG: Saving watermarked image to: ${watermarkedFile.path}');
      
      final encodedImage = img.encodeJpg(watermarkedImage, quality: 90);
      await watermarkedFile.writeAsBytes(encodedImage);
      
      // Verify the watermarked file was created
      if (await watermarkedFile.exists()) {
        final watermarkedSize = await watermarkedFile.length();
        print('✅ Watermark added successfully to: ${watermarkedFile.path}');
        print('✅ Watermarked file size: $watermarkedSize bytes');
        return watermarkedFile;
      } else {
        print('🚨 ERROR: Watermarked file was not created');
        throw Exception('Watermarked file was not created');
      }
    } catch (e) {
      print('🚨 Error adding watermark: $e');
      print('🚨 Stack trace: ${StackTrace.current}');
      print('🚨 Returning original file as fallback');
      
      // Verify original file still exists before returning
      if (await imageFile.exists()) {
        print('✅ Original file still exists, returning it');
        return imageFile;
      } else {
        print('🚨 CRITICAL: Original file no longer exists!');
        throw Exception('Both watermarked and original files are missing');
      }
    }
  }
  
  /// Get current location as formatted string
  static Future<String> _getCurrentLocation() async {
    try {
      print('🔍 DEBUG: Starting location retrieval...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('🔍 DEBUG: Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('🚨 WARNING: Location services are disabled');
        return 'Lokasi tidak tersedia';
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔍 DEBUG: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('🔍 DEBUG: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🔍 DEBUG: Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('🚨 WARNING: Location permission denied by user');
          return 'Izin lokasi ditolak';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('🚨 WARNING: Location permission denied forever');
        return 'Izin lokasi ditolak permanen';
      }
      
      // Get current position with more lenient settings
      print('🔍 DEBUG: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium
        timeLimit: const Duration(seconds: 15), // Increased from 10 to 15 seconds
      );
      
      print('🔍 DEBUG: Position obtained: ${position.latitude}, ${position.longitude}');
      
      // Format coordinates
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      
      final locationString = 'Lat: $lat, Lng: $lng';
      print('🔍 DEBUG: Location formatted: $locationString');
      return locationString;
    } catch (e) {
      print('🚨 Error getting location: $e');
      print('🔍 DEBUG: Returning fallback location text');
      return 'Lokasi tidak tersedia';
    }
  }
  
  /// Add text watermark to image
  static Future<img.Image> _addTextWatermark(
    img.Image originalImage, 
    String text,
  ) async {
    try {
      // Create a copy of the original image
      final watermarkedImage = img.Image.from(originalImage);
      
      // Calculate text position (bottom right corner with padding)
      const int padding = 20;
      
      // Use more aggressive font sizing for better visibility
      // Make watermarks significantly larger and more consistent
      final imageArea = originalImage.width * originalImage.height;
      final double scaleFactor = (imageArea / 800000).clamp(1.2, 4.0); // Increased minimum and maximum scale
      
      // Choose font based on scale factor with larger fonts
      img.BitmapFont selectedFont;
      String fontName;
      if (scaleFactor <= 1.8) {
        selectedFont = img.arial24; // Changed from arial14 to arial24
        fontName = 'arial24';
      } else if (scaleFactor <= 2.8) {
        selectedFont = img.arial48; // Changed from arial24 to arial48  
        fontName = 'arial48';
      } else {
        // For very large images, use arial48 with additional scaling
        selectedFont = img.arial48;
        fontName = 'arial48 (large)';
      }
      
      print('🔍 DEBUG: Image ${originalImage.width}x${originalImage.height}, area: $imageArea, scale: ${scaleFactor.toStringAsFixed(2)}, font: $fontName');
      
      // Split text into lines
      final lines = text.split('\n');
      
      // Draw each line of text
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        
        // Calculate position for this line based on font height
        final fontHeight = selectedFont.lineHeight;
        final yPosition = watermarkedImage.height - padding - (fontHeight + 5) * (lines.length - i);
        
        // Draw text with background for better visibility
        _drawTextWithBackground(
          watermarkedImage,
          line,
          watermarkedImage.width - padding,
          yPosition,
          selectedFont,
        );
      }
      
      return watermarkedImage;
    } catch (e) {
      print('🚨 Error adding text watermark: $e');
      return originalImage;
    }
  }
  
  /// Draw text with semi-transparent background for better visibility
  static void _drawTextWithBackground(
    img.Image image,
    String text,
    int x,
    int y,
    img.BitmapFont font,
  ) {
    try {
      // Calculate text dimensions based on actual font metrics
      final textWidth = (text.length * (font.lineHeight * 0.6)).round();
      final textHeight = font.lineHeight;
      
      // Calculate background rectangle with proper padding
      final bgX = x - textWidth - 10;
      final bgY = y - 5;
      final bgWidth = textWidth + 20;
      final bgHeight = textHeight + 10;
      
      // Draw semi-transparent background
      img.fillRect(
        image,
        x1: bgX.clamp(0, image.width),
        y1: bgY.clamp(0, image.height),
        x2: (bgX + bgWidth).clamp(0, image.width),
        y2: (bgY + bgHeight).clamp(0, image.height),
        color: img.ColorRgba8(0, 0, 0, 128), // Semi-transparent black
      );
      
      // Draw white text with the provided font
      img.drawString(
        image,
        text,
        font: font,
        x: (x - textWidth).clamp(0, image.width - textWidth),
        y: y.clamp(0, image.height - textHeight),
        color: img.ColorRgba8(255, 255, 255, 255), // White text
      );
      
      print('🔍 DEBUG: Drew text "$text" with font ${font.lineHeight}px at position ($x, $y)');
    } catch (e) {
      print('🚨 Error drawing text with background: $e');
      // Fallback: draw simple white text with default font
      img.drawString(
        image,
        text,
        font: img.arial24,
        x: (x - text.length * 12).clamp(0, image.width),
        y: y.clamp(0, image.height),
        color: img.ColorRgba8(255, 255, 255, 255),
      );
    }
  }
  
  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('🚨 Error checking location permission: $e');
      return false;
    }
  }
  
  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('🚨 Error requesting location permission: $e');
      return false;
    }
  }
}