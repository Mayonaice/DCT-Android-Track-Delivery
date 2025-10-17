import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class PhotoCacheService {
  static const String _keyPrefix = 'item_photos_';
  static const String _tempDirName = 'temp_photos';
  
  // Save multiple photos for a specific item
  Future<void> saveItemPhotos(String itemId, List<File> photos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempDir = await _getTempDirectory();
      
      List<String> photoPaths = [];
      
      for (int i = 0; i < photos.length; i++) {
        final file = photos[i];
        final fileName = '${itemId}_photo_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tempFile = File('${tempDir.path}/$fileName');
        
        // Copy file to temp directory
        await file.copy(tempFile.path);
        photoPaths.add(tempFile.path);
      }
      
      // Save paths to SharedPreferences
      await prefs.setStringList('$_keyPrefix$itemId', photoPaths);
    } catch (e) {
      print('Error saving item photos: $e');
    }
  }
  
  // Get photos for a specific item
  Future<List<File>> getItemPhotos(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPaths = prefs.getStringList('$_keyPrefix$itemId') ?? [];
      
      List<File> photos = [];
      for (String path in photoPaths) {
        final file = File(path);
        if (await file.exists()) {
          photos.add(file);
        }
      }
      
      return photos;
    } catch (e) {
      print('Error getting item photos: $e');
      return [];
    }
  }
  
  // Check if item has cached photos
  Future<bool> hasItemPhotos(String itemId) async {
    try {
      final photos = await getItemPhotos(itemId);
      return photos.isNotEmpty;
    } catch (e) {
      print('Error checking item photos: $e');
      return false;
    }
  }
  
  // Clear photos for a specific item
  Future<void> clearItemPhotos(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPaths = prefs.getStringList('$_keyPrefix$itemId') ?? [];
      
      // Delete physical files
      for (String path in photoPaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from SharedPreferences
      await prefs.remove('$_keyPrefix$itemId');
    } catch (e) {
      print('Error clearing item photos: $e');
    }
  }
  
  // Clear all cached photos
  Future<void> clearAllPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      for (String key in keys) {
        final itemId = key.replaceFirst(_keyPrefix, '');
        await clearItemPhotos(itemId);
      }
      
      // Also clear temp directory
      final tempDir = await _getTempDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing all photos: $e');
    }
  }
  
  // Get temp directory for storing photos
  Future<Directory> _getTempDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/$_tempDirName');
    
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    
    return tempDir;
  }
  
  // Convert File to base64 for API submission
  Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return null;
    }
  }
  
  // Get original filename from File
  String getOriginalFilename(File file) {
    return file.path.split('/').last;
  }
  
  // Validate image file
  bool isValidImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }
  
  // Get file size in MB
  Future<double> getFileSizeInMB(File file) async {
    try {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      print('Error getting file size: $e');
      return 0.0;
    }
  }
}