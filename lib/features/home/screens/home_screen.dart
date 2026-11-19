import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: For session locking

import '../../../redux/app_state.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/redux/auth_actions.dart';

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
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
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

  // --- Exact Colors from Image ---
  static const Color heroGradientStart = Color(0xFF2A3C50);
  static const Color heroGradientEnd = Color(0xFF1B2838);
  static const Color heroInnerCardBg = Color(0xFF33465A);
  static const Color primaryTextBlue = Color(0xFF1E293B);
  static const Color secondaryTextBlue = Color(0xFF64748B);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color chipBlueBg = Color(0xFFE8F1F8);
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
          colors: [Color(0xFFF0F6FA), Color(0xFFDCE9F2)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DottedBackgroundPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGreetingShiftCard(),
                        const SizedBox(height: 16),
                        _buildMoodCheckInCard(),
                        const SizedBox(height: 20),
                        _buildMonthlySnapshotSection(),
                        const SizedBox(height: 16),
                        _buildQuickActionBanner(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          colors: [Color(0xFFF0F6FA), Color(0xFFDCE9F2)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
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
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF345B7A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'NG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nandgate',
                style: TextStyle(
                  color: primaryTextBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Mindful Daily Dashboard',
                style: TextStyle(
                  color: secondaryTextBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_outlined,
              size: 20,
              color: Color(0xFF6B9BBF),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF345B7A),
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Log out',
            onPressed: () {
              StoreProvider.of<AppState>(context).dispatch(LogoutAction());
            },
            icon: const Icon(Icons.logout, color: primaryTextBlue),
          ),
        ],
      ),
    );
  }

  // --- Greeting & Shift Tracker Hero Card ---
  Widget _buildGreetingShiftCard() {
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '21°C • Bangalore',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Text(
                      'LIVE TIME',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '02:33 PM',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Good afternoon, Sarah',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: heroInnerCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildShiftStatItem(
                  'Check In',
                  '09:02 AM',
                  'On time',
                  const Color(0xFF10B981),
                ),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildShiftStatItem(
                  'Worked Today',
                  '06h 24m',
                  'Focus Mode',
                  Colors.white70,
                ),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildShiftStatItem(
                  'Expected Out',
                  '06:00 PM',
                  '0h 36m left',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Shift Completion',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    '80%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: 0.8,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    color: Color(0xFF2C3E50),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Daily Mood Check-In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryTextBlue,
                    ),
                  ),
                ],
              ),
              // Show Reset button ONLY if session is locked
              if (_isSessionLocked)
                GestureDetector(
                  onTap: _handleResetSession,
                  child: const Text(
                    '(Reset Session)',
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Mindful Pulse',
                    style: TextStyle(
                      fontSize: 10,
                      color: accentBlue,
                      fontWeight: FontWeight.w600,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextBlue,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (index) {
                return GestureDetector(
                  onTap: () => _handleRatingClick(index),
                  child: Column(
                    children: [
                      Text(
                        _moods[index]['emoji'],
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _moods[index]['label'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextBlue,
                        ),
                      ),
                    ],
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
                  color: const Color(0xFFF4F8FB),
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
                        color: Color(0xFF334155),
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
                'Select a mood to reveal your personalized quote for the day.',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextBlue,
                  fontStyle: FontStyle.italic,
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
  Widget _buildMonthlySnapshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Snapshot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryTextBlue,
                ),
              ),
              Text(
                'November 2024',
                style: TextStyle(
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
          childAspectRatio: 1.45,
          children: [
            _buildMetricCard(
              title: 'Days Present',
              value: '18 / 22',
              subtitle: 'This month • On track',
              icon: Icons.calendar_today_rounded,
              chipText: '82%',
              chipColor: accentBlue,
              chipBg: chipBlueBg,
            ),
            _buildMetricCard(
              title: 'Hours Worked',
              value: '142h 20m',
              subtitle: 'Across 18 working days',
              icon: Icons.access_time_rounded,
              trailingIcon: Icons.trending_up_rounded,
              chipColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Leave Balance',
              value: '12 days',
              subtitle: 'Available anytime',
              icon: Icons.flight_takeoff_rounded,
              chipText: 'Ready',
              chipColor: const Color(0xFF10B981),
              chipBg: const Color(0xFFECFDF5),
            ),
            _buildMetricCard(
              title: 'Next Payday',
              value: '30 Nov',
              subtitle: 'November cycle',
              icon: Icons.account_balance_wallet_rounded,
              chipText: 'In 6d',
              chipColor: accentBlue,
              chipBg: chipBlueBg,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    String? chipText,
    Color? chipColor,
    Color? chipBg,
    IconData? trailingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: primaryTextBlue),
              ),
              if (chipText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: chipColor,
                    ),
                  ),
                ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 16, color: chipColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryTextBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Quick Mindful Action Banner ---
  Widget _buildQuickActionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F1F8), Color(0xFFD3E6F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF345B7A),
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
              backgroundColor: const Color(0xFF345B7A),
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
      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8EEF4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = _currentBottomNavIndex == index;

            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: Tooltip(
                  message: item.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _selectNavigationItem(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF244762)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1 : 0.92,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  item.icon,
                                  size: 21,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF8293A3),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                child: SizedBox(
                                  height: selected ? 14 : 0,
                                  child: selected
                                      ? Text(
                                          item.label,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
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
            );
          }),
        ),
      ),
    );
  }
}

// --- Custom Painter for Dotted Grid + Dotted Airplane ---
class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFB0C4D8).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    const double spacing = 24.0;
    const double radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, gridPaint);
      }
    }

    final airplanePaint = Paint()
      ..color = const Color(0xFF8FA9C1).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    final startX = size.width * 0.45;
    final startY = size.height * 0.75;
    final s = size.width / 350;

    path.moveTo(startX, startY);
    path.lineTo(startX + 140 * s, startY + 50 * s);
    path.lineTo(startX + 50 * s, startY + 90 * s);
    path.lineTo(startX + 10 * s, startY + 60 * s);
    path.close();

    path.moveTo(startX + 140 * s, startY + 50 * s);
    path.lineTo(startX + 70 * s, startY + 20 * s);
    path.lineTo(startX + 50 * s, startY + 90 * s);

    path.moveTo(startX + 10 * s, startY + 60 * s);
    path.lineTo(startX + 30 * s, startY + 120 * s);
    path.lineTo(startX + 50 * s, startY + 90 * s);

    _drawDottedPath(canvas, path, airplanePaint, 7.0);
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint, double spacing) {
    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2.2, paint);
        }
        distance += spacing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
