import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../app/theme/app_theme.dart';
import '../../../redux/app_state.dart';
import '../models/attendance_models.dart';
import '../redux/attendance_actions.dart';
import '../redux/attendance_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

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
                ),
                backgroundColor: AppTheme.darkSlate,
              ),
            );
          });
        }
      },
      builder: (context, state) {
        return Container(
          color: AppTheme.scaffoldBg,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.darkSlate,
                    onRefresh: () async {
                      _loadMonth();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 350),
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(height: 14),
                        if (state.monthData != null)
                          _buildEmployeeCard(state.monthData!.employee),
                        if (state.monthData != null) ...[
                          const SizedBox(height: 14),
                          _buildTodayCard(state.monthData!.today),
                          const SizedBox(height: 18),
                          _buildSummary(state.monthData!.totals),
                          const SizedBox(height: 22),
                        ],
                        _buildAttendanceList(state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AttendanceState state) {
    final employee = state.monthData?.employee;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.darkSlate,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  employee == null
                      ? 'Monthly summary and daily records'
                      : '${employee.name} · ${employee.empCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh attendance',
            onPressed: _loadMonth,
            icon: const Icon(Icons.refresh_rounded),
            color: AppTheme.darkSlate,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppTheme.darkSlate,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_monthName(_month.month)} ${_month.year}',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous month',
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.darkSlate,
          ),
          IconButton(
            tooltip: 'Next month',
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.darkSlate,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(AttendanceEmployee employee) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSlate,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${employee.designation} · ${employee.empCode}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(AttendanceToday today) {
    final isIn = today.status.toUpperCase() == 'IN';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIn ? Icons.login_rounded : Icons.schedule_rounded,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Today',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _statusPill(today.status),
          if (today.lastPunch != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(today.lastPunch),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(AttendanceTotals totals) {
    final items = [
      ('Present', totals.present.toString(), Icons.check_circle_outline),
      ('Half day', totals.half.toString(), Icons.timelapse_rounded),
      ('Leave', totals.leave.toString(), Icons.event_busy_outlined),
      ('Work time', _formatDuration(totals.workMinutes), Icons.schedule),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly summary',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w800,
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
            mainAxisExtent: 82,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Icon(item.$3, color: AppTheme.darkSlate, size: 21),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
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

  Widget _buildAttendanceList(AttendanceState state) {
    if (state.monthStatus == AttendanceLoadStatus.loading &&
        state.monthData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.darkSlate),
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
                'Attendance history',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (state.monthStatus == AttendanceLoadStatus.loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.darkSlate,
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
          _emptyCard('No attendance records for this month.'),
        ...days.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _dayCard(day, state),
          ),
        ),
      ],
    );
  }

  Widget _dayCard(AttendanceDaySummary day, AttendanceState state) {
    final dateKey = day.workDate == null ? '' : _dateKey(day.workDate!);
    final selected = state.selectedDate == dateKey;
    final showRegularization = _shouldShowRegularization(day);
    final showLopActions = _hasLop(day);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppTheme.primarySky : const Color(0xFFE8EEF4),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: dateKey.isEmpty ? null : () => _loadDay(day.workDate!),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _dateBadge(day.workDate),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateLabel(day.workDate),
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'IN  ${_formatTime(day.firstIn)}    OUT  ${_formatTime(day.lastOut)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusPill(day.status),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        _smallMetric(
                          Icons.timer_outlined,
                          _formatDuration(day.workMinutes),
                        ),
                        const SizedBox(width: 16),
                        if (showLopActions)
                          _smallMetric(
                            Icons.remove_circle_outline,
                            'LOP ${day.lopValue}',
                            color: const Color(0xFFB45309),
                          ),
                        if (day.isLate) ...[
                          const SizedBox(width: 12),
                          _smallMetric(
                            Icons.schedule,
                            'Late',
                            color: const Color(0xFFB45309),
                          ),
                        ],
                        if (day.needsRegularization) ...[
                          const SizedBox(width: 12),
                          _smallMetric(
                            Icons.info_outline,
                            'Review',
                            color: const Color(0xFFB45309),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          selected
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.chevron_right_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (showRegularization || showLopActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (showRegularization)
                        _displayOnlyAction('Apply regularization'),
                      if (showLopActions) ...[
                        _displayOnlyAction('Apply leave'),
                        _displayOnlyAction('Apply permission'),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date == null
                                ? 'Attendance details'
                                : _weekdayName(date.weekday),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.date,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
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
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: _buildDayDetails(dayState),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.darkSlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
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
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.darkSlate),
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
                  'Day details',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                data.date,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary == null)
            const Text(
              'No day summary is available.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
            const SizedBox(height: 14),
            _detailPair('First in', _formatTime(summary.firstIn)),
            _detailPair('Last out', _formatTime(summary.lastOut)),
            _detailPair('Break', _formatDuration(summary.breakMinutes)),
            _detailPair(
              'Permission',
              _formatDuration(summary.permissionMinutes),
            ),
          ],
          if (data.sessions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 18),
            const Text(
              'Sessions',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...data.sessions.map(
              (session) => _detailPair(
                session.flag ?? 'Session',
                '${_formatTime(session.inAt)} – ${_formatTime(session.outAt)}'
                '${session.durationMinutes == null ? '' : ' · ${_formatDuration(session.durationMinutes!)}'}',
              ),
            ),
          ],
          if (data.punches.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 18),
            const Text(
              'Punch log',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...data.punches.map(
              (punch) => _detailPair(
                '${punch.direction}${punch.isCorrection ? ' · Correction' : ''}',
                '${_formatTime(punch.punchedAt)}'
                    '${punch.sourceType.isEmpty ? '' : ' · ${punch.sourceType}'}',
              ),
            ),
          ],
          if (data.punches.isEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 18),
            const Text(
              'Punch log',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '—',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (data.breakGaps.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 18),
            const Text(
              'Break gaps',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...data.breakGaps.indexed.map(
              (entry) => _detailPair(
                'Break ${entry.$1 + 1}',
                _formatAttributes(entry.$2),
              ),
            ),
          ],
          if (data.permissions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 18),
            const Text(
              'Permissions',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...data.permissions.indexed.map(
              (entry) => _detailPair(
                'Permission ${entry.$1 + 1}',
                _formatAttributes(entry.$2),
              ),
            ),
          ],
          if (data.flags.needsRegularization ||
              data.flags.isLate ||
              data.flags.excessBreak ||
              data.flags.isLocked) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (data.flags.needsRegularization)
                  _flagChip('Needs regularization'),
                if (data.flags.isLate) _flagChip('Late'),
                if (data.flags.excessBreak) _flagChip('Excess break'),
                if (data.flags.isLocked) _flagChip('Locked'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailPair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBadge(DateTime? date) {
    return Container(
      width: 42,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date == null ? '—' : date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppTheme.darkSlate,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            date == null ? '' : _weekdayShort(date.weekday),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final upper = status.toUpperCase();
    final (Color foreground, Color background) = switch (upper) {
      'PRESENT' || 'IN' => (const Color(0xFF167447), const Color(0xFFE6F7EE)),
      'LEAVE' => (const Color(0xFF315D8A), const Color(0xFFEAF2FB)),
      'WEEKLY_OFF' ||
      'HOLIDAY' => (const Color(0xFF64748B), const Color(0xFFF1F5F9)),
      'HALF_DAY' => (const Color(0xFF9A6700), const Color(0xFFFFF5D6)),
      'INSUFFICIENT' ||
      'ABSENT' ||
      'OUT' => (const Color(0xFFB42336), const Color(0xFFFFEBEE)),
      _ => (const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _smallMetric(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? const Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _displayOnlyAction(String label) {
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FA),
          border: Border.all(color: const Color(0xFFC9D8E8)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkSlate,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42336), size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ),
    );
  }

  Widget _flagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9A6700),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _lopChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'LOP $value',
        style: const TextStyle(
          color: Color(0xFFB42336),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    border: Border.all(color: const Color(0xFFE8EEF4)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1E293B).withValues(alpha: 0.035),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

bool _shouldShowRegularization(AttendanceDaySummary day) =>
    day.needsRegularization || day.firstIn == null || day.lastOut == null;

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
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key.replaceAll('_', ' ')}: ${entry.value}')
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

String _weekdayShort(int weekday) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][weekday - 1];
