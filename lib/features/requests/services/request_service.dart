import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/request_models.dart';

/// Thrown for client-side problems (e.g. missing token, malformed data).
class RequestException implements Exception {
  final String message;
  RequestException(this.message);
  @override
  String toString() => message;
}

String requestErrorMessage(Object e) {
  if (e is ApiException) return e.message;
  if (e is RequestException) return e.message;
  return 'Unable to process request. Please try again.';
}

/// Uses the app's existing ApiClient (base URL = ApiConstants.baseUrl, which
/// already ends with /api/v1) and SecureStorageService (auth token).
class RequestService {
  RequestService({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  final ApiClient _api;
  final SecureStorageService _storage;

  Future<String> _token() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw RequestException(
          'Authentication token not found. Please login again.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _get(String path, String label) async {
    final res = await _api.get(path, token: await _token());
    return _data(res, label);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    String label, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _api.post(path, body: body, token: await _token());
    return _data(res, label);
  }

  Map<String, dynamic> _data(Map<String, dynamic> res, String label) {
    final d = res['data'];
    if (d is! Map<String, dynamic>) {
      throw RequestException('$label failed.');
    }
    return d;
  }

  List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) =>
      (raw as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(f)
          .toList();

  /* ------------------------------- fetch ---------------------------------- */

  Future<List<LeaveRequest>> fetchLeaveRequests(RequestMonthFilter f) async {
    final d = await _get('/leave/me/requests${f.query}', 'Leave requests');
    return _list(d['leave_requests'], LeaveRequest.fromJson);
  }

  Future<List<PermissionRequest>> fetchPermissionRequests(
      RequestMonthFilter f) async {
    final d = await _get('/permission/me/permission/requests${f.query}',
        'Permission requests');
    return _list(d['permission_requests'], PermissionRequest.fromJson);
  }

  Future<List<RegularizationRequest>> fetchRegularizationRequests(
      RequestMonthFilter f) async {
    final d =
        await _get('/regularization/me${f.query}', 'Regularization requests');
    return _list(d['requests'], RegularizationRequest.fromJson);
  }

  Future<PermissionBalance> fetchPermissionBalance() async {
    final d = await _get('/permission/me/balance', 'Permission balance');
    return PermissionBalance.fromJson(d);
  }

  /* -------------------------------- apply --------------------------------- */

  Future<LeaveApplyResult> applyForLeave(LeaveRequestPayload p) async {
    final d = await _post('/leave/me/apply', 'Leave application',
        body: p.toJson());
    return LeaveApplyResult.fromJson(d);
  }

  Future<PermissionApplyResult> applyForPermission(
      PermissionRequestPayload p) async {
    final d = await _post('/permission/me/apply', 'Permission application',
        body: p.toJson());
    return PermissionApplyResult.fromJson(d);
  }

  Future<RegularizationRequest> applyForRegularization(
      RegularizationRequestPayload p) async {
    final d = await _post('/regularization/me/apply',
        'Regularization application',
        body: p.toJson());
    final r = d['regularization_request'];
    if (r is! Map<String, dynamic>) {
      throw RequestException('Regularization application failed.');
    }
    return RegularizationRequest.fromJson(r);
  }

  /* -------------------------------- cancel -------------------------------- */

  Future<void> cancelLeave(String id) async {
    await _api.post('/leave/me/${Uri.encodeComponent(id)}/cancel',
        token: await _token());
  }

  Future<void> cancelPermission(String id) async {
    await _api.post('/permission/me/${Uri.encodeComponent(id)}/cancel',
        token: await _token());
  }
}