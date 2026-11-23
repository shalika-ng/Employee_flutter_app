import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../redux/app_state.dart';
import '../models/attendance_models.dart';
import '../redux/attendance_actions.dart';
import '../redux/attendance_state.dart';
import 'attendance_request_form_screen.dart';

/// Somaflow Sage Green & Warm Parchment Design System Tokens
class SomaflowTheme {
  // Brand Sage Greens
  static const Color sagePrimary = Color(0xFF6B8268);
  static const Color sageDeep = Color(0xFF51644F);
  static const Color sageDark = Color(0xFF384736);
  static const Color sageMuted = Color(0xFF869984);
  static const Color sageLight = Color(0xFFD6E0D3);
  static const Color sageWash = Color(0xFFEAF0E8);

  // Backgrounds & Surfaces
  static const Color backgroundTop = Color(0xFFBACAB7);
  static const Color backgroundBottom = Color(0xFFF3EFE9);
  static const Color surfaceCard = Color(0xF8FFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFCFAF7);
  static const Color surfaceContainer = Color(0xFFEFF4ED);
  static const Color chipBackground = Color(0xFFEFF4ED);
  static const Color borderLight = Color(0xFFD6DDD4);
  static const Color borderSubtle = Color(0xFFE6ECE4);
  static const Color warmSand = Color(0xFFD8C7B5);

  // Status & Telemetry Accents
  static const Color statusGreen = Color(0xFF388E3C);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusGreenBorder = Color(0xFFC8E6C9);

  static const Color absentCoral = Color(0xFFC25D4E);
  static const Color absentBg = Color(0xFFFDF0ED);
  static const Color absentBorder = Color(0xFFF3D2CC);

  static const Color halfDayAmber = Color(0xFF9E7B3B);
  static const Color halfDayBg = Color(0xFFFAF4E8);
  static const Color halfDayBorder = Color(0xFFF2E6CE);

  // Typography (Charcoal & Muted Sage)
  static const Color textCharcoal = Color(0xFF2C352B);
  static const Color textMuted = Color(0xFF687467);
  static const Color textSubtle = Color(0xFF8E9B8D);
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({this.onNavigate, super.key});

  final ValueChanged<int>? onNavigate;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _month;
  bool _requestedInitialData = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialData) return;
    _requestedInitialData = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMonth();
    });
  }

  void _loadMonth() {
    StoreProvider.of<AppState>(context).dispatch(
      FetchAttendanceMonthAction(month: _month.month, year: _month.year),
    );
  }

  void _loadDay(DateTime date) {
    StoreProvider.of<AppState>(context)
        .dispatch(FetchAttendanceDayAction(date: _dateKey(date)));
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
    _loadMonth();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_month.year, _month.month, DateTime.now().day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: SomaflowTheme.sagePrimary,
            onPrimary: Colors.white,
            surface: SomaflowTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (picked.month != _month.month || picked.year != _month.year) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _loadMonth();
    }
    _loadDay(picked);
  }

  void _openRequest(AttendanceRequestType type, DateTime? date) {
    if (date == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AttendanceRequestFormScreen(
          type: type,
          initialDate: date,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AttendanceState>(
      converter: (store) => store.state.attendance,
      onWillChange: (previous, current) {
        if (previous?.dayStatus == AttendanceLoadStatus.loading &&
            current.dayStatus == AttendanceLoadStatus.success &&
            current.dayData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showDayPopup(current.dayData!);
          });
        } else if (previous?.dayStatus == AttendanceLoadStatus.loading &&
            current.dayStatus == AttendanceLoadStatus.failure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  current.dayError ?? 'Unable to load day details.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: SomaflowTheme.absentCoral,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: SomaflowTheme.backgroundBottom,
          body: Stack(
            children: [
              // Somaflow Organic Ripples Ambient Backdrop
              Positioned.fill(
                child: CustomPaint(painter: _SomaflowBackgroundPainter()),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        color: SomaflowTheme.sagePrimary,
                        backgroundColor: SomaflowTheme.surfaceCard,
                        onRefresh: () async {
                          _loadMonth();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 350),
                          );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                          children: [
                            if (state.monthData != null) ...[
                              _buildEmployeeCard(state.monthData!.employee),
                              const SizedBox(height: 14),
                            ],
                            _buildMonthSelector(),
                            if (state.monthData != null) ...[
                              const SizedBox(height: 14),
                              _buildTodayCard(state.monthData!.today),
                              const SizedBox(height: 18),
                              _buildSummary(
                                state.monthData!.totals,
                                state.monthData!.days.length,
                              ),
                            ],
                            const SizedBox(height: 20),
                            _buildAttendanceList(state),
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
      },
    );
  }

  /* ------------------------------ HEADER ----------------------------- */

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: SomaflowTheme.backgroundBottom.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: SomaflowTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: SomaflowTheme.textCharcoal,
            )
          else
            const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: SomaflowTheme.sagePrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Attendance',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Pick a date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined, size: 24),
            color: SomaflowTheme.textCharcoal,
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadMonth,
            icon: const Icon(Icons.refresh_rounded, size: 24),
            color: SomaflowTheme.sagePrimary,
          ),
        ],
      ),
    );
  }

  /* --------------------------- EMPLOYEE CARD ------------------------- */

  Widget _buildEmployeeCard(AttendanceEmployee employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SomaflowTheme.sagePrimary, SomaflowTheme.sageDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDeep.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Concentric circular ripples from Somaflow
          Positioned(
            right: -20,
            bottom: -30,
            child: Opacity(
              opacity: 0.12,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 20),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            employee.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.designation} · ${employee.empCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: SomaflowTheme.statusGreen,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: SomaflowTheme.statusGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
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

  /* --------------------------- MONTH SELECTOR ------------------------ */

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: SomaflowTheme.sagePrimary,
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 20, color: SomaflowTheme.sagePrimary),
              const SizedBox(width: 8),
              Text(
                '${_monthName(_month.month)} ${_month.year}',
                style: const TextStyle(
                  color: SomaflowTheme.textCharcoal,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: SomaflowTheme.sagePrimary,
          ),
        ],
      ),
    );
  }

  /* ----------------------------- TODAY CARD -------------------------- */

  Widget _buildTodayCard(AttendanceToday today) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S PRESENCE",
                style: TextStyle(
                  color: SomaflowTheme.sagePrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              _statusPill(today.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dateLabel(DateTime.now()),
            style: const TextStyle(
              color: SomaflowTheme.textCharcoal,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: SomaflowTheme.chipBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SomaflowTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SomaflowTheme.sageDark.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      color: SomaflowTheme.sagePrimary, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last punch',
                        style: TextStyle(
                          color: SomaflowTheme.textCharcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Biometric Turnstile',
                        style: TextStyle(
                          color: SomaflowTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(today.lastPunch),
                  style: const TextStyle(
                    color: SomaflowTheme.sageDeep,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ------------------------------ SUMMARY ---------------------------- */

  Widget _buildSummary(AttendanceTotals totals, int totalDays) {
    final pct = totalDays == 0
        ? 0
        : ((totals.present / totalDays) * 100).round().clamp(0, 100);

    final items = <_Metric>[
      _Metric('Present Days', '${totals.present}', '/$totalDays',
          Icons.check_circle_outline_rounded, '$pct%',
          SomaflowTheme.statusGreen, SomaflowTheme.statusGreenBg),
      _Metric('Productive Hours', '${totals.workMinutes ~/ 60}h',
          ' ${totals.workMinutes % 60}m', Icons.schedule_rounded, null,
          SomaflowTheme.sagePrimary, SomaflowTheme.chipBackground),
      _Metric('Leaves Taken', totals.leave.toString().padLeft(2, '0'), '',
          Icons.event_busy_outlined, null,
          SomaflowTheme.absentCoral, SomaflowTheme.absentBg),
      _Metric('Half Days', totals.half.toString().padLeft(2, '0'), '',
          Icons.hourglass_empty_rounded, null,
          SomaflowTheme.halfDayAmber, SomaflowTheme.halfDayBg),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Pulse',
          style: TextStyle(
            color: SomaflowTheme.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) {
            final m = items[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: m.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.icon, color: m.color, size: 19),
                      ),
                      if (m.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: m.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.badge!,
                            style: TextStyle(
                              color: m.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: m.value,
                          style: const TextStyle(
                            color: SomaflowTheme.textCharcoal,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (m.suffix.isNotEmpty)
                          TextSpan(
                            text: m.suffix,
                            style: const TextStyle(
                              color: SomaflowTheme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    m.label,
                    style: const TextStyle(
                      color: SomaflowTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /* ----------------------------- DAY LIST ---------------------------- */

  Widget _buildAttendanceList(AttendanceState state) {
    if (state.monthStatus == AttendanceLoadStatus.loading &&
        state.monthData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: SomaflowTheme.sagePrimary),
        ),
      );
    }

    if (state.monthStatus == AttendanceLoadStatus.failure &&
        state.monthData == null) {
      return _errorCard(
        state.monthError ?? 'Unable to load attendance.',
        onRetry: _loadMonth,
      );
    }

    final days = state.monthData?.days ?? const <AttendanceDaySummary>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daily Logs',
                style: TextStyle(
                  color: SomaflowTheme.textCharcoal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (state.monthStatus == AttendanceLoadStatus.loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SomaflowTheme.sagePrimary,
                ),
              ),
          ],
        ),
        if (state.monthError != null) ...[
          const SizedBox(height: 8),
          _errorCard(state.monthError!, onRetry: _loadMonth),
        ],
        const SizedBox(height: 10),
        if (days.isEmpty && state.monthStatus == AttendanceLoadStatus.success)
          _emptyCard('No attendance records found for this month.'),
        ...days.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _dayCard(day, state),
          ),
        ),
      ],
    );
  }

  Widget _dayCard(AttendanceDaySummary day, AttendanceState state) {
    final date = day.workDate;
    final dateKey = date == null ? '' : _dateKey(date);
    final selected = dateKey.isNotEmpty && state.selectedDate == dateKey;
    final absent = _isAbsent(day);
    final showRegularization = _shouldShowRegularization(day);
    final showLopActions = _hasLop(day);

    final String subtitle;
    final Color subtitleColor;
    if (absent) {
      subtitle = 'No punches recorded';
      subtitleColor = SomaflowTheme.absentCoral;
    } else if (day.needsRegularization) {
      subtitle = 'Needs regularization';
      subtitleColor = SomaflowTheme.halfDayAmber;
    } else if (day.isLate) {
      subtitle = 'Late check-in';
      subtitleColor = SomaflowTheme.absentCoral;
    } else {
      subtitle = 'Regular shift';
      subtitleColor = SomaflowTheme.textMuted;
    }

    return Container(
      decoration: BoxDecoration(
        color: SomaflowTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? SomaflowTheme.sagePrimary : SomaflowTheme.borderLight,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: date == null ? null : () => _loadDay(date),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateLabel(date),
                            style: const TextStyle(
                              color: SomaflowTheme.textCharcoal,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusPill(day.status),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: SomaflowTheme.chipBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Text(
                        'IN  ${_formatTime(day.firstIn)}',
                        style: const TextStyle(
                          color: SomaflowTheme.sageDeep,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'OUT  ${_formatTime(day.lastOut)}',
                        style: const TextStyle(
                          color: SomaflowTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatDuration(day.workMinutes),
                        style: const TextStyle(
                          color: SomaflowTheme.sageDeep,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (day.isLate || showLopActions) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (day.isLate) _flagChip('Late'),
                      if (showLopActions) _lopChip(day.lopValue),
                    ],
                  ),
                ],
                if (showRegularization || showLopActions) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (showRegularization)
                        _requestAction(
                          'Apply Regularization',
                          AttendanceRequestType.regularization,
                          date,
                          isSolid: true,
                        ),
                      if (showLopActions) ...[
                        _requestAction(
                          'Apply Leave',
                          AttendanceRequestType.leave,
                          date,
                        ),
                        _requestAction(
                          'Permission',
                          AttendanceRequestType.permission,
                          date,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* --------------------------- DAY DETAIL SHEET ---------------------- */

  void _showDayPopup(AttendanceDayData data) {
    final date = DateTime.tryParse(data.date);
    final dayState = AttendanceState(
      dayStatus: AttendanceLoadStatus.success,
      selectedDate: data.date,
      dayData: data,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Container(
          decoration: const BoxDecoration(
            color: SomaflowTheme.backgroundBottom,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: SomaflowTheme.borderLight, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: SomaflowTheme.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SHIFT AUDIT LOG',
                            style: TextStyle(
                              color: SomaflowTheme.sagePrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            date == null
                                ? 'Attendance Details'
                                : '${_weekdayName(date.weekday)}, ${data.date}',
                            style: const TextStyle(
                              color: SomaflowTheme.textCharcoal,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: SomaflowTheme.chipBackground,
                        foregroundColor: SomaflowTheme.textCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: SomaflowTheme.borderLight),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: _buildDayDetails(dayState),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: SomaflowTheme.borderLight)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: SomaflowTheme.sagePrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetails(AttendanceState state) {
    if (state.dayStatus == AttendanceLoadStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: SomaflowTheme.sagePrimary),
        ),
      );
    }
    if (state.dayStatus == AttendanceLoadStatus.failure) {
      return _errorCard(
        state.dayError ?? 'Unable to load day details.',
        onRetry: () {
          final selectedDate = state.selectedDate;
          if (selectedDate != null) {
            StoreProvider.of<AppState>(context)
                .dispatch(FetchAttendanceDayAction(date: selectedDate));
          }
        },
      );
    }

    final data = state.dayData;
    if (data == null) return const SizedBox.shrink();
    final summary = data.summary;

    Widget title(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t,
            style: const TextStyle(
              color: SomaflowTheme.textCharcoal,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daily Metric Summary',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                data.date,
                style: const TextStyle(
                  color: SomaflowTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary == null)
            const Text(
              'No day summary is available.',
              style: TextStyle(color: SomaflowTheme.textMuted, fontSize: 14),
            )
          else ...[
            Row(
              children: [
                _statusPill(summary.status),
                if (summary.lopValue != '0.00' && summary.lopValue != '0') ...[
                  const SizedBox(width: 8),
                  _lopChip(summary.lopValue),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _detailPair('First in', _formatTime(summary.firstIn)),
            _detailPair('Last out', _formatTime(summary.lastOut)),
            _detailPair('Break time', _formatDuration(summary.breakMinutes)),
            _detailPair(
              'Permission duration',
              _formatDuration(summary.permissionMinutes),
            ),
          ],
          if (data.sessions.isNotEmpty) ...[
            const Divider(height: 28, color: SomaflowTheme.borderLight),
            title('Recorded Sessions'),
            ...data.sessions.map(
              (session) => _detailPair(
                session.flag ?? 'Session',
                '${_formatTime(session.inAt)} – ${_formatTime(session.outAt)}'
                '${session.durationMinutes == null ? '' : ' · ${_formatDuration(session.durationMinutes!)}'}',
              ),
            ),
          ],
          if (data.punches.isNotEmpty) ...[
            const Divider(height: 28, color: SomaflowTheme.borderLight),
            title('Biometric Punch Log'),
            ...data.punches.map(
              (punch) => _detailPair(
                '${punch.direction}${punch.isCorrection ? ' · Correction' : ''}',
                '${_formatTime(punch.punchedAt)}'
                '${punch.sourceType.isEmpty ? '' : ' · ${punch.sourceType}'}',
              ),
            ),
          ],
          if (data.breakGaps.isNotEmpty) ...[
            const Divider(height: 28, color: SomaflowTheme.borderLight),
            title('Break Gaps'),
            ...data.breakGaps.indexed.map(
              (e) => _detailPair('Break ${e.$1 + 1}', _formatAttributes(e.$2)),
            ),
          ],
          if (data.permissions.isNotEmpty) ...[
            const Divider(height: 28, color: SomaflowTheme.borderLight),
            title('Permissions'),
            ...data.permissions.indexed.map(
              (e) =>
                  _detailPair('Permission ${e.$1 + 1}', _formatAttributes(e.$2)),
            ),
          ],
          if (data.flags.needsRegularization ||
              data.flags.isLate ||
              data.flags.excessBreak ||
              data.flags.isLocked) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (data.flags.needsRegularization)
                  _flagChip('Needs regularization'),
                if (data.flags.isLate) _flagChip('Late punch'),
                if (data.flags.excessBreak) _flagChip('Excess break'),
                if (data.flags.isLocked) _flagChip('Record locked'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailPair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SomaflowTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: SomaflowTheme.textCharcoal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /* ----------------------------- SMALL PIECES ------------------------ */

  Widget _statusPill(String status) {
    final upper = status.toUpperCase();
    final Color fg;
    final Color bg;
    final Color bd;

    if (upper.contains('PRESENT') || upper == 'IN') {
      fg = SomaflowTheme.statusGreen;
      bg = SomaflowTheme.statusGreenBg;
      bd = SomaflowTheme.statusGreenBorder;
    } else if (upper.contains('HALF')) {
      fg = SomaflowTheme.halfDayAmber;
      bg = SomaflowTheme.halfDayBg;
      bd = SomaflowTheme.halfDayBorder;
    } else if (upper == 'LEAVE' ||
        upper == 'ABSENT' ||
        upper == 'OUT' ||
        upper == 'INSUFFICIENT') {
      fg = SomaflowTheme.absentCoral;
      bg = SomaflowTheme.absentBg;
      bd = SomaflowTheme.absentBorder;
    } else {
      fg = SomaflowTheme.textMuted;
      bg = SomaflowTheme.chipBackground;
      bd = SomaflowTheme.borderLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bd),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _requestAction(
    String label,
    AttendanceRequestType type,
    DateTime? date, {
    bool isSolid = false,
  }) {
    return ElevatedButton.icon(
      onPressed: date == null ? null : () => _openRequest(type, date),
      icon: Icon(
        type == AttendanceRequestType.regularization
            ? Icons.edit_calendar_outlined
            : type == AttendanceRequestType.leave
                ? Icons.event_available_outlined
                : Icons.description_outlined,
        size: 16,
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSolid ? Colors.white : SomaflowTheme.sageDeep,
        backgroundColor:
            isSolid ? SomaflowTheme.sagePrimary : SomaflowTheme.chipBackground,
        elevation: isSolid ? 1 : 0,
        side: isSolid
            ? BorderSide.none
            : const BorderSide(color: SomaflowTheme.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _flagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SomaflowTheme.halfDayBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SomaflowTheme.halfDayBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SomaflowTheme.halfDayAmber,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _lopChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SomaflowTheme.absentBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SomaflowTheme.absentBorder),
      ),
      child: Text(
        'LOP $value',
        style: const TextStyle(
          color: SomaflowTheme.absentCoral,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorCard(String message, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SomaflowTheme.absentBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SomaflowTheme.absentBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: SomaflowTheme.absentCoral, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: SomaflowTheme.absentCoral,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: SomaflowTheme.absentCoral,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: SomaflowTheme.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: SomaflowTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SomaflowTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

class _Metric {
  const _Metric(
    this.label,
    this.value,
    this.suffix,
    this.icon,
    this.badge,
    this.color,
    this.bg,
  );

  final String label, value, suffix;
  final IconData icon;
  final String? badge;
  final Color color, bg;
}

/// Somaflow ambient organic ripples
class _SomaflowBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintSage = Paint()
      ..color = SomaflowTheme.sageMuted.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final paintSand = Paint()
      ..color = SomaflowTheme.warmSand.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(size.width * 0.45, 0, size.width * 0.55, size.height * 0.18, 0,
            size.height * 0.28)
        ..close(),
      paintSage,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, 0)
        ..cubicTo(size.width * 0.75, size.height * 0.08, size.width,
            size.height * 0.04, size.width, size.height * 0.20)
        ..lineTo(size.width, 0)
        ..close(),
      paintSand,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */

bool _isAbsent(AttendanceDaySummary day) {
  final s = day.status.toUpperCase();
  if (s == 'ABSENT') return true;
  const nonWorking = {'WEEKLY_OFF', 'HOLIDAY', 'LEAVE', 'HALF_DAY'};
  return !nonWorking.contains(s) && day.firstIn == null && day.lastOut == null;
}

bool _shouldShowRegularization(AttendanceDaySummary day) {
  final s = day.status.toUpperCase();
  if (s == 'WEEKLY_OFF' || s == 'HOLIDAY' || s == 'LEAVE') {
    return day.needsRegularization;
  }
  return day.needsRegularization || day.firstIn == null || day.lastOut == null;
}

bool _hasLop(AttendanceDaySummary day) =>
    (double.tryParse(day.lopValue) ?? 0) > 0;

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dateLabel(DateTime? date) {
  if (date == null) return 'Date unavailable';
  return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}';
}

String _statusLabel(String status) => status
    .toLowerCase()
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

String _formatTime(DateTime? date) {
  if (date == null) return '—';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _formatDuration(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

String _formatAttributes(Map<String, dynamic> attributes) {
  final values = attributes.entries
      .where((e) => e.value != null)
      .map((e) => '${e.key.replaceAll('_', ' ')}: ${e.value}')
      .take(3)
      .toList();
  return values.isEmpty ? '—' : values.join(' · ');
}

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];

String _weekdayName(int weekday) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];