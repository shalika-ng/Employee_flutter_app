import 'package:flutter/foundation.dart';

import '../features/attendance/redux/attendance_state.dart';
import '../features/auth/redux/auth_state.dart';

/// Root Redux state for the whole app. Add more feature slices here
/// (e.g. `AttendanceState attendance`) as the app grows.
@immutable
class AppState {
  const AppState({
    required this.auth,
    this.attendance = const AttendanceState(),
  });

  factory AppState.initial() =>
      AppState(auth: AuthState.initial(), attendance: const AttendanceState());

  final AuthState auth;
  final AttendanceState attendance;

  AppState copyWith({AuthState? auth, AttendanceState? attendance}) {
    return AppState(
      auth: auth ?? this.auth,
      attendance: attendance ?? this.attendance,
    );
  }
}
