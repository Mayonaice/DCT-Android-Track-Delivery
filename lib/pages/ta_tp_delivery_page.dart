import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/delivery_transaction_detail_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/photo_cache_service.dart';
import '../services/pdf_service.dart';
import '../services/watermark_service.dart';
import '../enums/user_role.dart';
import '../widgets/custommodals.dart';
import 'ta_tp_item_detail_page.dart';
import 'image_preview_page.dart';
import 'photo_preview_page.dart';

class TaTpDeliveryPage extends StatefulWidget {
  final String deliveryCode;
  final String? deliveryNo; // Add deliveryNo parameter
  final String loginCode; // Kode yang dimasukkan user saat login (TP/TA)
  final int loginSeqNo; // SeqNo dari respon LoginByCode untuk memetakan langkah TP
  final String token;
  final UserRole userRole;
  final String status; // Status dari response login by code

  const TaTpDeliveryPage({
    Key? key,
    required this.deliveryCode,
    this.deliveryNo, // Make it optional for backward compatibility
    required this.loginCode,
    required this.loginSeqNo,
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
  List<File> _selectedImages = [];

  // Helper: treat sentinel or empty date string as null/empty
  bool _isNullishDate(String? value) {
    if (value == null) return true;
    final v = value.trim();
    if (v.isEmpty) return true;
    final lower = v.toLowerCase();
    // Common sentinel formats: 0001-01-01T00:00:00 or with space
    if (lower.startsWith('0001-01-01')) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: TaTpDeliveryPage initState called');
    print('🔍 DEBUG: deliveryCode: ${widget.deliveryCode}');
    print('🔍 DEBUG: loginCode: ${widget.loginCode}');
    print('🔍 DEBUG: loginSeqNo: ${widget.loginSeqNo}');
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
        // Reset foto yang sudah dipilih saat refresh
        _selectedImages.clear();
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
        _errorMessage = e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    // Check if there are existing photos in cache
    final photoCacheService = PhotoCacheService();
    final cachedPhotos = await photoCacheService.getItemPhotos('ta_tp_${widget.deliveryCode}');
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
          itemId: 'ta_tp_${widget.deliveryCode}',
          existingPhotos: _selectedImages.isNotEmpty ? _selectedImages : null,
        ),
      ),
    );
    
    if (result != null && result is List<File>) {
      setState(() {
        _selectedImages = result;
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
                itemId: 'ta_tp_${widget.deliveryCode}',
                existingPhotos: _selectedImages.isNotEmpty ? _selectedImages : null,
              ),
            ),
          );
          
          if (result != null && result is List<File>) {
            setState(() {
              _selectedImages = result;
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
                itemId: 'ta_tp_${widget.deliveryCode}',
                existingPhotos: currentImages,
              ),
            ),
          );
          
          if (result != null && result is List<File>) {
            setState(() {
              _selectedImages = result;
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

  // Fungsi untuk mengkonversi File ke Base64
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  // Method untuk hit API PostReceiveData
  Future<bool> _postReceiveData() async {
    try {
      print('🔍 DEBUG: Starting _postReceiveData...');
      print('🔍 DEBUG: Selected images count: ${_selectedImages.length}');
      print('🔍 DEBUG: Delivery code: ${widget.deliveryCode}');
      print('🔍 DEBUG: Description: ${_descriptionController.text.trim()}');

      if (_selectedImages.isEmpty) {
        print('🚨 DEBUG: No images selected');
        CustomModals.showErrorModal(
          context,
          'Pilih foto terlebih dahulu.',
        );
        return false;
      }

      // Convert all images to base64
      print('🔍 DEBUG: Converting images to base64...');
      List<Map<String, String>> photoList = [];
      
      for (int i = 0; i < _selectedImages.length; i++) {
        final base64Image = await _convertImageToBase64(_selectedImages[i]);
        if (base64Image == null) {
          print('🚨 DEBUG: Failed to convert image ${i + 1} to base64');
          CustomModals.showErrorModal(
            context,
            'Gagal memproses foto ${i + 1}. Silakan coba lagi.',
          );
          return false;
        }
        
        photoList.add({
          "photo64": base64Image,
          "filename": "delivery_${widget.deliveryCode}_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg",
          "description": _descriptionController.text.trim().isEmpty 
              ? "Foto bukti terima barang ${i + 1}" 
              : "${_descriptionController.text.trim()} - Foto ${i + 1}",
        });
      }
      
      print('🔍 DEBUG: Base64 conversion successful for ${photoList.length} images');

      // Prepare photo body
      final photoBody = {
        "photo": photoList
      };

      print('🔍 DEBUG: Photo body prepared with ${photoList.length} photos');

      // Get token from storage
      print('🔍 DEBUG: Getting token from storage...');
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        print('🚨 DEBUG: Token is null or empty');
        CustomModals.showErrorModal(
          context,
          'Token tidak ditemukan. Silakan login ulang.',
        );
        return false;
      }
      print('🔍 DEBUG: Token retrieved successfully, length: ${token.length}');

      // Determine endpoint based on role and status
      final endpoint = _getEndpointForRoleAndStatus();
      
      print('🔍 DEBUG: Preparing API call...');
      print('🔍 DEBUG: Endpoint: $endpoint');
      print('🔍 DEBUG: Query params: DeliveryCode=${widget.deliveryCode}');

      // Hit API endpoint
      print('🔍 DEBUG: Calling API...');
      final response = await _apiService.post(
        endpoint,
        photoBody,
        token: token,
        queryParams: {
          'DeliveryCode': widget.deliveryCode,
        },
      );

      print('🔍 DEBUG: API call completed');
      print('🔍 DEBUG: Full response: $response');
      print('🔍 DEBUG: Response type: ${response.runtimeType}');

      // Check API response structure - handle 'ok'/'Ok' casing
      final responseData = response['data'];
      print('🔍 DEBUG: Response data type: ${responseData.runtimeType}');
      print('🔍 DEBUG: Response data content: $responseData');
      final bool isOk = (responseData?['ok'] == true) || (responseData?['Ok'] == true);
      print('🔍 DEBUG: Response data ok value: ${responseData?['ok'] ?? responseData?['Ok']}');
      
      if (responseData != null && isOk) {
        print('🔍 DEBUG: Response data ok is true - SUCCESS!');
        
        // Check if this is TA role performing receive/confirm actions that should generate PDF
        bool shouldCallReceiveDocuments = false;
        final statusInt = int.tryParse(widget.status) ?? 0;
        
        if (widget.userRole == UserRole.ta) {
          // TA with status 3 (Terima Barang) or status 4 (Konfirmasi Terima)
          // Also allow status 2 with single consignee (bypass)
          if (statusInt == 3 || statusInt == 4 || (statusInt == 2 && _deliveryData != null && _deliveryData!.consignees.length == 1)) {
            shouldCallReceiveDocuments = true;
            print('🔍 DEBUG: TA role - will generate PDF and call ReceiveDocuments endpoint (status: $statusInt)');
          }
        }
        
        // If TA role performing eligible actions, generate PDF and hit ReceiveDocuments endpoint
        if (shouldCallReceiveDocuments) {
          print('🔍 DEBUG: Generating PDF first before calling ReceiveDocuments...');
          
          try {
            // Debug: Check delivery data and items
            print('🔍 DEBUG: _deliveryData is null: ${_deliveryData == null}');
            print('🔍 DEBUG: _deliveryData.items length: ${_deliveryData?.items.length ?? 0}');
            if (_deliveryData?.items.isNotEmpty == true) {
              print('🔍 DEBUG: First item deliveryNo: ${_deliveryData!.items.first.deliveryNo}');
              print('🔍 DEBUG: First item itemName: ${_deliveryData!.items.first.itemName}');
            }
            
            // Get deliveryNo from first item if available
            String deliveryCodeForReceiveDocuments = widget.deliveryCode; // fallback
            if (_deliveryData?.items.isNotEmpty == true && _deliveryData!.items.first.deliveryNo != null) {
              deliveryCodeForReceiveDocuments = _deliveryData!.items.first.deliveryNo!;
              print('🔍 DEBUG: Using deliveryNo from first item: $deliveryCodeForReceiveDocuments');
            } else {
              print('🔍 DEBUG: No deliveryNo found in items, using deliveryCode: $deliveryCodeForReceiveDocuments');
            }
            
            print('🔍 DEBUG: Final deliveryCodeForReceiveDocuments: $deliveryCodeForReceiveDocuments');
            
            if (_deliveryData == null) {
              print('🚨 DEBUG: Cannot generate PDF because _deliveryData is null');
            } else {
            // Generate PDF first
            final pdfFile = await PdfService.generateReceiptPdf(
              deliveryData: _deliveryData!,
              deliveryCode: deliveryCodeForReceiveDocuments,
            );
            
            print('🔍 DEBUG: PDF generated successfully at: ${pdfFile.path}');
            
            // Convert PDF to base64 for API upload
            final pdfBytes = await pdfFile.readAsBytes();
            final pdfBase64 = base64Encode(pdfBytes);
            
            // Prepare body with PDF file for ReceiveDocuments (matching ReceiveGoods model)
            final receiveDocumentsBody = {
              "Photo": [
                {
                  "Photo64": pdfBase64,
                  "Filename": "receipt_$deliveryCodeForReceiveDocuments.pdf",
                  "Description": "Tanda terima barang untuk delivery $deliveryCodeForReceiveDocuments"
                }
              ]
            };
            
            print('🔍 DEBUG: Calling ReceiveDocuments endpoint with PDF...');
            print('🔍 DEBUG: GET URL will be: Transaction2/Trx/ReceiveDocuments?DeliveryCode=$deliveryCodeForReceiveDocuments');
            
            final receiveDocumentsResponse = await _apiService.post(
              'Transaction2/Trx/ReceiveDocuments',
              receiveDocumentsBody,
              token: token,
              queryParams: {
                'DeliveryCode': deliveryCodeForReceiveDocuments, // Use deliveryNo from first item if available
              },
            );
            
            print('🔍 DEBUG: ReceiveDocuments API call completed');
            print('🔍 DEBUG: ReceiveDocuments response: $receiveDocumentsResponse');
            
            final receiveDocumentsData = receiveDocumentsResponse['data'];
            final bool receiveOk = (receiveDocumentsData?['ok'] == true) || (receiveDocumentsData?['Ok'] == true);
            
            if (receiveDocumentsData != null && receiveOk) {
              print('🔍 DEBUG: ReceiveDocuments call successful with PDF!');
            } else {
              final msg = receiveDocumentsData?['message'] ?? receiveDocumentsData?['Message'];
              print('🚨 DEBUG: ReceiveDocuments call failed: $msg');
              // Don't fail the entire operation if ReceiveDocuments fails
            }
            }
          } catch (error) {
            print('🚨 DEBUG: PDF generation or ReceiveDocuments API call exception: $error');
            // Don't fail the entire operation if PDF generation or ReceiveDocuments fails
          }
        }
        
        // Show success modal regardless of ReceiveDocuments result
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomModals.hideLoadingModal(context);
          print('🔍 DEBUG: Loading modal hidden, about to show success modal...');
          
          CustomModals.showSuccessModal(
            context,
            'Konfirmasi penerimaan barang berhasil!',
            onOk: () async {
              print('🔍 DEBUG: Success modal OK button pressed');
              // Clear photo cache after successful post action
              final photoCacheService = PhotoCacheService();
              await photoCacheService.clearItemPhotos('ta_tp_${widget.deliveryCode}');
              print('🔍 DEBUG: Photo cache cleared for ta_tp_${widget.deliveryCode}');
              // Refresh halaman setelah modal ditutup
              _loadDeliveryDetail();
            },
          );
          print('🔍 DEBUG: Success modal called');
        });
        return true;
      } else {
        print('🚨 DEBUG: Response data ok is not true - FAILED!');
        print('🚨 DEBUG: Response data ok value: ${responseData?['ok'] ?? responseData?['Ok']}');
        final errorMessage = responseData?['message'] ?? responseData?['Message'] ?? 'Gagal mengkonfirmasi penerimaan barang';
        print('🚨 DEBUG: Error message: $errorMessage');
        
        // Gunakan WidgetsBinding untuk memastikan frame selesai sebelum menampilkan modal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomModals.hideLoadingModal(context);
          print('🚨 DEBUG: Loading modal hidden, about to show error modal...');
          
          CustomModals.showErrorModal(
            context,
            errorMessage,
            onOk: () {
              print('🚨 DEBUG: Error modal OK button pressed');
              // Refresh halaman setelah modal ditutup
              _loadDeliveryDetail();
            },
          );
          print('🚨 DEBUG: Error modal called');
        });
        return false;
      }
    } catch (e) {
      print('🚨 DEBUG: Exception in _postReceiveData: $e');
      print('🚨 DEBUG: Exception type: ${e.runtimeType}');
      print('🚨 DEBUG: Stack trace: ${StackTrace.current}');
      
      // Gunakan WidgetsBinding untuk memastikan frame selesai sebelum menampilkan modal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomModals.hideLoadingModal(context);
        print('🚨 DEBUG: Loading modal hidden, about to show exception error modal...');
        
        CustomModals.showErrorModal(
          context,
          e is TimeoutException
              ? 'Koneksi Timeout, harap hubungi tim IT'
              : 'Terjadi kesalahan: ${e.toString()}',
          onOk: () {
            print('🚨 DEBUG: Exception error modal OK button pressed');
            // Refresh halaman setelah modal ditutup
            _loadDeliveryDetail();
          },
        );
        print('🚨 DEBUG: Exception error modal called');
      });
      return false;
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
        
        // Photo and description in one row (matching add_items_form_page.dart)
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
    final statusInt = int.tryParse(widget.status) ?? 0;
    
    print('🔍 DEBUG: Checking button enabled for role: ${widget.userRole}, status: ${widget.status}');
    
    // Helper: consignees-based sequential TP logic
    List<DeliveryConsignee> _sortedConsignees() {
      final list = List<DeliveryConsignee>.from(_deliveryData?.consignees ?? []);
      list.sort((a, b) {
        final aSeq = a.seqNo ?? 1 << 30; // null seq goes to end
        final bSeq = b.seqNo ?? 1 << 30;
        return aSeq.compareTo(bSeq);
      });
      return list;
    }

    List<DeliveryConsignee> _tpConsigneesExcludingLast() {
      final sorted = _sortedConsignees();
      if (sorted.length <= 1) return sorted; // nothing to exclude
      return sorted.sublist(0, sorted.length - 1);
    }

    int _pendingTpIndex() {
      final tpList = _tpConsigneesExcludingLast();
      for (int i = 0; i < tpList.length; i++) {
        final c = tpList[i];
        final received = !_isNullishDate(c.timeReceived);
        if (!received) {
          return i; // first pending TP step
        }
      }
      return -1; // all TP steps done
    }

    // Gating TP berlaku bila ada minimal satu langkah TP (>=2 consignees)
    final hasSequentialTp = (_deliveryData?.consignees.length ?? 0) >= 2;

    if (widget.userRole == UserRole.tp) {
      // TP role: tombol aktif hanya untuk TP yang sesuai loginSeqNo dan sesuai urutan.
      final sorted = _sortedConsignees();
      if (sorted.isEmpty) {
        print('🔍 DEBUG: No consignees found - TP button disabled');
        return false;
      }

      int _findCurrentIndex() {
        for (int i = 0; i < sorted.length; i++) {
          final c = sorted[i];
          if (c.seqNo != null && c.seqNo == widget.loginSeqNo) return i;
        }
        return -1;
      }

      final currentIndex = _findCurrentIndex();
      if (currentIndex == -1) {
        // Tidak bisa memetakan login ke consignee mana pun: demi keamanan, disable
        print('🚫 DEBUG: Cannot map loginSeqNo to any consignee.seqNo - TP button disabled');
        return false;
      }

      final currentConsignee = sorted[currentIndex];
      final currentReceived = !_isNullishDate(currentConsignee.timeReceived);
      final previousAllReceived = sorted
          .take(currentIndex)
          .every((c) => !_isNullishDate(c.timeReceived));

      // Untuk kasus berjenjang (>=2 consignees): abaikan status, hanya urutan & timeReceived yang menentukan
      if (sorted.length >= 2) {
        final enabled = previousAllReceived && !currentReceived;
        print('🔍 DEBUG: TP sequential gating -> previousAllReceived: $previousAllReceived, currentReceived: $currentReceived, enabled: $enabled');
        return enabled;
      }

      // Kasus single consignee: tetap hormati status == "2"
      final enabled = (widget.status == "2") && !currentReceived;
      print('🔍 DEBUG: TP single gating -> status==2: ${widget.status == "2"}, currentReceived: $currentReceived, enabled: $enabled');
      return enabled;
    } else if (widget.userRole == UserRole.ta) {
      // Special case: TA role with status "2" and only 1 consignee bypasses normal rule
      // BUT NOT if status is "4" (already received by target)
      if (widget.status == "2" && widget.status != "4" && _deliveryData != null && _deliveryData!.consignees.length == 1) {
        print('🔍 DEBUG: TA role bypass - status "2" with single consignee, enabling button');
        return true;
      }
      
      // Sequential TP consideration for TA:
      // If there are >2 consignees, TA should only be enabled when all TP steps are completed
      if (hasSequentialTp) {
        final pendingIndex = _pendingTpIndex();
        final tpAllDone = pendingIndex == -1;
        if (!tpAllDone) {
          print('🔍 DEBUG: TA role - sequential TP pending (index $pendingIndex), disabling button');
          return false;
        }
        // All TP steps done -> follow normal TA rules
      }
      
      // Normal TA rules:
      // - Status 3: enabled (uses Trx/Receive endpoint, same as TP)
      // - Status 4: enabled (uses Trx/Confirm endpoint)
      if (statusInt == 3) {
        print('🔍 DEBUG: TA role - status 3 - button enabled: true');
        return true;
      } else if (statusInt == 4) {
        print('🔍 DEBUG: TA role - status 4 - button enabled: true');
        return true;
      } else {
        print('🔍 DEBUG: TA role - status ${widget.status} - button enabled: false');
        return false;
      }
    }
    
    print('🔍 DEBUG: Unknown role - button enabled: false');
    return false;
  }

  void _handleKonfirmasiTerima() async {
    if (!_isButtonEnabled()) {
      String errorMessage;
      if (widget.userRole == UserRole.tp) {
        errorMessage = 'Status harus "2" untuk mengkonfirmasi';
      } else if (widget.userRole == UserRole.ta) {
        if (_deliveryData != null && _deliveryData!.consignees.length == 1) {
          errorMessage = 'Status harus "2" atau "3" untuk mengkonfirmasi (bypass untuk 1 penerima)';
        } else {
          errorMessage = 'Status harus "3" untuk mengkonfirmasi';
        }
      } else {
        errorMessage = 'Role tidak valid untuk konfirmasi';
      }
      
      CustomModals.showErrorModal(
        context,
        errorMessage,
      );
      return;
    }

    // Validasi foto terlebih dahulu sebelum show loading
    if (_selectedImages.isEmpty) {
      CustomModals.showErrorModal(
        context,
        'Upload foto bukti terima barang terlebih dahulu!',
      );
      return;
    }

    // Show loading modal
    CustomModals.showLoadingModal(context, message: 'Memproses konfirmasi...');

    try {
      // Call API endpoint
      final success = await _postReceiveData();
      
      // Hide loading modal
      CustomModals.hideLoadingModal(context);
      
      if (success) {
        print('🔍 DEBUG: Konfirmasi penerimaan barang berhasil');
      } else {
        print('🔍 DEBUG: Konfirmasi penerimaan barang gagal');
      }
    } catch (e) {
      // Hide loading modal in case of error
      CustomModals.hideLoadingModal(context);
      print('🚨 DEBUG: Error in _handleKonfirmasiTerima: $e');
      
      CustomModals.showErrorModal(
        context,
        e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat memproses konfirmasi: ${e.toString()}',
      );
    }
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
                             _getButtonTextForRoleAndStatus(),
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

  // Helper method to determine endpoint based on role and status
  String _getEndpointForRoleAndStatus() {
    final statusInt = int.tryParse(widget.status) ?? 0;
    
    print('🔍 DEBUG: Determining endpoint for role: ${widget.userRole}, status: ${widget.status}');
    
    if (widget.userRole == UserRole.tp) {
      // TP always uses Trx/Receive (only for status 2)
      print('🔍 DEBUG: TP role - using Trx/Receive endpoint');
      return 'Transaction/Trx/Receive';
    } else if (widget.userRole == UserRole.ta) {
      if (statusInt == 3) {
        // TA with status 3 uses Trx/Receive (same as TP)
        print('🔍 DEBUG: TA role with status 3 - using Trx/Receive endpoint');
        return 'Transaction/Trx/Receive';
      } else if (statusInt == 4) {
        // TA with status 4 uses Trx/Confirm
        print('🔍 DEBUG: TA role with status 4 - using Trx/Confirm endpoint');
        return 'Transaction/Trx/Confirm';
      } else {
        // Default fallback for other statuses
        print('🔍 DEBUG: TA role with status ${widget.status} - using default Trx/Receive endpoint');
        return 'Transaction/Trx/Receive';
      }
    }
    
    // Default fallback
    print('🔍 DEBUG: Default fallback - using Trx/Receive endpoint');
    return 'Transaction/Trx/Receive';
  }

  // Helper method to determine button text based on role and status
  String _getButtonTextForRoleAndStatus() {
    final statusInt = int.tryParse(widget.status) ?? 0;
    
    print('🔍 DEBUG: Determining button text for role: ${widget.userRole}, status: ${widget.status}');
    
    // Helper for TP numbering label
    String _tpOrderLabel() {
      final list = List<DeliveryConsignee>.from(_deliveryData?.consignees ?? []);
      list.sort((a, b) => (a.seqNo ?? 1 << 30).compareTo(b.seqNo ?? 1 << 30));
      if (list.length <= 2) return '';
      final tpList = list.sublist(0, list.length - 1);
      int order = 1;
      for (int i = 0; i < tpList.length; i++) {
        final c = tpList[i];
        final received = !_isNullishDate(c.timeReceived);
        if (!received) {
          order = i + 1; // next pending TP order (1-based)
          break;
        }
        // if all received, keep last order value
        order = tpList.length; 
      }
      return ' (TP$order)';
    }

    if (widget.userRole == UserRole.tp) {
      // TP shows "Terima Barang" with order label when sequential TP applies
      print('🔍 DEBUG: TP role - button text: Terima Barang');
      return 'Terima Barang';
    } else if (widget.userRole == UserRole.ta) {
      if (statusInt == 3) {
        // TA with status 3 shows "Terima Barang" (same as TP)
        print('🔍 DEBUG: TA role with status 3 - button text: Terima Barang');
        return 'Terima Barang';
      } else if (statusInt == 4) {
        // TA with status 4 shows "Konfirmasi Terima"
        print('🔍 DEBUG: TA role with status 4 - button text: Konfirmasi Terima');
        return 'Konfirmasi Terima';
      } else {
        // Default for other statuses
        print('🔍 DEBUG: TA role with status ${widget.status} - button text: Konfirmasi Terima');
        return 'Konfirmasi Terima';
      }
    }
    
    // Default fallback
    print('🔍 DEBUG: Default fallback - button text: Terima Barang');
    return 'Terima Barang';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}