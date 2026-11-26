import 'dart:async';
import 'dart:typed_data';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/payslips/models/payslip.dart';
import 'package:attendence_employee/features/payslips/screens/payslip_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final slips = PayslipCollection(
  total: 2,
  payslips: [
    Payslip(
      id: '58',
      month: 4,
      year: 2027,
      publishedAt: DateTime.utc(2026, 8, 25),
    ),
    Payslip(
      id: '14',
      month: 11,
      year: 2026,
      publishedAt: DateTime.utc(2026, 8, 24),
    ),
  ],
);

void main() {
  testWidgets('filters payslips and saves the selected PDF', (tester) async {
    String? downloaded;
    String? savedName;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(
            token: 'access-token',
            loader: (_) async => slips,
            downloader: (slip, token) async {
              expect(token, 'access-token');
              downloaded = slip.id;
              return Uint8List.fromList([37, 80, 68, 70, 45]);
            },
            saver: (bytes, name) async {
              expect(bytes, [37, 80, 68, 70, 45]);
              savedName = name;
              return 'saved';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('April 2027'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);

    await tester.tap(find.text('2027'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsNothing);
    await tester.ensureVisible(find.text('Save PDF'));
    await tester.tap(find.text('Save PDF'));
    await tester.pumpAndSettle();
    expect(downloaded, '58');
    expect(savedName, 'payslip-2027-04-58');
    expect(find.text('Payslip saved successfully.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No statements match your search.'), findsOneWidget);
  });

  testWidgets('reports a download error and permits retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(
            token: 'token',
            loader: (_) async => slips,
            downloader: (_, _) async {
              calls++;
              throw ApiException('Download not allowed');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save PDF').first);
    await tester.tap(find.text('Save PDF').first);
    await tester.pumpAndSettle();
    expect(find.text('Download not allowed'), findsOneWidget);
    await tester.tap(find.text('Save PDF').first);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('shows empty and load error states', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(
            token: 'token',
            loader: (_) async {
              calls++;
              if (calls == 1) throw ApiException('Unavailable');
              return const PayslipCollection(total: 0, payslips: []);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No payslips have been published yet.'), findsOneWidget);
  });

  testWidgets('does not save a completed download after the token changes', (
    tester,
  ) async {
    final download = Completer<Uint8List>();
    var saved = false;
    Future<PayslipCollection> loader(String _) async => slips;
    Future<Uint8List> downloader(Payslip _, String _) => download.future;
    Future<String?> saver(Uint8List _, String _) async {
      saved = true;
      return 'saved';
    }

    Widget screen(String? token) => MaterialApp(
      home: Scaffold(
        body: PayslipScreen(
          token: token,
          loader: loader,
          downloader: downloader,
          saver: saver,
        ),
      ),
    );

    await tester.pumpWidget(screen('token'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save PDF').first);
    await tester.tap(find.text('Save PDF').first);
    await tester.pump();
    await tester.pumpWidget(screen(null));
    download.complete(Uint8List.fromList([37, 80, 68, 70, 45]));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(find.text('Sign in to view your payslips.'), findsOneWidget);
  });

  testWidgets('fits a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(token: 'token', loader: (_) async => slips),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('November 2026'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('views the selected PDF, supports back, and preserves save', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    String? requestedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(
            token: 'access-token',
            loader: (_) async => slips,
            downloader: (slip, token) {
              expect(token, 'access-token');
              requestedId = slip.id;
              return pending.future;
            },
            previewBuilder: (_, bytes) => Text('PDF bytes: ${bytes.length}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View PDF').first);
    await tester.tap(find.text('View PDF').first);
    await tester.pump();
    expect(requestedId, '58');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Payslip · SLIP-58'), findsOneWidget);
    pending.complete(Uint8List.fromList([37, 80, 68, 70, 45]));
    await tester.pumpAndSettle();
    expect(find.text('PDF bytes: 5'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to payslips'));
    await tester.pumpAndSettle();
    expect(find.text('Payslips & Salary Statements'), findsOneWidget);
    expect(find.text('Save PDF'), findsWidgets);
  });

  testWidgets('preview reports errors and retries', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayslipScreen(
            token: 'token',
            loader: (_) async => slips,
            downloader: (_, _) async {
              calls++;
              if (calls == 1) throw ApiException('PDF unavailable');
              return Uint8List.fromList([37, 80, 68, 70, 45]);
            },
            previewBuilder: (_, _) => const Text('Preview loaded'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View PDF').first);
    await tester.tap(find.text('View PDF').first);
    await tester.pumpAndSettle();
    expect(find.text('PDF unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Preview loaded'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Payslips & Salary Statements'), findsOneWidget);
  });

  testWidgets('closes preview and discards data when token changes', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    Future<PayslipCollection> loader(String _) async => slips;
    Future<Uint8List> downloader(Payslip _, String _) => pending.future;
    Widget screen(String? token) => MaterialApp(
      home: Scaffold(
        body: PayslipScreen(
          token: token,
          loader: loader,
          downloader: downloader,
          previewBuilder: (_, _) => const Text('Private PDF'),
        ),
      ),
    );
    await tester.pumpWidget(screen('token'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View PDF').first);
    await tester.tap(find.text('View PDF').first);
    await tester.pump();
    await tester.pumpWidget(screen(null));
    pending.complete(Uint8List.fromList([37, 80, 68, 70, 45]));
    await tester.pumpAndSettle();
    expect(find.text('Private PDF'), findsNothing);
    expect(find.text('Sign in to view your payslips.'), findsOneWidget);
  });
}
