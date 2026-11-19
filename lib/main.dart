import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'app/app.dart';
import 'features/auth/redux/auth_actions.dart';
import 'redux/app_state.dart';
import 'redux/store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final store = createStore();
  store.dispatch(RestoreSessionAction());

  runApp(StoreProvider<AppState>(store: store, child: const App()));
}
