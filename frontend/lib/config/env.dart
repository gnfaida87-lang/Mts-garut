class Env {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  static const String apiPrefix = '/api';
  static String get apiUrl => '$baseUrl$apiPrefix';

  static const String appName = 'Sistem Informasi MTs Persis Garut';
  static const String appVersion = '1.0.0';

  // QR Token untuk absensi (harus cocok di client & server)
  static const String qrAbsensiToken = 'PPI_ABSENSI_QR_2026';
}
