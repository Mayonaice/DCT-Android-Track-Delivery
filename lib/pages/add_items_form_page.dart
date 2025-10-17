import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../models/item_data.dart';
import '../widgets/custommodals.dart';
import '../services/watermark_service.dart';
import 'add_trx_form_page.dart';
import 'photo_preview_page.dart';
import '../services/photo_cache_service.dart';

class AddItemsFormPage extends StatefulWidget {
  final ItemData? existingData;
  
  const AddItemsFormPage({super.key, this.existingData});

  @override
  State<AddItemsFormPage> createState() => _AddItemsFormPageState();
}

class _AddItemsFormPageState extends State<AddItemsFormPage> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahBarangController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _deskripsiBarangController = TextEditingController();
  
  File? _selectedImage;
  List<File> _selectedImages = []; // New field for multiple photos
  String _itemId = ''; // Unique identifier for cache management
  final ImagePicker _picker = ImagePicker();
  final PhotoCacheService _photoCacheService = PhotoCacheService();

  @override
  void initState() {
    super.initState();
    
    // Generate unique item ID
    _itemId = DateTime.now().millisecondsSinceEpoch.toString();
    
    if (widget.existingData != null) {
      _namaBarangController.text = widget.existingData!.namaBarang;
      _jumlahBarangController.text = widget.existingData!.jumlahBarang;
      _serialNumberController.text = widget.existingData!.serialNumber;
      _deskripsiBarangController.text = widget.existingData!.deskripsiBarang;
      _selectedImage = widget.existingData!.selectedImage;
      _selectedImages = List.from(widget.existingData!.selectedImages);
      _itemId = widget.existingData!.itemId;
    }
    
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final cachedPhotos = await _photoCacheService.getItemPhotos(_itemId);
    if (cachedPhotos.isNotEmpty) {
      setState(() {
        _selectedImages = cachedPhotos;
        _selectedImage = _selectedImages.first;
      });
    }
  }

  Future<void> _saveToCache(ItemData itemData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(itemData.toJson());
    await prefs.setString('item_data', jsonString);
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _jumlahBarangController.dispose();
    _serialNumberController.dispose();
    _deskripsiBarangController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    // Check if there are existing photos in cache
    final cachedPhotos = await _photoCacheService.getItemPhotos(_itemId);
    if (cachedPhotos.isNotEmpty) {
      // If photos exist, go directly to preview page
      _openPhotoPreview();
      return;
    }
    
    // If no photos exist, show source selection dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B8B7A),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Color(0xFF1B8B7A),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B8B7A),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 40,
                              color: Color(0xFF1B8B7A),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Galeri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _openPhotoPreview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoPreviewPage(
          itemId: _itemId,
          existingPhotos: _selectedImages.isNotEmpty ? _selectedImages : null,
        ),
      ),
    );
    
    if (result != null && result is List<File>) {
      setState(() {
        _selectedImages = result;
        _selectedImage = _selectedImages.isNotEmpty ? _selectedImages.first : null;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Validasi format gambar
        final String fileName = image.path.toLowerCase();
        final List<String> allowedExtensions = ['.png', '.jpg', '.jpeg'];
        
        bool isValidFormat = allowedExtensions.any((ext) => fileName.endsWith(ext));
        
        if (!isValidFormat) {
          // Tampilkan pesan error menggunakan CustomModals
          CustomModals.showErrorModal(
            context, 
            'Format gambar tidak didukung. Hanya file PNG, JPG, dan JPEG yang diperbolehkan.',
          );
          return;
        }
        
        final File imageFile = File(image.path);
        
        // Add watermark to the image if it's from camera
        File finalImageFile = imageFile;
        if (source == ImageSource.camera) {
          print('🔍 DEBUG: Adding watermark to camera image...');
          finalImageFile = await WatermarkService.addWatermarkToImage(imageFile);
          print('🔍 DEBUG: Watermark added successfully');
        }
        
        if (source == ImageSource.camera) {
          // For camera, go to preview page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoPreviewPage(
                initialImagePath: finalImageFile.path,
                itemId: _itemId,
                existingPhotos: _selectedImages.isNotEmpty ? _selectedImages : null,
              ),
            ),
          );
          
          if (result != null && result is List<File>) {
            setState(() {
              _selectedImages = result;
              _selectedImage = _selectedImages.isNotEmpty ? _selectedImages.first : null;
            });
          }
        } else {
          // For gallery, add directly to the list and go to preview
          List<File> currentImages = List.from(_selectedImages);
          currentImages.add(finalImageFile);
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoPreviewPage(
                itemId: _itemId,
                existingPhotos: currentImages,
              ),
            ),
          );
          
          if (result != null && result is List<File>) {
            setState(() {
              _selectedImages = result;
              _selectedImage = _selectedImages.isNotEmpty ? _selectedImages.first : null;
            });
          }
        }
      }
    } catch (e) {
      CustomModals.showErrorModal(
        context,
        'Error picking image: $e',
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
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
            // Photo placeholder with multiple photo indicator
            Column(
              children: [
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          color: _selectedImages.isNotEmpty ? null : const Color(0xFFF9FAFB),
                        ),
                        child: _selectedImages.isNotEmpty
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImages.first,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF9CA3AF),
                                size: 24,
                              ),
                      ),
                      // Photo count indicator
                      if (_selectedImages.length > 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B8B7A),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_selectedImages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedImages.isEmpty 
                      ? 'Foto Barang' 
                      : '${_selectedImages.length} Foto',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Description field
            Expanded(
              child: _buildUnderlineTextField(
                controller: _deskripsiBarangController,
                hintText: 'Masukan Deskripsi Barang',
              ),
            ),
          ],
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
            const SizedBox(height: 4), // Further reduced spacing
            _buildDeskripsiWithPhotoField(),
            const SizedBox(height: 60), // Increased spacing before button

            // Simpan Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  
                  // Validasi form
                  if (_namaBarangController.text.isEmpty) {
                    CustomModals.showErrorModal(
                      context,
                      'Nama barang harus diisi',
                    );
                    return;
                  }
                  
                  // Buat object ItemData
                  final itemData = ItemData(
                    namaBarang: _namaBarangController.text,
                    jumlahBarang: _jumlahBarangController.text,
                    serialNumber: _serialNumberController.text,
                    deskripsiBarang: _deskripsiBarangController.text,
                    selectedImage: _selectedImage,
                    selectedImages: _selectedImages,
                    itemId: _itemId,
                  );
                  
                  // Simpan ke cache
                  await _saveToCache(itemData);
                  
                  // Navigate ke AddTrxFormPage dengan data atau return data jika edit
                  if (mounted) {
                    if (widget.existingData != null) {
                      // Jika edit, return data ke halaman sebelumnya
                      Navigator.pop(context, itemData);
                    } else {
                      // Jika tambah baru, return data ke halaman sebelumnya
                      Navigator.pop(context, itemData);
                    }
                  }
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