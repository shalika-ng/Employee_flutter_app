import 'package:flutter/foundation.dart';

import '../features/attendance/redux/attendance_state.dart';
import '../features/auth/redux/auth_state.dart';
import '../features/requests/redux/request_state.dart';

/// Root Redux state for the whole app. Add more feature slices here
/// (e.g. `AttendanceState attendance`) as the app grows.
@immutable
class AppState {
  const AppState({
    required this.auth,
    this.attendance = const AttendanceState(),
    this.request = const RequestState(),
  });

  factory AppState.initial() => AppState(
        auth: AuthState.initial(),
        attendance: const AttendanceState(),
        request: const RequestState(),
      );

  final AuthState auth;
  final AttendanceState attendance;
  final RequestState request;

  AppState copyWith({
    AuthState? auth,
    AttendanceState? attendance,
    RequestState? request,
  }) {
    return AppState(
      auth: auth ?? this.auth,
      attendance: attendance ?? this.attendance,
      request: request ?? this.request,
    );
  }
}
