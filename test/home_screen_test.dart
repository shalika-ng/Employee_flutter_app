// Widget test for the dashboard's mood check-in: verifies the thought/quote
// is hidden until an emoji is tapped, and that tapping a different mood
// swaps in that mood's quote.

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:attendence_employee/features/auth/redux/auth_reducer.dart';
import 'package:attendence_employee/features/home/screens/home_screen.dart';
import 'package:attendence_employee/redux/app_state.dart';

AppState _rootReducer(AppState state, dynamic action) {
  return state.copyWith(auth: authReducer(state.auth, action));
}

void main() {
  testWidgets('reveals the mood quote only after an emoji is tapped',
      (tester) async {
    final store = Store<AppState>(_rootReducer, initialState: AppState.initial());

    await tester.pumpWidget(
      StoreProvider<AppState>(
        store: store,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // No quote shown yet.
    expect(find.textContaining('Steady steps today'), findsNothing);

    await tester.tap(find.text('🧘'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Steady steps today'), findsOneWidget);

    // Tapping a different mood swaps the quote.
    await tester.tap(find.text('✨'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Steady steps today'), findsNothing);
    expect(find.textContaining('light up someone else'), findsOneWidget);
  });
}
