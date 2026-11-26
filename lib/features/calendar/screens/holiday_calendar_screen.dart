import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/somaflow_theme.dart';
import '../models/calendar_model.dart';
import '../services/calendar_service.dart';

typedef CalendarLoader = Future<EmployeeCalendar> Function(
  int month,
  int year,
  String token,
);

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({
    required this.token,
    this.loader,
    this.initialDate,
    super.key,
  });

  final String? token;
  final CalendarLoader? loader;
  final DateTime? initialDate;

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  late DateTime _today;
  late DateTime _month;
  late DateTime _selected;
  Future<EmployeeCalendar>? _future;
  final _service = CalendarService();

  @override
  void initState() {
    super.initState();
    _today = widget.initialDate ?? DateTime.now();
    _month = DateTime(_today.year, _today.month);
    _selected = DateTime(_today.year, _today.month, _today.day);
    _load();
  }

  @override
  void didUpdateWidget(HolidayCalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token || oldWidget.loader != widget.loader) {
      _load();
    }
  }

  void _load() {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      _future = null;
      return;
    }
    _future = widget.loader != null
        ? widget.loader!(_month.month, _month.year, token)
        : _service.getMyCalendar(
            month: _month.month,
            year: _month.year,
            token: token,
          );
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selected = _month.year == _today.year && _month.month == _today.month
          ? DateTime(_today.year, _today.month, _today.day)
          : _month;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: FutureBuilder<EmployeeCalendar>(
        key: ValueKey('${_month.year}-${_month.month}'),
        future: _future,
        builder: (context, snapshot) {
          final calendar = snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EMPLOYEE CALENDAR',
                  style: TextStyle(
                    color: SomaflowTheme.sageDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Holiday Calendar',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Holidays, weekly offs and leave at a glance.',
                  style: TextStyle(
                    color: SomaflowTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _monthButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Previous month',
                            onPressed: () => _changeMonth(-1),
                          ),
                          Expanded(
                            child: Text(
                              localizations.formatMonthYear(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: SomaflowTheme.textCharcoal,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _monthButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Next month',
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _calendarGrid(context, calendar),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _Legend(color: _common, label: 'Common'),
                          _Legend(color: _employee, label: 'Employee'),
                          _Legend(color: _pending, label: 'Pending leave'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_future == null)
                  _message('Sign in to view your calendar.')
                else if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: SomaflowTheme.sageDeep,
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.error is ApiException
                              ? (snapshot.error as ApiException).message
                              : 'Unable to load calendar. Please try again.',
                          style: const TextStyle(
                            color: SomaflowTheme.cancelCoral,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (calendar != null) ...[
                  _selectedDay(context, calendar),
                  const SizedBox(height: 16),
                  _holidayList(context, calendar),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _calendarGrid(BuildContext context, EmployeeCalendar? calendar) {
    final byDate = {
      for (final day in calendar?.days ?? <CalendarDay>[]) day.date: day,
    };
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final rows = ((firstWeekday + count) / 7).ceil();
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: SomaflowTheme.sageDeep,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dayNumber = row * 7 + col - firstWeekday + 1;
                      if (dayNumber < 1 || dayNumber > count) {
                        return const SizedBox(height: 52);
                      }
                      final date = DateTime(
                        _month.year,
                        _month.month,
                        dayNumber,
                      );
                      final day = byDate[_dateKey(date)];
                      final selected = DateUtils.isSameDay(date, _selected);
                      final today = DateUtils.isSameDay(date, _today);
                      final colors = <Color>{
                        for (final event in day?.events ?? <CalendarEvent>[])
                          if (_eventColor(event.type) case final Color color)
                            color,
                      };
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: [
                          MaterialLocalizations.of(context)
                              .formatFullDate(date),
                          if (today) 'Today',
                          for (final event in day?.events ?? <CalendarEvent>[])
                            event.name ?? event.label,
                        ].join(', '),
                        child: InkWell(
                          excludeFromSemantics: true,
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = date),
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? SomaflowTheme.sageWash
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(color: SomaflowTheme.sagePrimary)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 25,
                                  height: 25,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: today
                                        ? SomaflowTheme.sageDeep
                                        : null,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      color: today
                                          ? Colors.white
                                          : SomaflowTheme.textCharcoal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final color in colors)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _selectedDay(BuildContext context, EmployeeCalendar calendar) {
    final matching = calendar.days.where(
      (day) => day.date == _dateKey(_selected),
    );
    final day = matching.isEmpty ? null : matching.first;
    return _card(
      tint: const Color(0xFFF3F7F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('SELECTED DAY'),
          const SizedBox(height: 8),
          Text(
            MaterialLocalizations.of(context).formatFullDate(_selected),
            style: const TextStyle(
              color: SomaflowTheme.textCharcoal,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (day?.attendanceStatus case final String status) ...[
            const SizedBox(height: 6),
            Text(
              'Attendance: ${_readable(status)}',
              style: const TextStyle(
                color: SomaflowTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (day == null)
            const Text('No details available for this day.')
          else if (day.events.isEmpty)
            const Text(
              'No calendar event',
              style: TextStyle(color: SomaflowTheme.textMuted),
            )
          else
            for (final event in day.events) _eventDetail(context, event),
        ],
      ),
    );
  }

  Widget _eventDetail(BuildContext context, CalendarEvent event) {
    final color = _eventColor(event.type) ?? SomaflowTheme.sageDeep;
    final from = DateTime.tryParse(event.fromDate ?? '');
    final to = DateTime.tryParse(event.toDate ?? '');
    final localizations = MaterialLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name?.isNotEmpty == true ? event.name! : event.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            event.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (event.type == 'PENDING_LEAVE' && from != null && to != null) ...[
            const SizedBox(height: 5),
            Text(
              '${localizations.formatMediumDate(from)} – ${localizations.formatMediumDate(to)}${event.days == null ? '' : ' · ${event.days} day(s)'}',
              style: const TextStyle(
                color: SomaflowTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _holidayList(BuildContext context, EmployeeCalendar calendar) {
    final holidays = calendar.holidays;
    final localizations = MaterialLocalizations.of(context);
    return _card(
      tint: const Color(0xFFFAF6EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'This month',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SomaflowTheme.sageDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${holidays.length} ${holidays.length == 1 ? 'holiday' : 'holidays'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (holidays.isEmpty)
            const Text(
              'No holidays listed.',
              style: TextStyle(color: SomaflowTheme.textMuted),
            )
          else
            for (final event in holidays)
              Builder(
                builder: (context) {
                  final date = DateTime.tryParse(event.date ?? '');
                  final inMonth =
                      date != null &&
                      date.year == _month.year &&
                      date.month == _month.month;
                  final color =
                      _eventColor(event.type) ?? SomaflowTheme.sageDeep;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: inMonth
                        ? () => setState(() => _selected = date)
                        : null,
                    leading: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        date == null ? '—' : '${date.day}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    title: Text(
                      event.name?.isNotEmpty == true
                          ? event.name!
                          : event.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${date == null ? 'Date unavailable' : localizations.formatMediumDate(date)} · ${event.label}',
                      style: const TextStyle(
                        color: SomaflowTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: inMonth
                        ? const Icon(
                            Icons.chevron_right_rounded,
                            color: SomaflowTheme.sageMuted,
                          )
                        : null,
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _message(String message) => _card(child: Text(message));
}

const _common = Color(0xFFC85D44);
const _employee = Color(0xFF9B6A38);
const _pending = Color(0xFF5D6953);

Color? _eventColor(String type) => switch (type) {
  'COMMON_HOLIDAY' => _common,
  'EMPLOYEE_HOLIDAY' => _employee,
  'PENDING_LEAVE' => _pending,
  _ => null,
};

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _readable(String value) => value.replaceAll('_', ' ').toLowerCase();

Widget _card({required Widget child, Color tint = Colors.white}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: tint,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: SomaflowTheme.borderLight),
    boxShadow: [
      BoxShadow(
        color: SomaflowTheme.sageDark.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
  ),
  child: Material(color: Colors.transparent, child: child),
);

Widget _monthButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) => IconButton(
  onPressed: onPressed,
  tooltip: tooltip,
  icon: Icon(icon),
  color: SomaflowTheme.sageDeep,
  style: IconButton.styleFrom(
    backgroundColor: SomaflowTheme.sageWash,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: SomaflowTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: SomaflowTheme.sageDeep,
      fontWeight: FontWeight.w800,
      fontSize: 10,
      letterSpacing: 1.2,
    ),
  );
}
