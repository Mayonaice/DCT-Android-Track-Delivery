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
  
  /// Add timestamp and location watermark to an image
  static Future<File> addWatermarkToImage(File imageFile) async {
    try {
      // Get current timestamp
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      final timestamp = dateFormatter.format(now);
      
      // Get current location
      String locationText = await _getCurrentLocation();
      
      // Combine timestamp and location
      final watermarkText = '$timestamp\n$locationText';
      
      // Read the original image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }
      
      // Create watermark
      final watermarkedImage = await _addTextWatermark(
        originalImage, 
        watermarkText,
      );
      
      // Save the watermarked image
      final tempDir = await getTemporaryDirectory();
      final watermarkedFile = File('${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final encodedImage = img.encodeJpg(watermarkedImage, quality: 90);
      await watermarkedFile.writeAsBytes(encodedImage);
      
      print('✅ Watermark added successfully to: ${watermarkedFile.path}');
      return watermarkedFile;
    } catch (e) {
      print('🚨 Error adding watermark: $e');
      print('🚨 Stack trace: ${StackTrace.current}');
      // Return original file if watermark fails
      return imageFile;
    }
  }
  
  /// Get current location as formatted string
  static Future<String> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Lokasi tidak tersedia';
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Izin lokasi ditolak';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return 'Izin lokasi ditolak permanen';
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Format coordinates
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      
      return 'Lat: $lat, Lng: $lng';
    } catch (e) {
      print('🚨 Error getting location: $e');
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
      const int fontSize = 24;
      
      // Split text into lines
      final lines = text.split('\n');
      
      // Draw each line of text
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        
        // Calculate position for this line
        final yPosition = watermarkedImage.height - padding - (fontSize + 5) * (lines.length - i);
        
        // Draw text with background for better visibility
        _drawTextWithBackground(
          watermarkedImage,
          line,
          watermarkedImage.width - padding,
          yPosition,
          fontSize,
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
    int fontSize,
  ) {
    try {
      // Estimate text dimensions (rough calculation)
      final textWidth = text.length * (fontSize * 0.6).round();
      final textHeight = fontSize + 4;
      
      // Calculate background rectangle
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
      
      // Draw white text
      img.drawString(
        image,
        text,
        font: img.arial24,
        x: (x - textWidth).clamp(0, image.width - textWidth),
        y: y.clamp(0, image.height - textHeight),
        color: img.ColorRgba8(255, 255, 255, 255), // White text
      );
    } catch (e) {
      print('🚨 Error drawing text with background: $e');
      // Fallback: draw simple white text
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