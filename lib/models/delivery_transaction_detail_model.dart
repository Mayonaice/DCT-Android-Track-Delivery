// Model untuk Transaction Detail API Response
class DeliveryTransactionDetailResponse {
  final bool ok;
  final String message;
  final DeliveryTransactionDetailData? data;

  DeliveryTransactionDetailResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory DeliveryTransactionDetailResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryTransactionDetailResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? DeliveryTransactionDetailData.fromJson(json['data'])
          : null,
    );
  }
}

class DeliveryTransactionDetailData {
  final DeliveryStatus status;
  final List<DeliveryItem> items;
  final List<DeliveryConsignee> consignees;
  final List<DeliveryViewer> viewers;

  DeliveryTransactionDetailData({
    required this.status,
    required this.items,
    required this.consignees,
    required this.viewers,
  });

  factory DeliveryTransactionDetailData.fromJson(Map<String, dynamic> json) {
    return DeliveryTransactionDetailData(
      status: DeliveryStatus.fromJson(json['status'] ?? {}),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => DeliveryItem.fromJson(item))
          .toList() ?? [],
      consignees: (json['consignees'] as List<dynamic>?)
          ?.map((item) => DeliveryConsignee.fromJson(item))
          .toList() ?? [],
      viewers: (json['viewers'] as List<dynamic>?)
          ?.map((item) => DeliveryViewer.fromJson(item))
          .toList() ?? [],
    );
  }
}

class DeliveryStatus {
  final String status;
  final String transactionTime;

  DeliveryStatus({
    required this.status,
    required this.transactionTime,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      status: json['status'] ?? '',
      transactionTime: json['transactionTime'] ?? '',
    );
  }
}

class DeliveryItem {
  final String itemName;
  final int qty;
  final String serialNumber;
  final String itemDescription;
  final List<DeliveryPhoto> photo;

  DeliveryItem({
    required this.itemName,
    required this.qty,
    required this.serialNumber,
    required this.itemDescription,
    required this.photo,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      itemName: json['itemName'] ?? '',
      qty: json['qty'] ?? 0,
      serialNumber: json['serialNumber'] ?? '',
      itemDescription: json['itemDescription'] ?? '',
      photo: (json['photo'] as List<dynamic>?)
          ?.map((item) => DeliveryPhoto.fromJson(item))
          .toList() ?? [],
    );
  }
}

class DeliveryPhoto {
  final String photo64;

  DeliveryPhoto({
    required this.photo64,
  });

  factory DeliveryPhoto.fromJson(Map<String, dynamic> json) {
    return DeliveryPhoto(
      photo64: json['photo64'] ?? '',
    );
  }
}

class DeliveryConsignee {
  final String name;
  final String phoneNumber;

  DeliveryConsignee({
    required this.name,
    required this.phoneNumber,
  });

  factory DeliveryConsignee.fromJson(Map<String, dynamic> json) {
    return DeliveryConsignee(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}

class DeliveryViewer {
  final String name;
  final String phoneNumber;

  DeliveryViewer({
    required this.name,
    required this.phoneNumber,
  });

  factory DeliveryViewer.fromJson(Map<String, dynamic> json) {
    return DeliveryViewer(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}