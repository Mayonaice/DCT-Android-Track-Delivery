class NotificationResponse {
  final bool ok;
  final String message;
  final List<NotificationData> data;

  NotificationResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => NotificationData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class NotificationData {
  final String seqNo;
  final String seqNoDelivery;
  final String title;
  final String description;
  final String timeInput;
  final String timeRead;

  NotificationData({
    required this.seqNo,
    required this.seqNoDelivery,
    required this.title,
    required this.description,
    required this.timeInput,
    required this.timeRead,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      seqNo: json['seqNo']?.toString() ?? '',
      seqNoDelivery: json['seqNoDelivery']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeInput: json['timeInput'] ?? '',
      timeRead: json['timeRead'] ?? '',
    );
  }

  // Helper method to check if notification is read
  bool get isRead {
    return timeRead != "0001-01-01T00:00:00" && timeRead.isNotEmpty;
  }

  // Helper method to get formatted time
  String get formattedTime {
    try {
      final dateTime = DateTime.parse(timeInput);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return timeInput;
    }
  }

  // Helper method to get icon based on description (same logic as delivery_status_detail_model.dart)
  int getStatusLevel() {
    final desc = description.toLowerCase();
    
    // Icon 3: Pengiriman dikonfirmasi penerima
    if (desc.contains('pengiriman dikonfirmasi oleh penerima') || 
        desc.contains('pengiriman kamu telah dikonfirmasi oleh penerima')) {
      return 3; // Icon dikonfirmasi
    } 
    // Icon 2: Pengiriman diterima target
    else if (desc.contains('pengiriman diterima oleh target') ||
             desc.contains('pengiriman kamu telah diterima oleh penerima')) {
      return 2; // Icon diterima
    } 
    // Icon 1: Pengiriman diterima perantara
    else if (desc.contains('pengiriman diterima oleh perantara')) {
      return 1; // Icon perantara
    } 
    // Default: Pengiriman dibuat atau disubmit
    else {
      return 0; // Icon submitted
    }
  }

  // Helper method to get icon asset path
  String getIconAsset() {
    switch (getStatusLevel()) {
      case 0:
        return 'assets/images/icon-status2(submitted).png';
      case 1:
        return 'assets/images/icon-status3(diterimaperantara).png';
      case 2:
        return 'assets/images/icon-status5(diterima).png';
      case 3:
        return 'assets/images/icon-status4(dikonfirmasi).png';
      default:
        return 'assets/images/icon-status2(submitted).png';
    }
  }
}