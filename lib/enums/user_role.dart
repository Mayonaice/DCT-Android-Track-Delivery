// Enum untuk role pengguna berdasarkan 2 huruf awal kode
enum UserRole {
  ta('TA', 'Technical Assistant'),
  tp('TP', 'Technical Personnel'), 
  tt('TT', 'Technical Technician');

  const UserRole(this.code, this.description);
  
  final String code;
  final String description;

  // Fungsi untuk mendeteksi role berdasarkan kode
  static UserRole? detectRoleFromCode(String code) {
    if (code.length < 2) return null;
    
    final prefix = code.substring(0, 2).toUpperCase();
    
    switch (prefix) {
      case 'TA':
        return UserRole.ta;
      case 'TP':
        return UserRole.tp;
      case 'TT':
        return UserRole.tt;
      default:
        return null;
    }
  }

  // Fungsi untuk mendapatkan role string
  String get roleString => code;
  
  // Fungsi untuk cek apakah role adalah TT (yang bisa akses halaman delivery detail)
  bool get canAccessDeliveryDetail => this == UserRole.tt;
}