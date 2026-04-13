class AppConfig {
  static const bool isProduction = true;

  static String get baseUrl {
    if (isProduction) {
      return "https://chime-api.onrender.com";
    } else {
      return "http://$_localIp:5000";
    }
  }

  // Set your current dev IP here once
     static const String _localIp = "192.168.18.1"; //res prod
     //static const String _localIp = "10.254.66.225";// School prod
}
