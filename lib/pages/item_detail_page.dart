import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/delivery_transaction_detail_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'image_preview_page.dart';

class ItemDetailPage extends StatefulWidget {
  final String deliveryCode;
  final String token;
  final int itemIndex;
  
  const ItemDetailPage({
    super.key, 
    required this.deliveryCode,
    required this.token,
    required this.itemIndex,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  DeliveryItem? _itemData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: ItemDetailPage - initState called');
    print('🔍 DEBUG: ItemDetailPage - deliveryCode: ${widget.deliveryCode}');
    print('🔍 DEBUG: ItemDetailPage - token: ${widget.token.substring(0, 20)}...');
    print('🔍 DEBUG: ItemDetailPage - itemIndex: ${widget.itemIndex}');
    _loadItemDetail();
  }

  Future<void> _loadItemDetail() async {
    try {
      print('🔍 DEBUG: ItemDetailPage - Starting _loadItemDetail...');
      print('🔍 DEBUG: ItemDetailPage - deliveryCode: ${widget.deliveryCode}');
      print('🔍 DEBUG: ItemDetailPage - itemIndex: ${widget.itemIndex}');
      print('🔍 DEBUG: ItemDetailPage - token: ${widget.token.substring(0, 20)}...');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔍 DEBUG: ItemDetailPage - Using token directly from widget: ${widget.token.substring(0, 20)}...');

      // Get transaction detail using token from widget
      print('🔍 DEBUG: ItemDetailPage - Calling getTransactionDetail...');
      final response = await _apiService.getTransactionDetail(widget.deliveryCode, widget.token);
      
      print('🔍 DEBUG: ItemDetailPage - API Response received');
      print('🔍 DEBUG: ItemDetailPage - Response ok: ${response.ok}');
      print('🔍 DEBUG: ItemDetailPage - Response message: ${response.message}');
      
      if (response.ok && response.data != null) {
        print('🔍 DEBUG: ItemDetailPage - Items count: ${response.data!.items.length}');
        print('🔍 DEBUG: ItemDetailPage - Requested itemIndex: ${widget.itemIndex}');
        
        if (widget.itemIndex < response.data!.items.length) {
          final item = response.data!.items[widget.itemIndex];
          print('🔍 DEBUG: ItemDetailPage - Item found: ${item.itemName}');
          print('🔍 DEBUG: ItemDetailPage - Item photos count: ${item.photo.length}');
          
          setState(() {
            _itemData = item;
            _isLoading = false;
          });
        } else {
          print('🔍 DEBUG: ItemDetailPage - Item index out of range');
          setState(() {
            _errorMessage = 'Item tidak ditemukan';
            _isLoading = false;
          });
        }
      } else {
        print('🔍 DEBUG: ItemDetailPage - API Error: ${response.message}');
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔍 DEBUG: ItemDetailPage - Exception caught: ${e.toString()}');
      print('🔍 DEBUG: ItemDetailPage - Exception type: ${e.runtimeType}');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getFileExtensionFromBase64(String base64Data) {
    // Detect file format from base64 data header
    if (base64Data.startsWith('/9j/') || base64Data.startsWith('data:image/jpeg')) {
      return '.jpg';
    } else if (base64Data.startsWith('iVBORw0KGgo') || base64Data.startsWith('data:image/png')) {
      return '.png';
    } else if (base64Data.startsWith('R0lGODlh') || base64Data.startsWith('data:image/gif')) {
      return '.gif';
    } else if (base64Data.startsWith('UklGR') || base64Data.startsWith('data:image/webp')) {
      return '.webp';
    } else {
      return '.jpg'; // Default fallback
    }
  }

  String _cleanBase64Data(String base64Data) {
    // Remove data URL prefix if present
    if (base64Data.contains(',')) {
      return base64Data.split(',').last;
    }
    return base64Data;
  }

  Uint8List? _convertBase64ToImage(String base64Data) {
    try {
      print('🔍 DEBUG: ItemDetailPage - Converting base64 to image...');
      print('🔍 DEBUG: ItemDetailPage - Base64 data length: ${base64Data.length}');
      print('🔍 DEBUG: ItemDetailPage - Base64 data preview: ${base64Data.substring(0, base64Data.length > 50 ? 50 : base64Data.length)}...');
      
      final cleanedData = _cleanBase64Data(base64Data);
      print('🔍 DEBUG: ItemDetailPage - Cleaned data length: ${cleanedData.length}');
      
      final result = base64Decode(cleanedData);
      print('🔍 DEBUG: ItemDetailPage - Successfully converted to image, bytes: ${result.length}');
      return result;
    } catch (e) {
      print('🔍 DEBUG: ItemDetailPage - Error converting base64 to image: $e');
      return null;
    }
  }

  Widget _buildReadOnlyTextField({
    required String label,
    required String value,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_itemData?.photo.isEmpty ?? true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Barang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Single circular photo placeholder on the left
              Column(
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
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Foto Barang',
                    style: TextStyle(
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    _itemData?.itemDescription?.isEmpty ?? true ? '-' : _itemData!.itemDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF374151),
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi Barang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section on the left
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_itemData!.photo.isNotEmpty) {
                      final photo = _itemData!.photo[0];
                      final imageData = _convertBase64ToImage(photo.photo64);
                      if (imageData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImagePreviewPage(
                              imageData: imageData,
                              filename: 'photo_1${_getFileExtensionFromBase64(photo.photo64)}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: _itemData!.photo.isNotEmpty
                        ? () {
                            final imageData = _convertBase64ToImage(_itemData!.photo[0].photo64);
                            return imageData != null
                                ? ClipOval(
                                    child: Image.memory(
                                      imageData,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF9CA3AF),
                                    size: 24,
                                  );
                          }()
                        : const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF9CA3AF),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto Barang',
                  style: TextStyle(
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Text(
                  _itemData?.itemDescription?.isEmpty ?? true ? '-' : _itemData!.itemDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                  maxLines: 3,
                ),
              ),
            ),
          ],
        ),
        if (_itemData!.photo.length > 1) ...[
          const SizedBox(height: 12),
          Text(
            '+${_itemData!.photo.length - 1} foto lainnya',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ],
    );
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detail Barang',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B8B7A),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadItemDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8B7A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Fields
                      const Text(
                        'Detail Barang', // JANGAN DIUBAH
                style: TextStyle(
                  fontSize: 24, //JANGAN DIUBAH
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 28),

              _buildReadOnlyTextField(
                label: 'Nama Barang',
                value: _itemData?.itemName?.isEmpty ?? true ? '-' : _itemData!.itemName,
              ),
              const SizedBox(height: 16),

              _buildReadOnlyTextField(
                label: 'Jumlah Barang',
                value: _itemData?.qty?.toString() ?? '-',
              ),
              const SizedBox(height: 16),

              _buildReadOnlyTextField(
                label: 'Serial Number',
                value: _itemData?.serialNumber?.isEmpty ?? true ? '-' : _itemData!.serialNumber,
              ),
                      const SizedBox(height: 24),

                      // Photo and Description Section
                      _buildPhotoSection(),
                    ],
                  ),
                ),
    );
  }
}