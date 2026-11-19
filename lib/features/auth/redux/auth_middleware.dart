import 'dart:convert';

import 'package:redux/redux.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_actions.dart';

/// Bridges Redux actions to the async [AuthService] call, then dispatches
/// the resulting success/failure action and persists the token.
///
/// Registered on the store in `redux/store.dart`.
List<Middleware<State>> createAuthMiddleware<State>({
  AuthService? authService,
  SecureStorageService? secureStorage,
}) {
  final service = authService ?? AuthService();
  final storage = secureStorage ?? SecureStorageService();

  Future<void> handleLogin(
    Store<State> store,
    LoginSubmitAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      final result = await service.login(
        email: action.email,
        password: action.password,
      );
      await storage.saveTokens(
        token: result.token,
        refreshToken: result.refreshToken,
      );
      await storage.saveUserData(jsonEncode(result.user.toJson()));
      store.dispatch(
        LoginSuccessAction(user: result.user, token: result.token),
      );
    } on ApiException catch (e) {
      store.dispatch(LoginFailureAction(e.message));
    } catch (_) {
      store.dispatch(
        LoginFailureAction('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> handleRestoreSession(
    Store<State> store,
    RestoreSessionAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      final token = await storage.readToken();
      final refreshToken = await storage.readRefreshToken();
      final user = _readStoredUser(await storage.readUserData(), token);

      if (user == null) {
        await storage.clear();
        store.dispatch(RestoreSessionFailureAction());
        return;
      }

      if (token != null && _isTokenValid(token)) {
        store.dispatch(RestoreSessionSuccessAction(user: user, token: token));
        return;
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        await storage.clear();
        store.dispatch(RestoreSessionFailureAction());
        return;
      }

      final result = await service.refresh(refreshToken: refreshToken);
      await storage.saveTokens(token: result.token, refreshToken: refreshToken);
      store.dispatch(
        RestoreSessionSuccessAction(user: user, token: result.token),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 403) {
        await storage.clear();
      }
      store.dispatch(RestoreSessionFailureAction());
    } catch (_) {
      store.dispatch(RestoreSessionFailureAction());
    }
  }

  Future<void> handleRefreshToken(
    Store<State> store,
    RefreshTokenAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      final refreshToken = await storage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw ApiException('Refresh token is required.', statusCode: 400);
      }

      final result = await service.refresh(refreshToken: refreshToken);
      await storage.saveTokens(token: result.token, refreshToken: refreshToken);
      store.dispatch(RefreshTokenSuccessAction(token: result.token));
    } on ApiException catch (e) {
      store.dispatch(RefreshTokenFailureAction(e.message));
    } catch (_) {
      store.dispatch(
        RefreshTokenFailureAction('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> handleRegisterFcmToken(
    Store<State> store,
    RegisterFcmTokenAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      await service.registerFcmToken(
        token: action.token,
        accessToken: await storage.readToken(),
      );
      store.dispatch(FcmTokenRegisteredAction());
    } on ApiException catch (e) {
      store.dispatch(FcmTokenRegistrationFailureAction(e.message));
    } catch (_) {
      store.dispatch(
        FcmTokenRegistrationFailureAction(
          'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> handleLogout(
    Store<State> store,
    LogoutAction action,
    NextDispatcher next,
  ) async {
    await storage.clear();
    next(action);
  }

  return [
    TypedMiddleware<State, LoginSubmitAction>(handleLogin).call,
    TypedMiddleware<State, RestoreSessionAction>(handleRestoreSession).call,
    TypedMiddleware<State, RefreshTokenAction>(handleRefreshToken).call,
    TypedMiddleware<State, RegisterFcmTokenAction>(handleRegisterFcmToken).call,
    TypedMiddleware<State, LogoutAction>(handleLogout).call,
  ];
}

UserModel? _readStoredUser(String? userData, String? token) {
  if (userData != null) {
    try {
      final decoded = jsonDecode(userData);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromJson(decoded);
      }
    } on FormatException {
      // Older installs may have tokens without a persisted profile.
    }
  }

  final claims = _decodeTokenPayload(token);
  if (claims == null || claims['id'] == null) return null;
  return UserModel.fromJson(claims);
}

bool _isTokenValid(String token) {
  final claims = _decodeTokenPayload(token);
  final expiry = int.tryParse(claims?['exp']?.toString() ?? '');
  if (expiry == null) return false;
  return expiry > DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

Map<String, dynamic>? _decodeTokenPayload(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}
