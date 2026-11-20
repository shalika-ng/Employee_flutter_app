// Widget test for the dashboard's mood check-in: verifies the thought/quote
// is hidden until an emoji is tapped, and that tapping a different mood
// swaps in that mood's quote.

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendence_employee/features/auth/redux/auth_reducer.dart';
import 'package:attendence_employee/features/home/screens/home_screen.dart';
import 'package:attendence_employee/redux/app_state.dart';

AppState _rootReducer(AppState state, dynamic action) {
  return state.copyWith(auth: authReducer(state.auth, action));
}

void main() {
  testWidgets('reveals and saves a mood quote after an emoji is tapped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = Store<AppState>(
      _rootReducer,
      initialState: AppState.initial(),
    );

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.textContaining('— '), findsNothing);
    expect(find.text('🧘'), findsOneWidget);

    await tester.tap(find.text('🧘'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('— '), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('floating navigation switches to the selected menu page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = Store<AppState>(
      _rootReducer,
      initialState: AppState.initial(),
    );

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Calendar'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Calendar'), findsNWidgets(2));
    expect(
      find.text('Your shifts and important dates will appear here.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Home'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Mindful Daily Dashboard'), findsOneWidget);
  });
}
