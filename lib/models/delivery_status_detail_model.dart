class DeliveryStatusDetailResponse {
  final bool ok;
  final String message;
  final List<DeliveryStatusDetailData> data;

  DeliveryStatusDetailResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory DeliveryStatusDetailResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusDetailResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => DeliveryStatusDetailData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class DeliveryStatusDetailData {
  final String deliveryCode;
  final String nameTime;
  final String description;
  final List<StatusPhoto> photo;
  final String timeInput;

  DeliveryStatusDetailData({
    required this.deliveryCode,
    required this.nameTime,
    required this.description,
    required this.photo,
    required this.timeInput,
  });

  factory DeliveryStatusDetailData.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusDetailData(
      deliveryCode: json['deliveryCode'] ?? '',
      nameTime: json['nameTime'] ?? '',
      description: json['description'] ?? '',
      photo: (json['photo'] as List<dynamic>?)
          ?.map((item) => StatusPhoto.fromJson(item))
          .toList() ?? [],
      timeInput: json['timeInput'] ?? '',
    );
  }

  // Helper method untuk menentukan status berdasarkan description
  int getStatusLevel() {
    final desc = description.toLowerCase();
    
    // Icon 4: Pengiriman dikonfirmasi penerima
    if (desc.contains('pengiriman dikonfirmasi oleh target')) {
      return 4; // Semua icon aktif (1-4)
    } 
    // Icon 3: Pengiriman diterima target
    else if (desc.contains('pengiriman diterima oleh target')) {
      return 3; // Icon 1-3 aktif
    } 
    // Icon 2: Pengiriman diterima perantara
    else if (desc.contains('pengiriman diterima oleh perantara')) {
      return 2; // Icon 1-2 aktif
    } 
    // Icon 1: Pengiriman dibuat atau disubmit
    else if (desc.contains('pengiriman dibuat') || desc.contains('pengiriman disubmit')) {
      return 1; // Hanya icon 1 aktif
    } 
    else {
      return 1; // Default hanya icon 1 aktif
    }
  }

  // Helper method untuk extract waktu dari nameTime dan tambah WIB
  String getFormattedTime() {
    try {
      // Extract waktu dari nameTime (format: "Selasa, 14 Oktober 2025 15.17")
      final parts = nameTime.split(' ');
      if (parts.length >= 4) {
        final timePart = parts.last; // "15.17"
        final timeFormatted = timePart.replaceAll('.', ':'); // "15:17"
        return '$timeFormatted WIB';
      }
      return 'WIB';
    } catch (e) {
      return 'WIB';
    }
  }
}

class StatusPhoto {
  final String photo64;
  final String filename;
  final String? description;

  StatusPhoto({
    required this.photo64,
    required this.filename,
    this.description,
  });

  factory StatusPhoto.fromJson(Map<String, dynamic> json) {
    return StatusPhoto(
      photo64: json['photo64'] ?? '',
      filename: json['filename'] ?? '',
      description: json['description'],
    );
  }
}