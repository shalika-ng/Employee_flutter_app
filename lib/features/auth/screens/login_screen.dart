import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const NandgateApp());
}

class NandgateApp extends StatelessWidget {
  const NandgateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NANDGATE Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFF9BCBE5),
      ),
      home: const NandgateLoginScreen(),
    );
  }
}

class NandgateLoginScreen extends StatefulWidget {
  const NandgateLoginScreen({super.key});

  @override
  State<NandgateLoginScreen> createState() => _NandgateLoginScreenState();
}

class _NandgateLoginScreenState extends State<NandgateLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _agreeTerms = false;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Simulate network authentication request
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login action triggered successfully!'),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF9BCBE5),
      body: Stack(
        children: [
          // Ambient soft mesh gradient background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFA5D2EA),
                  Color(0xFF9BCBE5),
                  Color(0xFF8DBED8),
                ],
              ),
            ),
          ),

          // Scrollable login content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - topPadding - bottomPadding,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Full-width NANDGATE Logo Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLogoHeader(),
                      ),

                      const SizedBox(height: 24),

                      // Form Inputs & Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            // Username Pill Field
                            _buildPillInputField(
                              controller: _usernameController,
                              hintText: 'Username',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 16),

                            // Password Pill Field with Toggle
                            _buildPillInputField(
                              controller: _passwordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remember Me
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 2),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) {
                                              setState(() {
                                                _rememberMe = val ?? false;
                                              });
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            activeColor:
                                                const Color(0xFF1E293B),
                                            checkColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.white70,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Forgot Password
                                TextButton(
                                  onPressed: () {
                                    // Handle forgot password flow
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Action Button & Paint Slash Divider Baseline
                      Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // Bottom White Jagged Paint Slash Canvas
                          Column(
                            children: [
                              CustomPaint(
                                size: Size(size.width, 90),
                                painter: PaintSlashPainter(),
                              ),
                              Container(
                                width: double.infinity,
                                color: Colors.white,
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 24),
                                child: Column(
                                  children: [
                                    // Terms & Conditions Checkbox
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _agreeTerms = !_agreeTerms;
                                        });
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: _agreeTerms,
                                              onChanged: (val) {
                                                setState(() {
                                                  _agreeTerms = val ?? false;
                                                });
                                              },
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              activeColor:
                                                  const Color(0xFF1E293B),
                                              side: const BorderSide(
                                                color: Color(0xFF94A3B8),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'I agree with Terms & Conditions!',
                                            style: TextStyle(
                                              color: Color(0xFF1E293B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Powered by footer
                                    const Text(
                                      'POWERED BY NANDGATE-IT',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Circular Dark Slate Forward Button overlapping the slash
                          Positioned(
                            top: -24,
                            child: GestureDetector(
                              onTap: _handleLogin,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Brand Logo Header (renders the geometric monogram & wordmark)
  Widget _buildLogoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            // Monogram Mark with Central Logic Gate
            SizedBox(
              height: 140,
              child: CustomPaint(
                size: const Size(260, 140),
                painter: NandgateMonogramPainter(),
              ),
            ),
            const SizedBox(height: 8),
            // NANDGATE Typography
            const Text(
              'N A N D G A T E',
              style: TextStyle(
                fontFamily: 'sans-serif',
                color: Color(0xFF1E293B),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pill Input Field
  Widget _buildPillInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF64748B),
            size: 21,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// Custom Painter reproducing the paint slash / snow baseline with particles
class PaintSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw main diagonal white jagged paint slash
    final path = Path();
    path.moveTo(0, size.height * 0.72);

    // Dynamic jagged diagonal stroke climbing upwards to the right
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.65,
      size.width * 0.5,
      size.height * 0.52,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.38,
      size.width,
      size.height * 0.22,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, whitePaint);

    // Floating paint splatters / particles above the baseline
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final particles = [
      Offset(size.width * 0.08, size.height * 0.62),
      Offset(size.width * 0.16, size.height * 0.56),
      Offset(size.width * 0.24, size.height * 0.52),
      Offset(size.width * 0.32, size.height * 0.46),
      Offset(size.width * 0.42, size.height * 0.39),
      Offset(size.width * 0.54, size.height * 0.33),
      Offset(size.width * 0.64, size.height * 0.28),
      Offset(size.width * 0.76, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.16),
      Offset(size.width * 0.94, size.height * 0.12),
    ];

    for (int i = 0; i < particles.length; i++) {
      final radius = (i % 2 == 0) ? 2.8 : 3.6;
      canvas.drawCircle(particles[i], radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter reproducing the geometric NG Monogram + Central Logic Gate
class NandgateMonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Geometric 'N' facet (left side)
    final nPaintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final nPaintBlue = Paint()
      ..color = const Color(0xFF6BAED6)
      ..style = PaintingStyle.fill;

    final nPath1 = Path()
      ..moveTo(center.dx - 85, center.dy - 50)
      ..lineTo(center.dx - 45, center.dy - 50)
      ..lineTo(center.dx - 70, center.dy + 35)
      ..lineTo(center.dx - 110, center.dy + 35)
      ..close();
    canvas.drawPath(nPath1, nPaintWhite);

    final nPath2 = Path()
      ..moveTo(center.dx - 110, center.dy + 35)
      ..lineTo(center.dx - 70, center.dy + 35)
      ..lineTo(center.dx - 45, center.dy + 10)
      ..lineTo(center.dx - 85, center.dy - 10)
      ..close();
    canvas.drawPath(nPath2, nPaintBlue);

    // 2. Draw Geometric 'G' facet (right side)
    final gPaintSlate = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final gPaintLight = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final gPathWhite = Path()
      ..moveTo(center.dx + 45, center.dy - 50)
      ..lineTo(center.dx + 90, center.dy - 50)
      ..lineTo(center.dx + 90, center.dy - 20)
      ..lineTo(center.dx + 55, center.dy - 20)
      ..close();
    canvas.drawPath(gPathWhite, gPaintLight);

    final gPathSlate = Path()
      ..moveTo(center.dx + 30, center.dy - 10)
      ..lineTo(center.dx + 85, center.dy - 10)
      ..lineTo(center.dx + 85, center.dy + 35)
      ..lineTo(center.dx + 20, center.dy + 35)
      ..lineTo(center.dx + 20, center.dy + 10)
      ..lineTo(center.dx + 55, center.dy + 10)
      ..lineTo(center.dx + 55, center.dy + 18)
      ..lineTo(center.dx + 42, center.dy + 18)
      ..close();
    canvas.drawPath(gPathSlate, gPaintSlate);

    // 3. Central NAND Logic Gate Symbol
    final gatePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final gateFill = Paint()
      ..color = const Color(0xFF9BCBE5)
      ..style = PaintingStyle.fill;

    final gateRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(center.dx - 6, center.dy), width: 36, height: 38),
      topRight: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    // Draw gate body fill and outline
    canvas.drawRRect(gateRect, gateFill);
    canvas.drawRRect(gateRect, gatePaint);

    // Inputs (left lines)
    canvas.drawLine(Offset(center.dx - 32, center.dy - 10),
        Offset(center.dx - 24, center.dy - 10), gatePaint);
    canvas.drawLine(Offset(center.dx - 32, center.dy + 10),
        Offset(center.dx - 24, center.dy + 10), gatePaint);

    // Output bubble (inverter circle)
    final bubbleCenter = Offset(center.dx + 16, center.dy);
    canvas.drawCircle(bubbleCenter, 4.5, gateFill);
    canvas.drawCircle(bubbleCenter, 4.5, gatePaint);

    // Output lead line
    canvas.drawLine(Offset(center.dx + 21, center.dy),
        Offset(center.dx + 30, center.dy), gatePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
