class PhoneFormatter {
  /// Converts phone number starting with "0" to international format with "62"
  /// Example: "08123456789" -> "628123456789"
  static String convertToInternational(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Remove all non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If starts with "0", replace with "62"
    if (cleanNumber.startsWith('0')) {
      return '62${cleanNumber.substring(1)}';
    }
    
    // If already starts with "62", return as is
    if (cleanNumber.startsWith('62')) {
      return cleanNumber;
    }
    
    // If starts with "+62", remove the "+" and return
    if (phoneNumber.startsWith('+62')) {
      return cleanNumber;
    }
    
    // For other cases, assume it's already in correct format
    return cleanNumber;
  }
  
  /// Formats phone number for display (converts 62xxx to 08xxx for user-friendly display)
  /// Example: "628123456789" -> "08123456789"
  static String formatForDisplay(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Remove all non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If starts with "62", replace with "0"
    if (cleanNumber.startsWith('62')) {
      return '0${cleanNumber.substring(2)}';
    }
    
    // If already starts with "0", return as is
    if (cleanNumber.startsWith('0')) {
      return cleanNumber;
    }
    
    // For other cases, return as is
    return cleanNumber;
  }
  
  /// Validates Indonesian phone number format
  /// Returns true if the phone number is valid
  static bool isValidIndonesianPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;
    
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if it's Indonesian format (starts with 0 or 62)
    if (cleanNumber.startsWith('0')) {
      // Should be 10-13 digits total (0 + 9-12 digits)
      return cleanNumber.length >= 10 && cleanNumber.length <= 13;
    } else if (cleanNumber.startsWith('62')) {
      // Should be 11-14 digits total (62 + 9-12 digits)
      return cleanNumber.length >= 11 && cleanNumber.length <= 14;
    }
    
    return false;
  }
  
  /// Auto-converts phone number input in real-time
  /// This can be used with TextFormField onChanged callback
  static String autoConvert(String input) {
    if (input.isEmpty) return input;
    
    // Remove all non-digit characters for processing
    String cleanNumber = input.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If user types starting with "0", keep it as is for display
    // The actual conversion will happen when submitting the form
    return cleanNumber;
  }
  
  /// Formats phone number with country code for WhatsApp
  /// Example: "08123456789" -> "+628123456789"
  static String formatForWhatsApp(String phoneNumber) {
    String international = convertToInternational(phoneNumber);
    return '+$international';
  }
}