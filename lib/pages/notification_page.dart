import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/custommodals.dart';
import 'delivery_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<NotificationData> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Selection mode variables
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = await _storageService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getNotifications(token);
      if (response != null && response.ok) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Gagal memuat notifikasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Widget _buildNotificationItem(NotificationData notification) {
    final isRead = notification.isRead;
    final isSelected = _selectedNotifications.contains(notification.seqNo);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical margin
      decoration: BoxDecoration(
        color: _isSelectionMode && isSelected
            ? const Color(0xFFE3F2FD) // Light blue for selected items
            : isRead
                ? Colors.white
                : const Color(0xFFE8F5F3), // Light green for unread
        borderRadius: BorderRadius.circular(12),
        border: _isSelectionMode && isSelected
            ? Border.all(color: const Color(0xFF1B8B7A), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  _toggleNotificationSelection(notification.seqNo);
                },
                activeColor: const Color(0xFF1B8B7A),
              )
            : Stack(
                children: [
                  Container(
                    width: 40, // Reduced size
                    height: 40, // Reduced size
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Remove background color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      notification.getIconAsset(),
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.notifications,
                          color: const Color(0xFF1B8B7A),
                          size: 24,
                        );
                      },
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.formattedTime,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        trailing: null, // Remove the trailing red dot since it's now on the icon
        onTap: () async {
          if (_isSelectionMode) {
            // In selection mode, toggle selection
            _toggleNotificationSelection(notification.seqNo);
          } else {
            // Normal mode: Mark notification as read and navigate to delivery detail
            try {
              final token = await _storageService.getToken();
              if (token != null) {
                // Mark notification as read
                await _apiService.markNotificationAsRead(notification.seqNo, token);
                
                // Navigate to delivery detail page
                if (mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryDetailPage(
                        deliveryCode: notification.seqNoDelivery,
                        token: token,
                      ),
                    ),
                  );
                  
                  // Refresh notifications when returning from delivery detail
                  if (result == null || result == true) {
                    _loadNotifications();
                  }
                }
              }
            } catch (e) {
              print('Error handling notification tap: $e');
              if (mounted) {
                CustomModals.showErrorModal(
                  context,
                  'Terjadi kesalahan saat membuka detail pengiriman',
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul di sini ketika ada update pengiriman',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8B7A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
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
        automaticallyImplyLeading: false, // Remove back button since this is a main page
        title: _isSelectionMode
            ? Text(
                '${_selectedNotifications.length} dipilih',
                style: const TextStyle(
                  color: Color(0xFF1B8B7A),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const Text(
                'Notifikasi',
                style: TextStyle(
                  color: Color(0xFF1B8B7A),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        centerTitle: false,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: _selectedNotifications.isNotEmpty
                  ? _deleteSelectedNotifications
                  : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Color(0xFF1B8B7A),
              ),
              onPressed: _toggleSelectionMode,
            ),
          ] else
            IconButton(
              icon: const Icon(
                Icons.more_horiz, // Changed to horizontal three dots
                color: Color(0xFF1B8B7A),
              ),
              onPressed: _toggleSelectionMode,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B8B7A)),
            ),
          )
        : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _notifications.isEmpty
            ? RefreshIndicator(
                onRefresh: _refreshNotifications,
                color: const Color(0xFF1B8B7A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: _buildEmptyState(),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshNotifications,
                color: const Color(0xFF1B8B7A),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4), // Reduced padding
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(_notifications[index]);
                  },
                ),
              ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String seqNo) {
    setState(() {
      if (_selectedNotifications.contains(seqNo)) {
        _selectedNotifications.remove(seqNo);
      } else {
        _selectedNotifications.add(seqNo);
      }
    });
  }

  Future<void> _deleteSelectedNotifications() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus Notifikasi'),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${_selectedNotifications.length} notifikasi yang dipilih?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      if (mounted) {
        CustomModals.showLoadingModal(context, message: 'Menghapus notifikasi...');
      }

      final token = await _storageService.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          CustomModals.showErrorModal(
            context,
            'Token tidak ditemukan. Silakan login kembali.',
          );
        }
        return;
      }

      // Delete notifications
      final success = await _apiService.deleteMultipleNotifications(
        _selectedNotifications.toList(),
        token,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      if (success) {
        // Exit selection mode and refresh
        setState(() {
          _isSelectionMode = false;
          _selectedNotifications.clear();
        });
        
        if (mounted) {
          CustomModals.showSuccessModal(
            context,
            'Notifikasi berhasil dihapus',
          );
        }
        
        // Refresh notifications
        _loadNotifications();
      } else {
        if (mounted) {
          CustomModals.showErrorModal(
            context,
            'Gagal menghapus beberapa notifikasi. Silakan coba lagi.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        CustomModals.showErrorModal(
          context,
          'Terjadi kesalahan saat menghapus notifikasi: $e',
        );
      }
    }
  }
}