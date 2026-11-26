import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Thrown when the API responds with `success: false` or a non-2xx status.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around [http.Client] that centralizes base URL, headers,
/// JSON decoding and error handling for every request in the app.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Uint8List> getPdf(String path, {required String token}) async {
    final request =
        http.Request('GET', Uri.parse('${ApiConstants.baseUrl}$path'))
          ..headers.addAll(_headers(token))
          ..headers['Accept'] = 'application/pdf'
          ..followRedirects = false;
    late final http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConstants.connectTimeout);
      response = await http.Response.fromStream(streamed)
          .timeout(ApiConstants.connectTimeout);
    } on TimeoutException {
      throw ApiException('The download timed out. Please try again.');
    } on http.ClientException {
      throw ApiException('Unable to reach server. Please try again.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] is String) {
          message = json['message'] as String;
        }
      } on FormatException {
        // A non-JSON error still reports its HTTP status below.
      }
      throw ApiException(
        message ?? 'Unable to download payslip (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2d) {
      throw ApiException('The server did not return a valid PDF.');
    }
    return bytes;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: _headers(token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.connectTimeout);

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unable to reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.connectTimeout);

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unable to reach server. Please try again.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Invalid response from server.',
        statusCode: response.statusCode,
      );
    }

    final success = decoded['success'] == true;
    if (!success || response.statusCode >= 400) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Something went wrong.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }
}
