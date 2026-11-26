import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/calendar_model.dart';

class CalendarService {
  CalendarService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EmployeeCalendar> getMyCalendar({
    required int month,
    required int year,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.myCalendarEndpoint}?month=$month&year=$year',
      token: token,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> ||
        data['calendar'] is! Map<String, dynamic>) {
      throw ApiException('Invalid calendar response from server.');
    }
    try {
      final calendar = EmployeeCalendar.fromJson(
        data['calendar'] as Map<String, dynamic>,
      );
      if (calendar.month != month || calendar.year != year) {
        throw const FormatException('Calendar month does not match request.');
      }
      return calendar;
    } on FormatException {
      throw ApiException('Invalid calendar response from server.');
    } on TypeError {
      throw ApiException('Invalid calendar response from server.');
    }
  }
}
