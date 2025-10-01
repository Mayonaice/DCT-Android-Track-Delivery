import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class PhotoPreviewPage extends StatefulWidget {
  final String imagePath;
  
  const PhotoPreviewPage({super.key, required this.imagePath});

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  List<String> _capturedImages = [];
  
  @override
  void initState() {
    super.initState();
    _capturedImages.add(widget.imagePath);
  }

  void _retakePhoto() {
    // Return null to indicate retake
    Navigator.pop(context, null);
  }

  void _uploadPhoto() {
    // Return the image path to confirm upload
    Navigator.pop(context, widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
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
            Navigator.pop(context, null);
          },
        ),
        title: const Text(
          'Preview',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _uploadPhoto,
            child: const Text(
              'Upload',
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
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // Bottom section with thumbnails and retake button
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Thumbnails row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _capturedImages.map((imagePath) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Retake button with X icon
                GestureDetector(
                  onTap: _retakePhoto,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Ambil Ulang',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
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