import 'dart:convert';

import 'package:attendence_employee/core/network/api_client.dart';
import 'package:attendence_employee/core/storage/secure_storage_service.dart';
import 'package:attendence_employee/features/auth/models/user_model.dart';
import 'package:attendence_employee/features/auth/redux/auth_actions.dart';
import 'package:attendence_employee/features/auth/redux/auth_reducer.dart';
import 'package:attendence_employee/features/auth/redux/auth_state.dart';
import 'package:attendence_employee/features/auth/redux/auth_middleware.dart';
import 'package:attendence_employee/features/auth/services/auth_service.dart';
import 'package:attendence_employee/features/home/screens/home_screen.dart';
import 'package:attendence_employee/redux/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

void main() {
  test(
    'restores a session with an unexpired access token without refreshing',
    () async {
      final storage = _MemorySecureStorage(
        token: _token(expiry: _futureExpiry),
        refreshToken: 'refresh-token',
        userData: jsonEncode(_user.toJson()),
      );
      final service = _FakeAuthService();
      final store = _createStore(storage, service);

      store.dispatch(RestoreSessionAction());
      await Future<void>.delayed(Duration.zero);

      expect(store.state.auth.status, AuthStatus.authenticated);
      expect(store.state.auth.token, storage.token);
      expect(store.state.auth.user?.id, _user.id);
      expect(service.refreshCalls, 0);
    },
  );

  test('refreshes an expired access token and restores the session', () async {
    final storage = _MemorySecureStorage(
      token: _token(expiry: _pastExpiry),
      refreshToken: 'refresh-token',
      userData: jsonEncode(_user.toJson()),
    );
    final service = _FakeAuthService(
      refreshResult: RefreshResult(token: 'new-access-token', expiresIn: 3600),
    );
    final store = _createStore(storage, service);

    store.dispatch(RestoreSessionAction());
    await Future<void>.delayed(Duration.zero);

    expect(store.state.auth.status, AuthStatus.authenticated);
    expect(store.state.auth.token, 'new-access-token');
    expect(storage.token, 'new-access-token');
    expect(service.refreshCalls, 1);
  });

  test(
    'logout clears stored credentials and returns to unauthenticated state',
    () async {
      final storage = _MemorySecureStorage(
        token: 'access-token',
        refreshToken: 'refresh-token',
        userData: jsonEncode(_user.toJson()),
      );
      final store = _createStore(storage, _FakeAuthService());

      store.dispatch(
        RestoreSessionSuccessAction(user: _user, token: 'access-token'),
      );
      store.dispatch(LogoutAction());
      await Future<void>.delayed(Duration.zero);

      expect(store.state.auth.status, AuthStatus.unauthenticated);
      expect(storage.token, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.userData, isNull);
    },
  );

  testWidgets('dashboard logout button clears credentials and logs out', (
    tester,
  ) async {
    final storage = _MemorySecureStorage(
      token: 'access-token',
      refreshToken: 'refresh-token',
      userData: jsonEncode(_user.toJson()),
    );
    final store = _createStore(storage, _FakeAuthService());
    store.dispatch(
      RestoreSessionSuccessAction(user: _user, token: 'access-token'),
    );

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(store.state.auth.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
    expect(storage.refreshToken, isNull);
    expect(storage.userData, isNull);
  });
}

Store<AppState> _createStore(
  _MemorySecureStorage storage,
  _FakeAuthService service,
) {
  return Store<AppState>(
    (state, action) => state.copyWith(auth: authReducer(state.auth, action)),
    initialState: AppState.initial(),
    middleware: createAuthMiddleware<AppState>(
      authService: service,
      secureStorage: storage,
    ),
  );
}

const _user = UserModel(
  id: 'employee-1',
  empCode: 'EMP001',
  name: 'Test Employee',
  email: 'employee@example.com',
  phone: '1234567890',
  role: 'EMPLOYEE',
  designation: 'Employee',
  status: 'active',
);

final _futureExpiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
final _pastExpiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;

String _token({required int expiry}) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'id': _user.id, 'exp': expiry})),
  );
  return 'header.${base64Url.normalize(payload)}.signature';
}

class _MemorySecureStorage extends SecureStorageService {
  _MemorySecureStorage({this.token, this.refreshToken, this.userData});

  String? token;
  String? refreshToken;
  String? userData;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<String?> readUserData() async => userData;

  @override
  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    this.token = token;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUserData(String userData) async {
    this.userData = userData;
  }

  @override
  Future<void> clear() async {
    token = null;
    refreshToken = null;
    userData = null;
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.refreshResult});

  final RefreshResult? refreshResult;
  int refreshCalls = 0;

  @override
  Future<RefreshResult> refresh({required String refreshToken}) async {
    refreshCalls++;
    return refreshResult ??
        (throw ApiException('Invalid refresh token.', statusCode: 401));
  }
}
