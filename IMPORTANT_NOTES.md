# CATATAN PENTING UNTUK PENGEMBANGAN

## 🚨 ATURAN WAJIB UNTUK ERROR HANDLING

### 1. Notifikasi Error dari API Response
**SELALU** pastikan semua notifikasi kegagalan/error yang ditampilkan kepada user berasal dari message response API, bukan dari hardcoded message di client.

**Implementasi yang benar:**
```dart
// ✅ BENAR - Ambil message dari API response
String errorMessage = responseData['message'] ?? 
                     responseData['error'] ?? 
                     responseData['msg'] ?? 
                     'Default message';

// ❌ SALAH - Jangan hardcode message
String errorMessage = 'Login gagal'; // Jangan seperti ini
```

### 2. Prioritas Error Message
Urutan prioritas untuk mengambil error message dari API:
1. `responseData['message']`
2. `responseData['error']`
3. `responseData['msg']`
4. Default fallback message

### 3. JSON Parsing Error Handling
Selalu handle kemungkinan response yang tidak valid:
```dart
Map<String, dynamic> responseData;
try {
  responseData = jsonDecode(response.body);
} catch (jsonError) {
  // Handle invalid JSON response
  return error response;
}
```

## 📝 Lokasi File Penting
- API Service: `lib/services/api_service.dart`
- Custom Modals: `lib/widgets/custommodals.dart`
- Main Login: `lib/main.dart`

## 🔄 Update Terakhir
- Tanggal: Hari ini
- Perubahan: Fixed JSON parsing error dan memastikan error message dari API response