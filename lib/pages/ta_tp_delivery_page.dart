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
import '../widgets/custommodals.dart';
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
        // Reset foto yang sudah dipilih saat refresh
        _selectedImage = null;
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
      print('🔍 DEBUG: Selected image path: ${_selectedImage?.path}');
      print('🔍 DEBUG: Delivery code: ${widget.deliveryCode}');
      print('🔍 DEBUG: Description: ${_descriptionController.text.trim()}');

      // Convert image to base64
      print('🔍 DEBUG: Converting image to base64...');
      final base64Image = await _convertImageToBase64(_selectedImage!);
      if (base64Image == null) {
        print('🚨 DEBUG: Failed to convert image to base64');
        CustomModals.showErrorModal(
          context,
          'Gagal memproses foto. Silakan coba lagi.',
        );
        return false;
      }
      print('🔍 DEBUG: Base64 conversion successful, length: ${base64Image.length}');

      // Prepare photo body
      final photoBody = {
        "photo": [
          {
            "photo64": base64Image,
            "filename": "delivery_${widget.deliveryCode}_${DateTime.now().millisecondsSinceEpoch}.jpg",
            "description": _descriptionController.text.trim().isEmpty 
                ? "Foto bukti terima barang" 
                : _descriptionController.text.trim(),
          }
        ]
      };

      print('🔍 DEBUG: Photo body prepared:');
      print('🔍 DEBUG: - filename: ${photoBody["photo"]![0]["filename"]}');
      print('🔍 DEBUG: - description: ${photoBody["photo"]![0]["description"]}');
      print('🔍 DEBUG: - photo64 length: ${photoBody["photo"]![0]["photo64"]?.length}');

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

      print('🔍 DEBUG: Preparing API call...');
      print('🔍 DEBUG: Endpoint: Transaction/Trx/Receive');
      print('🔍 DEBUG: Query params: DeliveryCode=${widget.deliveryCode}');

      // Hit API endpoint
      print('🔍 DEBUG: Calling API...');
      final response = await _apiService.post(
        'Transaction/Trx/Receive',
        photoBody,
        token: token,
        queryParams: {
          'DeliveryCode': widget.deliveryCode,
        },
      );

      print('🔍 DEBUG: API call completed');
      print('🔍 DEBUG: Full response: $response');
      print('🔍 DEBUG: Response type: ${response.runtimeType}');

      // Check API response structure - focus on 'ok' field only
      final responseData = response['data'];
      print('🔍 DEBUG: Response data type: ${responseData.runtimeType}');
      print('🔍 DEBUG: Response data content: $responseData');
      print('🔍 DEBUG: Response data ok value: ${responseData?['ok']}');
      
      if (responseData != null && responseData['ok'] == true) {
        print('🔍 DEBUG: Response data ok is true - SUCCESS!');
        
        // Gunakan WidgetsBinding untuk memastikan frame selesai sebelum menampilkan modal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomModals.hideLoadingModal(context);
          print('🔍 DEBUG: Loading modal hidden, about to show success modal...');
          
          CustomModals.showSuccessModal(
            context,
            'Konfirmasi penerimaan barang berhasil!',
            onOk: () {
              print('🔍 DEBUG: Success modal OK button pressed');
              // Refresh halaman setelah modal ditutup
              _loadDeliveryDetail();
            },
          );
          print('🔍 DEBUG: Success modal called');
        });
        return true;
      } else {
        print('🚨 DEBUG: Response data ok is not true - FAILED!');
        print('🚨 DEBUG: Response data ok value: ${responseData?['ok']}');
        final errorMessage = responseData?['message'] ?? 'Gagal mengkonfirmasi penerimaan barang';
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
          'Terjadi kesalahan: ${e.toString()}',
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
    // Special case: TA role with status "2" and only 1 consignee bypasses normal rule
    // Exception: bypass does NOT apply if status is "4" (already received by target)
    
    if (widget.userRole == UserRole.tp) {
      return widget.status == "2";
    } else if (widget.userRole == UserRole.ta) {
      // Check if there's only 1 consignee and status is "2" - bypass normal TA rule
      // BUT NOT if status is "4" (already received by target)
      if (widget.status == "2" && widget.status != "4" && _deliveryData != null && _deliveryData!.consignees.length == 1) {
        print('🔍 DEBUG: TA role bypass - status "2" with single consignee, enabling button');
        return true;
      }
      // Normal TA rule: enabled when status is "3"
      return widget.status == "3";
    }
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
      return;
    }

    // Validasi foto terlebih dahulu sebelum show loading
    if (_selectedImage == null) {
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
        'Terjadi kesalahan saat memproses konfirmasi: ${e.toString()}',
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