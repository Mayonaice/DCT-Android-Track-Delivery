class Config {
  static bool isTestMode = false;

  static const String _testingBaseUrl = "https://dev.advantagescm.com/LocalTrackingDelivery/api/";
  static const String _productionBaseUrl = "https://android.advantagescm.com/AndroidTrackingDelivery/api/";

  static const String _testingReceiptBaseUrl = "https://dev.advantagescm.com/TYD/DataHandler/";
  static const String _productionReceiptBaseUrl = "https://dctweb2.advantagescm.com/TYD/DataHandler/";
  static const String _productionReceiptFallbackBaseUrl = "https://dctweb99.advantagescm.com/TYD/DataHandler/";

  static String get baseUrl {
    return isTestMode ? _testingBaseUrl : _productionBaseUrl;
  }

  static String get receiptHandlerBaseUrl {
    return isTestMode ? _testingReceiptBaseUrl : _productionReceiptBaseUrl;
  }

  static String get loginEndpoint => "Users/Login";

  static String getEndpoint(String endpoint) {
    return "$baseUrl$endpoint";
  }

  static String getReceiptDownloadUrl(String deliveryNo) {
    final encoded = Uri.encodeComponent(deliveryNo);
    return "${receiptHandlerBaseUrl}DownloadTandaTerima.ashx?DeliveryNo=$encoded";
  }

  static String getAlternateReceiptDownloadUrl(String deliveryNo) {
    final encoded = Uri.encodeComponent(deliveryNo);
    final base = isTestMode ? _testingReceiptBaseUrl : _productionReceiptFallbackBaseUrl;
    return "${base}DownloadTandaTerima.ashx?DeliveryNo=$encoded";
  }

  static String get environment => isTestMode ? "Testing" : "Production";

  static void setTestMode(bool enabled) {
    isTestMode = enabled;
  }
}
