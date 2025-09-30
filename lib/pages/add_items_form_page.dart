import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddItemsFormPage extends StatefulWidget {
  const AddItemsFormPage({super.key});

  @override
  State<AddItemsFormPage> createState() => _AddItemsFormPageState();
}

class _AddItemsFormPageState extends State<AddItemsFormPage> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahBarangController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _deskripsiBarangController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _namaBarangController.dispose();
    _jumlahBarangController.dispose();
    _serialNumberController.dispose();
    _deskripsiBarangController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF374151),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1B8B7A), width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      ),
    );
  }

  Widget _buildDeskripsiWithPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single circular photo placeholder on the left (increased size)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150, // Increased from 60 to 150 (2.5x)
                height: 150, // Increased from 60 to 150 (2.5x)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                  color: _selectedImage != null ? null : const Color(0xFFF9FAFB),
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 36, // Increased icon size proportionally
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Description field
            Expanded(
              child: _buildUnderlineTextField(
                controller: _deskripsiBarangController,
                hintText: 'Masukan Deskripsi Barang',
                maxLines: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // Reduced spacing
        // Foto Barang text positioned below the placeholder
        const Padding(
          padding: EdgeInsets.only(left: 60), // Center under the circular placeholder
          child: Text(
            'Foto Barang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B8B7A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Tambah Barang',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tambah Barang Section Header with larger font size
            const Text(
              'Tambah Barang',
              style: TextStyle(
                fontSize: 24, // Increased from 18 to 24
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 20),
            
            // Nama Barang
            const Text(
              'Nama Barang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _namaBarangController,
              hintText: 'Masukan Nama barang',
            ),
            const SizedBox(height: 20),
            
            // Jumlah Barang
            const Text(
              'Jumlah Barang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _jumlahBarangController,
              hintText: 'Masukan Jumlah barang',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            
            // Serial Number
            const Text(
              'Serial Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _serialNumberController,
              hintText: 'Masukan Serial Number',
            ),
            const SizedBox(height: 20),
            
            // Deskripsi Barang with circular photo placeholders
            const Text(
              'Deskripsi Barang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing from default
            _buildDeskripsiWithPhotoField(),
            const SizedBox(height: 60), // Increased spacing before button

            // Simpan Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement save functionality
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8B7A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}