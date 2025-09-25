import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custommodals.dart';

class CheckDeliveryPage extends StatefulWidget {
  const CheckDeliveryPage({super.key});

  @override
  State<CheckDeliveryPage> createState() => _CheckDeliveryPageState();
}

class _CheckDeliveryPageState extends State<CheckDeliveryPage> {
  final TextEditingController _deliveryCodeController = TextEditingController();

  @override
  void dispose() {
    _deliveryCodeController.dispose();
    super.dispose();
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
                      'Cek Pengiriman Kamu Disini',
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
              
              // Delivery code input field
              TextField(
                controller: _deliveryCodeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan Kode Pengiriman',
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
              
              // Check delivery button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    print('🔄 DEBUG: Check delivery button pressed');
                    // Handle check delivery logic here
                    HapticFeedback.lightImpact();
                    CustomModals.showSuccessModal(
                      context,
                      'Check delivery functionality will be implemented',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8B7A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Cek Pengiriman',
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
                            Navigator.pushNamedAndRemoveUntil(
                              context, 
                              '/', 
                              (route) => false,
                            );
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
                          'Anda Mendapat Kode Pengiriman? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/login-with-code');
                          },
                          child: const Text(
                            'Masuk dengan Kode',
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