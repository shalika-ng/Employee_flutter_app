import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../features/auth/redux/auth_state.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../redux/app_state.dart';
import 'theme/app_theme.dart';

/// Root widget. Decides whether to show the login screen or the home
/// screen based on the current auth status in the Redux store.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StoreConnector<AppState, AuthStatus>(
        converter: (store) => store.state.auth.status,
        builder: (context, status) {
          if (status == AuthStatus.restoring) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return status == AuthStatus.authenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
