class AppConfig {
  static const String apiBaseUrl = 'https://apiv1.winapp24.com';

  static const String appDownloadUrl = 'https://download.winapp24.com/';

  static const String appVersion = '1.1.2';

  static const String paymentScheme = 'winapp';

  static String mediaUrl(String path) {
    final value = path.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    return '$apiBaseUrl$value';
  }
}
