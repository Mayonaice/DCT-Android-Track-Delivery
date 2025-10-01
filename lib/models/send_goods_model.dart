class SendGoodsRequest {
  final List<ItemModel>? items;
  final List<ConsigneeModel>? consignees;
  final List<ViewerModel>? viewers;

  SendGoodsRequest({
    this.items,
    this.consignees,
    this.viewers,
  });

  Map<String, dynamic> toJson() {
    return {
      'Items': items?.map((item) => item.toJson()).toList(),
      'Consignees': consignees?.map((consignee) => consignee.toJson()).toList(),
      'Viewers': viewers?.map((viewer) => viewer.toJson()).toList(),
    };
  }
}

class ItemModel {
  final String itemName;
  final int qty;
  final String serialNumber;
  final String itemDescription;
  final List<PhotoModel> photo;
  final String userInput;
  final String timeInput;

  ItemModel({
    required this.itemName,
    required this.qty,
    required this.serialNumber,
    required this.itemDescription,
    required this.photo,
    required this.userInput,
    required this.timeInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'ItemName': itemName,
      'Qty': qty,
      'SerialNumber': serialNumber,
      'ItemDescription': itemDescription,
      'Photo': photo.map((p) => p.toJson()).toList(),
      'UserInput': userInput,
      'TimeInput': timeInput,
    };
  }
}

class ConsigneeModel {
  final String name;
  final String phoneNumber;
  final String userInput;
  final String timeInput;

  ConsigneeModel({
    required this.name,
    required this.phoneNumber,
    required this.userInput,
    required this.timeInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'PhoneNumber': phoneNumber,
      'UserInput': userInput,
      'TimeInput': timeInput,
    };
  }
}

class ViewerModel {
  final String name;
  final String phoneNumber;
  final String userInput;
  final String timeInput;

  ViewerModel({
    required this.name,
    required this.phoneNumber,
    required this.userInput,
    required this.timeInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'PhoneNumber': phoneNumber,
      'UserInput': userInput,
      'TimeInput': timeInput,
    };
  }
}

class PhotoModel {
  final String? photo64;
  final String? filename;
  final String? description;

  PhotoModel({
    this.photo64,
    this.filename,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'Photo64': photo64,
      'Filename': filename,
      'Description': description,
    };
  }
}

// Response model untuk API add transaction
class AddTransactionResponse {
  final bool ok;
  final String? message;

  AddTransactionResponse({
    required this.ok,
    this.message,
  });

  factory AddTransactionResponse.fromJson(Map<String, dynamic> json) {
    return AddTransactionResponse(
      ok: json['ok'] ?? false,
      message: json['message'],
    );
  }
}