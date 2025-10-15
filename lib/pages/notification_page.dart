import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_navigation_widget.dart';
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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical margin
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFE8F5F3), // Light green for unread
        borderRadius: BorderRadius.circular(12),
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
        leading: Stack(
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
          // Mark notification as read and navigate to delivery detail
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terjadi kesalahan saat membuka detail pengiriman'),
                  duration: Duration(seconds: 2),
                ),
              );
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
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_horiz, // Changed to horizontal three dots
              color: Color(0xFF1B8B7A),
            ),
            onPressed: () {
              // Show menu or options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu options'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
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
}