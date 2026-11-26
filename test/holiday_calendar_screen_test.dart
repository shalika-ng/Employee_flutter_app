import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/features/calendar/models/calendar_model.dart';
import 'package:attendence_employee/features/calendar/screens/holiday_calendar_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

EmployeeCalendar calendar(int month, int year) => EmployeeCalendar(
  month: month,
  year: year,
  days: [
    CalendarDay(
      date: '$year-${month.toString().padLeft(2, '0')}-09',
      attendanceStatus: 'HOLIDAY',
      events: const [
        CalendarEvent(
          type: 'COMMON_HOLIDAY',
          name: 'Diwali',
          date: '2026-11-09',
        ),
      ],
    ),
    CalendarDay(
      date: '$year-${month.toString().padLeft(2, '0')}-11',
      attendanceStatus: 'WEEKLY_OFF',
      events: const [
        CalendarEvent(
          type: 'PENDING_LEAVE',
          fromDate: '2026-11-11',
          toDate: '2026-11-12',
          days: 2,
        ),
      ],
    ),
  ],
  events: month == 11
      ? const [
          CalendarEvent(
            type: 'COMMON_HOLIDAY',
            name: 'Diwali',
            date: '2026-11-09',
          ),
          CalendarEvent(
            type: 'EMPLOYEE_HOLIDAY',
            name: 'Paid Off',
            date: '2026-11-27',
          ),
        ]
      : const [],
);

void main() {
  testWidgets('shows selected day, holiday list and changes month', (
    tester,
  ) async {
    final requests = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidayCalendarScreen(
            token: 'token',
            initialDate: DateTime(2026, 11, 9),
            loader: (month, year, token) async {
              requests.add('$year-$month');
              return calendar(month, year);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Attendance: holiday'), findsOneWidget);
    expect(find.text('2 holidays'), findsOneWidget);
    expect(find.text('Diwali'), findsWidgets);

    await tester.tap(
      find.bySemanticsLabel(RegExp('Wednesday, November 11, 2026')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Attendance: weekly off'), findsOneWidget);
    expect(find.textContaining('2 day(s)'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(requests, ['2026-11', '2026-12']);
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.text('No holidays listed.'), findsOneWidget);
  });

  testWidgets('shows error and retries the selected month', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidayCalendarScreen(
            token: 'token',
            initialDate: DateTime(2026, 11, 9),
            loader: (month, year, token) async {
              calls++;
              if (calls == 1) throw ApiException('Calendar unavailable');
              return calendar(month, year);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Calendar unavailable'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('2 holidays'), findsOneWidget);
  });
}
