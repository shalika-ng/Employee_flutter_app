import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:attendence_employee/features/auth/redux/auth_actions.dart';
import 'package:attendence_employee/features/auth/redux/auth_reducer.dart';
import 'package:attendence_employee/features/auth/redux/auth_state.dart';
import 'package:attendence_employee/features/auth/screens/login_screen.dart';
import 'package:attendence_employee/redux/app_state.dart';

AppState _rootReducer(AppState state, dynamic action) {
  return state.copyWith(auth: authReducer(state.auth, action));
}

Widget _buildTestable(Store<AppState> store) {
  return StoreProvider<AppState>(
    store: store,
    child: const MaterialApp(home: LoginScreen()),
  );
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.text('Sign in to portal');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('validates email, password and agreement', (tester) async {
    final store = Store<AppState>(
      _rootReducer,
      initialState: AppState.initial(),
    );
    await tester.pumpWidget(_buildTestable(store));

    expect(find.text('Sub ID / Workspace'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    final logo = tester.widget<Image>(find.byType(Image));
    expect(logo.image, isA<AssetImage>());
    expect((logo.image as AssetImage).assetName, 'assets/images/logo.png');

    await _submit(tester);
    expect(find.text('Email is required'), findsOneWidget);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.pump();
    await _submit(tester);
    expect(find.text('Password is required'), findsOneWidget);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await _submit(tester);
    expect(find.text('Please agree to the Terms & Conditions'), findsOneWidget);
    expect(store.state.auth.status, isNot(AuthStatus.loading));
  });

  testWidgets(
    'dispatches existing login action and disables form while loading',
    (tester) async {
      LoginSubmitAction? submitted;
      final store = Store<AppState>(
        _rootReducer,
        initialState: AppState.initial(),
        middleware: [
          (store, action, next) {
            if (action is LoginSubmitAction) submitted = action;
            next(action);
          },
        ],
      );
      await tester.pumpWidget(_buildTestable(store));
      await tester.enterText(
        find.byType(TextField).at(0),
        ' test@example.com ',
      );
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await _submit(tester);

      expect(submitted?.email, 'test@example.com');
      expect(submitted?.password, 'password');
      expect(store.state.auth.status, AuthStatus.loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.enabled, isFalse);
      }
    },
  );

  testWidgets('shows Redux errors and toggles password visibility', (
    tester,
  ) async {
    final store = Store<AppState>(
      _rootReducer,
      initialState: AppState.initial(),
    );
    await tester.pumpWidget(_buildTestable(store));
    final password = find.byType(TextField).at(1);
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);

    store.dispatch(LoginFailureAction('Invalid credentials'));
    await tester.pump();
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('form remains reachable on a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store<AppState>(
      _rootReducer,
      initialState: AppState.initial(),
    );
    await tester.pumpWidget(_buildTestable(store));
    await _submit(tester);
    expect(find.text('Email is required'), findsOneWidget);
  });
}
