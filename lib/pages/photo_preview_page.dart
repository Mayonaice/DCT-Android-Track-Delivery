import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/photo_cache_service.dart';
import '../services/watermark_service.dart';

class PhotoPreviewPage extends StatefulWidget {
  final String? initialImagePath;
  final String itemId;
  final List<File>? existingPhotos;
  
  const PhotoPreviewPage({
    super.key, 
    this.initialImagePath,
    required this.itemId,
    this.existingPhotos,
  });

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  List<File> _capturedImages = [];
  int _selectedImageIndex = 0;
  final PhotoCacheService _photoCacheService = PhotoCacheService();
  final ImagePicker _picker = ImagePicker();
  static const int maxPhotos = 10;
  
  @override
  void initState() {
    super.initState();
    _initializePhotos();
  }

  void _initializePhotos() async {
    // Load existing photos from cache first
    if (widget.existingPhotos != null && widget.existingPhotos!.isNotEmpty) {
      _capturedImages = List.from(widget.existingPhotos!);
    } else {
      // Try to load from cache
      final cachedPhotos = await _photoCacheService.getItemPhotos(widget.itemId);
      if (cachedPhotos.isNotEmpty) {
        _capturedImages = cachedPhotos;
      }
    }
    
    // Add new photo if provided
    if (widget.initialImagePath != null) {
      final newPhoto = File(widget.initialImagePath!);
      if (!_capturedImages.any((photo) => photo.path == newPhoto.path)) {
        _capturedImages.add(newPhoto);
        _selectedImageIndex = _capturedImages.length - 1;
      }
    }
    
    // If no photos at all, this shouldn't happen but handle gracefully
    if (_capturedImages.isEmpty && widget.initialImagePath != null) {
      _capturedImages.add(File(widget.initialImagePath!));
    }
    
    setState(() {});
    
    // Save to cache
    if (_capturedImages.isNotEmpty) {
      await _photoCacheService.saveItemPhotos(widget.itemId, _capturedImages);
    }
  }

  void _selectImage(int index) {
    setState(() {
      _selectedImageIndex = index;
    });
  }

  void _removeImage(int index) async {
    if (_capturedImages.length <= 1) {
      // If only one photo, show confirmation dialog
      final shouldRemove = await _showRemoveConfirmation();
      if (shouldRemove) {
        setState(() {
          _capturedImages.removeAt(index);
          _selectedImageIndex = 0;
        });
        // Clear cache and return empty result
        await _photoCacheService.clearItemPhotos(widget.itemId);
        Navigator.pop(context, <File>[]);
      }
      return;
    }
    
    setState(() {
      _capturedImages.removeAt(index);
      if (_selectedImageIndex >= _capturedImages.length) {
        _selectedImageIndex = _capturedImages.length - 1;
      }
    });
    
    // Update cache
    await _photoCacheService.saveItemPhotos(widget.itemId, _capturedImages);
  }

  Future<bool> _showRemoveConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Foto'),
          content: const Text('Apakah Anda yakin ingin menghapus foto ini? Ini adalah foto terakhir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _addPhoto() async {
    if (_capturedImages.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal $maxPhotos foto per item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  
                  if (photo != null) {
                    // Add watermark to camera image
                    print('🔍 DEBUG: Adding watermark to camera image...');
                    final File originalFile = File(photo.path);
                    final File watermarkedFile = await WatermarkService.addWatermarkToImage(originalFile);
                    print('🔍 DEBUG: Watermark added successfully');
                    
                    // Return the watermarked image
                    Navigator.pop(context, XFile(watermarkedFile.path));
                  } else {
                    Navigator.pop(context, null);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  Navigator.pop(context, photo);
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final newPhoto = File(result.path);
      
      // Validate file
      if (!_photoCacheService.isValidImageFile(newPhoto)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format file tidak didukung. Gunakan JPG, PNG, atau GIF.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check file size (max 5MB)
      final fileSizeInMB = await _photoCacheService.getFileSizeInMB(newPhoto);
      if (fileSizeInMB > 5.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file terlalu besar. Maksimal 5MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _capturedImages.add(newPhoto);
        _selectedImageIndex = _capturedImages.length - 1;
      });
      
      // Update cache
      await _photoCacheService.saveItemPhotos(widget.itemId, _capturedImages);
    }
  }

  void _uploadPhotos() async {
    if (_capturedImages.isEmpty) {
      Navigator.pop(context, <File>[]);
      return;
    }
    
    // Save to cache before returning
    await _photoCacheService.saveItemPhotos(widget.itemId, _capturedImages);
    
    // Return all photos
    Navigator.pop(context, _capturedImages);
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1B8B7A),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, <File>[]);
            },
          ),
          title: const Text(
            'Preview Foto',
            style: TextStyle(
              color: Color(0xFF1B8B7A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: Text(
            'Tidak ada foto untuk ditampilkan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B8B7A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, _capturedImages);
          },
        ),
        title: Text(
          'Preview Foto (${_capturedImages.length}/$maxPhotos)',
          style: const TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _uploadPhotos,
            child: const Text(
              'Selesai',
              style: TextStyle(
                color: Color(0xFF1B8B7A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main photo preview
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _capturedImages[_selectedImageIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // Bottom section with thumbnails and controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Thumbnails row with add button
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _capturedImages.length + (_capturedImages.length < maxPhotos ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _capturedImages.length) {
                        // Add photo button
                        return GestureDetector(
                          onTap: _addPhoto,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1B8B7A),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF1B8B7A),
                              size: 24,
                            ),
                          ),
                        );
                      }
                      
                      // Photo thumbnail
                      return GestureDetector(
                        onTap: () => _selectImage(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedImageIndex == index 
                                  ? const Color(0xFF1B8B7A)
                                  : const Color(0xFFE5E7EB),
                              width: _selectedImageIndex == index ? 3 : 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  _capturedImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              // Remove button
                              Positioned(
                                top: -2,
                                right: -2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info text
                Text(
                  'Tap foto untuk melihat, tap + untuk menambah foto baru',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}