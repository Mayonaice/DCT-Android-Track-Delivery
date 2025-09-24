import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import '../models/status_master.dart';
import '../widgets/status_filter_widget.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/bottom_navigation_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  String userName = '';
  String userEmail = '';
  
  // Filter states
  StatusFilterOption _selectedStatusFilter = StatusFilterOption.options.first;
  DateFilterOption _selectedDateFilter = DateFilterOption.options.first;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Transaction data
  List<TransactionData> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _storageService.getUserName();
    final email = await _storageService.getUserEmail();
    setState(() {
      userName = name;
      userEmail = email;
    });
    
    // Load transactions after getting user data
    if (email.isNotEmpty) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        print('🚨 DEBUG: No token found');
        return;
      }

      print('🔍 DEBUG: Loading transactions for user: $userEmail');
      print('🔍 DEBUG: Selected status filter: ${_selectedStatusFilter.statusId}');
      print('🔍 DEBUG: Date range: ${_getStartDateString()} to ${_getEndDateString()}');

      // Build request based on filters
      String? statusValue;
      String? startDate;
      String? endDate;

      // Handle status filter - hanya kirim jika bukan "Semua Status"
      if (_selectedStatusFilter.statusId != null && _selectedStatusFilter.statusId != 0) {
        statusValue = _selectedStatusFilter.statusId.toString();
      }

      // Handle date filter - hanya kirim jika bukan "Semua Tanggal"
      if (_selectedDateFilter.type != DateFilterType.all) {
        startDate = _getStartDateString();
        endDate = _getEndDateString();
      }

      final request = TransactionRequest(
        userEmail: userEmail,
        pageSize: 10,
        status: statusValue,
        tanggalFrom: startDate,
        tanggalEnd: endDate,
      );

      print('🔍 DEBUG: Request object: ${request.toJson()}');

      final response = await _apiService.getTransactions(request, token);
      
      print('🔍 DEBUG: API Response received: ${response != null}');
      if (response != null) {
        print('🔍 DEBUG: Response data count: ${response.data.length}');
        print('🔍 DEBUG: Response message: ${response.message}');
        setState(() {
          _transactions = response.data;
        });
      } else {
        print('🚨 DEBUG: Response is null');
      }
    } catch (e) {
      print('🚨 DEBUG: Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _getStartDateString() {
    if (_selectedDateFilter.type == DateFilterType.all) return null;
    
    if (_selectedDateFilter.type == DateFilterType.preset) {
      final days = _selectedDateFilter.days ?? 30;
      final startDate = DateTime.now().subtract(Duration(days: days));
      // Set to start of day (00:00:00)
      final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
      return startOfDay.toIso8601String();
    }
    
    if (_selectedDateFilter.type == DateFilterType.custom && _customStartDate != null) {
      // Set to start of day (00:00:00)
      final startOfDay = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
      return startOfDay.toIso8601String();
    }
    
    return null;
  }

  String? _getEndDateString() {
    if (_selectedDateFilter.type == DateFilterType.all) return null;
    
    if (_selectedDateFilter.type == DateFilterType.preset) {
      final endDate = DateTime.now();
      // Set to end of day (23:59:59)
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      return endOfDay.toIso8601String();
    }
    
    if (_selectedDateFilter.type == DateFilterType.custom && _customEndDate != null) {
      // Set to end of day (23:59:59)
      final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
      return endOfDay.toIso8601String();
    }
    
    return null;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                   'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF059669), // Teal-600 (warna lama profile)
                    Color(0xFF047857), // Teal-700 (warna lama profile)
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 35.0), // Tambah padding bottom untuk tinggi
                child: Column(
                  children: [
                    // Top bar with greeting and profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $userName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Selamat Pagi!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        // Profile Picture Placeholder
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF1B8B7A),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search something...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Filter Buttons
                    Row(
                      children: [
                        _buildFilterButton(
                          _selectedStatusFilter.label,
                          true,
                          () => showStatusFilter(
                            context,
                            _selectedStatusFilter,
                            (option) {
                              setState(() {
                                _selectedStatusFilter = option;
                              });
                              _loadTransactions();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildFilterButton(
                          _selectedDateFilter.label,
                          false,
                          () => showDateFilter(
                            context,
                            _selectedDateFilter,
                            _customStartDate,
                            _customEndDate,
                            (option, startDate, endDate) {
                              setState(() {
                                _selectedDateFilter = option;
                                _customStartDate = startDate;
                                _customEndDate = endDate;
                              });
                              _loadTransactions();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Status List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _transactions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada data transaksi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _transactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction = _transactions[index];
                                    return _buildStatusItem(transaction);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new delivery action
        },
        backgroundColor: const Color(0xFF1B8B7A),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B8B7A) : Colors.transparent,
          border: Border.all(
            color: const Color(0xFF1B8B7A),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1B8B7A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: isSelected ? Colors.white : const Color(0xFF1B8B7A),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(TransactionData transaction) {
    final statusInfo = StatusMaster.getStatusById(transaction.status);
    
    DateTime transactionDate;
    try {
      transactionDate = transaction.transactionDate;
    } catch (e) {
      transactionDate = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon status di sebelah kiri
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                statusInfo?.iconPath ?? 'assets/images/icon-status1(submitted).png',
                width: 56,
                height: 56,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusInfo?.color ?? Colors.grey,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Konten utama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Penerima
                Text(
                  'Kirim Ke ${transaction.consigneeName ?? 'Pengiriman'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Status
                Text(
                  'Status: ${statusInfo?.name ?? 'Unknown Status'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusInfo?.color ?? Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Kode Pengiriman
                Text(
                  'Kode Pengiriman: ${transaction.transactionCode ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Tanggal di sebelah kanan
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(transactionDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(transactionDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}