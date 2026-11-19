import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/attendance/services/attendance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'monthly attendance sends month/year query and parses summaries',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/attendance/me');
        expect(request.url.queryParameters, {'month': '8', 'year': '2026'});
        expect(request.headers['Authorization'], 'Bearer access-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'employee': {
                'id': '6',
                'emp_code': 'EMP003',
                'name': 'Test Employee',
                'designation': 'Software Engineer',
              },
              'month': 8,
              'year': 2026,
              'day_summaries': [
                {
                  'id': '1',
                  'work_date': '2026-08-12T18:30:00.000Z',
                  'status': 'PRESENT',
                  'first_in': '2026-08-13T03:30:00.000Z',
                  'last_out': '2026-08-13T12:30:00.000Z',
                  'work_min': 540,
                  'break_min': 0,
                  'permission_min': 0,
                  'is_late': false,
                  'excess_break': false,
                  'needs_regularization': false,
                  'lop_value': '0.00',
                  'is_locked': false,
                },
              ],
              'today': {
                'date': '2026-08-20',
                'status': 'OUT',
                'last_punch': null,
              },
              'totals': {
                'present': 1,
                'half': 0,
                'absent': 0,
                'leave': 0,
                'holiday': 0,
                'weekly_off': 0,
                'insufficient': 0,
                'late_count': 0,
                'work_hours': 9,
                'work_minutes': 540,
              },
            },
          }),
          200,
        );
      });

      final result = await AttendanceService(
        apiClient: ApiClient(client: client),
      ).getMyAttendance(month: 8, year: 2026, token: 'access-token');

      expect(result.employee.empCode, 'EMP003');
      expect(result.days.single.status, 'PRESENT');
      expect(result.days.single.workMinutes, 540);
      expect(result.totals.workMinutes, 540);
    },
  );

  test(
    'day details sends date query and parses sessions and punches',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/attendance/me/day');
        expect(request.url.queryParameters, {'date': '2026-08-17'});
        expect(request.headers['Authorization'], 'Bearer access-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'employee': {
                'id': '6',
                'emp_code': 'EMP003',
                'name': 'Test Employee',
                'designation': 'Software Engineer',
              },
              'date': '2026-08-17',
              'summary': {
                'id': '5',
                'work_date': '2026-08-16T18:30:00.000Z',
                'status': 'INSUFFICIENT',
                'first_in': '2026-08-17T03:30:00.000Z',
                'last_out': '2026-08-17T12:30:00.000Z',
                'work_min': 0,
                'break_min': 0,
                'permission_min': 0,
                'is_late': false,
                'excess_break': false,
                'needs_regularization': true,
                'lop_value': '1.00',
                'is_locked': false,
              },
              'sessions': [
                {
                  'id': '7',
                  'in_at': '2026-08-17T03:30:00.000Z',
                  'out_at': '2026-08-17T03:30:00.000Z',
                  'duration_min': 0,
                  'flag': null,
                },
              ],
              'punches': [
                {
                  'id': '1',
                  'punched_at': '2026-08-17T03:30:00.000Z',
                  'direction': 'IN',
                  'source_type': 'RAW',
                  'is_correction': false,
                },
              ],
              'flags': {
                'needs_regularization': true,
                'is_late': false,
                'excess_break': false,
                'is_locked': false,
              },
            },
          }),
          200,
        );
      });

      final result = await AttendanceService(
        apiClient: ApiClient(client: client),
      ).getMyAttendanceDay(date: '2026-08-17', token: 'access-token');

      expect(result.date, '2026-08-17');
      expect(result.summary?.status, 'INSUFFICIENT');
      expect(result.sessions.single.durationMinutes, 0);
      expect(result.punches.single.direction, 'IN');
      expect(result.flags.needsRegularization, isTrue);
    },
  );
}
