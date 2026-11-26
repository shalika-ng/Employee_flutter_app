import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/calendar/services/calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'requests the selected month and parses holidays and pending leave',
    () async {
      final service = CalendarService(
        apiClient: ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/employees/me/calendar');
            expect(request.url.queryParameters, {
              'month': '11',
              'year': '2026',
            });
            expect(request.headers.containsKey('Authorization'), isTrue);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'calendar': {
                    'month': 11,
                    'year': 2026,
                    'days': [
                      {
                        'date': '2026-11-11',
                        'attendance': {'status': 'ABSENT'},
                        'events': [
                          {
                            'type': 'PENDING_LEAVE',
                            'from_date': '2026-11-11',
                            'to_date': '2026-11-12',
                            'days': 2,
                          },
                        ],
                      },
                      {
                        'date': '2026-11-27',
                        'attendance': null,
                        'events': [
                          {
                            'type': 'EMPLOYEE_HOLIDAY',
                            'date': '2026-11-27',
                            'name': 'Paid Off',
                          },
                        ],
                      },
                    ],
                    'events': [
                      {
                        'type': 'EMPLOYEE_HOLIDAY',
                        'date': '2026-11-27',
                        'name': 'Paid Off',
                      },
                      {
                        'type': 'PENDING_LEAVE',
                        'from_date': '2026-11-11',
                        'to_date': '2026-11-12',
                        'days': 2,
                      },
                      {
                        'type': 'COMMON_HOLIDAY',
                        'date': '2026-11-09',
                        'name': 'Diwali Holidays',
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }),
        ),
      );
      final calendar = await service.getMyCalendar(
        month: 11,
        year: 2026,
        token: 'token',
      );
      expect(calendar.days.first.attendanceStatus, 'ABSENT');
      expect(calendar.days.first.events.first.days, 2);
      expect(calendar.holidays.map((event) => event.name), [
        'Diwali Holidays',
        'Paid Off',
      ]);
      expect(calendar.days.last.attendanceStatus, isNull);
    },
  );

  test('rejects invalid or mismatched calendar data', () async {
    final service = CalendarService(
      apiClient: ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'calendar': {
                  'month': 12,
                  'year': 2026,
                  'days': [],
                  'events': [],
                },
              },
            }),
            200,
          ),
        ),
      ),
    );
    expect(
      () => service.getMyCalendar(month: 11, year: 2026, token: 'token'),
      throwsA(isA<ApiException>()),
    );
  });
}
