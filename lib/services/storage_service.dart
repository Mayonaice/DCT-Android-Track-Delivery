import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _tokenKey = 'token_access';
  static const String _tokenExpiresKey = 'token_expires';
  static const String _userDataKey = 'user_data';
  static const String _profileDataKey = 'profile_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _testModeKey = 'test_mode';
  static const String _loginEmailKey = 'login_email';
  static const String _loginPasswordKey = 'login_password';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Save login data
  Future<void> saveLoginData(
    Map<String, dynamic> loginData, {
    String? email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    print('🔍 DEBUG: Saving login data: $loginData');
    
    // Extract tokenAccess from various possible locations
    String? tokenAccess;
    String? tokenExpires;
    Map<String, dynamic>? profileData;
    
    // Try to find tokenAccess in different structures
    if (loginData['application'] != null) {
      tokenAccess = loginData['application']['tokenAccess'];
      tokenExpires = loginData['application']['tokenExpires'];
    } else if (loginData['tokenAccess'] != null) {
      tokenAccess = loginData['tokenAccess'];
      tokenExpires = loginData['tokenExpires'];
    } else if (loginData['token'] != null) {
      tokenAccess = loginData['token'];
      tokenExpires = loginData['expires'];
    } else if (loginData['access_token'] != null) {
      tokenAccess = loginData['access_token'];
      tokenExpires = loginData['expires_at'];
    }
    
    // Try to find profile data
    if (loginData['profile'] != null) {
      profileData = loginData['profile'];
    } else if (loginData['user'] != null) {
      profileData = loginData['user'];
    }
    
    if (tokenAccess != null && tokenAccess.isNotEmpty) {
      // Save token and expires
      await prefs.setString(_tokenKey, tokenAccess);
      if (tokenExpires != null) {
        await prefs.setString(_tokenExpiresKey, tokenExpires);
      }
      
      // Save profile data if available
      if (profileData != null) {
        await prefs.setString(_profileDataKey, jsonEncode(profileData));
      }
      
      // Save entire user data
      await prefs.setString(_userDataKey, jsonEncode(loginData));
      await prefs.setBool(_isLoggedInKey, true);

      final resolvedEmail = (email?.trim().isNotEmpty ?? false)
          ? email!.trim()
          : (profileData?['userEmail']?.toString().trim() ?? '');
      if (resolvedEmail.isNotEmpty) {
        await prefs.setString(_loginEmailKey, resolvedEmail);
      }

      if (password != null && password.trim().isNotEmpty) {
        await _secureStorage.write(key: _loginPasswordKey, value: password);
      }
      
      print('✅ DEBUG: Login data saved successfully with token: ${tokenAccess.substring(0, 10)}...');
    } else {
      print('❌ DEBUG: No valid tokenAccess found in login data');
      throw Exception('No valid tokenAccess found in login response');
    }
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get token expires
  Future<String?> getTokenExpires() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenExpiresKey);
  }

  // Get profile data
  Future<Map<String, dynamic>?> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileDataKey);
    if (profileJson != null) {
      return jsonDecode(profileJson);
    }
    return null;
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<bool> isTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? false;
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final tokenExpires = await getTokenExpires();
    if (tokenExpires == null) return true;
    
    try {
      final expiryDate = DateTime.parse(tokenExpires);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  // Clear all login data (logout)
  Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiresKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_profileDataKey);
    await prefs.remove(_loginEmailKey);
    await _secureStorage.delete(key: _loginPasswordKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<void> setTestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, enabled);
  }

  // Get user name
  Future<String> getUserName() async {
    final profileData = await getProfileData();
    return profileData?['name'] ?? 'User';
  }

  // Get user email
  Future<String> getUserEmail() async {
    final profileData = await getProfileData();
    return profileData?['userEmail'] ?? '';
  }

  Future<String> getLoginEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_loginEmailKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return getUserEmail();
  }

  Future<String?> getLoginPassword() async {
    return _secureStorage.read(key: _loginPasswordKey);
  }

  // Get user phone
  Future<String> getUserPhone() async {
    final profileData = await getProfileData();
    return profileData?['phoneNumber'] ?? '';
  }

  // Get user ID number
  Future<String> getUserIdNumber() async {
    final profileData = await getProfileData();
    return profileData?['idNumber'] ?? '';
  }

  // Get user address
  Future<String> getUserAddress() async {
    final profileData = await getProfileData();
    return profileData?['address'] ?? '';
  }

  // Get profile picture filename
  Future<String?> getProfilePictureFileName() async {
    final profileData = await getProfileData();
    return profileData?['profilePictureFileName'];
  }
}
