import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:android_tyd/pages/add_items_form_page.dart';
import '../models/item_data.dart';
import '../models/send_goods_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/photo_cache_service.dart';

class AddTrxFormPage extends StatefulWidget {
  final ItemData? itemData;
  
  const AddTrxFormPage({super.key, this.itemData});

  @override
  State<AddTrxFormPage> createState() => _AddTrxFormPageState();
}

class _AddTrxFormPageState extends State<AddTrxFormPage> {
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nohpPenerimaController = TextEditingController();
  final TextEditingController _namaTembusan1Controller = TextEditingController();
  final TextEditingController _nohpTembusan1Controller = TextEditingController();
  
  // List untuk menyimpan penerima tambahan
  List<Map<String, TextEditingController>> _additionalReceivers = [];
  
  // List untuk menyimpan tembusan tambahan
  List<Map<String, TextEditingController>> _additionalTembusan = [];
  
  // Data barang yang ditambahkan - ubah menjadi list untuk multiple items
  List<ItemData> _itemsList = [];
  
  // Services
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final PhotoCacheService _photoCacheService = PhotoCacheService();
  
  // Loading state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Jika ada itemData dari constructor, tambahkan ke list
    if (widget.itemData != null) {
      _itemsList.add(widget.itemData!);
    }
    _loadFromCache();
    
    // Add listeners untuk auto-save
    _namaPenerimaController.addListener(_saveFormDataToCache);
    _nohpPenerimaController.addListener(_saveFormDataToCache);
    _namaTembusan1Controller.addListener(_saveFormDataToCache);
    _nohpTembusan1Controller.addListener(_saveFormDataToCache);
  }

  Future<void> _loadFromCache() async {
    // Load items from cache
    final prefs = await SharedPreferences.getInstance();
    final itemsJsonString = prefs.getString('items_data');
    if (itemsJsonString != null) {
      final itemsJsonList = jsonDecode(itemsJsonString) as List;
      setState(() {
        _itemsList = itemsJsonList.map((json) => ItemData.fromJson(json)).toList();
      });
    }
    
    // Load form data from cache
    await _loadFormDataFromCache();
  }

  // Fungsi untuk menyimpan items ke cache
  Future<void> _saveItemsToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJsonList = _itemsList.map((item) => item.toJson()).toList();
    await prefs.setString('items_data', jsonEncode(itemsJsonList));
  }

  // Fungsi untuk menyimpan data form ke cache
  Future<void> _saveFormDataToCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Prepare form data
    Map<String, dynamic> formData = {
      'namaPenerima': _namaPenerimaController.text,
      'nohpPenerima': _nohpPenerimaController.text,
      'namaTembusan1': _namaTembusan1Controller.text,
      'nohpTembusan1': _nohpTembusan1Controller.text,
      'additionalReceivers': _additionalReceivers.map((receiver) => {
        'nama': receiver['nama']?.text ?? '',
        'nohp': receiver['nohp']?.text ?? '',
      }).toList(),
      'additionalTembusan': _additionalTembusan.map((tembusan) => {
        'nama': tembusan['nama']?.text ?? '',
        'nohp': tembusan['nohp']?.text ?? '',
      }).toList(),
    };
    
    await prefs.setString('form_data', jsonEncode(formData));
  }

  // Fungsi untuk memuat data form dari cache
  Future<void> _loadFormDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final formDataString = prefs.getString('form_data');
    
    if (formDataString != null) {
      final formData = jsonDecode(formDataString);
      
      setState(() {
        _namaPenerimaController.text = formData['namaPenerima'] ?? '';
        _nohpPenerimaController.text = formData['nohpPenerima'] ?? '';
        _namaTembusan1Controller.text = formData['namaTembusan1'] ?? '';
        _nohpTembusan1Controller.text = formData['nohpTembusan1'] ?? '';
        
        // Load additional receivers
        _additionalReceivers.clear();
        if (formData['additionalReceivers'] != null) {
          for (var receiverData in formData['additionalReceivers']) {
            final namaController = TextEditingController(text: receiverData['nama'] ?? '');
            final nohpController = TextEditingController(text: receiverData['nohp'] ?? '');
            _additionalReceivers.add({
              'nama': namaController,
              'nohp': nohpController,
            });
          }
        }
        
        // Load additional tembusan
        _additionalTembusan.clear();
        if (formData['additionalTembusan'] != null) {
          for (var tembusanData in formData['additionalTembusan']) {
            final namaController = TextEditingController(text: tembusanData['nama'] ?? '');
            final nohpController = TextEditingController(text: tembusanData['nohp'] ?? '');
            _additionalTembusan.add({
              'nama': namaController,
              'nohp': nohpController,
            });
          }
        }
      });
    }
  }

  Future<void> _clearItemData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('items_data'); // Update untuk multiple items
    await prefs.remove('form_data'); // Clear form data juga
    setState(() {
      _itemsList.clear(); // Clear list items
    });
  }

  @override
  void dispose() {
    _namaPenerimaController.dispose();
    _nohpPenerimaController.dispose();
    _namaTembusan1Controller.dispose();
    _nohpTembusan1Controller.dispose();
    
    // Dispose additional receivers
    for (var receiver in _additionalReceivers) {
      receiver['nama']?.dispose();
      receiver['nohp']?.dispose();
    }
    
    // Dispose additional tembusan
    for (var tembusan in _additionalTembusan) {
      tembusan['nama']?.dispose();
      tembusan['nohp']?.dispose();
    }
    
    super.dispose();
  }

  void _addReceiver() {
    setState(() {
      _additionalReceivers.add({
        'nama': TextEditingController(),
        'nohp': TextEditingController(),
      });
    });
    // Save form data setelah menambah receiver
    _saveFormDataToCache();
  }

  void _removeReceiver(int index) {
    setState(() {
      _additionalReceivers[index]['nama']?.dispose();
      _additionalReceivers[index]['nohp']?.dispose();
      _additionalReceivers.removeAt(index);
    });
    // Save form data setelah menghapus receiver
    _saveFormDataToCache();
  }

  void _addCopy() {
    setState(() {
      _additionalTembusan.add({
        'nama': TextEditingController(),
        'nohp': TextEditingController(),
      });
    });
    // Save form data setelah menambah tembusan
    _saveFormDataToCache();
  }

  // Fungsi untuk mengkonversi File ke Base64
  Future<String?> _convertImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;
    
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }
  
  // Fungsi untuk submit data ke API
  Future<void> _submitTransaction() async {
    // Validasi data wajib
    if (_itemsList.isEmpty) {
      _showErrorDialog('Silakan tambahkan barang terlebih dahulu');
      return;
    }
    
    if (_namaPenerimaController.text.trim().isEmpty) {
      _showErrorDialog('Nama penerima harus diisi');
      return;
    }
    
    if (_nohpPenerimaController.text.trim().isEmpty) {
      _showErrorDialog('No HP penerima harus diisi');
      return;
    }
    
    if (_namaTembusan1Controller.text.trim().isEmpty) {
      _showErrorDialog('Nama tembusan harus diisi');
      return;
    }
    
    if (_nohpTembusan1Controller.text.trim().isEmpty) {
      _showErrorDialog('No HP tembusan harus diisi');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Get token
      final token = await _storageService.getToken();
      if (token == null) {
        _showErrorDialog('Token tidak ditemukan. Silakan login ulang.');
        return;
      }
      
      // Get user email for userInput
      final userEmail = await _storageService.getUserEmail();
      final currentTime = DateTime.now().toIso8601String();
      
      // Prepare items data - loop through all items
      List<ItemModel> items = [];
      
      for (ItemData itemData in _itemsList) {
        // Convert multiple images to base64
        List<PhotoModel> photos = [];
        
        // Use selectedImages (multiple photos) instead of selectedImage (single photo)
        for (File imageFile in itemData.selectedImages) {
          String? photoBase64 = await _convertImageToBase64(imageFile);
          String originalFilename = imageFile.path.split('/').last;
          
          if (photoBase64 != null) {
            photos.add(PhotoModel(
              photo64: photoBase64,
              filename: originalFilename,
              description: itemData.deskripsiBarang,
            ));
          }
        }
        
        // If no photos, add empty photo to maintain API compatibility
        if (photos.isEmpty) {
          photos.add(PhotoModel(
            photo64: '',
            filename: '',
            description: itemData.deskripsiBarang,
          ));
        }
        
        items.add(ItemModel(
          itemName: itemData.namaBarang,
          qty: int.tryParse(itemData.jumlahBarang) ?? 1,
          serialNumber: itemData.serialNumber,
          itemDescription: itemData.deskripsiBarang,
          photo: photos,
          userInput: userEmail,
          timeInput: currentTime,
        ));
      }
      
      // Prepare consignees data
      List<ConsigneeModel> consignees = [];
      
      // Add main receiver
      print('🔍 DEBUG: Adding main receiver - Name: "${_namaPenerimaController.text.trim()}", Phone: "${_nohpPenerimaController.text.trim()}"');
      consignees.add(ConsigneeModel(
        name: _namaPenerimaController.text.trim(),
        phoneNumber: _nohpPenerimaController.text.trim(),
        userInput: userEmail,
        timeInput: currentTime,
      ));
      
      // Add additional receivers
      for (var receiver in _additionalReceivers) {
        final nama = receiver['nama']?.text.trim() ?? '';
        final nohp = receiver['nohp']?.text.trim() ?? '';
        if (nama.isNotEmpty && nohp.isNotEmpty) {
          print('🔍 DEBUG: Adding additional receiver - Name: "$nama", Phone: "$nohp"');
          consignees.add(ConsigneeModel(
            name: nama,
            phoneNumber: nohp,
            userInput: userEmail,
            timeInput: currentTime,
          ));
        }
      }
      
      print('🔍 DEBUG: Total consignees created: ${consignees.length}');
      
      // Prepare viewers data (tembusan)
      List<ViewerModel> viewers = [];
      
      // Add main tembusan
      print('🔍 DEBUG: Adding main viewer - Name: "${_namaTembusan1Controller.text.trim()}", Phone: "${_nohpTembusan1Controller.text.trim()}"');
      viewers.add(ViewerModel(
        name: _namaTembusan1Controller.text.trim(),
        phoneNumber: _nohpTembusan1Controller.text.trim(),
        userInput: userEmail,
        timeInput: currentTime,
      ));
      
      // Add additional tembusan
      for (var tembusan in _additionalTembusan) {
        final nama = tembusan['nama']?.text.trim() ?? '';
        final nohp = tembusan['nohp']?.text.trim() ?? '';
        if (nama.isNotEmpty && nohp.isNotEmpty) {
          print('🔍 DEBUG: Adding additional viewer - Name: "$nama", Phone: "$nohp"');
          viewers.add(ViewerModel(
            name: nama,
            phoneNumber: nohp,
            userInput: userEmail,
            timeInput: currentTime,
          ));
        }
      }
      
      print('🔍 DEBUG: Total viewers created: ${viewers.length}');
      
      // Create SendGoodsRequest
      print('🔍 DEBUG: Creating SendGoodsRequest with ${items.length} items, ${consignees.length} consignees, ${viewers.length} viewers');
      final sendGoodsRequest = SendGoodsRequest(
        items: items,
        consignees: consignees,
        viewers: viewers,
      );
      
      // Call API
      final response = await _apiService.addTransaction(sendGoodsRequest, token);
      
      if (response['success'] == true) {
        // Success
        _showSuccessDialog('Transaksi berhasil dikirim!');
        
        // Clear photo cache for all items after successful post action
        final photoCacheService = PhotoCacheService();
        for (ItemData itemData in _itemsList) {
          await photoCacheService.clearItemPhotos(itemData.itemId);
          print('🔍 DEBUG: Photo cache cleared for item ${itemData.itemId}');
        }
        
        // Clear form data
        await _clearItemData();
        _clearFormData();
        
        // Clear form data cache juga
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('form_data');
        
        // Navigate back to home with success result
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false, arguments: {'refresh': true});
        }
      } else {
        // Error from API
        final message = response['message'] ?? 'Terjadi kesalahan saat mengirim transaksi';
        _showErrorDialog(message);
      }
      
    } catch (e) {
      print('Error submitting transaction: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  // Fungsi untuk clear form data
  void _clearFormData() {
    _namaPenerimaController.clear();
    _nohpPenerimaController.clear();
    _namaTembusan1Controller.clear();
    _nohpTembusan1Controller.clear();
    
    // Clear additional receivers
    for (var receiver in _additionalReceivers) {
      receiver['nama']?.clear();
      receiver['nohp']?.clear();
    }
    
    // Clear additional tembusan
    for (var tembusan in _additionalTembusan) {
      tembusan['nama']?.clear();
      tembusan['nohp']?.clear();
    }
    
    setState(() {
      _additionalReceivers.clear();
      _additionalTembusan.clear();
    });
  }
  
  // Fungsi untuk menampilkan dialog error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  // Fungsi untuk menampilkan dialog success
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
   }
  
  void _removeCopy(int index) {
    setState(() {
      _additionalTembusan[index]['nama']?.dispose();
      _additionalTembusan[index]['nohp']?.dispose();
      _additionalTembusan.removeAt(index);
    });
    // Save form data setelah menghapus tembusan
    _saveFormDataToCache();
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF374151),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1B8B7A), width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B8B7A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Kirim Barang',
          style: TextStyle(
            color: Color(0xFF1B8B7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daftar Barang Section
            const Text(
              'Daftar Barang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 20),
            
            // Tampilkan daftar barang jika ada
            if (_itemsList.isNotEmpty) ...[
              // Loop untuk menampilkan semua items
              ...List.generate(_itemsList.length, (index) {
                final item = _itemsList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${item.namaBarang}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icon edit
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddItemsFormPage(existingData: item),
                            ),
                          );
                          if (result != null && result is ItemData) {
                            setState(() {
                              _itemsList[index] = result;
                            });
                            await _saveItemsToCache();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF1B8B7A),
                            size: 20,
                          ),
                        ),
                      ),
                      // Icon delete
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _itemsList.removeAt(index);
                          });
                          _saveItemsToCache();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Garis pembatas
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ],
            
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddItemsFormPage(),
                  ),
                );
                if (result != null && result is ItemData) {
                  setState(() {
                    _itemsList.add(result);
                  });
                  await _saveItemsToCache();
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.add,
                    color: Color(0xFF1B8B7A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tambah Barang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1B8B7A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Detail Penerima Section
            const Row(
              children: [
                Text(
                  'Detail Penerima',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Nama Penerima
            const Text(
              'Nama Penerima',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _namaPenerimaController,
              hintText: 'Masukan Nama Penerima',
            ),
            const SizedBox(height: 20),
            
            // No HP Penerima
            const Text(
              'No HP (Whatsapp)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _nohpPenerimaController,
              hintText: 'Masukan No HP Penerima',
              keyboardType: TextInputType.phone,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/images/No-HP-icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Additional receivers
            ...List.generate(_additionalReceivers.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _removeReceiver(index),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  // Nama Penerima
                  const Text(
                    'Nama Penerima',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalReceivers[index]['nama']!,
                    hintText: 'Masukan Nama Penerima',
                  ),
                  const SizedBox(height: 16),
                  // No HP Penerima
                  const Text(
                    'No HP (Whatsapp)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalReceivers[index]['nohp']!,
                    hintText: 'Masukan No HP Penerima',
                    keyboardType: TextInputType.phone,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        'assets/images/No-HP-icon.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
            
            // Tambah Penerima Button
            GestureDetector(
              onTap: _addReceiver,
              child: const Row(
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xFF1B8B7A),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Penerima',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1B8B7A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Detail Tembusan Section
            const Row(
              children: [
                Text(
                  'Detail Tembusan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Nama Tembusan
            const Text(
              'Nama Tembusan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _namaTembusan1Controller,
              hintText: 'Masukan Nama Tembusan',
            ),
            const SizedBox(height: 20),
            
            // No HP Tembusan
            const Text(
              'No HP (Whatsapp)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _buildUnderlineTextField(
              controller: _nohpTembusan1Controller,
              hintText: 'Masukan No HP Penerima',
              keyboardType: TextInputType.phone,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/images/No-HP-icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Additional copies
            ...List.generate(_additionalTembusan.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _removeCopy(index),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  // Nama Tembusan
                  const Text(
                    'Nama Tembusan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalTembusan[index]['nama']!,
                    hintText: 'Masukan Nama Tembusan',
                  ),
                  const SizedBox(height: 16),
                  // No HP Tembusan
                  const Text(
                    'No HP (Whatsapp)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalTembusan[index]['nohp']!,
                    hintText: 'Masukan No HP Penerima',
                    keyboardType: TextInputType.phone,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        'assets/images/No-HP-icon.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
            
            // Tambah Tembusan Button
            GestureDetector(
              onTap: _addCopy,
              child: const Row(
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xFF1B8B7A),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Tembusan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1B8B7A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () {
                  HapticFeedback.lightImpact();
                  _submitTransaction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting ? Colors.grey : const Color(0xFF1B8B7A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}