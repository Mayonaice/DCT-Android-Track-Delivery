import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custommodals.dart';

class UbahPasswordPage extends StatefulWidget {
  const UbahPasswordPage({super.key});

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  // Form controllers
  final TextEditingController _passwordLamaController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();
  
  // State variables
  bool _isSaving = false;
  bool _obscurePasswordLama = true;
  bool _obscurePasswordBaru = true;
  bool _obscureKonfirmasiPassword = true;

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    print('🔍 DEBUG: _changePassword started');
    
    // Validasi form
    if (_passwordLamaController.text.trim().isEmpty) {
      CustomModals.showErrorModal(context, 'Password lama tidak boleh kosong');
      return;
    }

    if (_passwordBaruController.text.trim().isEmpty) {
      CustomModals.showErrorModal(context, 'Password baru tidak boleh kosong');
      return;
    }

    if (_konfirmasiPasswordController.text.trim().isEmpty) {
      CustomModals.showErrorModal(context, 'Konfirmasi password tidak boleh kosong');
      return;
    }

    // Validasi konfirmasi password
    if (_passwordBaruController.text.trim() != _konfirmasiPasswordController.text.trim()) {
      CustomModals.showErrorModal(context, 'Konfirmasi password tidak sesuai dengan password baru');
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      print('🔍 DEBUG: Getting token from storage...');
      final token = await _storageService.getToken();
      
      if (token == null) {
        if (mounted) {
          CustomModals.showErrorModal(context, 'Token tidak ditemukan. Silakan login kembali.');
        }
        return;
      }

      print('🔍 DEBUG: Calling changePassword API...');
      final response = await _apiService.changePassword(
        token,
        _passwordLamaController.text.trim(),
        _passwordBaruController.text.trim(),
      );
      
      print('🔍 DEBUG: Response: $response');
      
      if (mounted) {
        if (response['success'] == true) {
          CustomModals.showSuccessModal(
            context, 
            'Password berhasil diubah',
            onOk: () {
              Navigator.pop(context);
            },
          );
        } else {
          CustomModals.showErrorModal(
            context, 
            response['message'] ?? 'Gagal mengubah password',
          );
        }
      }
    } catch (e) {
      print('🚨 DEBUG: Error changing password: $e');
      if (mounted) {
        CustomModals.showErrorModal(
          context, 
          'Terjadi kesalahan: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            border: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF059669),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
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
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF059669),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ubah Password',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Password Lama Field
            _buildPasswordField(
              label: 'Password Lama',
              controller: _passwordLamaController,
              obscureText: _obscurePasswordLama,
              onToggleVisibility: () {
                setState(() {
                  _obscurePasswordLama = !_obscurePasswordLama;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Password Baru Field
            _buildPasswordField(
              label: 'Password Baru',
              controller: _passwordBaruController,
              obscureText: _obscurePasswordBaru,
              onToggleVisibility: () {
                setState(() {
                  _obscurePasswordBaru = !_obscurePasswordBaru;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Konfirmasi Password Baru Field
            _buildPasswordField(
              label: 'Konfirmasi Password Baru',
              controller: _konfirmasiPasswordController,
              obscureText: _obscureKonfirmasiPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureKonfirmasiPassword = !_obscureKonfirmasiPassword;
                });
              },
            ),
            const SizedBox(height: 40),
            
            // Ubah Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}