import 'package:attendence_employee/features/attendance/models/attendance_models.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_actions.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_state.dart';
import 'package:attendence_employee/features/attendance/screens/attendance_screen.dart';
import 'package:attendence_employee/app/theme/app_theme.dart';
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

    final store = _createStore();

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );

    final heading = tester.widget<Text>(find.text('Attendance'));
    expect(heading.style?.fontFamily, HomeTheme.fontFamily);
    expect(heading.style?.fontSize, 16);
    expect(heading.style?.color, HomeTheme.primaryText);
    expect(find.text('Apply regularization'), findsOneWidget);
    expect(find.text('Apply leave'), findsOneWidget);
    expect(find.text('Apply permission'), findsOneWidget);

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

  const requestForms = [
    ('Apply leave', 'New Leave Request', 'Leave dates'),
    ('Apply permission', 'New Permission Request', 'Permission date'),
    (
      'Apply regularization',
      'Attendance Regularization',
      'Correct attendance time',
    ),
  ];
  for (final (action, title, section) in requestForms) {
    testWidgets('$action opens its form', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_attendanceApp(_createStore()));

      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final titleWidget = tester.widget<Text>(find.text(title));
      expect(appBar.backgroundColor, HomeTheme.heroGradientStart);
      expect(titleWidget.style?.fontFamily, HomeTheme.fontFamily);
      expect(titleWidget.style?.fontSize, 16);
      expect(titleWidget.style?.fontWeight, FontWeight.w800);
      expect(find.text(title), findsOneWidget);
      expect(find.text(section), findsOneWidget);
    });
  }

  testWidgets('request form retains navigation to the other app sections', (
    tester,
  ) async {
    _setTestViewport(tester);
    final navigatorKey = GlobalKey<NavigatorState>();
    var selectedIndex = 1;

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: _createStore(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: AttendanceScreen(
            onNavigate: (index) {
              navigatorKey.currentState!.popUntil((route) => route.isFirst);
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Apply leave'));
    await tester.tap(find.text('Apply leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Leave Request'), findsOneWidget);
    expect(find.byTooltip('Calendar'), findsOneWidget);
    await tester.tap(find.byTooltip('Calendar'));

    expect(selectedIndex, 3);
    expect(navigatorKey.currentState!.canPop(), isFalse);
  });
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Store<AppState> _createStore() {
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
  return Store<AppState>(
    appReducer,
    initialState: AppState.initial().copyWith(
      attendance: AttendanceState(
        monthStatus: AttendanceLoadStatus.success,
        monthData: monthData,
      ),
    ),
  );
}

Widget _attendanceApp(Store<AppState> store) {
  return StoreProvider<AppState>(
    store: store,
    child: const MaterialApp(home: AttendanceScreen()),
  );
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
