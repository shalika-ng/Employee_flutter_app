class EmployeeCalendar {
  const EmployeeCalendar({
    required this.month,
    required this.year,
    required this.days,
    required this.events,
  });

  factory EmployeeCalendar.fromJson(Map<String, dynamic> json) {
    final month = json['month'];
    final year = json['year'];
    final days = json['days'];
    final events = json['events'];
    if (month is! int ||
        month < 1 ||
        month > 12 ||
        year is! int ||
        days is! List ||
        events is! List) {
      throw const FormatException('Invalid calendar response.');
    }
    return EmployeeCalendar(
      month: month,
      year: year,
      days: days.map((item) => CalendarDay.fromJson(_map(item))).toList(),
      events: events.map((item) => CalendarEvent.fromJson(_map(item))).toList(),
    );
  }

  final int month;
  final int year;
  final List<CalendarDay> days;
  final List<CalendarEvent> events;

  List<CalendarEvent> get holidays =>
      events.where((event) => event.isHoliday).toList()
        ..sort((a, b) => (a.date ?? '').compareTo(b.date ?? ''));
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.attendanceStatus,
    required this.events,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    final events = json['events'];
    final attendance = json['attendance'];
    if (date is! String || DateTime.tryParse(date) == null || events is! List) {
      throw const FormatException('Invalid calendar day.');
    }
    return CalendarDay(
      date: date,
      attendanceStatus: attendance == null
          ? null
          : _map(attendance)['status'] as String?,
      events: events.map((item) => CalendarEvent.fromJson(_map(item))).toList(),
    );
  }

  final String date;
  final String? attendanceStatus;
  final List<CalendarEvent> events;
}

class CalendarEvent {
  const CalendarEvent({
    required this.type,
    this.name,
    this.date,
    this.fromDate,
    this.toDate,
    this.days,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Invalid calendar event.');
    }
    return CalendarEvent(
      type: type,
      name: json['name'] as String?,
      date: json['date'] as String?,
      fromDate: json['from_date'] as String?,
      toDate: json['to_date'] as String?,
      days: json['days'] as num?,
    );
  }

  final String type;
  final String? name;
  final String? date;
  final String? fromDate;
  final String? toDate;
  final num? days;

  bool get isHoliday => type == 'COMMON_HOLIDAY' || type == 'EMPLOYEE_HOLIDAY';

  String get label => switch (type) {
    'COMMON_HOLIDAY' => 'Common holiday',
    'EMPLOYEE_HOLIDAY' => 'Employee holiday',
    'PENDING_LEAVE' => 'Pending leave',
    _ => type.replaceAll('_', ' ').toLowerCase(),
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Invalid calendar data.');
}
