import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/attendance/services/attendance_request_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'applies leave with the documented fields and authenticated token',
    () async {
      final service = AttendanceRequestService(
        apiClient: ApiClient(
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/v1/leave/me/apply');
            expect(request.headers['Authorization'], 'Bearer access-token');
            expect(jsonDecode(request.body), {
              'from_date': '2026-08-27',
              'to_date': '2026-08-30',
              'reason': 'Family event',
            });
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Leave request submitted successfully',
                'data': {
                  'leave_request': {'id': '2'},
                },
              }),
              200,
            );
          }),
        ),
      );

      final receipt = await service.applyLeave(
        fromDate: '2026-08-27',
        toDate: '2026-08-30',
        reason: 'Family event',
        token: 'access-token',
      );

      expect(receipt.id, '2');
      expect(receipt.message, 'Leave request submitted successfully');
    },
  );

  test('cancels leave with the request id and no request body', () async {
    final service = AttendanceRequestService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/leave/me/2/cancel');
          expect(request.headers['Authorization'], 'Bearer access-token');
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Leave request cancelled successfully',
              'data': {
                'leave_request': {'id': '2', 'status': 'CANCELLED'},
              },
            }),
            200,
          );
        }),
      ),
    );

    expect(
      await service.cancelLeave(id: '2', token: 'access-token'),
      'Leave request cancelled successfully',
    );
  });

  test(
    'applies permission with its date, start time, minutes, and reason',
    () async {
      final service = AttendanceRequestService(
        apiClient: ApiClient(
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/v1/permission/me/apply');
            expect(request.headers['Authorization'], 'Bearer access-token');
            expect(jsonDecode(request.body), {
              'perm_date': '2026-08-14',
              'start_time': '09:00',
              'minutes': 30,
              'reason': 'Medical appointment',
            });
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Permission request submitted successfully',
                'data': {
                  'permission_request': {'id': '5'},
                },
              }),
              200,
            );
          }),
        ),
      );

      final receipt = await service.applyPermission(
        date: '2026-08-14',
        startTime: '09:00',
        minutes: 30,
        reason: 'Medical appointment',
        token: 'access-token',
      );

      expect(receipt.id, '5');
    },
  );

  test('loads permission balance and cancels permission requests', () async {
    var balanceRequested = false;
    var cancellationRequested = false;
    final service = AttendanceRequestService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer access-token');
          if (request.method == 'GET') {
            balanceRequested = true;
            expect(request.url.path, '/api/v1/permission/me/balance');
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'month': 8,
                  'year': 2026,
                  'monthly_limit': 120,
                  'used_minutes': 60,
                  'pending_minutes': 30,
                  'remaining_minutes': 30,
                },
              }),
              200,
            );
          }

          cancellationRequested = true;
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/permission/me/6/cancel');
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Permission request cancelled successfully',
              'data': {
                'permission_request': {'id': '6', 'status': 'CANCELLED'},
              },
            }),
            200,
          );
        }),
      ),
    );

    final balance = await service.getPermissionBalance(token: 'access-token');
    expect(balance.monthlyLimit, 120);
    expect(balance.usedMinutes, 60);
    expect(balance.pendingMinutes, 30);
    expect(balance.remainingMinutes, 30);
    expect(
      await service.cancelPermission(id: '6', token: 'access-token'),
      'Permission request cancelled successfully',
    );
    expect(balanceRequested, isTrue);
    expect(cancellationRequested, isTrue);
  });
}
