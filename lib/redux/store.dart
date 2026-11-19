import 'package:redux/redux.dart';

import '../features/auth/redux/auth_middleware.dart';
import '../features/auth/redux/auth_reducer.dart';
import 'app_state.dart';

/// App-wide root reducer: delegates each slice of [AppState] to its own
/// feature reducer.
AppState appReducer(AppState state, dynamic action) {
  return state.copyWith(auth: authReducer(state.auth, action));
}

/// Creates the single Redux [Store] used by the whole app. Call this once
/// in `main.dart` and provide it via `StoreProvider`.
Store<AppState> createStore() {
  return Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [
      ...createAuthMiddleware<AppState>(),
    ],
  );
}
