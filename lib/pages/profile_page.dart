import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile_model.dart';
import 'ubah_profile_page.dart';
import '../widgets/custommodals.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  UserProfileData? _profileData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = await _storageService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan, silakan login ulang';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getUserProfile(token);
      
      if (response['success'] == true && response['data'] != null) {
        final profileResponse = UserProfileResponse.fromJson(response['data']);
        
        if (profileResponse.ok && profileResponse.data != null) {
          setState(() {
            _profileData = profileResponse.data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = profileResponse.message.isNotEmpty 
                ? profileResponse.message 
                : 'Gagal memuat data profil';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data profil';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Profile Section
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF059669), // Teal-600 (konsisten dengan home)
                            Color(0xFF047857), // Teal-700 (konsisten dengan home)
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Profile Picture
                              Container(
                                width: 100, //jangan ubah ukuran ini!
                                height: 100, //jangan ubah ukuran ini!
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 45, //jangan ubah ukuran ini!
                                  backgroundColor: Colors.grey,
                                  backgroundImage: NetworkImage(
                                    'https://via.placeholder.com/150x150/CCCCCC/FFFFFF?text=User',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Profile Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      _profileData?.name ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Phone Number
                                    Text(
                                      _profileData?.maskedPhoneNumber ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    
                                    // Email
                                    Text(
                                      _profileData?.maskedEmail ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          
                    // Content Section
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pengaturan Section
                            const Text(
                              'Pengaturan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Ubah Profil Menu
                            _buildMenuItem(
                              icon: 'assets/images/ubah-profile-icon.png',
                              title: 'Ubah Profil',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UbahProfilePage(),
                                  ),
                                );
                              },
                            ),
                            
                            // Ubah Password Menu
                            _buildMenuItem(
                              icon: 'assets/images/ubah-password-icon.png',
                              title: 'Ubah Password',
                              onTap: () {
                                Navigator.pushNamed(context, '/ubah-password');
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Tentang Kami Section
                            const Text(
                              'Tentang Kami',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // FAQ Menu
                            _buildMenuItem(
                              icon: 'assets/images/faq-icon.png',
                              title: 'FAQ',
                              onTap: () {
                                // TODO: Navigate to FAQ page
                              },
                            ),
                            
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                    
                    // Log Out Button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showLogoutDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: const Color(0xFFDC2626),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25), // Ubah dari 12 ke 25 untuk rounded pill
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 2),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      icon,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.settings,
                          size: 24,
                          color: Color(0xFF6B7280),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                
                // Arrow Icon
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Implement logout logic
                try {
                  print('🔄 DEBUG: Starting logout process');
                  // Clear all login data from storage
                  await _storageService.clearLoginData();
                  
                  print('✅ DEBUG: Logout successful, navigating to login');
                  // Navigate to login page and clear navigation stack
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', 
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  print('🚨 DEBUG: Error during logout: $e');
                  // Handle logout error
                  if (mounted) {
                    CustomModals.showErrorModal(context, 'Error saat logout: $e');
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}