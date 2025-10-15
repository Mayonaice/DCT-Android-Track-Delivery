import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/custommodals.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final Map<String, dynamic>? registrationData; // Add registration data parameter

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.phoneNumber,
    this.registrationData, // Optional registration data
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _hasError = false; // Add error state
  String _errorMessage = ''; // Add error message
  
  // Countdown timer variables
  Timer? _countdownTimer;
  int _countdownSeconds = 60; // 1 minute countdown
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    setState(() {
      _countdownSeconds = 60;
      _canResendOtp = false;
    });
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResendOtp || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 DEBUG: Resending OTP verification code');
      
      // Call RegisterVerification API to resend OTP
      final response = await _apiService.registerVerification(
        name: widget.registrationData?['name'] ?? '',
        email: widget.email,
        phoneNumber: widget.phoneNumber,
      );

      print('📥 DEBUG: Resend OTP response: $response');

      if (response['success'] == true) {
        print('✅ DEBUG: OTP resent successfully');
        
        // Clear current OTP inputs
        for (var controller in _otpControllers) {
          controller.clear();
        }
        
        // Reset error state
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
        
        // Restart countdown timer
        _startCountdownTimer();
        
        // Show success message
        CustomModals.showSuccessModal(
          context,
          'Kode OTP baru telah dikirim',
        );
      } else {
        print('❌ DEBUG: Failed to resend OTP: ${response['message']}');
        CustomModals.showErrorModal(
          context,
          response['message'] ?? 'Gagal mengirim ulang kode OTP',
        );
      }
    } catch (e) {
      print('🚨 DEBUG: Error resending OTP: $e');
      CustomModals.showErrorModal(
        context,
        'Terjadi kesalahan saat mengirim ulang kode OTP',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOtpComplete() {
    return _getOtpCode().length == 6;
  }

  void _onOtpChanged(String value, int index) {
    // Reset error state when user starts typing
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
    
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto submit when OTP is complete
    if (_isOtpComplete()) {
      _verifyOtp();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete()) {
      CustomModals.showErrorModal(context, 'Silakan masukkan kode OTP lengkap');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false; // Reset error state
      _errorMessage = ''; // Reset error message
    });

    try {
      print('🔄 DEBUG: Starting OTP verification');
      print('📧 DEBUG: Email: ${widget.email}');
      print('🔢 DEBUG: OTP: ${_getOtpCode()}');

      final response = await _apiService.otpVerification(
        otp: _getOtpCode(),
        email: widget.email,
      );

      print('📥 DEBUG: OTP verification response: $response');

      if (response['success'] == true) {
        print('✅ DEBUG: OTP verification successful');
        
        // Reset error state on success
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
        
        // If registration data is provided, register the user after OTP verification
        if (widget.registrationData != null) {
          print('📝 DEBUG: Registering user after OTP verification');
          
          final registerResponse = await _apiService.register(
            name: widget.registrationData!['name'],
            idNumber: widget.registrationData!['idNumber'],
            userEmail: widget.registrationData!['userEmail'],
            phoneNumber: widget.registrationData!['phoneNumber'],
            password: widget.registrationData!['password'],
            address: widget.registrationData!['address'],
          );

          print('📥 DEBUG: Register response after OTP: $registerResponse');

          if (registerResponse['success'] == true) {
            print('✅ DEBUG: User registration successful after OTP verification');
            CustomModals.showSuccessModal(
              context,
              'Verifikasi berhasil! Akun Anda telah terdaftar.',
              onOk: () {
                // Navigate back to main.dart
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            );
          } else {
            print('❌ DEBUG: User registration failed after OTP: ${registerResponse['message']}');
            CustomModals.showErrorModal(context, registerResponse['message'] ?? 'Gagal mendaftarkan pengguna setelah verifikasi OTP');
          }
        } else {
          // No registration data, just show success (for other use cases)
          CustomModals.showSuccessModal(
            context,
            'Verifikasi berhasil!',
            onOk: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          );
        }
      } else {
        print('❌ DEBUG: OTP verification failed: ${response['message']}');
        
        // Set error state and message
        setState(() {
          _hasError = true;
          _errorMessage = response['message'] ?? 'Kode OTP tidak valid';
        });
        
        // Don't show modal, just update UI with red outline and error message
      }
    } catch (e) {
      print('🚨 DEBUG: Error during OTP verification: $e');
      
      // Set error state for network/system errors
      setState(() {
        _hasError = true;
        _errorMessage = 'Terjadi kesalahan saat verifikasi OTP';
      });
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B8B7A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verifikasi',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Title
            const Text(
              'Masukan Kode Verifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Kode verifikasi telah dikirim ke whatsapp ${widget.phoneNumber} dan email ${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            
            // OTP Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasError 
                          ? Colors.red // Red border when there's an error
                          : (_otpControllers[index].text.isNotEmpty 
                              ? const Color(0xFF1B8B7A) 
                              : const Color(0xFFE5E7EB)),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      setState(() {
                        _onOtpChanged(value, index);
                      });
                    },
                    onTap: () {
                      _otpControllers[index].selection = TextSelection.fromPosition(
                        TextPosition(offset: _otpControllers[index].text.length),
                      );
                    },
                    onSubmitted: (value) {
                      if (value.isEmpty && index > 0) {
                        _onBackspace(index);
                      }
                    },
                  ),
                );
              }),
            ),
            
            // Error message below OTP boxes
            if (_hasError && _errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Resend Code Timer/Button
            GestureDetector(
              onTap: _canResendOtp ? _resendOtp : null,
              child: Text(
                _canResendOtp 
                    ? 'Kirim Ulang Kode OTP'
                    : 'Kirim Ulang Kode dalam ${_countdownSeconds ~/ 60}:${(_countdownSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  color: _canResendOtp ? const Color(0xFF1B8B7A) : const Color(0xFF6B7280),
                  fontWeight: _canResendOtp ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Loading indicator when processing
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B8B7A)),
              ),
          ],
        ),
      ),
    );
  }
}