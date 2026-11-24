import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../core/utils/validators.dart';
import '../../../redux/app_state.dart';
import '../redux/auth_actions.dart';
import '../redux/auth_state.dart';

class AppColors {
  static const primaryBackground = Color(0xFFA5B8A4);
  static const cardBackground = Colors.white;
  static const darkText = Color(0xFF1E281D);
  static const bodyMutedText = Color(0xFF556553);
  static const inputFieldBg = Color(0xFFEBF1EA);
  static const inputBorderColor = Color(0xFFDCE5DA);
  static const inputLabelColor = Color(0xFF263324);
  static const placeholderText = Color(0xFF7E8F7C);
  static const ctaButtonBg = Color(0xFF213B26);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (StoreProvider.of<AppState>(context).state.auth.status ==
        AuthStatus.loading) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final usernameError = Validators.email(username);
    final passwordError = Validators.password(password);
    if (usernameError != null || passwordError != null) {
      _showSnack(context, usernameError ?? passwordError!);
      return;
    }

    if (!_agreedToTerms) {
      _showSnack(context, 'Please agree to the Terms & Conditions');
      return;
    }

    StoreProvider.of<AppState>(context)
        .dispatch(LoginSubmitAction(email: username, password: password));
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.ctaButtonBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: StoreConnector<AppState, AuthState>(
          converter: (store) => store.state.auth,
          onWillChange: (previous, current) {
            if (current.status == AuthStatus.failure &&
                current.errorMessage != null &&
                current.errorMessage != previous?.errorMessage) {
              _showSnack(context, current.errorMessage!);
            }
          },
          builder: (context, authState) {
            final isLoading = authState.status == AuthStatus.loading;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            semanticLabel: 'Nandgate logo',
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Your\nattendance.\nAll in one place.',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -1,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sign in to view your attendance and\nrecords.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: AppColors.bodyMutedText,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E2F20)
                                    .withValues(alpha: 0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use your organization account.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.bodyMutedText,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _fieldLabel('Email address'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _usernameController,
                                hint: 'name@organization.com',
                                icon: Icons.email_outlined,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              _fieldLabel('Password'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _passwordController,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                obscure: !_isPasswordVisible,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                onSubmitted: () => _submit(context),
                                suffix: IconButton(
                                  tooltip: _isPasswordVisible
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        }),
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.bodyMutedText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreedToTerms,
                                    activeColor: AppColors.ctaButtonBg,
                                    checkColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.bodyMutedText,
                                    ),
                                    onChanged: isLoading
                                        ? null
                                        : (value) => setState(() {
                                            _agreedToTerms = value ?? false;
                                          }),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'I agree with Terms & Conditions',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.bodyMutedText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _submit(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ctaButtonBg,
                                    disabledBackgroundColor: AppColors
                                        .ctaButtonBg
                                        .withValues(alpha: 0.6),
                                    elevation: 4,
                                    shadowColor: AppColors.ctaButtonBg
                                        .withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Sign in to portal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Center(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Need access? ',
                                    children: [
                                      TextSpan(
                                        text: 'Contact administrator',
                                        style: TextStyle(
                                          color: AppColors.darkText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.bodyMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'By continuing, you agree to our\n'
                            'Terms of Service  ·  Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.bodyMutedText,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.inputLabelColor,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputFieldBg,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.placeholderText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: AppColors.bodyMutedText, size: 21),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(AppColors.inputBorderColor),
        enabledBorder: border(AppColors.inputBorderColor),
        focusedBorder: border(AppColors.ctaButtonBg, width: 1.5),
        disabledBorder: border(AppColors.inputBorderColor),
      ),
    );
  }
}
