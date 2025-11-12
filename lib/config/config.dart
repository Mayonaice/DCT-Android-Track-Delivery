class Config {
  // Ubah nilai isProduction untuk mengganti environment
  // true = Production, false = Testing
  static const bool isProduction = false;
  
  // Base URLs
  static const String _testingBaseUrl = "http://10.10.0.223/LocalTrackingDelivery/api/";
  static const String _productionBaseUrl = "https://dctweb.advantages.com/AndroidTrackingDelivery/api/";
  
  // Receipt handler (ASHX) base URLs
  // Dev: http://10.10.0.223/TYD/DataHandler/
  // Prod: https://tyd.advantagescm.com/DataHandler/
  static const String _testingReceiptBaseUrl = "http://10.10.0.223/TYD/DataHandler/";
  static const String _productionReceiptBaseUrl = "https://tyd.advantagescm.com/DataHandler/";
  
  // Get current base URL based on environment
  static String get baseUrl {
    return isProduction ? _productionBaseUrl : _testingBaseUrl;
  }
  
  // Get current ASHX receipt handler base URL based on environment
  static String get receiptHandlerBaseUrl {
    return isProduction ? _productionReceiptBaseUrl : _testingReceiptBaseUrl;
  }
  
  // API Endpoints
  static String get loginEndpoint => "Users/Login";
  
  // Helper method to get full URL for any endpoint
  static String getEndpoint(String endpoint) {
    return "$baseUrl$endpoint";
  }
  
  // Helper to build full ASHX receipt download URL
  static String getReceiptDownloadUrl(String deliveryNo) {
    final encoded = Uri.encodeComponent(deliveryNo);
    return "${receiptHandlerBaseUrl}DownloadTandaTerima.ashx?DeliveryNo=$encoded";
  }
  
  // Environment info
  static String get environment => isProduction ? "Production" : "Testing";
}