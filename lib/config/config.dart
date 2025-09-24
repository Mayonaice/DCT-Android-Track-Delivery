class Config {
  // Ubah nilai isProduction untuk mengganti environment
  // true = Production, false = Testing
  static const bool isProduction = false;
  
  // Base URLs
  static const String _testingBaseUrl = "http://10.10.0.223/LocalTrackingDelivery/api/";
  static const String _productionBaseUrl = "https://dctweb.advantages.com/AndroidTrackingDelivery/api/";
  
  // Get current base URL based on environment
  static String get baseUrl {
    return isProduction ? _productionBaseUrl : _testingBaseUrl;
  }
  
  // API Endpoints
  static String get loginEndpoint => "Users/Login";
  
  // Helper method to get full URL for any endpoint
  static String getEndpoint(String endpoint) {
    return "$baseUrl$endpoint";
  }
  
  // Environment info
  static String get environment => isProduction ? "Production" : "Testing";
}