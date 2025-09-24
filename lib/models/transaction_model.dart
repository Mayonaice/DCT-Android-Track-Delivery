class TransactionResponse {
  final bool ok;
  final String message;
  final List<TransactionData> data;

  TransactionResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => TransactionData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class TransactionData {
  final int seqNo;
  final int status;
  final String statusName;
  final String consigneeName;
  final String transactionCode;
  final DateTime transactionDate;

  TransactionData({
    required this.seqNo,
    required this.status,
    required this.statusName,
    required this.consigneeName,
    required this.transactionCode,
    required this.transactionDate,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      seqNo: json['seqNo'] ?? 0,
      status: json['status'] ?? 0,
      statusName: json['statusName'] ?? '',
      consigneeName: json['consigneeName'] ?? '',
      transactionCode: json['transactionCode'] ?? '',
      transactionDate: DateTime.tryParse(json['transactionDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seqNo': seqNo,
      'status': status,
      'statusName': statusName,
      'consigneeName': consigneeName,
      'transactionCode': transactionCode,
      'transactionDate': transactionDate.toIso8601String(),
    };
  }
}

// Request model untuk Transaction API
class TransactionRequest {
  final String userEmail;
  final int pageSize;
  final String? status;
  final String? tanggalFrom;
  final String? tanggalEnd;

  TransactionRequest({
    required this.userEmail,
    this.pageSize = 10,
    this.status,
    this.tanggalFrom,
    this.tanggalEnd,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userEmail': userEmail,
      'pageSize': pageSize,
    };

    // Hanya tambahkan field jika ada nilainya (sesuai requirement)
    if (status != null && status!.isNotEmpty) {
      data['status'] = status;
    }

    if (tanggalFrom != null && tanggalFrom!.isNotEmpty) {
      data['tanggalFrom'] = tanggalFrom;
    }

    if (tanggalEnd != null && tanggalEnd!.isNotEmpty) {
      data['tanggalEnd'] = tanggalEnd;
    }

    return data;
  }
}