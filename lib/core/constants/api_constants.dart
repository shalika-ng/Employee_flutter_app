/// Centralized API configuration for the app.
///
/// Update [baseUrl] when moving between local, staging and production
/// backends. All endpoint paths are relative to [baseUrl].
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.1.88:5001/api/v1';

  // Auth
  static const String loginEndpoint = '/auth/employee/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String fcmTokenEndpoint = '/auth/fcm-token';

  static const Duration connectTimeout = Duration(seconds: 15);
}
