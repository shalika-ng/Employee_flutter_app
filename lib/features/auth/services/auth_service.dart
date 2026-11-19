import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Talks to the employee auth endpoints. Kept framework-agnostic so it can
/// be unit tested without Redux or Flutter widgets involved.
class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.loginEndpoint,
      body: {'email': email, 'password': password},
    );

    return LoginResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<RefreshResult> refresh({required String refreshToken}) async {
    final response = await _apiClient.post(
      ApiConstants.refreshEndpoint,
      body: {'refresh_token': refreshToken},
    );

    return RefreshResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> registerFcmToken({
    required String token,
    String? accessToken,
  }) async {
    await _apiClient.post(
      ApiConstants.fcmTokenEndpoint,
      body: {'token': token},
      token: accessToken,
    );
  }
}
