// Widget test for the branded Redux-backed login screen: verifies the
// circular submit button validates the form via a SnackBar before
// dispatching, and that a failed login surfaces the Redux error message
// via a SnackBar as well.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:attendence_employee/features/auth/redux/auth_actions.dart';
import 'package:attendence_employee/features/auth/redux/auth_reducer.dart';
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

void main() {
  testWidgets('shows a validation message when submitting an empty form',
      (tester) async {
    final store = Store<AppState>(_rootReducer, initialState: AppState.initial());

    await tester.pumpWidget(_buildTestable(store));
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();

    expect(find.text('Please enter Sub ID / Workspace'), findsOneWidget);
  });

  testWidgets('displays the auth error message from Redux state via SnackBar',
      (tester) async {
    final store = Store<AppState>(_rootReducer, initialState: AppState.initial());

    await tester.pumpWidget(_buildTestable(store));

    store.dispatch(LoginFailureAction('Invalid credentials'));
    await tester.pump();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
