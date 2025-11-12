import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/transaction_model.dart';
import '../models/delivery_detail_model.dart';
import '../models/send_goods_model.dart';
import '../models/login_code_model.dart';
import '../models/delivery_transaction_detail_model.dart';
import '../models/delivery_status_detail_model.dart';
import '../models/notification_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Login API
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('${Config.baseUrl}${Config.loginEndpoint}');
      
      print('🔍 DEBUG: Login URL: $url');
      print('🔍 DEBUG: Request body: {"username": "$username", "password": "***"}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      // IMPORTANT: Handle empty or invalid JSON response
      Map<String, dynamic> responseData;
      try {
        if (response.body.isEmpty) {
          print('🚨 DEBUG: Response body is empty!');
          return {
            'success': false,
            'message': 'Server mengembalikan response kosong',
            'data': null,
          };
        }
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Parsed response data: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: JSON parsing error: $jsonError');
        return {
          'success': false,
          'message': 'Server mengembalikan response yang tidak valid: ${response.body}',
          'data': null,
        };
      }

      if (response.statusCode == 200) {
        // IMPORTANT: Check if API response indicates success
        // Even with status 200, API might return ok: false for failed login
        bool isApiSuccess = responseData['ok'] == true || 
                           responseData['success'] == true ||
                           responseData['status'] == true;
        
        if (isApiSuccess && responseData['data'] != null) {
          // Validate that we have tokenAccess in the response
          // Check multiple possible locations for the token
          var tokenAccess;
          
          // First check in data.application.tokenAccess (current API structure)
          if (responseData['data']['application'] != null) {
            tokenAccess = responseData['data']['application']['tokenAccess'];
          }
          
          // Fallback to other possible locations
          if (tokenAccess == null) {
            tokenAccess = responseData['data']['tokenAccess'] ?? 
                         responseData['tokenAccess'] ?? 
                         responseData['token'] ?? 
                         responseData['access_token'];
          }
          
          print('🔍 DEBUG: Looking for token in response structure...');
          print('🔍 DEBUG: Found tokenAccess: ${tokenAccess != null ? "YES" : "NO"}');
          
          if (tokenAccess != null && tokenAccess.toString().isNotEmpty) {
            print('✅ DEBUG: Login successful with valid token: ${tokenAccess.toString().substring(0, 20)}...');
            return {
              'success': true,
              'data': responseData['data'],
            };
          } else {
            print('❌ DEBUG: Login failed - no valid token in response');
            print('🔍 DEBUG: Response structure: ${responseData.toString()}');
            return {
              'success': false,
              'message': 'Login gagal - token tidak valid',
              'data': responseData,
            };
          }
        } else {
          // API returned ok: false or similar
          String errorMessage = 'Login gagal';
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'] ?? 
                          responseData['error'] ?? 
                          responseData['msg'] ?? 
                          responseData['Message'] ?? 
                          responseData['Error'] ?? 
                          'Login gagal - kredensial tidak valid';
          }
          
          print('❌ DEBUG: API returned failure: $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
            'data': responseData,
          };
        }
      } else {
        // IMPORTANT: Always use message from API response for error notifications
        String errorMessage = 'Login gagal';
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? 
                        responseData['error'] ?? 
                        responseData['msg'] ?? 
                        responseData['Message'] ?? 
                        responseData['Error'] ?? 
                        'Login gagal - tidak ada pesan error dari server';
        }
        
        print('❌ DEBUG: Login failed with message: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'data': responseData,
        };
      }
    } catch (e) {
      print('🚨 DEBUG: Exception occurred: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // DaftarByDCT API
  Future<Map<String, dynamic>> daftarByDCT(String username, String password) async {
    try {
      final url = Uri.parse('${Config.baseUrl}Users/DaftarByDCT');
      
      print('🔍 DEBUG: DaftarByDCT URL: $url');
      print('🔍 DEBUG: Request body: {"username": "$username", "password": "***"}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      // IMPORTANT: Handle empty or invalid JSON response
      Map<String, dynamic> responseData;
      try {
        if (response.body.isEmpty) {
          print('🚨 DEBUG: Response body is empty!');
          return {
            'success': false,
            'message': 'Server mengembalikan response kosong',
            'data': null,
          };
        }
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Parsed response data: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: JSON parsing error: $jsonError');
        return {
          'success': false,
          'message': 'Server mengembalikan response yang tidak valid: ${response.body}',
          'data': null,
        };
      }

      if (response.statusCode == 200) {
        // IMPORTANT: Check if API response indicates success using 'ok' field
        bool isApiSuccess = responseData['ok'] == true;
        
        if (isApiSuccess && responseData['data'] != null) {
          // Validate that we have tokenAccess in the response
          // Check multiple possible locations for the token
          var tokenAccess;
          
          // First check in data.application.tokenAccess (current API structure)
          if (responseData['data']['application'] != null) {
            tokenAccess = responseData['data']['application']['tokenAccess'];
          }
          
          // Fallback to other possible locations
          if (tokenAccess == null) {
            tokenAccess = responseData['data']['tokenAccess'] ?? 
                         responseData['tokenAccess'] ?? 
                         responseData['token'] ?? 
                         responseData['access_token'];
          }
          
          print('🔍 DEBUG: Looking for token in response structure...');
          print('🔍 DEBUG: Found tokenAccess: ${tokenAccess != null ? "YES" : "NO"}');
          
          if (tokenAccess != null && tokenAccess.toString().isNotEmpty) {
            print('✅ DEBUG: DaftarByDCT successful with valid token: ${tokenAccess.toString().substring(0, 20)}...');
            return {
              'success': true,
              'data': responseData['data'],
            };
          } else {
            print('❌ DEBUG: DaftarByDCT failed - no valid token in response');
            print('🔍 DEBUG: Response structure: ${responseData.toString()}');
            return {
              'success': false,
              'message': 'Daftar gagal - token tidak valid',
              'data': responseData,
            };
          }
        } else {
          // API returned ok: false
          String errorMessage = 'Daftar gagal';
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'] ?? 
                          responseData['error'] ?? 
                          responseData['msg'] ?? 
                          responseData['Message'] ?? 
                          responseData['Error'] ?? 
                          'Daftar gagal - kredensial tidak valid';
          }
          
          print('❌ DEBUG: API returned failure: $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
            'data': responseData,
          };
        }
      } else {
        // IMPORTANT: Always use message from API response for error notifications
        String errorMessage = 'Daftar gagal';
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? 
                        responseData['error'] ?? 
                        responseData['msg'] ?? 
                        responseData['Message'] ?? 
                        responseData['Error'] ?? 
                        'Daftar gagal - tidak ada pesan error dari server';
        }
        
        print('❌ DEBUG: DaftarByDCT failed with message: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'data': responseData,
        };
      }
    } catch (e) {
      print('🚨 DEBUG: Exception occurred: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Generic GET request with token
  Future<Map<String, dynamic>> get(String endpoint, {String? token, Map<String, String>? queryParams}) async {
    try {
      Uri url;
      if (queryParams != null && queryParams.isNotEmpty) {
        url = Uri.parse('${Config.baseUrl}$endpoint').replace(queryParameters: queryParams);
      } else {
        url = Uri.parse('${Config.baseUrl}$endpoint');
      }
      
      print('🔍 DEBUG: GET URL: $url');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('🔍 DEBUG: GET Headers: $headers');

      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      
      print('🔍 DEBUG: GET Response status: ${response.statusCode}');
      print('🔍 DEBUG: GET Response body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: Server returned empty response!');
        return {
          'success': false,
          'message': 'Server mengembalikan response kosong',
          'data': null,
        };
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Successfully parsed JSON: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: JSON parsing failed: $jsonError');
        return {
          'success': false,
          'message': 'Server mengembalikan response yang tidak valid: ${jsonError.toString()}',
          'data': null,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request gagal',
          'data': responseData,
        };
      }
    } catch (e) {
      print('🚨 DEBUG: GET request exception: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Generic POST request with token and optional query parameters
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token, Map<String, dynamic>? queryParams}) async {
    try {
      Uri url = Uri.parse('${Config.baseUrl}$endpoint');
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('🔍 DEBUG: POST URL: $url');
      print('🔍 DEBUG: POST Headers: $headers');
      print('🔍 DEBUG: POST Body: ${jsonEncode(body)}');
      if (queryParams != null) {
        print('🔍 DEBUG: POST Query Params: $queryParams');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Response status code: ${response.statusCode}');
      print('🔍 DEBUG: Response headers: ${response.headers}');
      print('🔍 DEBUG: Raw response body: "${response.body}"');
      print('🔍 DEBUG: Response body length: ${response.body.length}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: Server returned empty response!');
        return {
          'success': false,
          'message': 'Server mengembalikan response kosong',
          'data': null,
        };
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Successfully parsed JSON: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: JSON parsing failed: $jsonError');
        print('🚨 DEBUG: Raw response that failed to parse: "${response.body}"');
        return {
          'success': false,
          'message': 'Server mengembalikan response yang tidak valid: ${jsonError.toString()}',
          'data': null,
        };
      }

      if (response.statusCode == 200) {
        // Check if response has 'ok' field and use it for success determination
        bool isSuccess = responseData['ok'] ?? true; // Default to true if 'ok' field doesn't exist
        
        return {
          'success': isSuccess,
          'message': responseData['message'] ?? (isSuccess ? 'Request berhasil' : 'Request gagal'),
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request gagal dengan status ${response.statusCode}',
          'data': responseData,
        };
      }
    } catch (e) {
      print('🚨 DEBUG: POST request exception: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Helper function to truncate base64 values
  String _truncateBase64(dynamic value) {
    if (value is String && value.length > 100) {
      // Check if it looks like base64 (contains typical base64 characters)
      if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
        return '${value.substring(0, 50)}...${value.substring(value.length - 10)}';
      }
    }
    return value.toString();
  }

  // Helper function to process object and truncate base64 values
  Map<String, dynamic> _processObjectForDebug(Map<String, dynamic> obj) {
    Map<String, dynamic> processed = {};
    obj.forEach((key, value) {
      if (value is String && value.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
        processed[key] = '${value.substring(0, 50)}...${value.substring(value.length - 10)}';
      } else if (value is Map<String, dynamic>) {
        processed[key] = _processObjectForDebug(value);
      } else if (value is List) {
        processed[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _processObjectForDebug(item);
          } else if (item is String && item.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(item)) {
            return '${item.substring(0, 50)}...${item.substring(item.length - 10)}';
          }
          return item;
        }).toList();
      } else {
        processed[key] = value;
      }
    });
    return processed;
  }

  // Add Transaction API
  Future<Map<String, dynamic>> addTransaction(SendGoodsRequest sendGoods, String token) async {
    try {
      final url = Uri.parse('${Config.baseUrl}Transaction/Trx/Add');
      
      print('🔍 DEBUG: Add Transaction URL: $url');
      
      // Debug request body dengan format yang lebih readable
      final requestBody = sendGoods.toJson();
      print('🔍 DEBUG: Request body structure:');
      print('  - Items count: ${requestBody['Items']?.length ?? 0}');
      print('  - Consignees count: ${requestBody['Consignees']?.length ?? 0}');
      print('  - Viewers count: ${requestBody['Viewers']?.length ?? 0}');
      
      // Debug individual sections with base64 truncation
      if (requestBody['Items'] != null && requestBody['Items'].isNotEmpty) {
        final processedItem = _processObjectForDebug(requestBody['Items'][0]);
        print('🔍 DEBUG: First Item: ${jsonEncode(processedItem)}');
      }
      
      if (requestBody['Consignees'] != null && requestBody['Consignees'].isNotEmpty) {
        final processedConsignee = _processObjectForDebug(requestBody['Consignees'][0]);
        print('🔍 DEBUG: First Consignee: ${jsonEncode(processedConsignee)}');
      } else {
        print('🚨 DEBUG: Consignees is null or empty!');
      }
      
      if (requestBody['Viewers'] != null && requestBody['Viewers'].isNotEmpty) {
        final processedViewer = _processObjectForDebug(requestBody['Viewers'][0]);
        print('🔍 DEBUG: First Viewer: ${jsonEncode(processedViewer)}');
      } else {
        print('🚨 DEBUG: Viewers is null or empty!');
      }

      // Process request body for debug output
      final processedRequestBody = _processObjectForDebug(requestBody);
      final requestBodyJson = jsonEncode(processedRequestBody);
      print('🔍 DEBUG: Request body length: ${jsonEncode(requestBody).length} characters (original)');
      print('🔍 DEBUG: Processed request body: $requestBodyJson');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: Response body is empty!');
        return {
          'success': false,
          'message': 'Server mengembalikan response kosong',
          'data': null,
        };
      }

      // Parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Parsed response data: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: JSON parsing error: $jsonError');
        return {
          'success': false,
          'message': 'Server mengembalikan response yang tidak valid: ${response.body}',
          'data': null,
        };
      }

      if (response.statusCode == 200) {
        // Check if API response indicates success
        bool isApiSuccess = responseData['ok'] == true;
        
        if (isApiSuccess) {
          print('✅ DEBUG: Add transaction successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Transaksi berhasil ditambahkan',
            'data': responseData,
          };
        } else {
          // API returned ok: false
          String errorMessage = responseData['message'] ?? 'Gagal menambahkan transaksi';
          print('❌ DEBUG: API returned failure: $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
            'data': responseData,
          };
        }
      } else {
        String errorMessage = responseData['message'] ?? 'Gagal menambahkan transaksi';
        print('❌ DEBUG: Add transaction failed with message: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'data': responseData,
        };
      }
    } catch (e) {
      print('🚨 DEBUG: Exception occurred: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Get Transactions API
  Future<TransactionResponse?> getTransactions(TransactionRequest request, String token) async {
    try {
      print('🔍 DEBUG: Request body: ${jsonEncode(request.toJson())}');
      print('🔍 DEBUG: Token: ${token.substring(0, 20)}...');
      
      final response = await post(
        'Transaction/Trx',  // Hanya endpoint, bukan full URL
        request.toJson(),
        token: token,
      );

      print('🔍 DEBUG: Raw API response: $response');
      print('🔍 DEBUG: Response success: ${response['success']}');
      print('🔍 DEBUG: Response data type: ${response['data'].runtimeType}');

      if (response['success'] == true) {
        final transactionResponse = TransactionResponse.fromJson(response['data']);
        print('🔍 DEBUG: Parsed transaction count: ${transactionResponse.data.length}');
        return transactionResponse;
      } else {
        print('🚨 DEBUG: Transaction API error: ${response['message']}');
        print('🚨 DEBUG: Full error response: $response');
        return null;
      }
    } catch (e, stackTrace) {
      print('🚨 DEBUG: Transaction API exception: $e');
      print('🚨 DEBUG: Stack trace: $stackTrace');
      return null;
    }
  }

  // Get User Profile API
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await get('Users/Profile', token: token);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat mengambil data profil: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Update User Profile API
  Future<Map<String, dynamic>> updateUserProfile(String token, Map<String, dynamic> profileData) async {
    try {
      print('🔍 DEBUG: Updating user profile with data: $profileData');
      
      final response = await post('Users/Profile', profileData, token: token);
      
      print('🔍 DEBUG: Update profile response: $response');
      return response;
    } catch (e) {
      print('🚨 DEBUG: Error updating profile: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat memperbarui profil: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Change Password API
  Future<Map<String, dynamic>> changePassword(String token, String oldPassword, String newPassword) async {
    try {
      print('🔍 DEBUG: Changing password...');
      print('🔍 DEBUG: Old password length: ${oldPassword.length}');
      print('🔍 DEBUG: New password length: ${newPassword.length}');
      
      // Membuat URL dengan query parameters sesuai spesifikasi
      final endpoint = 'Users/ChangePassword?OldPassword=${Uri.encodeComponent(oldPassword)}&NewPassword=${Uri.encodeComponent(newPassword)}';
      print('🔍 DEBUG: Change password endpoint: $endpoint');
      
      final response = await post(endpoint, {}, token: token);
      
      print('🔍 DEBUG: Change password full response: $response');
      print('🔍 DEBUG: Response success field: ${response['success']}');
      print('🔍 DEBUG: Response message field: ${response['message']}');
      print('🔍 DEBUG: Response data field: ${response['data']}');
      
      // Periksa apakah response berhasil
      if (response['success'] == true) {
        // Periksa data response untuk menentukan apakah operasi benar-benar berhasil
        if (response['data'] != null && response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          print('🔍 DEBUG: Response data content: $data');
          
          // Periksa field 'ok' untuk menentukan status sebenarnya
          if (data.containsKey('ok')) {
            final isOk = data['ok'];
            if (isOk == true) {
              print('✅ DEBUG: Password change successful - API returned ok: true');
              return {
                'success': true,
                'message': data['message'] ?? 'Password berhasil diubah',
                'data': data,
              };
            } else {
              print('❌ DEBUG: Password change failed - API returned ok: false');
              return {
                'success': false,
                'message': data['message'] ?? 'Gagal mengubah password',
                'data': data,
              };
            }
          }
          
          // Jika tidak ada field 'ok', periksa apakah ada field 'error' yang menunjukkan error
          if (data.containsKey('error') && data['error'] != null && data['error'].toString().isNotEmpty) {
            final errorMessage = data['error'];
            print('🚨 DEBUG: Found error in response data: $errorMessage');
            return {
              'success': false,
              'message': errorMessage.toString(),
              'data': data,
            };
          }
        }
        
        print('✅ DEBUG: Password change successful - default success handling');
        return response;
      } else {
        print('❌ DEBUG: Password change failed with message: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('🚨 DEBUG: Error changing password: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat mengubah password: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String name,
    required String idNumber,
    required String userEmail,
    required String phoneNumber,
    required String password,
    String address = "",
  }) async {
    try {
      print('🔄 DEBUG: Starting user registration');
      print('📧 DEBUG: Email: $userEmail');
      print('📱 DEBUG: Phone: $phoneNumber');
      print('👤 DEBUG: Name: $name');
      
      final body = {
        "name": name,
        "idNumber": idNumber,
        "userEmail": userEmail,
        "phoneNumber": phoneNumber,
        "password": password,
        "address": address,
      };
      
      print('📤 DEBUG: Register request body: $body');
      
      final response = await post('Users/Register', body);
      
      print('📥 DEBUG: Register response: $response');
      
      if (response['success'] == true) {
        print('✅ DEBUG: Registration successful');
        return response;
      } else {
        print('❌ DEBUG: Registration failed with message: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('🚨 DEBUG: Error during registration: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat mendaftar: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Register verification - send OTP
  Future<Map<String, dynamic>> registerVerification({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      print('🔄 DEBUG: Starting register verification');
      print('📧 DEBUG: Email: $email');
      print('📱 DEBUG: Phone: $phoneNumber');
      print('👤 DEBUG: Name: $name');
      
      final queryParams = {
        'Name': name,
        'Email': email,
        'PhoneNumber': phoneNumber,
      };
      
      print('📤 DEBUG: Register verification query params: $queryParams');
      
      final response = await post(
        'Users/RegisterVerification',
        {}, // Empty body since we're using query parameters
        queryParams: queryParams,
      );
      
      print('📥 DEBUG: Register verification response: $response');
      
      if (response['success'] == true) {
        print('✅ DEBUG: Register verification successful - OTP sent');
        return response;
      } else {
        print('❌ DEBUG: Register verification failed with message: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('🚨 DEBUG: Error during register verification: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat mengirim kode verifikasi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // OTP verification
  Future<Map<String, dynamic>> otpVerification({
    required String otp,
    required String email,
  }) async {
    try {
      print('🔄 DEBUG: Starting OTP verification');
      print('📧 DEBUG: Email: $email');
      print('🔢 DEBUG: OTP: $otp');
      
      final queryParams = {
        'OTP': otp,
        'Email': email,
      };
      
      print('📤 DEBUG: OTP verification query params: $queryParams');
      
      final response = await post(
        'Users/OTPVerification',
        {}, // Empty body since we're using query parameters
        queryParams: queryParams,
      );
      
      print('📥 DEBUG: OTP verification response: $response');
      
      if (response['success'] == true) {
        print('✅ DEBUG: OTP verification successful');
        return response;
      } else {
        print('❌ DEBUG: OTP verification failed with message: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('🚨 DEBUG: Error during OTP verification: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat verifikasi OTP: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Get Delivery Detail API
  Future<DeliveryDetailResponse?> getDeliveryDetail(String deliveryCode) async {
    try {
      print('🔍 DEBUG: Getting delivery detail for code: $deliveryCode');
      
      final queryParams = {
        'DeliveryCode': deliveryCode,
      };
      
      print('📤 DEBUG: Delivery detail query params: $queryParams');
      
      final response = await get(
        'Users/Track',
        queryParams: queryParams,
      );
      
      print('📥 DEBUG: Delivery detail response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        // Check if data is empty array
        if (response['data'] is List && (response['data'] as List).isEmpty) {
          print('❌ DEBUG: Delivery detail returned empty data - invalid delivery code');
          return DeliveryDetailResponse(
            ok: false,
            message: 'Kode Delivery tidak valid',
            data: null,
          );
        }
        
        print('✅ DEBUG: Delivery detail retrieved successfully');
        
        // The API response has nested structure: response['data']['data']
        final actualData = response['data']['data'];
        if (actualData != null) {
          // Additional validation: check if essential fields are null or empty
          final status = actualData['status'];
          final sender = actualData['sender'];
          final receiver = actualData['recevier']; // Note: API uses 'recevier' (typo)
          final detailStatus = actualData['detailStatus'];
          
          // Check if all essential data is null or empty
          bool isDataEmpty = (status == null) && 
                           (sender == null) && 
                           (receiver == null || (receiver is List && receiver.isEmpty)) &&
                           (detailStatus == null || (detailStatus is List && detailStatus.isEmpty));
          
          if (isDataEmpty) {
            print('❌ DEBUG: Delivery detail has null/empty essential data - invalid delivery code');
            return DeliveryDetailResponse(
              ok: false,
              message: 'Kode Pengiriman tidak valid atau tidak ada',
              data: null,
            );
          }
          
          final deliveryResponse = DeliveryDetailResponse(
            ok: true,
            message: 'Data berhasil diambil',
            data: DeliveryDetailData.fromJson(actualData),
          );
          
          return deliveryResponse;
        } else {
          return DeliveryDetailResponse(
            ok: false,
            message: 'Data tidak ditemukan',
            data: null,
          );
        }
      } else {
        print('❌ DEBUG: Delivery detail failed with message: ${response['message']}');
        return DeliveryDetailResponse(
          ok: false,
          message: response['message'] ?? 'Kode Delivery tidak valid',
          data: null,
        );
      }
    } catch (e) {
      print('🚨 DEBUG: Error getting delivery detail: $e');
      return DeliveryDetailResponse(
        ok: false,
        message: e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan saat mengambil detail pengiriman: ${e.toString()}',
        data: null,
      );
    }
  }

  // Login By Code API
  Future<LoginCodeResponse> loginByCode(String code) async {
    try {
      final url = Uri.parse('http://10.10.0.223/LocalTrackingDelivery/api/Users/LoginByCode?Code=$code');
      
      print('🔍 DEBUG: LoginByCode URL: $url');
      print('🔍 DEBUG: LoginByCode Code: $code');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: LoginByCode Response status: ${response.statusCode}');
      print('🔍 DEBUG: LoginByCode Response body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: LoginByCode returned empty response!');
        return LoginCodeResponse(
          ok: false,
          message: 'Server mengembalikan response kosong',
        );
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: LoginByCode parsed JSON: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: LoginByCode JSON parsing failed: $jsonError');
        return LoginCodeResponse(
          ok: false,
          message: 'Server mengembalikan response yang tidak valid',
        );
      }

      return LoginCodeResponse.fromJson(responseData);
    } catch (e) {
      print('🚨 DEBUG: LoginByCode error: $e');
      return LoginCodeResponse(
        ok: false,
        message: e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
      );
    }
  }

  // Get Transaction Detail API
  Future<DeliveryTransactionDetailResponse> getTransactionDetail(String deliveryCode, String token) async {
    try {
      final url = Uri.parse('http://10.10.0.223/LocalTrackingDelivery/api/Transaction/Trx/Detail?DeliveryCode=$deliveryCode');
      
      print('🔍 DEBUG: TransactionDetail URL: $url');
      print('🔍 DEBUG: TransactionDetail DeliveryCode: $deliveryCode');
      print('🔍 DEBUG: TransactionDetail Token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: TransactionDetail Response status: ${response.statusCode}');
      print('🔍 DEBUG: TransactionDetail Response body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: TransactionDetail returned empty response!');
        return DeliveryTransactionDetailResponse(
          ok: false,
          message: 'Server mengembalikan response kosong',
          data: null,
        );
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: TransactionDetail parsed JSON: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: TransactionDetail JSON parsing failed: $jsonError');
        return DeliveryTransactionDetailResponse(
          ok: false,
          message: 'Server mengembalikan response yang tidak valid',
          data: null,
        );
      }

      return DeliveryTransactionDetailResponse.fromJson(responseData);
    } catch (e) {
      print('🚨 DEBUG: TransactionDetail error: $e');
      return DeliveryTransactionDetailResponse(
        ok: false,
        message: e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get Delivery Status Detail API
  Future<DeliveryStatusDetailResponse?> getDeliveryStatusDetail(String deliveryCode, String token) async {
    try {
      print('🔍 DEBUG: Getting delivery status detail for code: $deliveryCode');
      print('🔍 DEBUG: Using token: ${token.substring(0, 20)}...');
      
      final queryParams = {
        'DeliveryCode': deliveryCode,
      };
      
      print('📤 DEBUG: Delivery status detail query params: $queryParams');
      
      final url = Uri.parse('${Config.baseUrl}Transaction/Trx/DetailStatus').replace(queryParameters: queryParams);
      
      print('🔍 DEBUG: Delivery status detail URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Delivery status detail Response status: ${response.statusCode}');
      print('🔍 DEBUG: Delivery status detail Response body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        print('🚨 DEBUG: Delivery status detail returned empty response!');
        return DeliveryStatusDetailResponse(
          ok: false,
          message: 'Server mengembalikan response kosong',
          data: [],
        );
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Delivery status detail parsed JSON: $responseData');
      } catch (jsonError) {
        print('🚨 DEBUG: Delivery status detail JSON parsing failed: $jsonError');
        return DeliveryStatusDetailResponse(
          ok: false,
          message: 'Server mengembalikan response yang tidak valid',
          data: [],
        );
      }

      return DeliveryStatusDetailResponse.fromJson(responseData);
    } catch (e) {
      print('🚨 DEBUG: Delivery status detail error: $e');
      return DeliveryStatusDetailResponse(
        ok: false,
        message: e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Terjadi kesalahan koneksi: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get Notifications/Inbox API
  Future<NotificationResponse?> getNotifications(String token) async {
    try {
      print('🔍 DEBUG: Getting notifications');
      print('🔍 DEBUG: Using token: ${token.substring(0, 20)}...');
      
      final url = Uri.parse('${Config.baseUrl}Users/Inbox');
      print('🔍 DEBUG: Notification URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Notification response status: ${response.statusCode}');
      print('🔍 DEBUG: Notification response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return NotificationResponse.fromJson(responseData);
      } else {
        print('❌ DEBUG: Failed to get notifications - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Error getting notifications: $e');
      return null;
    }
  }

  // Mark Notification as Read API
  Future<bool> markNotificationAsRead(String seqNo, String token) async {
    try {
      print('🔍 DEBUG: Marking notification as read');
      print('🔍 DEBUG: SeqNo: $seqNo');
      print('🔍 DEBUG: Using token: ${token.substring(0, 20)}...');
      
      final url = Uri.parse('${Config.baseUrl}Users/Inbox/Read?SeqNo=$seqNo');
      print('🔍 DEBUG: Mark as read URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Mark as read response status: ${response.statusCode}');
      print('🔍 DEBUG: Mark as read response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['ok'] == true || responseData['success'] == true;
      } else {
        print('❌ DEBUG: Failed to mark notification as read - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ DEBUG: Error marking notification as read: $e');
      return false;
    }
  }

  // Delete Notification API
  Future<bool> deleteNotification(String seqNo, String token) async {
    try {
      print('🔍 DEBUG: Deleting notification');
      print('🔍 DEBUG: SeqNo: $seqNo');
      print('🔍 DEBUG: Using token: ${token.substring(0, 20)}...');
      
      final url = Uri.parse('${Config.baseUrl}Users/Inbox?SeqNo=$seqNo');
      print('🔍 DEBUG: Delete notification URL: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Delete notification response status: ${response.statusCode}');
      print('🔍 DEBUG: Delete notification response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['ok'] == true || responseData['success'] == true;
      } else {
        print('❌ DEBUG: Failed to delete notification - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ DEBUG: Error deleting notification: $e');
      return false;
    }
  }

  // Delete Multiple Notifications API
  Future<bool> deleteMultipleNotifications(List<String> seqNos, String token) async {
    try {
      print('🔍 DEBUG: Deleting multiple notifications');
      print('🔍 DEBUG: SeqNos: $seqNos');
      
      bool allSuccess = true;
      
      for (String seqNo in seqNos) {
        final success = await deleteNotification(seqNo, token);
        if (!success) {
          allSuccess = false;
          print('❌ DEBUG: Failed to delete notification with SeqNo: $seqNo');
        }
      }
      
      return allSuccess;
    } catch (e) {
      print('❌ DEBUG: Error deleting multiple notifications: $e');
      return false;
    }
  }

  // Get Profile Image API
  Future<Map<String, dynamic>> getProfileImage(String token) async {
    try {
      print('🔍 DEBUG: Getting profile image');
      print('🔍 DEBUG: Using token: ${token.substring(0, 20)}...');
      
      final url = Uri.parse('${Config.baseUrl}Users/ProfileImage');
      print('🔍 DEBUG: Get profile image URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'image/*',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 DEBUG: Get profile image response status: ${response.statusCode}');
      print('🔍 DEBUG: Get profile image response content-type: ${response.headers['content-type']}');
      print('🔍 DEBUG: Get profile image response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        // Check if response has image data
        if (response.bodyBytes.isNotEmpty) {
          return {
            'success': true,
            'data': {
              'imageBytes': response.bodyBytes,
              'contentType': response.headers['content-type'] ?? 'image/jpeg',
            },
          };
        } else {
          return {
            'success': false,
            'message': 'No profile image found',
          };
        }
      } else {
        print('❌ DEBUG: Failed to get profile image - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to get profile image',
        };
      }
    } catch (e) {
      print('❌ DEBUG: Error getting profile image: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Error getting profile image: $e',
      };
    }
  }

  // Change Profile Image API
  Future<Map<String, dynamic>> changeProfileImage(String base64, String filename, String token) async {
    try {
      print('DEBUG API: Sending request to ${Config.baseUrl}Users/ChangeProfilePicture');
      print('DEBUG API: Filename: $filename');
      print('DEBUG API: Base64 length: ${base64.length}');
      
      final url = Uri.parse('${Config.baseUrl}Users/ChangeProfilePicture');
      print('🔍 DEBUG: Change profile image URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Base64': base64,
          'Filename': filename,
        }),
      ).timeout(const Duration(seconds: 20));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('DEBUG API: Exception occurred: $e');
      return {
        'success': false,
        'message': e is TimeoutException
            ? 'Koneksi Timeout, harap hubungi tim IT'
            : 'Network error: $e',
      };
    }
  }
}