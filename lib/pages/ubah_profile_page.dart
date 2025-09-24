import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile_model.dart';

class UbahProfilePage extends StatefulWidget {
  const UbahProfilePage({super.key});

  @override
  State<UbahProfilePage> createState() => _UbahProfilePageState();
}

class _UbahProfilePageState extends State<UbahProfilePage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  // Form controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ktpController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  
  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  UserProfileData? _profileData;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: initState called - starting to load user profile');
    _loadUserProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _ktpController.dispose();
    _nomorHpController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    print('🔍 DEBUG: _loadUserProfile started');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔍 DEBUG: Getting token from storage...');
      final token = await _storageService.getToken();
      print('🔍 DEBUG: Token retrieved: ${token != null ? "Token exists" : "Token is null"}');
      
      if (token == null) {
        print('🚨 DEBUG: Token is null, showing error');
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }

      print('🔍 DEBUG: Calling getUserProfile API...');
      final response = await _apiService.getUserProfile(token);
      print('🔍 DEBUG: Response received: $response');
      
      if (response['success'] == true && response['data'] != null) {
        print('🔍 DEBUG: Response data: ${response['data']}');
        
        // Data user ada di response['data']['data'] karena struktur nested
        final userData = response['data']['data'];
        print('🔍 DEBUG: User data: $userData');
        
        if (userData != null) {
          setState(() {
            _profileData = UserProfileData.fromJson(userData);
            print('🔍 DEBUG: Profile data created: ${_profileData!.name}');
            // Set default values to form controllers
            _namaController.text = _profileData!.name;
            _ktpController.text = _profileData!.idNumber;
            _nomorHpController.text = _profileData!.phoneNumber;
            _emailController.text = _profileData!.userEmail;
            _alamatController.text = _profileData!.address;
            print('🔍 DEBUG: Controllers set - Nama: ${_namaController.text}, KTP: ${_ktpController.text}');
            _isLoading = false;
          });
        } else {
          print('🚨 DEBUG: User data is null in nested response');
          setState(() {
            _errorMessage = 'Data user tidak ditemukan dalam response';
            _isLoading = false;
          });
        }
      } else {
        print('🚨 DEBUG: API call failed: ${response['message']}');
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data profil';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🚨 DEBUG: Exception in _loadUserProfile: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    // TODO: Implement save profile API call
    setState(() {
      _isSaving = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isSaving = false;
    });
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 16,
            color: readOnly ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: readOnly ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: readOnly ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB),
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
            counterText: '', // Hide character counter
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
          'Ubah Profil',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false, // Ubah dari true ke false untuk align kiri
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1.0,
          ),
        ),
      ),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Field (Editable)
                      _buildTextField(
                        label: 'Nama',
                        controller: _namaController,
                      ),
                      const SizedBox(height: 20),
                      
                      // No KTP Field (Read-only)
                      _buildTextField(
                        label: 'No KTP',
                        controller: _ktpController,
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      
                      // Nomor HP Field (Editable) - Max 13 characters
                      _buildTextField(
                        label: 'Nomor HP',
                        controller: _nomorHpController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        maxLength: 13,
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Field (Read-only)
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        readOnly: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      
                      // Alamat Field (Editable)
                      _buildTextField(
                        label: 'Alamat',
                        controller: _alamatController,
                      ),
                      const SizedBox(height: 40),
                      
                      // Simpan Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25), // Ubah dari 12 ke 25 untuk rounded pill
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
                                  'Simpan',
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