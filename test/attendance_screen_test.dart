import 'package:attendence_employee/features/attendance/models/attendance_models.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_actions.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_state.dart';
import 'package:attendence_employee/features/attendance/screens/attendance_screen.dart';
import 'package:attendence_employee/redux/app_state.dart';
import 'package:attendence_employee/redux/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

void main() {
  testWidgets('opening a day shows its attendance details in a popup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final monthData = AttendanceMonthData(
      employee: _employee,
      month: 11,
      year: 2026,
      days: [_summary],
      today: const AttendanceToday(
        date: '2026-11-19',
        status: 'OUT',
        lastPunch: null,
      ),
      totals: const AttendanceTotals(
        present: 1,
        half: 0,
        absent: 0,
        leave: 0,
        holiday: 0,
        weeklyOff: 0,
        insufficient: 0,
        lateCount: 0,
        workMinutes: 480,
      ),
    );
    final store = Store<AppState>(
      appReducer,
      initialState: AppState.initial().copyWith(
        attendance: AttendanceState(
          monthStatus: AttendanceLoadStatus.success,
          monthData: monthData,
        ),
      ),
    );

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );

    expect(find.text('Apply regularization'), findsOneWidget);
    expect(find.text('Apply leave'), findsOneWidget);
    expect(find.text('Apply permission'), findsOneWidget);

    await tester.tap(find.text('Apply leave'));
    await tester.pump();
    expect(find.text('Punch log'), findsNothing);

    await tester.ensureVisible(find.text('PRESENT'));
    await tester.tap(find.text('PRESENT'));
    await tester.pump();
    store.dispatch(AttendanceDaySuccessAction(_dayData));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Punch log'), findsOneWidget);
    expect(find.text('LOP 0.50'), findsNWidgets(2));
    expect(find.text('Close'), findsOneWidget);
  });
}

const _employee = AttendanceEmployee(
  id: '6',
  empCode: 'EMP003',
  name: 'Test Employee',
  designation: 'Software Engineer',
);

final _summary = AttendanceDaySummary(
  id: '5',
  workDate: DateTime(2026, 11, 15),
  status: 'PRESENT',
  firstIn: DateTime(2026, 11, 15, 9),
  lastOut: DateTime(2026, 11, 15, 17),
  workMinutes: 480,
  breakMinutes: 30,
  permissionMinutes: 0,
  isLate: false,
  excessBreak: false,
  needsRegularization: true,
  lopValue: '0.50',
  isLocked: false,
);

final _dayData = AttendanceDayData(
  employee: _employee,
  date: '2026-11-15',
  summary: _summary,
  sessions: const [],
  punches: const [],
  breakGaps: const [],
  flags: const AttendanceFlags(
    needsRegularization: false,
    isLate: false,
    excessBreak: false,
    isLocked: false,
  ),
  permissions: const [],
);
