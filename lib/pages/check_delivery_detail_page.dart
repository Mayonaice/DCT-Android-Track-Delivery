import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/delivery_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/custommodals.dart';
import '../widgets/view_only_photo_preview.dart';
import '../widgets/photo_viewer_widget.dart';

class CheckDeliveryDetailPage extends StatefulWidget {
  final String deliveryCode;

  const CheckDeliveryDetailPage({
    super.key,
    required this.deliveryCode,
  });

  @override
  State<CheckDeliveryDetailPage> createState() => _CheckDeliveryDetailPageState();
}

class _CheckDeliveryDetailPageState extends State<CheckDeliveryDetailPage> {
  final ApiService _apiService = ApiService();
  DeliveryDetailResponse? _deliveryDetail;
  bool _isLoading = true;

  String _normalizeDeliveryCode(String? deliveryCode) {
    return (deliveryCode ?? '').trim().toLowerCase();
  }

  String _normalizePhotoFilename(String filename) {
    var normalized = filename.replaceAll('/', '\\').trim().toLowerCase();
    while (normalized.contains('\\\\')) {
      normalized = normalized.replaceAll('\\\\', '\\');
    }
    return normalized;
  }

  String _buildPhotoKey(String? deliveryCode, String filename) {
    final normalizedDeliveryCode = _normalizeDeliveryCode(deliveryCode);
    final normalizedFilename = _normalizePhotoFilename(filename);
    if (normalizedDeliveryCode.isEmpty) return normalizedFilename;
    if (normalizedFilename.isEmpty) return normalizedDeliveryCode;
    return '$normalizedDeliveryCode|$normalizedFilename';
  }

  Map<String, String> _buildPhoto64ByFilename(List<DeliveryDetailStatus> statuses) {
    final map = <String, String>{};
    for (final status in statuses) {
      for (final photo in status.photo) {
        final photo64 = photo.photo64;
        if (photo64.isEmpty) continue;
        final key = _buildPhotoKey(status.deliveryCode, photo.filename);
        if (key.isEmpty) continue;
        map[key] = photo64;
      }
    }
    return map;
  }

  DetailStatusPhoto? _firstDetailStatusPhotoWhereOrNull(
    List<DetailStatusPhoto> photos,
    bool Function(DetailStatusPhoto) test,
  ) {
    for (final photo in photos) {
      if (test(photo)) return photo;
    }
    return null;
  }

  List<DetailStatusPhoto> _selectPhotosForStatus(
    DeliveryDetailStatus status,
    Map<String, String> photo64ByFilename,
  ) {
    final desc = (status.description ?? '').toLowerCase();
    final wantsConfirm = desc.contains('konfirm');
    final wantsReceive = desc.contains('terima');

    List<DetailStatusPhoto> candidates;
    if (wantsConfirm) {
      candidates = status.photo
          .where((p) => p.filename.toLowerCase().contains('confirmitemsphoto'))
          .toList();
    } else if (wantsReceive) {
      candidates = status.photo
          .where((p) => p.filename.toLowerCase().contains('receiveitemsphoto'))
          .toList();
    } else {
      candidates = status.photo.toList();
    }
    if (candidates.isEmpty) {
      candidates = status.photo.toList();
    }

    final results = <DetailStatusPhoto>[];
    final seen = <String>{};

    for (final photo in candidates) {
      var photo64 = photo.photo64;
      if (photo64.isEmpty) {
        final key = _buildPhotoKey(status.deliveryCode, photo.filename);
        photo64 = photo64ByFilename[key] ?? '';
      }
      if (photo64.isEmpty) continue;

      final normalizedFilename = _normalizePhotoFilename(photo.filename);
      final uniqueKey = normalizedFilename.isNotEmpty ? normalizedFilename : photo64;
      if (uniqueKey.isEmpty || seen.contains(uniqueKey)) continue;
      seen.add(uniqueKey);

      results.add(
        DetailStatusPhoto(
          photo64: photo64,
          filename: photo.filename,
          description: photo.description,
        ),
      );
    }

    if (results.isNotEmpty) return results;

    final fallback = _firstDetailStatusPhotoWhereOrNull(status.photo, (p) => p.photo64.isNotEmpty) ??
        (status.photo.isNotEmpty ? status.photo.first : null);
    if (fallback == null) return [];

    var fallbackPhoto64 = fallback.photo64;
    if (fallbackPhoto64.isEmpty) {
      final key = _buildPhotoKey(status.deliveryCode, fallback.filename);
      fallbackPhoto64 = photo64ByFilename[key] ?? '';
    }
    if (fallbackPhoto64.isEmpty) return [];

    return [
      DetailStatusPhoto(
        photo64: fallbackPhoto64,
        filename: fallback.filename,
        description: fallback.description,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetail();
  }

  Future<void> _loadDeliveryDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔍 DEBUG: Loading delivery detail for code: ${widget.deliveryCode}');
      
      final response = await _apiService.getDeliveryDetail(widget.deliveryCode);
      
      if (response != null) {
        if (response.ok && response.data != null) {
          setState(() {
            _deliveryDetail = response;
            _isLoading = false;
          });
          print('✅ DEBUG: Delivery detail loaded successfully');
        } else {
          // Show error modal for invalid delivery code
          setState(() {
            _isLoading = false;
          });
          
          CustomModals.showErrorModal(
            context,
            response.message.isNotEmpty ? response.message : 'Kode Delivery tidak valid',
            onOk: () {
              Navigator.of(context).pop(); // Go back to previous page
            },
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        CustomModals.showErrorModal(
          context,
          'Terjadi kesalahan saat mengambil data pengiriman',
          onOk: () {
            Navigator.of(context).pop(); // Go back to previous page
          },
        );
      }
    } catch (e) {
      print('🚨 DEBUG: Error loading delivery detail: $e');
      setState(() {
        _isLoading = false;
      });
      
      CustomModals.showErrorModal(
        context,
        e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan: ${e.toString()}',
        onOk: () {
          Navigator.of(context).pop(); // Go back to previous page
        },
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Cek Pengiriman',
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
          : _deliveryDetail != null && _deliveryDetail!.data != null
              ? _buildDeliveryDetailContent()
              : const Center(
                  child: Text(
                    'Data tidak ditemukan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDeliveryDetailContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confirmation Card
          _buildConfirmationCard(),
          const SizedBox(height: 16),
          
          // Sender Info - Always show
          _buildSenderInfo(),
          const SizedBox(height: 16),
          
          // Receiver Info - Always show
          _buildReceiverInfo(),
          const SizedBox(height: 16),
          
          // Delivery Status Timeline
          _buildStatusTimeline(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    final statusText = _deliveryDetail?.data?.status?.getStatusText() ?? 'Dikonfirmasi Penerima';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kode Pengiriman: ${_deliveryDetail?.data?.status?.deliveryNo ?? widget.deliveryCode}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSenderInfo() {
    final sender = _deliveryDetail?.data?.sender;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengirim',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nama Pengirim: ${sender?.name ?? 'Tidak tersedia'}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tanggal Kirim: ${_formatTransactionTime(sender?.transactionTime)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionTime(DateTime? dateTime) {
    if (dateTime == null) return 'Tidak tersedia';
    
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month];
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year $hour:$minute';
  }

  Widget _buildReceiverInfo() {
    final receivers = _deliveryDetail?.data?.recevier ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penerima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          if (receivers.isEmpty)
            const Text(
              'Nama Penerima: Tidak tersedia',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            )
          else
            ...receivers.asMap().entries.map((entry) {
              final index = entry.key;
              final receiver = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < receivers.length - 1 ? 4 : 0),
                child: Text(
                  receivers.length > 1 
                      ? 'Nama Penerima ${index + 1}: ${receiver.name ?? 'Tidak tersedia'}'
                      : 'Nama Penerima: ${receiver.name ?? 'Tidak tersedia'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final detailStatuses = _deliveryDetail?.data?.detailStatus ?? [];
    final photo64ByFilename = _buildPhoto64ByFilename(detailStatuses);
    
    if (detailStatuses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Pengiriman',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Tidak ada data status pengiriman',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Pengiriman',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 20),
          ...detailStatuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isLast = index == detailStatuses.length - 1;
            
            return _buildTimelineItemFromAPI(status, isLast, photo64ByFilename);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItemFromAPI(
    DeliveryDetailStatus status,
    bool isLast,
    Map<String, String> photo64ByFilename,
  ) {
    final nameTime = status.nameTime ?? 'Waktu tidak tersedia';
    final description = status.description ?? 'Deskripsi tidak tersedia';
    final selectedPhotos = _selectPhotosForStatus(status, photo64ByFilename);
    final hasPhoto = selectedPhotos.isNotEmpty;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot with connecting line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B8B7A), // Green color matching design
                  shape: BoxShape.circle,
                ),
              ),
              // Connecting line yang mengikuti tinggi konten
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    color: const Color(0xFF1B8B7A), // Green connecting line
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Status content
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameTime,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B8B7A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5), // Light green background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (selectedPhotos.isNotEmpty) {
                            _showPhotoViewer(selectedPhotos);
                          } else {
                            CustomModals.showErrorModal(
                              context,
                              'Foto Tidak Tersedia',
                              onOk: () {},
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            selectedPhotos.length > 1 ? 'Lihat Foto (${selectedPhotos.length})' : 'Lihat Foto',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669), // Green text
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    
    final dayName = days[dateTime.weekday % 7];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$dayName, $day $month $year $hour:$minute';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  void _showPhotoViewer(List<DetailStatusPhoto> photos) {
    if (photos.isEmpty) {
      CustomModals.showErrorModal(
        context,
        'Foto Tidak Tersedia',
        onOk: () {},
      );
      return;
    }

    // Convert DetailStatusPhoto to PhotoData
    List<PhotoData> photoDataList = photos.map((photo) {
      return PhotoData(
        photo64: photo.photo64,
        filename: photo.filename,
        description: photo.description ?? '',
      );
    }).toList();

    // Navigate to ViewOnlyPhotoPreview
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewOnlyPhotoPreview(
          photos: photoDataList,
          title: 'Foto Status Pengiriman',
        ),
      ),
    );
  }
}
