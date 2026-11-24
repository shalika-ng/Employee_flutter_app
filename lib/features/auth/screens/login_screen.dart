import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';


import '../../../core/utils/validators.dart';
import '../../../redux/app_state.dart';
import '../redux/auth_actions.dart';
import '../redux/auth_state.dart';


/// ---------- COLOURS (taken from your design) ----------
class AppColors {
 static const navy = Color(0xFF1B2A41); // text, icons, button
 static const buttonDark = Color(0xFF1E293B); // arrow button
 static const accent = Color(0xFF1F5A7A); // decorative line icons
 static const hint = Color(0xFF6B7280); // hint text
 static const bgTop = Color(0xFFE6F0F9);
 static const bgBottom = Color(0xFF9DC3E0);
 static const gridLine = Color(0xFF4A6785);
}


class LoginScreen extends StatefulWidget {
 const LoginScreen({super.key});


 @override
 State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
 // Controllers
 final _subIdController = TextEditingController();
 final _usernameController = TextEditingController();
 final _passwordController = TextEditingController();


 // State
 bool _isPasswordVisible = false;
 bool _agreedToTerms = true;


 @override
 void dispose() {
   _subIdController.dispose();
   _usernameController.dispose();
   _passwordController.dispose();
   super.dispose();
 }


 void _submit(BuildContext context) {
   final subId = _subIdController.text.trim();
   final username = _usernameController.text.trim();
   final password = _passwordController.text;


   // Basic validation
   if (subId.isEmpty) {
     _showSnack(context, 'Please enter Sub ID / Workspace');
     return;
   }


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


   // Dispatch to Redux
   StoreProvider.of<AppState>(context).dispatch(
     LoginSubmitAction(
       email: username,
       password: password,
     ),
   );
 }


 void _showSnack(BuildContext context, String message) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(message),
       backgroundColor: AppColors.navy,
       behavior: SnackBarBehavior.floating,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
     ),
   );
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     resizeToAvoidBottomInset: false,
     backgroundColor: Colors.white,
     body: StoreConnector<AppState, AuthState>(
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


         return LayoutBuilder(
           builder: (context, c) {
             final w = c.maxWidth;
             final h = c.maxHeight;
             // Adjusted wave slightly lower to make room for the lower form
             final waveTop = h * 0.73;


             return Stack(
               children: [
                 // 1. Blue gradient background
                 Positioned.fill(
                   child: Container(
                     decoration: const BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [AppColors.bgTop, AppColors.bgBottom],
                       ),
                     ),
                   ),
                 ),


                 // 2. Dashed grid
                 Positioned.fill(
                   child: CustomPaint(painter: _GridPainter()),
                 ),


                 // 3. Decorative line icons (half cut off at screen edges)
                 Positioned(
                   left: -28,
                   top: h * 0.20,
                   child: _deco(Icons.event_available_outlined, 110),
                 ),
                 Positioned(
                   right: -40,
                   top: h * 0.03,
                   child: _deco(Icons.schedule_outlined, 150),
                 ),
                 Positioned(
                   left: -8,
                   top: h * 0.54,
                   child: _deco(Icons.badge_outlined, 110),
                 ),
                 Positioned(
                   right: -6,
                   top: h * 0.57,
                   child: _deco(Icons.phone_android_outlined, 100),
                 ),


                 // 4. White wave at the bottom
                 Positioned.fill(
                   child: CustomPaint(painter: _WavePainter(waveTop: waveTop)),
                 ),


                 // 5. Logo card
                 Positioned(
                   top: h * 0.16,
                   left: w * 0.18,
                   right: w * 0.12,
                   child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.55),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Image.asset(
                       'assets/images/logo.png',
                       height: h * 0.20,
                       fit: BoxFit.contain,
                       errorBuilder: (_, _, _) => SizedBox(
                         height: h * 0.20,
                         child: const Center(
                           child: Text(
                             'NANDGATE',
                             style: TextStyle(
                               fontSize: 28,
                               letterSpacing: 4,
                               fontWeight: FontWeight.w700,
                               color: AppColors.navy,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),


                 // 6. Input fields
                 Positioned(
                   top: h * 0.43,
                   left: w * 0.11,
                   right: w * 0.11,
                   child: Column(
                     children: [
                       _pillField(
                         controller: _subIdController,
                         hint: 'Sub ID / Workspace Name',
                         icon: Icons.work_outline,
                         enabled: !isLoading,
                         textInputAction: TextInputAction.next,
                       ),
                       const SizedBox(height: 16),
                       _pillField(
                         controller: _usernameController,
                         hint: 'Username / Email',
                         icon: Icons.person_outline,
                         enabled: !isLoading,
                         keyboardType: TextInputType.emailAddress,
                         textInputAction: TextInputAction.next,
                       ),
                       const SizedBox(height: 16),
                       _pillField(
                         controller: _passwordController,
                         hint: 'Password',
                         icon: Icons.lock_outline,
                         obscure: !_isPasswordVisible,
                         enabled: !isLoading,
                         textInputAction: TextInputAction.done,
                         onSubmitted: () => _submit(context),
                         suffix: IconButton(
                           icon: Icon(
                             _isPasswordVisible
                                 ? Icons.visibility_outlined
                                 : Icons.visibility_off_outlined,
                             color: Colors.grey.shade500,
                             size: 22,
                           ),
                           onPressed: isLoading
                               ? null
                               : () => setState(() => _isPasswordVisible =
                                   !_isPasswordVisible),
                         ),
                       ),
                     ],
                   ),
                 ),


                 // 7. Round arrow button
                 Positioned(
                   top: h * 0.68,
                   left: 0,
                   right: 0,
                   child: Center(
                     child: GestureDetector(
                       onTap: isLoading ? null : () => _submit(context),
                       child: AnimatedContainer(
                         duration: const Duration(milliseconds: 200),
                         width: 60,
                         height: 60,
                         decoration: BoxDecoration(
                           color: AppColors.buttonDark,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withValues(alpha: 0.25),
                               blurRadius: 12,
                               offset: const Offset(0, 5),
                             ),
                           ],
                         ),
                         child: Center(
                           child: isLoading
                               ? const SizedBox(
                                   width: 24,
                                   height: 24,
                                   child: CircularProgressIndicator(
                                     strokeWidth: 2.5,
                                     valueColor: AlwaysStoppedAnimation<Color>(
                                         Colors.white),
                                   ),
                                 )
                               : const Icon(
                                   Icons.arrow_forward,
                                   color: Colors.white,
                                   size: 26,
                                 ),
                         ),
                       ),
                     ),
                   ),
                 ),


                 // 8. Terms & footer
                 Positioned(
                   bottom: h * 0.10,
                   left: 0,
                   right: 0,
                   child: Column(
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           GestureDetector(
                             onTap: isLoading
                                 ? null
                                 : () => setState(
                                     () => _agreedToTerms = !_agreedToTerms),
                             child: Container(
                               width: 20,
                               height: 20,
                               decoration: BoxDecoration(
                                 color: _agreedToTerms
                                     ? AppColors.navy
                                     : Colors.white,
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(
                                     color: AppColors.navy, width: 1.5),
                               ),
                               child: _agreedToTerms
                                   ? const Icon(Icons.check,
                                       size: 15, color: Colors.white)
                                   : null,
                             ),
                           ),
                           const SizedBox(width: 10),
                           const Text(
                             'I agree with Terms & Conditions!',
                             style: TextStyle(
                               fontSize: 13,
                               color: AppColors.navy,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 22),
                       const Text(
                         'POWERED BY NANDGATE-IT',
                         style: TextStyle(
                           fontSize: 11,
                           letterSpacing: 1.6,
                           fontWeight: FontWeight.w700,
                           color: AppColors.hint,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             );
           },
         );
       },
     ),
   );
 }


 // ---------- Helpers ----------


 Widget _deco(IconData icon, double size) => Icon(
       icon,
       size: size,
       color: AppColors.accent.withValues(alpha: 0.85),
     );


 Widget _pillField({
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
   return Container(
     height: 56,
     decoration: BoxDecoration(
       color: Colors.white,
       borderRadius: BorderRadius.circular(30),
       boxShadow: [
         BoxShadow(
           color: Colors.black.withValues(alpha: 0.05),
           blurRadius: 10,
           offset: const Offset(0, 3),
         ),
       ],
     ),
     child: TextField(
       controller: controller,
       obscureText: obscure,
       enabled: enabled,
       keyboardType: keyboardType,
       textInputAction: textInputAction,
       onSubmitted: (_) => onSubmitted?.call(),
       style: const TextStyle(fontSize: 15, color: AppColors.navy),
       decoration: InputDecoration(
         hintText: hint,
         hintStyle: const TextStyle(fontSize: 15, color: AppColors.hint),
         prefixIcon: Icon(icon, color: AppColors.navy, size: 22),
         suffixIcon: suffix,
         border: InputBorder.none,
         contentPadding: const EdgeInsets.symmetric(vertical: 17),
       ),
     ),
   );
 }
}


/// Dashed grid lines over the blue background
class _GridPainter extends CustomPainter {
 @override
 void paint(Canvas canvas, Size size) {
   final paint = Paint()
     ..color = AppColors.gridLine.withValues(alpha: 0.55)
     ..strokeWidth = 0.9;
   const gap = 50.0;
   const dash = 8.0;
   const space = 5.0;


   for (double x = 12; x < size.width; x += gap) {
     for (double y = 0; y < size.height; y += dash + space) {
       canvas.drawLine(Offset(x, y), Offset(x, y + dash), paint);
     }
   }
   for (double y = 22; y < size.height; y += gap) {
     for (double x = 0; x < size.width; x += dash + space) {
       canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
     }
   }
 }


 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// White wavy bottom with brush strokes
class _WavePainter extends CustomPainter {
 final double waveTop;
 _WavePainter({required this.waveTop});


 @override
 void paint(Canvas canvas, Size size) {
   final w = size.width;
   final h = size.height;


   // Main white body
   final path = Path()
     ..moveTo(0, waveTop + 40)
     ..cubicTo(w * 0.25, waveTop + 5, w * 0.45, waveTop + 55, w * 0.7,
         waveTop + 25)
     ..cubicTo(w * 0.85, waveTop + 8, w * 0.95, waveTop - 5, w, waveTop - 12)
     ..lineTo(w, h)
     ..lineTo(0, h)
     ..close();
   canvas.drawPath(path, Paint()..color = Colors.white);


   // Brush strokes
   final stroke = Paint()
     ..color = Colors.white
     ..style = PaintingStyle.stroke
     ..strokeCap = StrokeCap.round;


   stroke.strokeWidth = 5;
   canvas.drawPath(
     Path()
       ..moveTo(0, waveTop + 38)
       ..quadraticBezierTo(w * 0.5, waveTop + 8, w, waveTop - 22),
     stroke,
   );
   stroke.strokeWidth = 2.5;
   canvas.drawPath(
     Path()
       ..moveTo(w * 0.05, waveTop + 48)
       ..quadraticBezierTo(w * 0.55, waveTop + 15, w, waveTop - 12),
     stroke,
   );


   // Small speckles
   final dot = Paint()..color = Colors.white.withValues(alpha: 0.9);
   final dots = [
     Offset(w * 0.08, waveTop + 8),
     Offset(w * 0.18, waveTop - 4),
     Offset(w * 0.40, waveTop + 18),
     Offset(w * 0.55, waveTop + 6),
     Offset(w * 0.75, waveTop - 4),
     Offset(w * 0.88, waveTop - 18),
   ];
   for (final d in dots) {
     canvas.drawCircle(d, 2.2, dot);
   }
 }


 @override
 bool shouldRepaint(covariant _WavePainter old) => old.waveTop != waveTop;
}

