class DeliveryDetailResponse {
  final bool ok;
  final String message;
  final DeliveryDetailData? data;

  DeliveryDetailResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  factory DeliveryDetailResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? DeliveryDetailData.fromJson(json['data']) : null,
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

class DeliveryDetailData {
  final DeliveryStatusInfo? status;
  final DeliverySender? sender;
  final List<DeliveryReceiver> recevier;
  final List<DeliveryDetailStatus> detailStatus;

  DeliveryDetailData({
    this.status,
    this.sender,
    required this.recevier,
    required this.detailStatus,
  });

  factory DeliveryDetailData.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailData(
      status: json['status'] != null 
          ? DeliveryStatusInfo.fromJson(json['status'])
          : null,
      sender: json['sender'] != null 
          ? DeliverySender.fromJson(json['sender'])
          : null,
      recevier: (json['recevier'] as List<dynamic>?)
          ?.map((r) => DeliveryReceiver.fromJson(r))
          .toList() ?? [],
      detailStatus: (json['detailStatus'] as List<dynamic>?)
          ?.map((d) => DeliveryDetailStatus.fromJson(d))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status?.toJson(),
      'sender': sender?.toJson(),
      'recevier': recevier.map((r) => r.toJson()).toList(),
      'detailStatus': detailStatus.map((d) => d.toJson()).toList(),
    };
  }
}

class DeliveryStatusInfo {
  final String? status;
  final String? deliveryNo;

  DeliveryStatusInfo({
    this.status,
    this.deliveryNo,
  });

  factory DeliveryStatusInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusInfo(
      status: json['status']?.toString(),
      deliveryNo: json['deliveryNo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'deliveryNo': deliveryNo,
    };
  }

  String getStatusText() {
    switch (status) {
      case '1':
        return 'Baru';
      case '2':
        return 'Disubmit';
      case '3':
        return 'Diterima Perantara';
      case '4':
        return 'Diterima Target';
      case '5':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Diketahui';
    }
  }
}

class DeliverySender {
  final String? name;
  final DateTime? transactionTime;

  DeliverySender({
    this.name,
    this.transactionTime,
  });

  factory DeliverySender.fromJson(Map<String, dynamic> json) {
    return DeliverySender(
      name: json['name']?.toString(),
      transactionTime: json['transactionTime'] != null 
          ? DateTime.tryParse(json['transactionTime'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'transactionTime': transactionTime?.toIso8601String(),
    };
  }
}

class DeliveryReceiver {
  final String? name;

  DeliveryReceiver({
    this.name,
  });

  factory DeliveryReceiver.fromJson(Map<String, dynamic> json) {
    return DeliveryReceiver(
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

class DeliveryDetailStatus {
  final String? deliveryCode;
  final String? nameTime;
  final String? description;
  final List<String> photo;
  final DateTime? timeInput;

  DeliveryDetailStatus({
    this.deliveryCode,
    this.nameTime,
    this.description,
    required this.photo,
    this.timeInput,
  });

  factory DeliveryDetailStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailStatus(
      deliveryCode: json['deliveryCode']?.toString(),
      nameTime: json['nameTime']?.toString(),
      description: json['description']?.toString(),
      photo: (json['photo'] as List<dynamic>?)
          ?.map((p) => p.toString())
          .toList() ?? [],
      timeInput: json['timeInput'] != null 
          ? DateTime.tryParse(json['timeInput'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryCode': deliveryCode,
      'nameTime': nameTime,
      'description': description,
      'photo': photo,
      'timeInput': timeInput?.toIso8601String(),
    };
  }

  bool get hasPhoto => photo.isNotEmpty;
}

class DeliveryItem {
  final int? seqNo;
  final String? itemName;
  final String? itemDescription;
  final int? quantity;
  final String? unit;
  final String? notes;
  final List<DeliveryPhoto> photos;

  DeliveryItem({
    this.seqNo,
    this.itemName,
    this.itemDescription,
    this.quantity,
    this.unit,
    this.notes,
    required this.photos,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      seqNo: json['SeqNo'] is int ? json['SeqNo'] : int.tryParse(json['SeqNo']?.toString() ?? ''),
      itemName: json['ItemName']?.toString(),
      itemDescription: json['ItemDescription']?.toString(),
      quantity: json['Quantity'] is int ? json['Quantity'] : int.tryParse(json['Quantity']?.toString() ?? ''),
      unit: json['Unit']?.toString(),
      notes: json['Notes']?.toString(),
      photos: (json['Photos'] as List<dynamic>?)
          ?.map((photo) => DeliveryPhoto.fromJson(photo))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SeqNo': seqNo,
      'ItemName': itemName,
      'ItemDescription': itemDescription,
      'Quantity': quantity,
      'Unit': unit,
      'Notes': notes,
      'Photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }
}

class DeliveryConsignee {
  final String? consigneeName;
  final String? consigneePhone;
  final String? consigneeAddress;
  final String? relationship;
  final DateTime? receivedDate;
  final String? receivedBy;
  final String? notes;
  final List<DeliveryPhoto> photos;

  DeliveryConsignee({
    this.consigneeName,
    this.consigneePhone,
    this.consigneeAddress,
    this.relationship,
    this.receivedDate,
    this.receivedBy,
    this.notes,
    required this.photos,
  });

  factory DeliveryConsignee.fromJson(Map<String, dynamic> json) {
    return DeliveryConsignee(
      consigneeName: json['ConsigneeName']?.toString(),
      consigneePhone: json['ConsigneePhone']?.toString(),
      consigneeAddress: json['ConsigneeAddress']?.toString(),
      relationship: json['Relationship']?.toString(),
      receivedDate: json['ReceivedDate'] != null 
          ? DateTime.tryParse(json['ReceivedDate'].toString())
          : null,
      receivedBy: json['ReceivedBy']?.toString(),
      notes: json['Notes']?.toString(),
      photos: (json['Photos'] as List<dynamic>?)
          ?.map((photo) => DeliveryPhoto.fromJson(photo))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ConsigneeName': consigneeName,
      'ConsigneePhone': consigneePhone,
      'ConsigneeAddress': consigneeAddress,
      'Relationship': relationship,
      'ReceivedDate': receivedDate?.toIso8601String(),
      'ReceivedBy': receivedBy,
      'Notes': notes,
      'Photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }
}

class DeliveryViewer {
  final String? viewerName;
  final String? viewerPhone;
  final String? viewerAddress;
  final DateTime? viewedDate;
  final String? notes;

  DeliveryViewer({
    this.viewerName,
    this.viewerPhone,
    this.viewerAddress,
    this.viewedDate,
    this.notes,
  });

  factory DeliveryViewer.fromJson(Map<String, dynamic> json) {
    return DeliveryViewer(
      viewerName: json['ViewerName']?.toString(),
      viewerPhone: json['ViewerPhone']?.toString(),
      viewerAddress: json['ViewerAddress']?.toString(),
      viewedDate: json['ViewedDate'] != null 
          ? DateTime.tryParse(json['ViewedDate'].toString())
          : null,
      notes: json['Notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ViewerName': viewerName,
      'ViewerPhone': viewerPhone,
      'ViewerAddress': viewerAddress,
      'ViewedDate': viewedDate?.toIso8601String(),
      'Notes': notes,
    };
  }
}

class DeliveryPhoto {
  final String? filename;
  final String? base64Data;
  final DateTime? uploadDate;

  DeliveryPhoto({
    this.filename,
    this.base64Data,
    this.uploadDate,
  });

  factory DeliveryPhoto.fromJson(Map<String, dynamic> json) {
    return DeliveryPhoto(
      filename: json['Filename']?.toString(),
      base64Data: json['Base64Data']?.toString(),
      uploadDate: json['UploadDate'] != null 
          ? DateTime.tryParse(json['UploadDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Filename': filename,
      'Base64Data': base64Data,
      'UploadDate': uploadDate?.toIso8601String(),
    };
  }
}

class DeliveryStatusTrack {
  final String status;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final bool hasPhoto;

  DeliveryStatusTrack({
    required this.status,
    required this.description,
    required this.timestamp,
    this.isCompleted = false,
    this.hasPhoto = false,
  });

  factory DeliveryStatusTrack.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusTrack(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      hasPhoto: json['hasPhoto'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
      'hasPhoto': hasPhoto,
    };
  }
}