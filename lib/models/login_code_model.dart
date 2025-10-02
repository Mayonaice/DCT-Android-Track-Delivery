// Model untuk Login By Code API Response
class LoginCodeResponse {
  final bool ok;
  final String message;
  final LoginCodeData? data;

  LoginCodeResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory LoginCodeResponse.fromJson(Map<String, dynamic> json) {
    return LoginCodeResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginCodeData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class LoginCodeData {
  final int seqNo;
  final String deliveryCode;
  final String name;
  final String phoneNumber;
  final String status;
  final String token;

  LoginCodeData({
    required this.seqNo,
    required this.deliveryCode,
    required this.name,
    required this.phoneNumber,
    required this.status,
    required this.token,
  });

  factory LoginCodeData.fromJson(Map<String, dynamic> json) {
    return LoginCodeData(
      seqNo: json['seqNo'] ?? 0,
      deliveryCode: json['deliveryCode'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seqNo': seqNo,
      'deliveryCode': deliveryCode,
      'name': name,
      'phoneNumber': phoneNumber,
      'status': status,
      'token': token,
    };
  }
}