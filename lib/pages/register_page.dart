import 'package:flutter/material.dart';
import 'login_with_code_page.dart';
import 'otp_verification_page.dart';
import '../services/api_service.dart';
import '../widgets/custommodals.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _ktpController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  
  final ApiService _apiService = ApiService();
  
  // Variables to store form data
  String _savedName = '';
  String _savedIdNumber = '';
  String _savedEmail = '';
  String _savedPhoneNumber = '';
  String _savedPassword = '';

  @override
  void dispose() {
    _namaController.dispose();
    _ktpController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    print('🔄 DEBUG: Starting form validation');
    
    // Check for empty fields and show specific error messages
    if (_namaController.text.trim().isEmpty) {
      print('❌ DEBUG: Nama field is empty');
      CustomModals.showErrorModal(context, 'Kolom Nama masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }
    
    if (_ktpController.text.trim().isEmpty) {
      print('❌ DEBUG: No KTP field is empty');
      CustomModals.showErrorModal(context, 'Kolom No KTP masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }
    
    if (_emailController.text.trim().isEmpty) {
      print('❌ DEBUG: Email field is empty');
      CustomModals.showErrorModal(context, 'Kolom Email masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      print('❌ DEBUG: Phone number field is empty');
      CustomModals.showErrorModal(context, 'Kolom No Handphone masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }
    
    // Validate phone number length (minimum 12 digits)
    if (_phoneController.text.trim().length < 12) {
      print('❌ DEBUG: Phone number too short');
      CustomModals.showErrorModal(context, 'No Handphone minimal harus 12 angka!');
      return false;
    }
    
    if (_passwordController.text.trim().isEmpty) {
      print('❌ DEBUG: Password field is empty');
      CustomModals.showErrorModal(context, 'Kolom Password masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }
    
    // Validate password complexity
    String password = _passwordController.text;
    if (password.length < 8) {
      print('❌ DEBUG: Password too short');
      CustomModals.showErrorModal(context, 'Password minimal harus 8 karakter!');
      return false;
    }
    
    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      print('❌ DEBUG: Password missing uppercase');
      CustomModals.showErrorModal(context, 'Password harus mengandung minimal 1 huruf besar!');
      return false;
    }
    
    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      print('❌ DEBUG: Password missing lowercase');
      CustomModals.showErrorModal(context, 'Password harus mengandung minimal 1 huruf kecil!');
      return false;
    }
    
    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      print('❌ DEBUG: Password missing number');
      CustomModals.showErrorModal(context, 'Password harus mengandung minimal 1 angka!');
      return false;
    }
    
    if (_confirmPasswordController.text.trim().isEmpty) {
      print('❌ DEBUG: Confirm password field is empty');
      CustomModals.showErrorModal(context, 'Kolom Konfirmasi Password masih kosong, harap dilengkapi terlebih dahulu!');
      return false;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      print('❌ DEBUG: Password confirmation mismatch');
      CustomModals.showErrorModal(context, 'Password dan konfirmasi password tidak sama');
      return false;
    }

    print('✅ DEBUG: Form validation successful');
    return true;
  }

  void _saveFormData() {
    print('💾 DEBUG: Saving form data');
    _savedName = _namaController.text.trim();
    _savedIdNumber = _ktpController.text.trim();
    _savedEmail = _emailController.text.trim();
    _savedPhoneNumber = _phoneController.text.trim();
    _savedPassword = _passwordController.text;
    
    print('📝 DEBUG: Saved data - Name: $_savedName, Email: $_savedEmail, Phone: $_savedPhoneNumber');
  }

  void _handleRegister() async {
    print('🚀 DEBUG: Register button pressed');
    
    if (!_validateForm()) {
      return;
    }

    _saveFormData();
    
    // Show verification modal
    CustomModals.showVerificationModal(
      context,
      phoneNumber: _savedPhoneNumber,
      email: _savedEmail,
      onSendVerification: _sendVerificationCode,
    );
  }

  Future<void> _sendVerificationCode() async {
    print('📤 DEBUG: Sending verification code');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // First, send verification code (OTP) - DON'T register user yet
      print('📧 DEBUG: Sending OTP verification code first');
      final verificationResponse = await _apiService.registerVerification(
        name: _savedName,
        email: _savedEmail,
        phoneNumber: _savedPhoneNumber,
      );

      print('📥 DEBUG: Verification response: $verificationResponse');

      if (verificationResponse['success'] == true) {
        print('✅ DEBUG: Verification code sent successfully');
        
        // Close modal and navigate to OTP page
        Navigator.of(context).pop(); // Close modal
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              email: _savedEmail,
              phoneNumber: _savedPhoneNumber,
              // Pass the form data to OTP page so it can register after verification
              registrationData: {
                'name': _savedName,
                'idNumber': _savedIdNumber,
                'userEmail': _savedEmail,
                'phoneNumber': _savedPhoneNumber,
                'password': _savedPassword,
                'address': '',
              },
            ),
          ),
        );
      } else {
        print('❌ DEBUG: Failed to send verification code: ${verificationResponse['message']}');
        CustomModals.showErrorModal(context, verificationResponse['message'] ?? 'Gagal mengirim kode verifikasi');
      }
    } catch (e) {
      print('🚨 DEBUG: Error during verification: $e');
      CustomModals.showErrorModal(context, 'Terjadi kesalahan saat mengirim kode verifikasi');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B8B7A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Nama Field
              const Text(
                'Nama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  hintText: 'Masukan Nama Anda',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // No KTP Field
              const Text(
                'No KTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ktpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Masukan No KTP Anda',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Email Field
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Masukan Email Anda',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // No Handphone Field
              const Text(
                'No Handphone (Whatsapp)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Masukan No HP Anda',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Masukan Password',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF1B8B7A),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Konfirmasi Password Field
              const Text(
                'Konfirmasi Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Masukan Konfirmasi Password',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B8B7A)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF1B8B7A),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Daftar Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8B7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Divider with "atau"
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE5E7EB),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'atau',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE5E7EB),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // DCT Web Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // Handle DCT Web registration
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF1B8B7A),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Logo-DCT.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'DAFTAR MENGGUNAKAN DCT WEB',
                        style: TextStyle(
                          color: Color(0xFF1B8B7A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Login Link
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Sudah Punya Akun? ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Klik disini',
                        style: TextStyle(
                          color: Color(0xFF1B8B7A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Anda Mendapat Kode Pengiriman? ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginWithCodePage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Masuk dengan Kode',
                        style: TextStyle(
                          color: Color(0xFF1B8B7A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}