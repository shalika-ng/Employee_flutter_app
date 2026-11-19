import 'attendance_actions.dart';
import 'attendance_state.dart';
import '../../auth/redux/auth_actions.dart';

AttendanceState attendanceReducer(AttendanceState state, dynamic action) {
  if (action is LogoutAction) return const AttendanceState();

  if (action is FetchAttendanceMonthAction) {
    return state.copyWith(
      monthStatus: AttendanceLoadStatus.loading,
      clearMonthError: true,
    );
  }

  if (action is AttendanceMonthSuccessAction) {
    return state.copyWith(
      monthStatus: AttendanceLoadStatus.success,
      monthData: action.data,
      clearMonthError: true,
    );
  }

  if (action is AttendanceMonthFailureAction) {
    return state.copyWith(
      monthStatus: AttendanceLoadStatus.failure,
      monthError: action.message,
    );
  }

  if (action is FetchAttendanceDayAction) {
    return state.copyWith(
      dayStatus: AttendanceLoadStatus.loading,
      selectedDate: action.date,
      clearDayData: true,
      clearDayError: true,
    );
  }

  if (action is AttendanceDaySuccessAction) {
    return state.copyWith(
      dayStatus: AttendanceLoadStatus.success,
      dayData: action.data,
      clearDayError: true,
    );
  }

  if (action is AttendanceDayFailureAction) {
    return state.copyWith(
      dayStatus: AttendanceLoadStatus.failure,
      dayError: action.message,
    );
  }

  return state;
}
