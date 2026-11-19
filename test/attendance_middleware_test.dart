import 'package:attendence_employee/core/storage/secure_storage_service.dart';
import 'package:attendence_employee/features/attendance/models/attendance_models.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_actions.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_middleware.dart';
import 'package:attendence_employee/features/attendance/redux/attendance_state.dart';
import 'package:attendence_employee/features/attendance/services/attendance_service.dart';
import 'package:attendence_employee/redux/app_state.dart';
import 'package:attendence_employee/redux/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

void main() {
  test(
    'attendance actions dispatch loaded monthly and day data into state',
    () async {
      final service = _FakeAttendanceService();
      final store = Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAttendanceMiddleware<AppState>(
          attendanceService: service,
          secureStorage: _MemoryStorage(),
        ),
      );

      final monthUpdated = store.onChange.firstWhere(
        (state) => state.attendance.monthStatus == AttendanceLoadStatus.success,
      );
      store.dispatch(const FetchAttendanceMonthAction(month: 8, year: 2026));
      final monthState = await monthUpdated;

      expect(monthState.attendance.monthData?.month, 8);
      expect(service.monthRequest, (
        month: 8,
        year: 2026,
        token: 'saved-token',
      ));

      final dayUpdated = store.onChange.firstWhere(
        (state) => state.attendance.dayStatus == AttendanceLoadStatus.success,
      );
      store.dispatch(const FetchAttendanceDayAction(date: '2026-08-17'));
      final dayState = await dayUpdated;

      expect(dayState.attendance.selectedDate, '2026-08-17');
      expect(dayState.attendance.dayData?.date, '2026-08-17');
      expect(service.dayRequest, (date: '2026-08-17', token: 'saved-token'));
    },
  );
}

class _FakeAttendanceService extends AttendanceService {
  ({int month, int year, String token})? monthRequest;
  ({String date, String token})? dayRequest;

  @override
  Future<AttendanceMonthData> getMyAttendance({
    required int month,
    required int year,
    required String token,
  }) async {
    monthRequest = (month: month, year: year, token: token);
    return _monthData;
  }

  @override
  Future<AttendanceDayData> getMyAttendanceDay({
    required String date,
    required String token,
  }) async {
    dayRequest = (date: date, token: token);
    return _dayData;
  }
}

class _MemoryStorage extends SecureStorageService {
  @override
  Future<String?> readToken() async => 'saved-token';
}

const _employee = AttendanceEmployee(
  id: '6',
  empCode: 'EMP003',
  name: 'Test Employee',
  designation: 'Software Engineer',
);

const _monthData = AttendanceMonthData(
  employee: _employee,
  month: 8,
  year: 2026,
  days: [],
  today: AttendanceToday(date: '2026-08-20', status: 'OUT', lastPunch: null),
  totals: AttendanceTotals(
    present: 0,
    half: 0,
    absent: 0,
    leave: 0,
    holiday: 0,
    weeklyOff: 0,
    insufficient: 0,
    lateCount: 0,
    workMinutes: 0,
  ),
);

const _dayData = AttendanceDayData(
  employee: _employee,
  date: '2026-08-17',
  summary: null,
  sessions: [],
  punches: [],
  breakGaps: [],
  flags: AttendanceFlags(
    needsRegularization: false,
    isLate: false,
    excessBreak: false,
    isLocked: false,
  ),
  permissions: [],
);
