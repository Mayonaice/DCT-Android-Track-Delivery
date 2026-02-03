import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/custommodals.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PdfViewerPage({
    Key? key,
    required this.pdfPath,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isRendered = false;
  int _pages = 0;
  int _currentPage = 0;
  final PDFViewController? _controller = null;
  static const MethodChannel _channel = MethodChannel('com.dct.tracking/android_actions');

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.pdfPath);
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
        title: Text(
          widget.title.isNotEmpty ? widget.title : fileName,
          style: const TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF1B8B7A)),
            onPressed: _downloadPdf,
            tooltip: 'Download',
          ),
          if (_isRendered && _pages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_currentPage + 1}/$_pages',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.HEIGHT,
            nightMode: false,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _pages = pages ?? 0;
                _isRendered = true;
              });
            },
            onError: (error) {
              CustomModals.showErrorModal(
                context,
                'Gagal membuka PDF: $error',
              );
            },
            onPageError: (page, error) {
              CustomModals.showErrorModal(
                context,
                'Error halaman $page: $error',
              );
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
          if (!_isRendered)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B8B7A)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final name = p.basename(widget.pdfPath);
      final data = await File(widget.pdfPath).readAsBytes();
      int sdkInt = 0;
      try {
        final v = await _channel.invokeMethod<int>('getSdkInt');
        sdkInt = v ?? 0;
      } catch (_) {}
      if (Platform.isAndroid && sdkInt < 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          CustomModals.showErrorModal(
            context,
            'Izin penyimpanan ditolak. Aktifkan WRITE/READ untuk menyimpan file.',
          );
          return;
        }
      }
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'saveToDownloads',
        {
          'name': name,
          'bytes': data,
          'mime': 'application/pdf',
        },
      );
      if (res != null) {
        final uri = res['uri']?.toString();
        final path = res['path']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan ${path ?? uri ?? ''}')),
        );
        await _channel.invokeMethod('openDownloads');
        return;
      }
      CustomModals.showErrorModal(context, 'Gagal menyimpan PDF');
    } catch (e) {
      CustomModals.showErrorModal(
        context,
        'Gagal menyimpan PDF: $e',
      );
    }
  }
}
