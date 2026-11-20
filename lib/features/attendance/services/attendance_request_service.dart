import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AttendanceRequestService {
  AttendanceRequestService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AttendanceRequestReceipt> applyLeave({
    required String fromDate,
    required String toDate,
    required String reason,
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.myLeaveRequestEndpoint,
      body: {'from_date': fromDate, 'to_date': toDate, 'reason': reason},
      token: token,
    );
    return _receipt(response, requestKey: 'leave_request');
  }

  Future<String> cancelLeave({
    required String id,
    required String token,
  }) async {
    return _cancel(
      prefix: ApiConstants.myLeaveRequestCancelPrefix,
      requestKey: 'leave_request',
      id: id,
      token: token,
    );
  }

  Future<AttendanceRequestReceipt> applyPermission({
    required String date,
    required String startTime,
    required int minutes,
    required String reason,
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.myPermissionRequestEndpoint,
      body: {
        'perm_date': date,
        'start_time': startTime,
        'minutes': minutes,
        'reason': reason,
      },
      token: token,
    );
    return _receipt(response, requestKey: 'permission_request');
  }

  Future<String> cancelPermission({
    required String id,
    required String token,
  }) async {
    return _cancel(
      prefix: ApiConstants.myPermissionRequestCancelPrefix,
      requestKey: 'permission_request',
      id: id,
      token: token,
    );
  }

  Future<PermissionBalance> getPermissionBalance({
    required String token,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.myPermissionBalanceEndpoint,
      token: token,
    );
    return PermissionBalance.fromJson(_asMap(response['data'], 'balance'));
  }

  Future<String> _cancel({
    required String prefix,
    required String requestKey,
    required String id,
    required String token,
  }) async {
    final response = await _apiClient.post(
      '$prefix${Uri.encodeComponent(id)}/cancel',
      token: token,
    );
    final data = _asMap(response['data'], 'cancellation');
    _asMap(data[requestKey], 'cancelled request');
    return _messageFrom(response);
  }

  AttendanceRequestReceipt _receipt(
    Map<String, dynamic> response, {
    required String requestKey,
  }) {
    final data = _asMap(response['data'], 'request');
    final request = _asMap(data[requestKey], 'submitted request');
    final id = request['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException('Invalid request response from server.');
    }
    return AttendanceRequestReceipt(id: id, message: _messageFrom(response));
  }

  String _messageFrom(Map<String, dynamic> response) {
    final message = response['message']?.toString();
    if (message == null || message.isEmpty) {
      throw ApiException('Invalid request response from server.');
    }
    return message;
  }

  Map<String, dynamic> _asMap(dynamic value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    throw ApiException('Invalid $field response from server.');
  }
}

class AttendanceRequestReceipt {
  const AttendanceRequestReceipt({required this.id, required this.message});

  final String id;
  final String message;
}

class PermissionBalance {
  const PermissionBalance({
    required this.month,
    required this.year,
    required this.monthlyLimit,
    required this.usedMinutes,
    required this.pendingMinutes,
    required this.remainingMinutes,
  });

  factory PermissionBalance.fromJson(Map<String, dynamic> json) {
    return PermissionBalance(
      month: _requiredInt(json, 'month'),
      year: _requiredInt(json, 'year'),
      monthlyLimit: _requiredInt(json, 'monthly_limit'),
      usedMinutes: _requiredInt(json, 'used_minutes'),
      pendingMinutes: _requiredInt(json, 'pending_minutes'),
      remainingMinutes: _requiredInt(json, 'remaining_minutes'),
    );
  }

  final int month;
  final int year;
  final int monthlyLimit;
  final int usedMinutes;
  final int pendingMinutes;
  final int remainingMinutes;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw ApiException('Invalid permission balance response from server.');
}
