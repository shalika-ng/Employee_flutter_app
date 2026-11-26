import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/modern_curved_bottom_nav.dart';
import '../../../redux/app_state.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/redux/auth_actions.dart';
import '../../calendar/screens/holiday_calendar_screen.dart';
import '../../payslips/screens/payslip_screen.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../../requests/screens/request_screen.dart';

/// Exact Somaflow Sage Green & Warm Parchment Tokens
class SomaflowTheme {
  // Backgrounds & Atmospheres (Gradient from sage mist to warm parchment)
  static const Color backgroundTop = Color(0xFFBACAB7);
  static const Color backgroundBottom = Color(0xFFF3EFE9);
  static const Color surfaceOatmeal = Color(0xFFFCFAF7);
  static const Color cardFrosted = Color(0xF5FFFFFF);
  static const Color cardTinted = Color(0xFFEFF4ED);

  // Somaflow Sage Greens
  static const Color sagePrimary = Color(0xFF6B8268);
  static const Color sageDeep = Color(0xFF51644F);
  static const Color sageDark = Color(0xFF384736);
  static const Color sageMuted = Color(0xFF869984);
  static const Color sageLight = Color(0xFFD6E0D3);
  static const Color sageWash = Color(0xFFEAF0E8);

  // Soft Borders & Warm Accents
  static const Color borderLight = Color(0xFFD6DDD4);
  static const Color borderSubtle = Color(0xFFE6ECE4);
  static const Color warmSand = Color(0xFFD8C7B5);

  // Telemetry & Status Badges
  static const Color statusGreen = Color(0xFF388E3C);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusGreenBorder = Color(0xFFC8E6C9);

  static const Color lopCoral = Color(0xFFC25D4E);
  static const Color lopCoralBg = Color(0xFFFDF0ED);

  static const Color holidayGold = Color(0xFF9E7B3B);
  static const Color holidayGoldBg = Color(0xFFFAF4E8);

  // Typography (Charcoal & Muted Sage from reference)
  static const Color textCharcoal = Color(0xFF2C352B);
  static const Color textMuted = Color(0xFF687467);
  static const Color textSubtle = Color(0xFF8E9B8D);
}

// --- Quote Model ---
class Quote {
  final int id;
  final String text;
  final String author;
  final List<int> moods;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.moods,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      moods: json['moods'] != null ? List<int>.from(json['moods']) : [],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mindful Daily Dashboard',
      theme: ThemeData(
        fontFamily: HomeTheme.fontFamily,
        useMaterial3: true,
        scaffoldBackgroundColor: SomaflowTheme.backgroundBottom,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool _hasOpenedAttendance = false;
  bool _hasOpenedCalendar = false;
  bool _hasOpenedPayslips = false;

  // --- Mood & Quote State ---
  int? _selectedMoodIndex;
  bool _isSessionLocked = false;
  List<Quote> _allQuotes = [];
  Quote? _currentQuote;
  bool _isLoadingQuotes = true;
  String? _dashboardToken;
  Future<DashboardData>? _dashboardFuture;

  // Moods mapped to JSON 'moods' array IDs
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😴', 'label': 'Tired', 'moodId': 1},
    {'emoji': '😟', 'label': 'Uneasy', 'moodId': 2},
    {'emoji': '🧘', 'label': 'Steady', 'moodId': 3},
    {'emoji': '🙂', 'label': 'Content', 'moodId': 4},
    {'emoji': '🤩', 'label': 'Radiant', 'moodId': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotesAndSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token != null && token.isNotEmpty && token != _dashboardToken) {
      _dashboardToken = token;
      _dashboardFuture = DashboardService().getMyDashboard(token: token);
    }
  }

  void _retryDashboard() {
    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _dashboardToken = token;
      _dashboardFuture = DashboardService().getMyDashboard(token: token);
    });
  }

  // Load JSON, check SharedPreferences, and lock session if it exists
  Future<void> _loadQuotesAndSession() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/quote.json',
      );
      final List<dynamic> data = json.decode(response);

      final prefs = await SharedPreferences.getInstance();
      final int? savedRating = prefs.getInt('saved_rating');
      final int? savedQuoteId = prefs.getInt('saved_quote_id');

      setState(() {
        _allQuotes = data.map((json) => Quote.fromJson(json)).toList();

        if (savedRating != null && savedQuoteId != null) {
          _selectedMoodIndex = savedRating - 1;
          _currentQuote = _allQuotes.firstWhere(
            (q) => q.id == savedQuoteId,
            orElse: () => _allQuotes.first,
          );
          _isSessionLocked = true;
        }
        _isLoadingQuotes = false;
      });
    } catch (e) {
      debugPrint('Error loading quotes: $e');
      setState(() => _isLoadingQuotes = false);
    }
  }

  // Handle emoji click (locks the quote)
  Future<void> _handleRatingClick(int index) async {
    if (_isSessionLocked) return;

    final int moodId = _moods[index]['moodId'];
    final matchingQuotes = _allQuotes
        .where((q) => q.moods.contains(moodId))
        .toList();

    if (matchingQuotes.isNotEmpty) {
      matchingQuotes.shuffle();
      final newQuote = matchingQuotes.first;

      setState(() {
        _selectedMoodIndex = index;
        _currentQuote = newQuote;
        _isSessionLocked = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_rating', index + 1);
      await prefs.setInt('saved_quote_id', newQuote.id);
    }
  }

  // Dev testing reset button
  Future<void> _handleResetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_rating');
    await prefs.remove('saved_quote_id');

    setState(() {
      _selectedMoodIndex = null;
      _currentQuote = null;
      _isSessionLocked = false;
    });
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: SomaflowTheme.backgroundBottom,
    body: Stack(
      children: [
        // Somaflow Ambient Waves Backdrop
        Positioned.fill(
          child: CustomPaint(
            painter: _SomaflowBackgroundPainter(),
          ),
        ),

        IndexedStack(
          index: _currentBottomNavIndex,
          children: [
            // 0. Dashboard
            _buildDashboardPage(),

            // 1. Attendance
            _hasOpenedAttendance
                ? AttendanceScreen(
                    onNavigate: _navigateFromNestedPage,
                  )
                : const SizedBox.shrink(),

            // 2. Requests
            const RequestsScreen(),

            // 3. Calendar
            _hasOpenedCalendar
                ? StoreConnector<AppState, String?>(
                    distinct: true,
                    converter: (store) => store.state.auth.token,
                    builder: (context, token) =>
                        HolidayCalendarScreen(token: token),
                  )
                : const SizedBox.shrink(),

            // 4. Payslip
            _hasOpenedPayslips
                ? StoreConnector<AppState, String?>(
                    distinct: true,
                    converter: (store) => store.state.auth.token,
                    builder: (context, token) => PayslipScreen(
                      token: token,
                      active: _currentBottomNavIndex == 4,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ],
    ),

    // Bottom Navigation
    bottomNavigationBar: _buildBottomNav(),
  );
  }

  void _selectNavigationItem(int index) {
    setState(() {
      _currentBottomNavIndex = index;
      if (index == 1) _hasOpenedAttendance = true;
      if (index == 3) _hasOpenedCalendar = true;
      if (index == 4) _hasOpenedPayslips = true;
    });
  }

  void _navigateFromNestedPage(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _selectNavigationItem(index);
  }

  Widget _buildDashboardPage() {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final error = snapshot.error;
          return Column(
            children: [
              _buildTopAppBar(data),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _dashboardFuture != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(
                            color: SomaflowTheme.sagePrimary,
                            backgroundColor: SomaflowTheme.sageWash,
                          ),
                        ),
                      if (error != null) _buildDashboardError(error),
                      _buildGreetingShiftCard(data),
                      const SizedBox(height: 14),
                      _buildMoodCheckInCard(),
                      const SizedBox(height: 18),
                      _buildMonthlySnapshotSection(data),
                      if (data != null) ...[
                        const SizedBox(height: 18),
                        _buildUpcomingEvents(data),
                      ],
                      const SizedBox(height: 14),
                      _buildQuickActionBanner(),
                      const SizedBox(height: 84),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Unable to load dashboard. Please try again.';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SomaflowTheme.lopCoralBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D2CC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: SomaflowTheme.lopCoral, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: SomaflowTheme.lopCoral,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _retryDashboard,
            style: TextButton.styleFrom(foregroundColor: SomaflowTheme.lopCoral),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopAppBar(DashboardData? data) {
    final user = StoreProvider.of<AppState>(context).state.auth.user;
    final name = data?.employee.name ?? user?.name ?? 'Employee';
    final employeeDetails = [
      data?.employee.empCode ?? user?.empCode,
      data?.employee.designation ?? user?.designation,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SomaflowTheme.sagePrimary, SomaflowTheme.sageDeep],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: SomaflowTheme.sageDeep.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'NG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nandgate',
                      style: TextStyle(
                        color: SomaflowTheme.textCharcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: SomaflowTheme.statusGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  employeeDetails.isEmpty
                      ? 'Mindful Presence & Focus'
                      : employeeDetails,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SomaflowTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: SomaflowTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: SomaflowTheme.sageDark.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.all_inclusive_rounded, size: 20, color: SomaflowTheme.sagePrimary),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: SomaflowTheme.sagePrimary,
                child: Text(
                  initials.isEmpty ? 'E' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: SomaflowTheme.statusGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Log out',
            onPressed: () {
              StoreProvider.of<AppState>(context).dispatch(LogoutAction());
            },
            icon: const Icon(
              Icons.logout_rounded,
              size: 21,
              color: SomaflowTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // --- Greeting & Shift Tracker Hero Card (Serene Sage Gradient) ---
  Widget _buildGreetingShiftCard(DashboardData? data) {
    final userName =
        data?.employee.name ??
        StoreProvider.of<AppState>(context).state.auth.user?.name ??
        'there';
    final designation = data?.employee.designation ?? '';
    final todayWorkMinutes = _todayWorkMinutes(data);
    final todayDate = DateTime.tryParse(data?.today.date ?? '');
    final dateLabel = todayDate == null
        ? 'Today'
        : MaterialLocalizations.of(context).formatMediumDate(todayDate);
    final status = data?.today.status ?? '—';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SomaflowTheme.sagePrimary, SomaflowTheme.sageDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDeep.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gentle concentric watermark ripples
          Positioned(
            right: -25,
            bottom: -25,
            child: Opacity(
              opacity: 0.12,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 22),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _heroPill(icon: Icons.calendar_today_rounded, label: dateLabel),
                  _heroPill(
                    icon: Icons.circle,
                    label: 'STATUS: $status',
                    iconColor: status.toUpperCase() == 'IN'
                        ? const Color(0xFF6EE7B7)
                        : Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Good ${_timeGreeting()}, $userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data?.today.punchInTime == null
                    ? 'Breath cadence active. Settle focus for mindful presence.'
                    : 'Your mindful shift is logged for today.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.35,
                ),
              ),
              if (designation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  designation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    _buildShiftStatItem(
                      'CHECK IN',
                      _formatTime(context, data?.today.punchInTime),
                      data?.today.punchInTime == null ? 'Not Started' : 'Today',
                      Colors.white70,
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    _buildShiftStatItem(
                      'WORKED',
                      _formatDuration(todayWorkMinutes),
                      todayWorkMinutes == null ? 'No data' : 'Today so far',
                      Colors.white,
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    _buildShiftStatItem(
                      'LAST PUNCH',
                      data?.today.lastPunch == null
                          ? 'None'
                          : _formatTime(context, data!.today.lastPunch),
                      data?.today.lastPunch == null
                          ? 'No punches today'
                          : 'Latest activity',
                      Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  int? _todayWorkMinutes(DashboardData? data) {
    if (data == null) return null;
    for (final day in data.days) {
      if (day.date == data.today.date) return day.attendance?.workMinutes ?? 0;
    }
    return null;
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '—';
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
  }

  String _formatTime(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return TimeOfDay.fromDateTime(value).format(context);
  }

  Widget _buildShiftStatItem(
    String label,
    String value,
    String subtitle,
    Color subColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Mood Check-In Card / Somatic Cadence ---
  Widget _buildMoodCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.self_improvement_rounded,
                    color: SomaflowTheme.sagePrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Somatic Cadence',
                    style: TextStyle(
                      color: SomaflowTheme.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (_isSessionLocked)
                GestureDetector(
                  onTap: _handleResetSession,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: SomaflowTheme.sagePrimary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SomaflowTheme.sageWash,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SomaflowTheme.borderLight),
                  ),
                  child: const Text(
                    'BREATH CADENCE',
                    style: TextStyle(
                      fontSize: 9,
                      color: SomaflowTheme.sageDeep,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Cadence Buttons
          if (!_isLoadingQuotes && _selectedMoodIndex == null) ...[
            const Center(
              child: Text(
                'HOW DOES YOUR BODY FEEL RIGHT NOW?',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: SomaflowTheme.sageDeep,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (index) {
                final selected = _selectedMoodIndex == index;
                return GestureDetector(
                  onTap: () => _handleRatingClick(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? SomaflowTheme.sagePrimary : SomaflowTheme.cardTinted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? SomaflowTheme.sageDeep : SomaflowTheme.borderLight,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: SomaflowTheme.sageDeep.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _moods[index]['emoji'],
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moods[index]['label'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                            color: selected ? Colors.white : SomaflowTheme.sageDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],

          // Quote Card Display (Serif Zen Style from Somaflow)
          if (_currentQuote != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_currentQuote!.id),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SomaflowTheme.cardTinted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SomaflowTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '"${_currentQuote!.text}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: SomaflowTheme.textCharcoal,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${_currentQuote!.author}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SomaflowTheme.sageDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isLoadingQuotes && _selectedMoodIndex == null) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Take a deep 6s breath to settle your attention.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: SomaflowTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (_isLoadingQuotes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: SomaflowTheme.sagePrimary, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  // --- Monthly Snapshot 2x2 Grid (Somaflow Frosted Style) ---
  Widget _buildMonthlySnapshotSection(DashboardData? data) {
    final monthLabel = data == null || data.month < 1 || data.year < 1
        ? 'This month'
        : MaterialLocalizations.of(context)
              .formatMonthYear(DateTime(data.year, data.month));
    final presentDays = data?.presentDays ?? 0;
    final totalDays = data?.days.length ?? 0;
    final workHours = data == null
        ? '—'
        : '${data.workMinutes ~/ 60}h ${data.workMinutes % 60}m';
    final nextHoliday = _nextHoliday(data);
    final holidayDate = nextHoliday == null
        ? '—'
        : DateTime.tryParse(nextHoliday.startDate);
    final holidayDateLabel = holidayDate is DateTime
        ? MaterialLocalizations.of(context).formatShortDate(holidayDate)
        : 'No date';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Cadence',
                style: TextStyle(
                  color: SomaflowTheme.textCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SomaflowTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.34,
          children: [
            _buildSnapshotCard(
              label: 'ATTENDANCE',
              value: data == null ? '—' : '$presentDays / $totalDays Days',
              badgeText: data == null ? 'Loading' : '$presentDays Present',
              footer: data == null
                  ? 'Cadence overview'
                  : '$presentDays present · $workHours',
              badgeColor: SomaflowTheme.statusGreenBg,
              badgeTextColor: SomaflowTheme.statusGreen,
              footerIcon: data == null ? null : Icons.circle,
            ),
            _buildSnapshotCard(
              label: 'LOSS OF PAY',
              value: data == null ? '—' : '${data.lopDays} Days',
              badgeText: data == null ? 'Loading' : 'Recorded',
              footer: '$monthLabel LOP',
              badgeColor: SomaflowTheme.lopCoralBg,
              badgeTextColor: SomaflowTheme.lopCoral,
            ),
            _buildSnapshotCard(
              label: 'LEAVE BALANCE',
              value: data == null
                  ? '—'
                  : '${data.leaveBalance.available} / ${data.leaveBalance.total} Days',
              badgeText: data == null
                  ? 'Loading'
                  : '${data.leaveBalance.available} Available',
              footer: data == null
                  ? 'Available leave'
                  : '${data.leaveBalance.pendingDays} pending approval',
              badgeColor: SomaflowTheme.sageWash,
              badgeTextColor: SomaflowTheme.sageDeep,
            ),
            _buildSnapshotCard(
              label: 'NEXT HOLIDAY',
              value: nextHoliday?.name ?? 'None scheduled',
              badgeText: data == null ? 'Loading' : holidayDateLabel,
              footer: nextHoliday == null
                  ? 'No upcoming holiday'
                  : 'Upcoming holiday',
              badgeColor: SomaflowTheme.holidayGoldBg,
              badgeTextColor: SomaflowTheme.holidayGold,
            ),
          ],
        ),
      ],
    );
  }

  DashboardEvent? _nextHoliday(DashboardData? data) {
    if (data == null) return null;
    final today = DateTime.tryParse(data.today.date);
    final holidays = data.events.where((event) {
      if (!event.type.contains('HOLIDAY')) return false;
      final date = DateTime.tryParse(event.startDate);
      return date != null && (today == null || !date.isBefore(today));
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    return holidays.isEmpty ? null : holidays.first;
  }

  Widget _buildSnapshotCard({
    required String label,
    required String value,
    required String badgeText,
    required String footer,
    required Color badgeColor,
    required Color badgeTextColor,
    IconData? footerIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: SomaflowTheme.sageDeep,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SomaflowTheme.textCharcoal,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            children: [
              if (footerIcon != null) ...[
                const Icon(Icons.circle, size: 6, color: SomaflowTheme.statusGreen),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: SomaflowTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Upcoming Announcements ---
  Widget _buildUpcomingEvents(DashboardData data) {
    final today = DateTime.tryParse(data.today.date);
    final events = data.events.where((event) {
      final date = DateTime.tryParse(event.startDate);
      return date != null && (today == null || !date.isBefore(today));
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                const Text(
                  'Mindful Circles & News',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: SomaflowTheme.sagePrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Text(
                  '${events.length} Events',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SomaflowTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ...events.take(3).map((event) {
            final date = DateTime.tryParse(event.startDate);
            final dateLabel = date == null
                ? event.startDate
                : MaterialLocalizations.of(context).formatShortDate(date);
            final icon = event.type.contains('HOLIDAY')
                ? Icons.calendar_month_outlined
                : Icons.event_note_outlined;
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: SomaflowTheme.sageWash,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: SomaflowTheme.sagePrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SomaflowTheme.textCharcoal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.type.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: SomaflowTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: SomaflowTheme.sageDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Quick Mindful Action Banner (Somaflow Pill Style) ---
  Widget _buildQuickActionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SomaflowTheme.sagePrimary, SomaflowTheme.sageDeep],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SomaflowTheme.sageDeep.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning Renewal Flow',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '6s Inhale · Somatic Pacing · 12 mins',
                  style: TextStyle(color: SomaflowTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: SomaflowTheme.sagePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(60, 36),
            ),
            child: const Text(
              'Start',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Frosted Card Decoration Helper ---
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: SomaflowTheme.cardFrosted,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SomaflowTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // --- Floating Bottom Navigation Bar ---
  Widget _buildBottomNav() {
    return ModernCurvedBottomNavBar(
      currentIndex: _currentBottomNavIndex,
      onTap: _selectNavigationItem,
      items: employeeBottomNavItems,
    );
  }
}

// --- Somaflow Organic Ripples Painter ---
class _SomaflowBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top sage-green organic canopy
    final paintSage = Paint()
      ..color = SomaflowTheme.sageMuted.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, 0)
      ..cubicTo(size.width * 0.45, 0, size.width * 0.55, size.height * 0.18, 0, size.height * 0.28)
      ..close();
    canvas.drawPath(path1, paintSage);

    // Warm sand side wave
    final paintSand = Paint()
      ..color = SomaflowTheme.warmSand.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..cubicTo(size.width * 0.75, size.height * 0.08, size.width, size.height * 0.04, size.width, size.height * 0.20)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path2, paintSand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}