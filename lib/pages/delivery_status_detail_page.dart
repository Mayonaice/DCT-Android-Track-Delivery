import 'package:flutter/material.dart';
import '../models/delivery_status_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/custommodals.dart';

class DeliveryStatusDetailPage extends StatefulWidget {
  final String deliveryCode;
  final String token;

  const DeliveryStatusDetailPage({
    Key? key,
    required this.deliveryCode,
    required this.token,
  }) : super(key: key);

  @override
  State<DeliveryStatusDetailPage> createState() => _DeliveryStatusDetailPageState();
}

class _DeliveryStatusDetailPageState extends State<DeliveryStatusDetailPage> {
  bool _isLoading = true;
  List<DeliveryStatusDetailData> _statusData = [];
  String _errorMessage = '';
  int _maxStatusLevel = 1; // Untuk menentukan berapa icon yang aktif

  @override
  void initState() {
    super.initState();
    _loadStatusDetail();
  }

  Future<void> _loadStatusDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getDeliveryStatusDetail(widget.deliveryCode, widget.token);

      if (response != null && response.ok && response.data.isNotEmpty) {
        setState(() {
          _statusData = response.data.reversed.toList(); // Reverse untuk urutan dari bawah ke atas
          _maxStatusLevel = _calculateMaxStatusLevel(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Gagal memuat data status';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _calculateMaxStatusLevel(List<DeliveryStatusDetailData> data) {
    int maxLevel = 1;
    for (var item in data) {
      int level = item.getStatusLevel();
      if (level > maxLevel) {
        maxLevel = level;
      }
    }
    return maxLevel;
  }

  void _showPhotoModal(List<StatusPhoto> photos) {
    if (photos.isEmpty) {
      CustomModals.showErrorModal(
        context,
        'Foto Tidak Tersedia',
        onOk: () {},
      );
      return;
    }

    // Show photo modal - untuk saat ini hanya tampilkan pesan
    // Nanti bisa dikembangkan untuk menampilkan foto base64
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Foto Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${photos.length} foto tersedia'),
              const SizedBox(height: 10),
              // TODO: Implement photo viewer
              const Text('Photo viewer akan diimplementasikan'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to format date and time
  String _formatDateOnly(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final monthNames = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                         'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      
      final dayName = dayNames[dateTime.weekday % 7];
      final day = dateTime.day;
      final monthName = monthNames[dateTime.month];
      final year = dateTime.year;
      
      return '$dayName, $day $monthName $year';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatTimeOnly(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute WIB';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStatusIcon(int index, bool isActive) {
    List<String> iconPaths = [
      'assets/images/icon-status2(submitted).png',
      'assets/images/icon-status3(diterimaperantara).png',
      'assets/images/icon-status5(diterima).png',
      'assets/images/icon-status4(dikonfirmasi).png',
    ];

    return Container(
      width: 86, // Increased from 72 to 86 (1.2x again)
      height: 86, // Increased from 72 to 86 (1.2x again)
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        iconPaths[index],
        width: 58, // Increased from 48 to 58 (1.2x again)
        height: 58, // Increased from 48 to 58 (1.2x again)
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.check_box,
            color: isActive ? const Color(0xFF1B8B7A) : Colors.grey[400],
            size: 43, // Increased from 36 to 43 (1.2x again)
          );
        },
      ),
    );
  }

  Widget _buildStatusConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B8B7A) : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Determine how many icons to show based on _maxStatusLevel, minimum 1, maximum 4
    int iconsToShow = _maxStatusLevel.clamp(1, 4);
    
    return Column(
      children: [
        // Icons and checkmarks with perfect alignment
        _buildAlignedIconsAndCheckmarks(iconsToShow),
      ],
    );
  }

  Widget _buildAlignedIconsAndCheckmarks(int iconsToShow) {
    return Column(
      children: [
        // Icons row
        Row(
          children: _buildIconsWithSpacing(iconsToShow),
        ),
        const SizedBox(height: 20),
        // Checkmarks row with connecting lines
        Row(
          children: _buildCheckmarksWithLines(iconsToShow),
        ),
      ],
    );
  }

  List<Widget> _buildIconsWithSpacing(int iconsToShow) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < iconsToShow; i++) {
      if (i == 0) {
        // First icon - add flexible space before if needed
        if (iconsToShow < 4) {
          widgets.add(Expanded(child: Container()));
        }
      }
      
      // Add the icon
      widgets.add(_buildStatusIcon(i, i < _maxStatusLevel));
      
      // Add spacing between icons
      if (i < iconsToShow - 1) {
        widgets.add(Expanded(child: Container()));
      }
      
      if (i == iconsToShow - 1) {
        // Last icon - add flexible space after if needed
        if (iconsToShow < 4) {
          widgets.add(Expanded(child: Container()));
        }
      }
    }
    
    return widgets;
  }

  List<Widget> _buildCheckmarksWithLines(int iconsToShow) {
    List<Widget> widgets = [];
    
    // Jika hanya 1 icon, tampilkan checkmark tanpa garis hijau
    if (iconsToShow == 1) {
      widgets.add(Expanded(child: Container()));
      widgets.add(Container(width: 43, child: Center(child: _buildCheckmark(0))));
      widgets.add(Expanded(child: Container()));
      return widgets;
    }
    
    // Untuk 2 atau lebih icon, tampilkan dengan garis penghubung
    for (int i = 0; i < iconsToShow; i++) {
      if (i == 0) {
        // First checkmark - add spacing to align with icon center
        if (iconsToShow < 4) {
          widgets.add(Expanded(child: Container()));
        }
        widgets.add(Container(width: 43, child: Center(child: _buildCheckmark(i))));
      } else {
        // Connecting line
        widgets.add(Expanded(
          child: Container(
            height: 3,
            color: i <= _maxStatusLevel - 1 ? const Color(0xFF1B8B7A) : Colors.grey[300],
          ),
        ));
        // Checkmark
        widgets.add(Container(width: 43, child: Center(child: _buildCheckmark(i))));
      }
      
      if (i == iconsToShow - 1) {
        // Last checkmark - add spacing to align with icon center
        if (iconsToShow < 4) {
          widgets.add(Expanded(child: Container()));
        }
      }
    }
    
    return widgets;
  }

  Widget _buildCheckmark(int index) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: index < _maxStatusLevel ? const Color(0xFF1B8B7A) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: index < _maxStatusLevel
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildTimelineItem(DeliveryStatusDetailData data, {bool isLast = false}) {
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
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time in right alignment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatDateOnly(data.timeInput),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Text(
                        _formatTimeOnly(data.timeInput),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    data.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Photo button - only show if photo exists
                  if (data.photo.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5), // Light green background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: InkWell(
                        onTap: () => _showPhotoModal(data.photo),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            'Lihat Foto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669), // Green text
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detail Status',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatusDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20), // Tambah jarak diatas icon
                      // Progress indicator dengan garis hijau di bawah
                      _buildProgressIndicator(),
                      const SizedBox(height: 20),
                      // Status confirmation text - dinamis dari response paling bawah
                      Center(
                        child: Text(
                          _statusData.isNotEmpty ? _statusData.last.description : 'Dikonfirmasi Penerima',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50), // Tambah jarak lebih besar
                      const SizedBox(height: 20), // Tambah jarak diatas Status Pengiriman
                      // Status Pengiriman section
                      const Text(
                        'Status Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Timeline
                      if (_statusData.isNotEmpty)
                        Column(
                          children: _statusData.reversed.toList().asMap().entries.map((entry) {
                            int index = entry.key;
                            DeliveryStatusDetailData data = entry.value;
                            bool isLast = index == _statusData.length - 1;
                            return _buildTimelineItem(data, isLast: isLast);
                          }).toList(),
                        ),
                    ],
                  ),
                ),
    );
  }
}