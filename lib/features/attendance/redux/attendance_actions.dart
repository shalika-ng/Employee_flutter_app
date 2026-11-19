import '../models/attendance_models.dart';

class FetchAttendanceMonthAction {
  const FetchAttendanceMonthAction({required this.month, required this.year});

  final int month;
  final int year;
}

class AttendanceMonthSuccessAction {
  const AttendanceMonthSuccessAction(this.data);

  final AttendanceMonthData data;
}

class AttendanceMonthFailureAction {
  const AttendanceMonthFailureAction(this.message);

  final String message;
}

class FetchAttendanceDayAction {
  const FetchAttendanceDayAction({required this.date});

  final String date;
}

class AttendanceDaySuccessAction {
  const AttendanceDaySuccessAction(this.data);

  final AttendanceDayData data;
}

class AttendanceDayFailureAction {
  const AttendanceDayFailureAction(this.message);

  final String message;
}
