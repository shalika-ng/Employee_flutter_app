import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_models.dart';

class AttendanceService {
  AttendanceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AttendanceMonthData> getMyAttendance({
    required int month,
    required int year,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.myAttendanceEndpoint}?month=$month&year=$year',
      token: token,
    );
    return AttendanceMonthData.fromJson(_dataFrom(response));
  }

  Future<AttendanceDayData> getMyAttendanceDay({
    required String date,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.myAttendanceDayEndpoint}?date=${Uri.encodeQueryComponent(date)}',
      token: token,
    );
    return AttendanceDayData.fromJson(_dataFrom(response));
  }

  Map<String, dynamic> _dataFrom(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry('$key', value));
    }
    throw ApiException('Invalid attendance response from server.');
  }
}
