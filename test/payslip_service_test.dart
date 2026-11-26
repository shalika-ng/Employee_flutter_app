import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/payslips/models/payslip.dart';
import 'package:attendence_employee/features/payslips/services/payslip_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads payslips and downloads the PDF with authentication', () async {
    final service = PayslipService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.headers['Authorization'], 'Bearer access-token');
          expect(request.body, isEmpty);
          if (request.url.path == '/api/v1/payroll/payslips/me') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'total': 1,
                  'payslips': [
                    {
                      'id': '58',
                      'month': 4,
                      'year': 2027,
                      'published_at': '2026-08-25T10:38:03.101Z',
                      'download_url': '/api/v1/payroll/payslips/me/58/download',
                    },
                  ],
                },
              }),
              200,
            );
          }
          expect(request.url.path, '/api/v1/payroll/payslips/me/58/download');
          expect(request.headers['Accept'], 'application/pdf');
          expect(request.followRedirects, isFalse);
          return http.Response.bytes(utf8.encode('%PDF-1.4 test'), 200);
        }),
      ),
    );
    final collection = await service.getMyPayslips(token: 'access-token');
    expect(collection.total, 1);
    expect(collection.payslips.single.month, 4);
    final bytes = await service.download(
      collection.payslips.single,
      token: 'access-token',
    );
    expect(utf8.decode(bytes), '%PDF-1.4 test');
  });

  test('reports server errors and rejects non-PDF responses', () async {
    var status = 400;
    final service = PayslipService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          if (status == 400) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'token is required'}),
              400,
            );
          }
          return http.Response('not a pdf', 200);
        }),
      ),
    );
    final slip = Payslip(id: '58', month: 4, year: 2027, publishedAt: _date);
    await expectLater(
      service.download(slip, token: 'access-token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'token is required',
        ),
      ),
    );
    status = 200;
    await expectLater(
      service.download(slip, token: 'access-token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('valid PDF'),
        ),
      ),
    );
  });

  test('rejects invalid payslip data and unsafe identifiers', () async {
    final service = PayslipService(
      apiClient: ApiClient(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'total': 1,
                'payslips': [
                  {
                    'id': '../unsafe',
                    'month': 4,
                    'year': 2027,
                    'published_at': '2026-08-25T10:38:03.101Z',
                  },
                ],
              },
            }),
            200,
          ),
        ),
      ),
    );
    await expectLater(
      service.getMyPayslips(token: 'token'),
      throwsA(isA<ApiException>()),
    );
    final unsafe = Payslip(
      id: '../unsafe',
      month: 4,
      year: 2027,
      publishedAt: _date,
    );
    expect(
      () => service.download(unsafe, token: 'token'),
      throwsA(isA<ApiException>()),
    );
  });
}

final DateTime _date = DateTime.utc(2026, 8, 25);
