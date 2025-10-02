import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/delivery_transaction_detail_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../enums/user_role.dart';
import 'ta_tp_item_detail_page.dart';
import 'image_preview_page.dart';

class TaTpDeliveryPage extends StatefulWidget {
  final String deliveryCode;
  final String token;
  final UserRole userRole;
  final String status; // Status dari response login by code

  const TaTpDeliveryPage({
    Key? key,
    required this.deliveryCode,
    required this.token,
    required this.userRole,
    required this.status,
  }) : super(key: key);

  @override
  State<TaTpDeliveryPage> createState() => _TaTpDeliveryPageState();
}

class _TaTpDeliveryPageState extends State<TaTpDeliveryPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  
  DeliveryTransactionDetailData? _deliveryData;
  bool _isLoading = true;
  String? _errorMessage;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: TaTpDeliveryPage initState called');
    print('🔍 DEBUG: deliveryCode: ${widget.deliveryCode}');
    print('🔍 DEBUG: userRole: ${widget.userRole.code}');
    print('🔍 DEBUG: status: ${widget.status}');
    _loadDeliveryDetail();
  }

  Future<void> _loadDeliveryDetail() async {
    try {
      print('🔍 DEBUG: TaTpDeliveryPage - Starting _loadDeliveryDetail...');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.getTransactionDetail(widget.deliveryCode, widget.token);
      
      print('🔍 DEBUG: TaTpDeliveryPage - API Response received');
      print('🔍 DEBUG: TaTpDeliveryPage - Response ok: ${response.ok}');
      
      if (response.ok && response.data != null) {
        setState(() {
          _deliveryData = response.data;
          _isLoading = false;
        });
        print('🔍 DEBUG: TaTpDeliveryPage - Data loaded successfully');
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
        print('🔍 DEBUG: TaTpDeliveryPage - API Error: ${response.message}');
      }
    } catch (e) {
      print('🔍 DEBUG: TaTpDeliveryPage - Exception: ${e.toString()}');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih gambar: $e')),
        );
      }
    }
  }

  Widget _buildItemsList() {
    if (_deliveryData?.items.isEmpty ?? true) {
      return const Text(
        'Tidak ada barang dalam pengiriman ini',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      );
    }

    return Column(
      children: _deliveryData!.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildItemCard(item, index);
      }).toList(),
    );
  }

  Widget _buildItemCard(DeliveryItem item, int index) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${item.itemName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaTpItemDetailPage(
                        deliveryCode: widget.deliveryCode,
                        token: widget.token,
                        itemIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/items-view-icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 7,
          color: Color.fromARGB(255, 192, 191, 191),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailPenerima() {
    if (_deliveryData?.consignees.isEmpty ?? true) {
      return const Text(
        'Data penerima tidak tersedia',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF6B7280),
        ),
      );
    }

    return Column(
      children: _deliveryData!.consignees.map((consignee) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama Penerima',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Text(
                consignee.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No HP (Whatsapp)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Text(
                consignee.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUploadPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti Terima Barang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single circular photo placeholder on the left
            Column(
              children: [
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 100,
                    height: 100,
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
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unggah Foto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Description input field
            Expanded(
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
                decoration: const InputDecoration(
                  hintText: 'Masukkan keterangan barang...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A), width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isButtonEnabled() {
    // TP role: button enabled when status is "2"
    // TA role: button enabled when status is "3"
    if (widget.userRole == UserRole.tp) {
      return widget.status == "2";
    } else if (widget.userRole == UserRole.ta) {
      return widget.status == "3";
    }
    return false;
  }

  void _handleKonfirmasiTerima() {
    if (!_isButtonEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.userRole == UserRole.tp 
                ? 'Status harus "2" untuk mengkonfirmasi'
                : 'Status harus "3" untuk mengkonfirmasi'
          ),
        ),
      );
      return;
    }

    // TODO: Implement confirmation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konfirmasi terima berhasil'),
        backgroundColor: Color(0xFF1B8B7A),
      ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terima Barang',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B8B7A)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeliveryDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8B7A),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daftar Barang Section
                      const Text(
                        'Daftar Barang',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildItemsList(),
                      const SizedBox(height: 40),

                      // Detail Penerima Section
                      const Text(
                        'Detail Penerima',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailPenerima(),
                      const SizedBox(height: 40),

                      // Upload Photo Section
                      _buildUploadPhotoSection(),
                      const SizedBox(height: 60),

                      // Konfirmasi Terima Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isButtonEnabled() ? _handleKonfirmasiTerima : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isButtonEnabled() 
                                ? const Color(0xFF1B8B7A) 
                                : const Color(0xFFE5E7EB),
                            foregroundColor: _isButtonEnabled() 
                                ? Colors.white 
                                : const Color(0xFF9CA3AF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            widget.userRole == UserRole.tp ? 'Terima Barang' : 'Konfirmasi Terima',
                            style: const TextStyle(
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}