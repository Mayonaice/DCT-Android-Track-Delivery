import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/config.dart';
import '../models/delivery_transaction_detail_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../widgets/custommodals.dart';
import 'item_detail_page.dart';
import 'delivery_status_detail_page.dart';
import 'pdf_viewer_page.dart';

class DeliveryDetailPage extends StatefulWidget {
  final String deliveryCode;
  final String token;

  const DeliveryDetailPage({
    Key? key,
    required this.deliveryCode,
    required this.token,
  }) : super(key: key);

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  final ApiService _apiService = ApiService();
  DeliveryTransactionDetailData? _deliveryData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: DeliveryDetailPage initState called');
    print('🔍 DEBUG: deliveryCode: ${widget.deliveryCode}');
    print('🔍 DEBUG: token: ${widget.token.substring(0, 20)}...');
    _loadDeliveryDetail();
  }

  Future<void> _loadDeliveryDetail() async {
    print('🔍 DEBUG: Starting _loadDeliveryDetail...');
    print('🔍 DEBUG: Setting loading state to true');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 DEBUG: Calling API getTransactionDetail...');
      print('🔍 DEBUG: Parameters - deliveryCode: ${widget.deliveryCode}, token: ${widget.token.substring(0, 20)}...');
      
      final response = await _apiService.getTransactionDetail(widget.deliveryCode, widget.token);
      
      print('🔍 DEBUG: Transaction Detail API response received:');
      print('  - ok: ${response.ok}');
      print('  - message: ${response.message}');
      print('  - data is null: ${response.data == null}');
      
      if (response.data != null) {
        print('🔍 DEBUG: Response data details:');
        print('  - status: ${response.data!.status.status}');
        print('  - transactionTime: ${response.data!.status.transactionTime}');
        print('  - items count: ${response.data!.items.length}');
        print('  - consignees count: ${response.data!.consignees.length}');
        print('  - viewers count: ${response.data!.viewers.length}');
      }
      
      if (response.ok && response.data != null) {
        print('✅ DEBUG: Data loaded successfully, updating UI');
        setState(() {
          _deliveryData = response.data;
          _isLoading = false;
        });
      } else {
        print('❌ DEBUG: API returned error or null data, showing error');
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
        
        if (mounted) {
          CustomModals.showErrorModal(context, response.message);
        } else {
          print('🚨 DEBUG: Widget not mounted, skipping error modal');
        }
      }
    } catch (e) {
      print('🚨 DEBUG: Exception in _loadDeliveryDetail: $e');
      print('🚨 DEBUG: Exception type: ${e.runtimeType}');
      
      setState(() {
        _errorMessage = e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
      
      if (mounted) {
        CustomModals.showErrorModal(
          context,
          e is TimeoutException
              ? 'Koneksi Timeout, harap hubungi tim IT'
              : 'Terjadi kesalahan: ${e.toString()}',
        );
      } else {
        print('🚨 DEBUG: Widget not mounted, skipping error modal');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: DeliveryDetailPage build called');
    print('  - _isLoading: $_isLoading');
    print('  - _errorMessage: $_errorMessage');
    print('  - _deliveryData is null: ${_deliveryData == null}');
    
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
          'Detail Pengiriman',
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
                        onPressed: () {
                          print('🔍 DEBUG: Retry button pressed');
                          _loadDeliveryDetail();
                        },
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    print('🔍 DEBUG: _buildContent called');
    
    if (_deliveryData == null) {
      print('🚨 DEBUG: _deliveryData is null, showing "Data tidak tersedia"');
      return const Center(
        child: Text('Data tidak tersedia'),
      );
    }

    print('✅ DEBUG: _deliveryData is available, building content sections');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildItemsSection(),
          const SizedBox(height: 40),
          _buildConsigneeSection(),
          const SizedBox(height: 40),
          _buildViewersSection(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    print('🔍 DEBUG: Building status section');
    print('  - status: ${_deliveryData?.status.status}');
    print('  - transactionTime: ${_deliveryData?.status.transactionTime}');
    
    // Format the date
    String formattedDate = _deliveryData!.status.transactionTime;
    try {
      DateTime dateTime = DateTime.parse(_deliveryData!.status.transactionTime);
      formattedDate = DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
    }
    
    String displayCode = _resolveDisplayCode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _deliveryData!.status.status,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final token = await StorageService().getToken();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryStatusDetailPage(
                        deliveryCode: widget.deliveryCode,
                        token: token,
                      ),
                    ),
                  );
                } else {
                  // Handle case when token is null
                  CustomModals.showErrorModal(
                    context,
                    'Token tidak ditemukan, silakan login ulang',
                  );
                }
              },
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  color: Color(0xFF1B8B7A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayCode,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            GestureDetector(
              onTap: _openPdfViewer,
              child: const Text(
                'Lihat Tanda Terima',
                style: TextStyle(
                  color: Color(0xFF1B8B7A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tanggal Pengiriman',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _resolveDisplayCode() {
    final code = widget.deliveryCode;
    final prefix = code.length >= 2 ? code.substring(0, 2).toUpperCase() : '';
    if (prefix == 'TP' || prefix == 'TA' || prefix == 'TT') {
      return code;
    }
    String? deliveryNo;
    if (_deliveryData?.items.isNotEmpty == true) {
      deliveryNo = _deliveryData!.items.first.deliveryNo;
    }
    if ((deliveryNo == null || deliveryNo.isEmpty) && _deliveryData?.consignees.isNotEmpty == true) {
      deliveryNo = _deliveryData!.consignees.first.deliveryNo;
    }
    return deliveryNo ?? code;
  }

  Widget _buildItemsSection() {
    print('🔍 DEBUG: Building items section');
    print('  - items count: ${_deliveryData?.items?.length ?? 0}');
    
    if (_deliveryData?.items == null || _deliveryData!.items.isEmpty) {
      print('🚨 DEBUG: No items found in delivery data');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Barang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada barang dalam pengiriman ini',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Barang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 20),
        ..._deliveryData!.items.asMap().entries.map((entry) {
          int index = entry.key;
          DeliveryItem item = entry.value;
          return _buildItemCard(item, index);
        }).toList(),
      ],
    );
  }

  Widget _buildItemCard(DeliveryItem item, int index) {
    print('🔍 DEBUG: Building item card for: ${item.itemName}');
    
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
                  print('🔍 DEBUG: DeliveryDetailPage - Item icon tapped');
                  print('🔍 DEBUG: DeliveryDetailPage - Item name: ${item.itemName}');
                  print('🔍 DEBUG: DeliveryDetailPage - Item index: $index');
                  print('🔍 DEBUG: DeliveryDetailPage - Delivery code: ${widget.deliveryCode}');
                  print('🔍 DEBUG: DeliveryDetailPage - Token: ${widget.token.substring(0, 20)}...');
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(
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

  Widget _buildConsigneeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Penerima',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 20),
        ..._deliveryData!.consignees.map((consignee) => _buildPersonCard(
          name: consignee.name,
          phoneNumber: consignee.phoneNumber,
          isConsignee: true,
        )).toList(),
      ],
    );
  }

  Widget _buildViewersSection() {
    if (_deliveryData!.viewers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Tembusan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 20),
        ..._deliveryData!.viewers.map((viewer) => _buildPersonCard(
          name: viewer.name,
          phoneNumber: viewer.phoneNumber,
          isConsignee: false,
        )).toList(),
      ],
    );
  }

  Widget _buildPersonCard({
    required String name,
    required String phoneNumber,
    required bool isConsignee,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isConsignee ? 'Nama Penerima' : 'Nama Tembusan',
          style: const TextStyle(
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
            name,
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/images/No-HP-icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _openPdfViewer() async {
    try {
      // Show loading indicator
      CustomModals.showLoadingModal(context, message: 'Memuat tanda terima...');
      
      // Get deliveryNo from first item if available, fallback to deliveryCode
      String? deliveryNo;
      if (_deliveryData?.items.isNotEmpty == true) {
        deliveryNo = _deliveryData!.items.first.deliveryNo;
      }
      
      // If no deliveryNo from items, we cannot proceed
      if (deliveryNo == null || deliveryNo.isEmpty) {
        print('🚨 DEBUG: deliveryNo not found in delivery items.');
        CustomModals.hideLoadingModal(context);
        CustomModals.showErrorModal(
          context,
          'DeliveryNo tidak ditemukan dari data halaman ini. Pastikan detail pengiriman dimuat dengan benar.',
        );
        return;
      }
      
      // Build ASHX URL based on environment
      final receiptUrl = Config.getReceiptDownloadUrl(deliveryNo);
      print('🔍 DEBUG: DownloadTandaTerima URL: $receiptUrl');
      
      final primaryUri = Uri.parse(receiptUrl);
      http.Response response;
      try {
        response = await http.get(primaryUri).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        final altUrl = Config.getAlternateReceiptDownloadUrl(deliveryNo);
        print('🚧 DEBUG: Primary domain timeout, trying fallback: $altUrl');
        final altUri = Uri.parse(altUrl);
        response = await http.get(altUri).timeout(const Duration(seconds: 30));
      }
      print('🔍 DEBUG: ASHX response status: ${response.statusCode}');
      print('🔍 DEBUG: ASHX response content-type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        CustomModals.hideLoadingModal(context);
        CustomModals.showErrorModal(
          context,
          'Gagal mengambil tanda terima (status ${response.statusCode}). Pastikan PDF sudah tersedia.',
        );
        return;
      }
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tanda_terima_${deliveryNo}.pdf';
      final savedPath = path.join(tempDir.path, fileName);
      await File(savedPath).writeAsBytes(response.bodyBytes);
      print('🔍 DEBUG: PDF saved locally at: $savedPath');
      
      // Hide loading indicator
      CustomModals.hideLoadingModal(context);
      
      // Navigate to PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            pdfPath: savedPath,
            title: 'Tanda Terima - $deliveryNo',
          ),
        ),
      );
    } catch (e) {
      // Hide loading indicator if still showing
      CustomModals.hideLoadingModal(context);
      
      print('Error opening PDF viewer: $e');
      CustomModals.showErrorModal(
        context,
        e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat membuka tanda terima: ${e.toString()}',
      );
    }
  }
}
