import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/transaction_model.dart';

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
      );

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
        'message': 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Generic GET request with token
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final url = Uri.parse('${Config.baseUrl}$endpoint');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

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
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Generic POST request with token
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final url = Uri.parse('${Config.baseUrl}$endpoint');
      
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

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

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
        return {
          'success': true,
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
        'message': 'Terjadi kesalahan koneksi: ${e.toString()}',
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
        'message': 'Terjadi kesalahan saat mengambil data profil: ${e.toString()}',
        'data': null,
      };
    }
  }
}