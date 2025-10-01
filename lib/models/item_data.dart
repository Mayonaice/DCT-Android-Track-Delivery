import 'dart:io';

class ItemData {
  final String namaBarang;
  final String jumlahBarang;
  final String serialNumber;
  final String deskripsiBarang;
  final File? selectedImage;

  ItemData({
    required this.namaBarang,
    required this.jumlahBarang,
    required this.serialNumber,
    required this.deskripsiBarang,
    this.selectedImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'namaBarang': namaBarang,
      'jumlahBarang': jumlahBarang,
      'serialNumber': serialNumber,
      'deskripsiBarang': deskripsiBarang,
      'imagePath': selectedImage?.path,
    };
  }

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      namaBarang: json['namaBarang'] ?? '',
      jumlahBarang: json['jumlahBarang'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      deskripsiBarang: json['deskripsiBarang'] ?? '',
      selectedImage: json['imagePath'] != null ? File(json['imagePath']) : null,
    );
  }
}