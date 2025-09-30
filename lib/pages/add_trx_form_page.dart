import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_tyd/pages/add_items_form_page.dart';

class AddTrxFormPage extends StatefulWidget {
  const AddTrxFormPage({super.key});

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
  }

  void _removeReceiver(int index) {
    setState(() {
      _additionalReceivers[index]['nama']?.dispose();
      _additionalReceivers[index]['nohp']?.dispose();
      _additionalReceivers.removeAt(index);
    });
  }

  void _addCopy() {
    setState(() {
      _additionalTembusan.add({
        'nama': TextEditingController(),
        'nohp': TextEditingController(),
      });
    });
  }

  void _removeCopy(int index) {
    setState(() {
      _additionalTembusan[index]['nama']?.dispose();
      _additionalTembusan[index]['nohp']?.dispose();
      _additionalTembusan.removeAt(index);
    });
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddItemsFormPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8B7A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Tambah Barang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              suffixIcon: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8B7A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 16,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Penerima ${index + 2}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
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
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalReceivers[index]['nama']!,
                    hintText: 'Masukan Nama Penerima',
                  ),
                  const SizedBox(height: 16),
                  _buildUnderlineTextField(
                    controller: _additionalReceivers[index]['nohp']!,
                    hintText: 'Masukan No HP Penerima',
                    keyboardType: TextInputType.phone,
                    suffixIcon: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8B7A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 16,
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
              suffixIcon: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8B7A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 16,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tembusan ${index + 2}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
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
                  const SizedBox(height: 8),
                  _buildUnderlineTextField(
                    controller: _additionalTembusan[index]['nama']!,
                    hintText: 'Masukan Nama Tembusan',
                  ),
                  const SizedBox(height: 16),
                  _buildUnderlineTextField(
                    controller: _additionalTembusan[index]['nohp']!,
                    hintText: 'Masukan No HP Penerima',
                    keyboardType: TextInputType.phone,
                    suffixIcon: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8B7A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 16,
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement submit functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8B7A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
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