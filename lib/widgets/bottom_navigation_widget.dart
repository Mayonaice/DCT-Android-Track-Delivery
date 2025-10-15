import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/notification_page.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/notification_model.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int currentIndex;
  
  const BottomNavigationWidget({
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  late int _selectedIndex;
  int _unreadCount = 0;
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await _apiService.getNotifications(token);
        if (response != null && response.ok) {
          final unreadNotifications = response.data.where((notification) => !notification.isRead).length;
          if (mounted) {
            setState(() {
              _unreadCount = unreadNotifications;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Jangan navigate jika sudah di halaman yang sama
    
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to different pages based on index
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NotificationPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, // Reduced from 80 to 64 (0.8x of 80)
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B8B7A),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Kirim',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_selectedIndex != 1 && _unreadCount > 0) // Only show badge when not on notification page and there are unread notifications
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}