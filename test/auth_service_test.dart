import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'refresh sends the refresh token and parses the new access token',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/refresh');
        expect(jsonDecode(request.body), {'refresh_token': 'refresh-token'});
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'access-token', 'expires_in': 86400},
          }),
          200,
        );
      });

      final result = await AuthService(apiClient: ApiClient(client: client))
          .refresh(refreshToken: 'refresh-token');

      expect(result.token, 'access-token');
      expect(result.expiresIn, 86400);
    },
  );

  test('FCM registration sends its token and current access token', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/fcm-token');
      expect(jsonDecode(request.body), {'token': 'fcm-token'});
      expect(request.headers['Authorization'], 'Bearer access-token');
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'FCM token registered successfully.',
        }),
        200,
      );
    });

    await AuthService(apiClient: ApiClient(client: client))
        .registerFcmToken(token: 'fcm-token', accessToken: 'access-token');
  });
}
