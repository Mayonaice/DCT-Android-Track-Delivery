class UserProfileResponse {
  final bool ok;
  final String message;
  final UserProfileData? data;

  UserProfileResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserProfileData.fromJson(json['data']) : null,
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

class UserProfileData {
  final int seqNo;
  final String userEmail;
  final String name;
  final String idNumber;
  final String phoneNumber;
  final String? employeeCode;
  final String? profilePictureFileName;
  final String address;

  UserProfileData({
    required this.seqNo,
    required this.userEmail,
    required this.name,
    required this.idNumber,
    required this.phoneNumber,
    this.employeeCode,
    this.profilePictureFileName,
    required this.address,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      seqNo: json['seqNo'] ?? 0,
      userEmail: json['userEmail'] ?? '',
      name: json['name'] ?? '',
      idNumber: json['idNumber'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      employeeCode: json['employeeCode'],
      profilePictureFileName: json['profilePictureFileName'],
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seqNo': seqNo,
      'userEmail': userEmail,
      'name': name,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'employeeCode': employeeCode,
      'profilePictureFileName': profilePictureFileName,
      'address': address,
    };
  }

  // Helper methods untuk sensor data
  String get maskedPhoneNumber {
    if (phoneNumber.length <= 4) return phoneNumber;
    final visiblePart = phoneNumber.substring(0, phoneNumber.length - 4);
    return '$visiblePart****';
  }

  String get maskedEmail {
    if (userEmail.isEmpty) return userEmail;
    if (userEmail.length <= 1) return userEmail;
    
    final firstChar = userEmail[0];
    final atIndex = userEmail.indexOf('@');
    
    if (atIndex == -1) {
      // Jika tidak ada @, sensor semua kecuali karakter pertama
      return firstChar + '*' * (userEmail.length - 1);
    }
    
    // Sensor bagian sebelum @ kecuali karakter pertama
    final beforeAt = userEmail.substring(0, atIndex);
    final afterAt = userEmail.substring(atIndex);
    
    if (beforeAt.length <= 1) {
      return userEmail; // Jika hanya 1 karakter sebelum @, tidak perlu sensor
    }
    
    return firstChar + '*' * (beforeAt.length - 1) + afterAt;
  }
}