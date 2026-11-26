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

  // Attendance
  static const String myAttendanceEndpoint = '/attendance/me';
  static const String myAttendanceDayEndpoint = '/attendance/me/day';
  static const String myDashboardEndpoint = '/employees/me/dashboard';
  static const String myCalendarEndpoint = '/employees/me/calendar';
  static const String myPayslipsEndpoint = '/payroll/payslips/me';

  // Employee requests
  static const String myLeaveRequestEndpoint = '/leave/me/apply';
  static const String myLeaveRequestCancelPrefix = '/leave/me/';
  static const String myPermissionRequestEndpoint = '/permission/me/apply';
  static const String myPermissionRequestCancelPrefix = '/permission/me/';
  static const String myPermissionBalanceEndpoint = '/permission/me/balance';

  static const Duration connectTimeout = Duration(seconds: 15);
}
