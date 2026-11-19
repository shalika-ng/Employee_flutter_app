import 'package:flutter/foundation.dart';

import '../features/auth/redux/auth_state.dart';

/// Root Redux state for the whole app. Add more feature slices here
/// (e.g. `AttendanceState attendance`) as the app grows.
@immutable
class AppState {
  const AppState({required this.auth});

  factory AppState.initial() => AppState(auth: AuthState.initial());

  final AuthState auth;

  AppState copyWith({AuthState? auth}) {
    return AppState(auth: auth ?? this.auth);
  }
}
