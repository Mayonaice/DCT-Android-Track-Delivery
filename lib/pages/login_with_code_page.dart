import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custommodals.dart';
import '../services/api_service.dart';
import 'delivery_detail_page.dart';

class LoginWithCodePage extends StatefulWidget {
  const LoginWithCodePage({super.key});

  @override
  State<LoginWithCodePage> createState() => _LoginWithCodePageState();
}

class _LoginWithCodePageState extends State<LoginWithCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('🔍 DEBUG: Starting login process...');
    
    final code = _codeController.text.trim();
    print('🔍 DEBUG: Input code: "$code"');
    
    if (code.isEmpty) {
      print('⚠️ DEBUG: Code is empty, showing error modal');
      CustomModals.showErrorModal(
        context,
        'Silakan masukkan kode pengiriman',
      );
      return;
    }

    print('🔍 DEBUG: Setting loading state to true');
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 DEBUG: Calling API loginByCode...');
      final response = await _apiService.loginByCode(code);
      
      print('🔍 DEBUG: Login API response received');
      print('🔍 DEBUG: Response ok: ${response.ok}');
      print('🔍 DEBUG: Response message: ${response.message}');
      print('🔍 DEBUG: Response data: ${response.data != null ? "Available" : "Null"}');
      
      if (response.ok && response.data != null) {
        print('✅ DEBUG: Login successful!');
        print('🔍 DEBUG: User data - seqNo: ${response.data!.seqNo}');
        print('🔍 DEBUG: User data - deliveryCode: ${response.data!.deliveryCode}');
        print('🔍 DEBUG: User data - name: ${response.data!.name}');
        print('🔍 DEBUG: User data - phoneNumber: ${response.data!.phoneNumber}');
        print('🔍 DEBUG: User data - status: ${response.data!.status}');
        print('🔍 DEBUG: User data - token: ${response.data!.token.substring(0, 20)}...');
        
        print('🔍 DEBUG: Navigating to DeliveryDetailPage...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetailPage(
              deliveryCode: response.data!.deliveryCode,
              token: response.data!.token,
            ),
          ),
        );
        print('🔍 DEBUG: Navigation completed');
      } else {
        print('❌ DEBUG: Login failed, showing error modal');
        CustomModals.showErrorModal(
          context,
          response.message.isNotEmpty 
              ? response.message 
              : 'Login gagal, silakan coba lagi',
        );
      }
    } catch (e) {
      print('🚨 DEBUG: Login exception occurred: $e');
      CustomModals.showErrorModal(
        context,
        'Terjadi kesalahan: ${e.toString()}',
      );
    } finally {
      print('🔍 DEBUG: Setting loading state to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Header with DCT logo and text
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/top_header.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              
              // Title text
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Masukan kode yang kamu terima',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Code input field
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan kode',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xFF1B8B7A), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
              const SizedBox(height: 40),
              
              // Login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8B7A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 200),
              
              // Bottom links
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah Punya Akun? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Klik disini',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1B8B7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Cek Pengiriman? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/check-delivery');
                          },
                          child: const Text(
                            'Klik Disini',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1B8B7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}