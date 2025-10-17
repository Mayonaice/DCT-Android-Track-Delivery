import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/delivery_transaction_detail_model.dart';

class PdfService {
  static const double _pageWidth = 595.28; // A4 width in points
  static const double _pageHeight = 841.89; // A4 height in points
  static const double _margin = 40.0;

  /// Generate PDF receipt document based on delivery data
  static Future<File> generateReceiptPdf({
    required DeliveryTransactionDetailData deliveryData,
    required String deliveryCode,
    required String senderName,
    required String recipientLocation,
  }) async {
    // Initialize locale data for Indonesian date formatting
    await initializeDateFormatting('id_ID', null);
    
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    final formattedDate = dateFormatter.format(now);

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
              _buildSignaturesSection(deliveryData.consignees, formattedDate),
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
  static pw.Widget _buildSignaturesSection(List<DeliveryConsignee> consignees, String currentDate) {
    // Determine signature layout based on consignee count
    final isMultipleConsignees = consignees.length > 1;
    
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          if (isMultipleConsignees) ...[
            // Multiple consignees - show as "Perantara"
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureBox('Pengirim', 'Robby', currentDate),
                _buildSignatureBox('Perantara', consignees.first.name, currentDate),
                _buildSignatureBox('Perantara', consignees.length > 1 ? consignees[1].name : 'Ionu', currentDate),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildSignatureBox('Penerima', 'Iqbal', currentDate),
              ],
            ),
          ] else ...[
            // Single consignee - show as "Penerima"
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureBox('Pengirim', 'Robby', currentDate),
                _buildSignatureBox('Perantara', 'Jordan', currentDate),
                _buildSignatureBox('Perantara', 'Ionu', currentDate),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildSignatureBox('Penerima', consignees.isNotEmpty ? consignees.first.name : 'Iqbal', currentDate),
              ],
            ),
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
}