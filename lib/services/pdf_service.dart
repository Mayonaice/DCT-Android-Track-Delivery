import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/delivery_transaction_detail_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PdfService {
  static const double _pageWidth = 595.28; // A4 width in points
  static const double _pageHeight = 841.89; // A4 height in points
  static const double _margin = 40.0;

  /// Generate PDF receipt document based on delivery data
  static Future<File> generateReceiptPdf({
    required DeliveryTransactionDetailData deliveryData,
    required String deliveryCode,
  }) async {
    // Initialize locale data for Indonesian date formatting
    await initializeDateFormatting('id_ID', null);
    
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    final formattedDate = dateFormatter.format(now);

    // Calculate dynamic values from data
    String senderName = 'N/A';
    String recipientLocation = 'N/A';
    
    // "Dikirim Dari" uses userInput from items (not consignees)
    if (deliveryData.items.isNotEmpty) {
      senderName = deliveryData.items.first.userInput ?? 'N/A';
    }
    
    // "Ditujukan Kepada" uses the LAST consignee's NAME (not userInput)
    if (deliveryData.consignees.isNotEmpty) {
      final lastConsignee = deliveryData.consignees.last;
      recipientLocation = lastConsignee.name;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              
              // Transaction Info
              _buildTransactionInfo(deliveryCode, formattedDate, senderName, recipientLocation),
              pw.SizedBox(height: 20),
              
              // Items Table
              _buildItemsTable(deliveryData.items),
              pw.SizedBox(height: 30),
              
              // Signatures Section
              _buildSignaturesSection(deliveryData.items, deliveryData.consignees, formattedDate),
            ],
          );
        },
      ),
    );

    // Save PDF to device
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'tanda_terima_${deliveryCode}_${now.millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Build PDF header section
  static pw.Widget _buildHeader() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'FORM TANDA TERIMA',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.black,
          ),
        ],
      ),
    );
  }

  /// Build transaction information section
  static pw.Widget _buildTransactionInfo(
    String deliveryCode,
    String formattedDate,
    String senderName,
    String recipientLocation,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('No Transaksi', deliveryCode),
        pw.SizedBox(height: 8),
        _buildInfoRow('Tanggal', formattedDate),
        pw.SizedBox(height: 8),
        _buildInfoRow('Dikirim Dari', senderName),
        pw.SizedBox(height: 8),
        _buildInfoRow('Ditujukan Kepada', recipientLocation),
      ],
    );
  }

  /// Build info row helper
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(': '),
        pw.Expanded(
          child: pw.Text(value),
        ),
      ],
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<DeliveryItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          columnWidths: {
            0: const pw.FixedColumnWidth(40),  // No
            1: const pw.FlexColumnWidth(3),   // Nama Barang
            2: const pw.FlexColumnWidth(2),   // Jumlah Barang
            3: const pw.FlexColumnWidth(2),   // Serial Number
            4: const pw.FlexColumnWidth(3),   // Deskripsi Barang
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('No', isHeader: true),
                _buildTableCell('Nama Barang', isHeader: true),
                _buildTableCell('Jumlah Barang', isHeader: true),
                _buildTableCell('Serial Number', isHeader: true),
                _buildTableCell('Deskripsi Barang', isHeader: true),
              ],
            ),
            // Data rows
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('${index + 1}'),
                  _buildTableCell(item.itemName ?? '-'),
                  _buildTableCell('${item.qty ?? 0}'),
                  _buildTableCell(item.serialNumber ?? '-'),
                  _buildTableCell(item.itemDescription ?? '-'),
                ],
              );
            }).toList(),
            // Empty rows to fill table (up to 11 rows total)
            ...List.generate(
              (11 - items.length).clamp(0, 10),
              (index) => pw.TableRow(
                children: [
                  _buildTableCell('${items.length + index + 1}'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build table cell helper
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Build signatures section
  static pw.Widget _buildSignaturesSection(List<DeliveryItem> items, List<DeliveryConsignee> consignees, String currentDate) {
    if (consignees.isEmpty) {
      return pw.Container();
    }

    // Get sender name from items userInput
    String senderName = 'N/A';
    if (items.isNotEmpty) {
      senderName = items.first.userInput ?? 'N/A';
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          if (consignees.length == 1) ...[
            // Single consignee - only fills "Penerima", sender comes from items
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureBox('Pengirim', senderName, currentDate),
                _buildSignatureBox('Penerima', consignees[0].name, currentDate),
              ],
            ),
          ] else ...[
            // Multiple consignees - consignees fill "Perantara" and "Penerima", sender comes from items
            () {
              List<pw.Widget> topRowSignatures = [];
              
              // Add sender (from items userInput)
              topRowSignatures.add(_buildSignatureBox('Pengirim', senderName, currentDate));
              
              // Add intermediaries (all consignees except the last one)
              for (int i = 0; i < consignees.length - 1; i++) {
                topRowSignatures.add(_buildSignatureBox('Perantara', consignees[i].name, currentDate));
              }
              
              return pw.Column(
                children: [
                  // Create top row with sender and intermediaries
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: topRowSignatures,
                  ),
                  pw.SizedBox(height: 30),
                  
                  // Bottom row with recipient (last consignee)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildSignatureBox('Penerima', consignees.last.name, currentDate),
                    ],
                  ),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }

  /// Build signature box helper
  static pw.Widget _buildSignatureBox(String role, String name, String date) {
    return pw.Column(
      children: [
        pw.Text(
          '$role,',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 40), // Space for signature
        pw.Text(
          name,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          date,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  /// Get PDF file path for viewing
  static Future<String> getPdfFilePath(String deliveryCode) async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    
    // Find the most recent PDF for this delivery code
    final pdfFiles = files
        .where((file) => file.path.contains('tanda_terima_$deliveryCode') && file.path.endsWith('.pdf'))
        .cast<File>()
        .toList();
    
    if (pdfFiles.isNotEmpty) {
      // Sort by modification time and return the most recent
      pdfFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return pdfFiles.first.path;
    }
    
    throw Exception('PDF file not found for delivery code: $deliveryCode');
  }

  /// Check if PDF exists for delivery code
  static Future<bool> pdfExists(String deliveryCode) async {
    try {
      await getPdfFilePath(deliveryCode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download PDF from receivedocuments endpoint and save to local storage
  static Future<String?> downloadPdfFromEndpoint(String deliveryCode) async {
    try {
      final apiService = ApiService();
      final storageService = StorageService();
      final token = await storageService.getToken();
      
      if (token == null) {
        throw Exception('Token tidak tersedia');
      }

      print('🔍 DEBUG: Downloading PDF from endpoint for delivery: $deliveryCode');
      
      // Call the receivedocuments endpoint
      final response = await apiService.get(
        'Transaction2/Trx/ReceiveDocuments',
        token: token,
        queryParams: {
          'DeliveryCode': deliveryCode,
        },
      );

      print('🔍 DEBUG: ReceiveDocuments response: $response');

      // Check if response has the expected structure
      // Response structure: {"success": true, "data": {"ok": true, "data": [...]}}
      if (response['success'] == true) {
        final responseData = response['data'];
        if (responseData != null && responseData['ok'] == true) {
          final documents = responseData['data'] as List?;
          print('🔍 DEBUG: Documents found: ${documents?.length ?? 0}');
          
          if (documents != null && documents.isNotEmpty) {
            // Get the first document (PDF)
            final document = documents.first;
            print('🔍 DEBUG: First document keys: ${document.keys.toList()}');
            
            final photo64 = document['photo64'] as String?;
            final filename = document['filename'] as String?;
            
            print('🔍 DEBUG: photo64 length: ${photo64?.length ?? 0}');
            print('🔍 DEBUG: filename: $filename');
          
          if (photo64 != null && photo64.isNotEmpty) {
            // Decode base64 to bytes
            final pdfBytes = base64Decode(photo64);
            
            // Get app documents directory
            final directory = await getApplicationDocumentsDirectory();
            
            // Create filename with timestamp if not provided
            final pdfFilename = filename ?? 'receipt_${deliveryCode}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final pdfPath = '${directory.path}/$pdfFilename';
            
            // Save PDF to local storage
            final pdfFile = File(pdfPath);
            await pdfFile.writeAsBytes(pdfBytes);
            
            print('🔍 DEBUG: PDF saved to: $pdfPath');
            return pdfPath;
          } else {
            print('🚨 DEBUG: No PDF data found in response');
            return null;
          }
        } else {
          print('🚨 DEBUG: No documents found in response');
          return null;
        }
      } else {
        print('🚨 DEBUG: Inner response not successful: ${responseData?['message']}');
        return null;
      }
    } else {
      print('🚨 DEBUG: API response not successful: ${response['message']}');
      return null;
    }
    } catch (e) {
      print('🚨 DEBUG: Error downloading PDF from endpoint: $e');
      return null;
    }
  }

  /// Get PDF path - try local first, then download from endpoint
  static Future<String?> getPdfPathWithFallback(String deliveryCode) async {
    try {
      // First, try to get local PDF
      final localPath = await getPdfFilePath(deliveryCode);
      if (File(localPath).existsSync()) {
        print('🔍 DEBUG: Found local PDF: $localPath');
        return localPath;
      }
    } catch (e) {
      print('🔍 DEBUG: No local PDF found, trying endpoint...');
    }
    
    // If local PDF not found, try to download from endpoint
    return await downloadPdfFromEndpoint(deliveryCode);
  }
}