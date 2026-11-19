import '../models/user_model.dart';

/// All Redux actions for the auth feature.
///
/// Flow: [LoginSubmitAction] -> middleware calls [AuthService] ->
/// dispatches [LoginSuccessAction] or [LoginFailureAction].
class LoginSubmitAction {
  LoginSubmitAction({required this.email, required this.password});

  final String email;
  final String password;
}

class LoginSuccessAction {
  LoginSuccessAction({required this.user, required this.token});

  final UserModel user;
  final String token;
}

class LoginFailureAction {
  LoginFailureAction(this.errorMessage);

  final String errorMessage;
}

class RestoreSessionAction {}

class RestoreSessionSuccessAction {
  RestoreSessionSuccessAction({required this.user, required this.token});

  final UserModel user;
  final String token;
}

class RestoreSessionFailureAction {}

class RefreshTokenAction {}

class RefreshTokenSuccessAction {
  RefreshTokenSuccessAction({required this.token});

  final String token;
}

class RefreshTokenFailureAction {
  RefreshTokenFailureAction(this.errorMessage);

  final String errorMessage;
}

class RegisterFcmTokenAction {
  RegisterFcmTokenAction({required this.token});

  final String token;
}

class FcmTokenRegisteredAction {}

class FcmTokenRegistrationFailureAction {
  FcmTokenRegistrationFailureAction(this.errorMessage);

  final String errorMessage;
}

/// Dispatched by the login screen to clear a previous error once the user
/// starts editing the form again.
class ClearAuthErrorAction {}

class LogoutAction {}
