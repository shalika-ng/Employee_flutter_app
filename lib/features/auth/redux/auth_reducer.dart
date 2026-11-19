import 'auth_actions.dart';
import 'auth_state.dart';

/// Pure reducer: given the current [AuthState] and an action, returns the
/// next state. No side effects (API calls) happen here — see
/// `auth_middleware.dart` for that.
AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginSubmitAction) {
    return state.copyWith(status: AuthStatus.loading, errorMessage: null);
  }

  if (action is LoginSuccessAction) {
    return state.copyWith(
      status: AuthStatus.authenticated,
      user: action.user,
      token: action.token,
      errorMessage: null,
    );
  }

  if (action is RestoreSessionSuccessAction) {
    return state.copyWith(
      status: AuthStatus.authenticated,
      user: action.user,
      token: action.token,
      errorMessage: null,
    );
  }

  if (action is RestoreSessionFailureAction) {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  if (action is RefreshTokenSuccessAction) {
    return state.copyWith(token: action.token, errorMessage: null);
  }

  if (action is RefreshTokenFailureAction) {
    return state.copyWith(errorMessage: action.errorMessage);
  }

  if (action is FcmTokenRegisteredAction) {
    return state.copyWith(errorMessage: null);
  }

  if (action is FcmTokenRegistrationFailureAction) {
    return state.copyWith(errorMessage: action.errorMessage);
  }

  if (action is LoginFailureAction) {
    return state.copyWith(
      status: AuthStatus.failure,
      errorMessage: action.errorMessage,
    );
  }

  if (action is ClearAuthErrorAction) {
    return state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  if (action is LogoutAction) {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  return state;
}
