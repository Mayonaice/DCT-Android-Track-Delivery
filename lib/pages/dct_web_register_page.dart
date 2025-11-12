import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custommodals.dart';
import '../pages/home_page.dart';

class DctWebRegisterPage extends StatefulWidget {
  const DctWebRegisterPage({Key? key}) : super(key: key);

  @override
  State<DctWebRegisterPage> createState() => _DctWebRegisterPageState();
}

class _DctWebRegisterPageState extends State<DctWebRegisterPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleDaftarByDCT() async {
    print('🔍 DEBUG: Starting DaftarByDCT process...');
    
    final username = _userController.text.trim();
    final password = _passwordController.text.trim();
    
    print('🔍 DEBUG: Input username: "$username"');
    print('🔍 DEBUG: Input password length: ${password.length}');
    
    if (username.isEmpty || password.isEmpty) {
      print('⚠️ DEBUG: Username or password is empty, showing error modal');
      CustomModals.showErrorModal(
        context,
        'Username dan password tidak boleh kosong',
      );
      return;
    }

    print('🔍 DEBUG: Setting loading state to true');
    setState(() {
      _isLoading = true;
    });

    // Unfocus any active text fields
    FocusScope.of(context).unfocus();

    CustomModals.showLoadingModal(context, message: 'Sedang mendaftar...');

    try {
      print('🔍 DEBUG: Calling API daftarByDCT...');
      final result = await _apiService.daftarByDCT(username, password);
      
      print('🔍 DEBUG: DaftarByDCT API response received');
      print('🔍 DEBUG: Response success: ${result['success']}');
      print('🔍 DEBUG: Response message: ${result['message']}');
      print('🔍 DEBUG: Response data: ${result['data'] != null ? "Available" : "Null"}');
      
      CustomModals.hideLoadingModal(context);
      
      if (result['success']) {
        print('✅ DEBUG: DaftarByDCT successful!');
        
        // Save login data (same as login flow)
        print('🔍 DEBUG: Saving login data to storage...');
        try {
          await _storageService.saveLoginData(result['data']);
          print('✅ DEBUG: Login data saved successfully to storage');
        } catch (e) {
          print('🚨 DEBUG: Failed to save login data to storage: $e');
        }
        
        // Show success message as specified by user
        CustomModals.showSuccessModal(
          context,
          'Daftar menggunakan akun DCT Web berhasil, akun anda sudah terbuat',
          onOk: () {
            // Navigate to HomePage (same as login flow)
            print('🔍 DEBUG: Navigating to HomePage...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          },
        );
      } else {
        print('❌ DEBUG: DaftarByDCT failed, showing error modal');
        // Use message from API response as specified by user
        CustomModals.showErrorModal(
          context,
          result['message'] ?? 'Daftar gagal, silakan coba lagi',
        );
      }
    } catch (e) {
      print('🚨 DEBUG: DaftarByDCT exception occurred: $e');
      CustomModals.hideLoadingModal(context);
      final message = e is TimeoutException
          ? 'Koneksi Timeout, harap hubungi tim IT'
          : 'Terjadi kesalahan: ${e.toString()}';
      CustomModals.showErrorModal(
        context,
        message,
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
    // Colors and metrics tuned to visually match the provided design
    const Color bgColor = Color(0xFFF4F1EE); // light beige background tone
    const Color cardShadow = Color(0x1A000000); // subtle shadow
    const double cardRadius = 10;
    const double cardHorizontalPadding = 22;
    const double cardVerticalPadding = 20;
    const double fieldHeight = 48;
    const Color inputBorderColor = Color(0xFFE5E7EB);
    const Color blueButton = Color(0xFF1E66C7);
    const Color linkBlue = Color(0xFF2962FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxCardWidth = 432; // enlarged by 1.2x (360 * 1.2 = 432)
            final double cardWidth = constraints.maxWidth < maxCardWidth
                ? constraints.maxWidth - 24
                : maxCardWidth;

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: cardHorizontalPadding,
                      vertical: cardVerticalPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Centered logo - enlarged by 1.5x
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 22),
                          child: SizedBox(
                            height: 90, // enlarged by 1.5x (60 * 1.5 = 90)
                            child: Image.asset(
                              'assets/images/adv3.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // User ID / Email / Nomor HP (Username field at top as requested)
                        SizedBox(
                          height: fieldHeight,
                          child: TextField(
                            controller: _userController,
                            focusNode: _userFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            decoration: InputDecoration(
                              hintText: 'User ID/Email/Nomor HP',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: inputBorderColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: inputBorderColor,
                                  width: 1.2,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password (Password field at bottom as requested)
                        SizedBox(
                          height: fieldHeight,
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleDaftarByDCT(),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: inputBorderColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: inputBorderColor,
                                  width: 1.2,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Login button (now functional with DaftarByDCT API call)
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleDaftarByDCT,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueButton,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 36), // increased spacing as requested

                        // Two links: Lupa Password DCT, Lupa Password Email
                        Column(
                          children: [
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: linkBlue,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Password DCT',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: linkBlue,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Password Email',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}