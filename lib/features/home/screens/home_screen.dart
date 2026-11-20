import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: For session locking

import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../redux/app_state.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/redux/auth_actions.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

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
      theme: ThemeData(fontFamily: HomeTheme.fontFamily, useMaterial3: true),
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

  // --- Mood & Quote State ---
  int? _selectedMoodIndex; // Changed to int? (null means no mood picked)
  bool _isSessionLocked = false; // Tracks if the session is locked
  List<Quote> _allQuotes = [];
  Quote? _currentQuote;
  bool _isLoadingQuotes = true;
  String? _dashboardToken;
  Future<DashboardData>? _dashboardFuture;

  // --- Exact Colors from Image ---
  static const Color backgroundGradientTop = HomeTheme.backgroundTop;
  static const Color backgroundGradientBottom = HomeTheme.backgroundBottom;
  static const Color heroGradientStart = HomeTheme.heroGradientStart;
  static const Color heroGradientEnd = HomeTheme.heroGradientEnd;
  static const Color heroInnerCardBg = HomeTheme.heroInnerCardBackground;
  static const Color primaryTextBlue = HomeTheme.primaryText;
  static const Color secondaryTextBlue = HomeTheme.secondaryText;
  static const Color accentBlue = HomeTheme.accentBlue;
  static const Color chipBlueBg = HomeTheme.chipBlueBackground;
  static const Color borderBlue = HomeTheme.borderBlue;
  static const Color icyMutedBlue = HomeTheme.icyMutedBlue;
  static const Color lightMutedBlue = HomeTheme.lightMutedBlue;
  static const Color cardWhite = Colors.white;

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

      // Load Local Storage Session
      final prefs = await SharedPreferences.getInstance();
      final int? savedRating = prefs.getInt('saved_rating');
      final int? savedQuoteId = prefs.getInt('saved_quote_id');

      setState(() {
        _allQuotes = data.map((json) => Quote.fromJson(json)).toList();

        // If a session exists, lock it in
        if (savedRating != null && savedQuoteId != null) {
          _selectedMoodIndex =
              savedRating - 1; // Convert 1-based to 0-based index
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
    if (_isSessionLocked) return; // Prevent clicking if already locked

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

      // Save to local storage
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
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildDashboardPage(),
          _hasOpenedAttendance
              ? const AttendanceScreen()
              : const SizedBox.shrink(),
          _buildSectionPage(
            title: 'Requests',
            description: 'Your leave and other requests will appear here.',
            icon: Icons.assignment_outlined,
          ),
          _buildSectionPage(
            title: 'Calendar',
            description: 'Your shifts and important dates will appear here.',
            icon: Icons.calendar_month_rounded,
          ),
          _buildSectionPage(
            title: 'Payslip',
            description: 'Your payslips will appear here.',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _selectNavigationItem(int index) {
    setState(() {
      _currentBottomNavIndex = index;
      if (index == 1) _hasOpenedAttendance = true;
    });
  }

  Widget _buildDashboardPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundGradientTop, backgroundGradientBottom],
        ),
      ),
      child: SafeArea(
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
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _dashboardFuture != null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(
                              color: heroGradientStart,
                              backgroundColor: Colors.white70,
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
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF9F2D25), fontSize: 12),
            ),
          ),
          TextButton(onPressed: _retryDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSectionPage({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundGradientTop, backgroundGradientBottom],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(null),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B)
                              .withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1F8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(icon, size: 36, color: accentBlue),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: const TextStyle(
                            color: primaryTextBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: secondaryTextBlue,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              color: primaryTextBlue,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryTextBlue.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'NG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
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
                    const Text('Nandgate', style: HomeTheme.headerTitle),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  employeeDetails.isEmpty
                      ? 'Mindful Daily Dashboard'
                      : employeeDetails,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeTheme.headerSubtitle,
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: const Icon(Icons.spa_outlined, size: 19, color: accentBlue),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentBlue,
                child: Text(
                  initials.isEmpty ? 'E' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
              color: secondaryTextBlue,
            ),
          ),
        ],
      ),
    );
  }

  // --- Greeting & Shift Tracker Hero Card ---
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
          colors: [heroGradientStart, heroGradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: heroGradientEnd.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Good ${_timeGreeting()}, $userName',
                style: HomeTheme.pageTitle.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 19)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data?.today.punchInTime == null
                ? 'Not punched in yet. Take a moment to prepare your day.'
                : 'Your attendance is recorded for today.',
            style: const TextStyle(
              fontSize: 12.5,
              color: icyMutedBlue,
              height: 1.35,
            ),
          ),
          if (designation.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              designation,
              style: const TextStyle(color: lightMutedBlue, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: heroInnerCardBg.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                _buildShiftStatItem(
                  'CHECK IN',
                  _formatTime(context, data?.today.punchInTime),
                  data?.today.punchInTime == null ? 'Not Started' : 'Today',
                  Colors.white60,
                ),
                Container(width: 1, height: 44, color: Colors.white10),
                _buildShiftStatItem(
                  'WORKED',
                  _formatDuration(todayWorkMinutes),
                  todayWorkMinutes == null ? 'No data' : 'Today so far',
                  lightMutedBlue,
                ),
                Container(width: 1, height: 44, color: Colors.white10),
                _buildShiftStatItem(
                  'LAST PUNCH',
                  data?.today.lastPunch == null
                      ? 'None'
                      : _formatTime(context, data!.today.lastPunch),
                  data?.today.lastPunch == null
                      ? 'No punches today'
                      : 'Latest activity',
                  Colors.white60,
                ),
              ],
            ),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
              fontWeight: FontWeight.w600,
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
            style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.5,
              color: lightMutedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
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

  // --- Mood Check-In Card with Dynamic JSON Quotes & Lock Logic ---
  Widget _buildMoodCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderBlue),
        boxShadow: [
          BoxShadow(
            color: primaryTextBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: primaryTextBlue,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text('Daily Mood Check-In', style: HomeTheme.cardTitle),
                ],
              ),
              // Show Reset button ONLY if session is locked
              if (_isSessionLocked)
                GestureDetector(
                  onTap: _handleResetSession,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11,
                      color: accentBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipBlueBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MINDFUL PULSE',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: primaryTextBlue,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // --- EMOJI PICKER (Only shows if NO rating is selected) ---
          if (!_isLoadingQuotes && _selectedMoodIndex == null) ...[
            const Center(
              child: Text(
                'HOW IS YOUR DAY GOING?',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: lightMutedBlue,
                  letterSpacing: 0.7,
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
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [heroGradientStart, heroGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF97C1DE)
                            : Colors.white.withValues(alpha: 0.18),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: primaryTextBlue.withValues(alpha: 0.2),
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
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFFDCE8F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],

          // --- QUOTE DISPLAY (Only shows if a quote is locked in) ---
          if (_currentQuote != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(
                  _currentQuote!.id,
                ), // Triggers animation on change
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '"${_currentQuote!.text}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: primaryTextBlue,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${_currentQuote!.author}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryTextBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- FALLBACK TEXT (Shows if data is loaded but no mood picked) ---
          if (!_isLoadingQuotes && _selectedMoodIndex == null) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Take a moment to check in with yourself.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: primaryTextBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // --- LOADING STATE ---
          if (_isLoadingQuotes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  // --- Monthly Snapshot 2x2 Grid ---
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
              Text('Monthly Snapshot', style: HomeTheme.sectionTitle),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextBlue,
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
          childAspectRatio: 1.36,
          children: [
            _buildSnapshotCard(
              label: 'ATTENDANCE',
              value: data == null ? '—' : '$presentDays / $totalDays Days',
              badgeText: data == null ? 'Loading' : '$presentDays Present',
              footer: data == null
                  ? 'Monthly attendance'
                  : '$presentDays present · $workHours worked',
              footerIcon: data == null ? null : Icons.circle,
            ),
            _buildSnapshotCard(
              label: 'LOSS OF PAY',
              value: data == null ? '—' : '${data.lopDays} Days',
              badgeText: data == null ? 'Loading' : 'Recorded',
              footer: '$monthLabel LOP',
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
            ),
            _buildSnapshotCard(
              label: 'NEXT HOLIDAY',
              value: nextHoliday?.name ?? 'None scheduled',
              badgeText: data == null ? 'Loading' : holidayDateLabel,
              footer: nextHoliday == null
                  ? 'No upcoming holiday'
                  : 'Upcoming holiday',
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
    IconData? footerIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroGradientStart, heroGradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primaryTextBlue.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: icyMutedBlue,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 88),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  badgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDCE8F3),
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTheme.metric.copyWith(color: Colors.white),
          ),
          Row(
            children: [
              if (footerIcon != null) ...[
                const Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: icyMutedBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                const Text('Announcements', style: HomeTheme.sectionTitle),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Text(
                  '${events.length} Events',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextBlue,
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
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderBlue),
                boxShadow: [
                  BoxShadow(
                    color: primaryTextBlue.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: chipBlueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accentBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryTextBlue,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.type.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: secondaryTextBlue,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: secondaryTextBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
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

  // --- Quick Mindful Action Banner ---
  Widget _buildQuickActionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderBlue),
        boxShadow: [
          BoxShadow(
            color: primaryTextBlue.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: primaryTextBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
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
                  'Take a 2-Min Mindful Breath',
                  style: TextStyle(
                    color: primaryTextBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Settle focus before your next sprint',
                  style: TextStyle(color: secondaryTextBlue, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTextBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

  // --- Floating Bottom Navigation Bar ---
  Widget _buildBottomNav() {
    const items = [
      (label: 'Home', icon: Icons.home_rounded),
      (label: 'Attendance', icon: Icons.fact_check_outlined),
      (label: 'Request', icon: Icons.assignment_outlined),
      (label: 'Calendar', icon: Icons.calendar_month_rounded),
      (label: 'Payslip', icon: Icons.account_balance_wallet_outlined),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderBlue),
          boxShadow: [
            BoxShadow(
              color: primaryTextBlue.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = _currentBottomNavIndex == index;
            return Semantics(
              button: true,
              selected: selected,
              label: item.label,
              child: Tooltip(
                message: item.label,
                child: selected
                    ? InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _selectNavigationItem(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryTextBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, color: Colors.white, size: 17),
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _selectNavigationItem(index),
                        icon: Icon(item.icon, color: lightMutedBlue, size: 20),
                        splashRadius: 20,
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
