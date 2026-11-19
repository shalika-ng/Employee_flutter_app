import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

enum AuthStatus { restoring, unauthenticated, loading, authenticated, failure }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.restoring,
    this.user,
    this.token,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState();

  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && token != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user?.id == other.user?.id &&
          token == other.token &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, user?.id, token, errorMessage);
}
