import 'dart:io';

class ItemData {
  final String namaBarang;
  final String jumlahBarang;
  final String serialNumber;
  final String deskripsiBarang;
  final File? selectedImage; // Keep for backward compatibility
  final List<File> selectedImages; // New field for multiple photos
  final String itemId; // Unique identifier for cache management

  ItemData({
    required this.namaBarang,
    required this.jumlahBarang,
    required this.serialNumber,
    required this.deskripsiBarang,
    this.selectedImage,
    List<File>? selectedImages,
    String? itemId,
  }) : selectedImages = selectedImages ?? (selectedImage != null ? [selectedImage] : []),
       itemId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'namaBarang': namaBarang,
      'jumlahBarang': jumlahBarang,
      'serialNumber': serialNumber,
      'deskripsiBarang': deskripsiBarang,
      'imagePath': selectedImage?.path, // Keep for backward compatibility
      'imagesPaths': selectedImages.map((file) => file.path).toList(),
      'itemId': itemId,
    };
  }

  factory ItemData.fromJson(Map<String, dynamic> json) {
    List<File> images = [];
    
    // Handle new multiple images format
    if (json['imagesPaths'] != null) {
      final imagesPaths = List<String>.from(json['imagesPaths']);
      images = imagesPaths.map((path) => File(path)).toList();
    }
    // Handle legacy single image format
    else if (json['imagePath'] != null) {
      images = [File(json['imagePath'])];
    }
    
    return ItemData(
      namaBarang: json['namaBarang'] ?? '',
      jumlahBarang: json['jumlahBarang'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      deskripsiBarang: json['deskripsiBarang'] ?? '',
      selectedImage: images.isNotEmpty ? images.first : null, // For backward compatibility
      selectedImages: images,
      itemId: json['itemId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // Helper method to get the primary image for display
  File? get primaryImage => selectedImages.isNotEmpty ? selectedImages.first : null;
  
  // Helper method to check if item has photos
  bool get hasPhotos => selectedImages.isNotEmpty;
  
  // Helper method to get photo count
  int get photoCount => selectedImages.length;
}