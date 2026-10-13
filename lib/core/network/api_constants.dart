class ApiConstants {
  static const String baseUrl = 'https://dev.saimpexenterprise.com/api/';
  static const String mediaBaseUrl = 'https://dev.saimpexenterprise.com/storage/';

  static const String sendOtp = 'customer/sendOtp';
  static const String verifyOtp = 'customer/verifyOtp';
  static const String logout = 'customer/logout';
  static const String profile = 'customer/profile';
  static const String updateProfile = 'customer/updateProfile';

  static String? mediaUrl(String? path) {
    if (path == null) return null;
    final value = path.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$mediaBaseUrl${value.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
