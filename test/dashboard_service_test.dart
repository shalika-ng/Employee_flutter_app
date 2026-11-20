import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/home/services/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('dashboard request parses attendance, leave, LOP, and events', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/employees/me/dashboard');
      expect(request.headers['Authorization'], 'Bearer access-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'employee': {
              'id': '3',
              'emp_code': 'EMP002',
              'name': 'Jane Smith',
              'designation': 'Designer',
            },
            'today': {
              'date': '2026-11-20',
              'status': 'OUT',
              'punch_in_time': '2026-11-20T03:30:00.000Z',
              'last_punch': '2026-11-20T12:30:00.000Z',
            },
            'calendar': {
              'month': 11,
              'year': 2026,
              'days': [
                {
                  'date': '2026-11-18',
                  'attendance': {'status': 'PRESENT', 'work_min': 480},
                },
                {
                  'date': '2026-11-19',
                  'attendance': {'status': 'ABSENT', 'work_min': 0},
                },
                {'date': '2026-11-20', 'attendance': null},
              ],
              'events': [
                {
                  'type': 'EMPLOYEE_HOLIDAY',
                  'date': '2026-11-27',
                  'name': 'Paid Off',
                },
                {
                  'type': 'EMPLOYEE_HOLIDAY',
                  'date': '2026-11-27',
                  'name': 'Paid Off',
                },
              ],
            },
            'lop': {'month': 11, 'year': 2026, 'days': 2},
            'leave_balance': {
              'available_balance': 1,
              'total_balance': 5,
              'consumed_this_month': 1,
              'pending_days': 2,
            },
          },
        }),
        200,
      );
    });

    final dashboard = await DashboardService(
      apiClient: ApiClient(client: client),
    ).getMyDashboard(token: 'access-token');

    expect(dashboard.employee.name, 'Jane Smith');
    expect(dashboard.today.status, 'OUT');
    expect(dashboard.today.punchInTime, isNotNull);
    expect(dashboard.today.lastPunch, isNotNull);
    expect(dashboard.presentDays, 1);
    expect(dashboard.workMinutes, 480);
    expect(dashboard.lopDays, 2);
    expect(dashboard.leaveBalance.available, 1);
    expect(dashboard.leaveBalance.pendingDays, 2);
    expect(dashboard.events, hasLength(1));
  });
}
