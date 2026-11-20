class DashboardData {
  const DashboardData({
    required this.employee,
    required this.today,
    required this.month,
    required this.year,
    required this.days,
    required this.events,
    required this.lopDays,
    required this.leaveBalance,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final calendar = _asMap(json['calendar']);
    return DashboardData(
      employee: DashboardEmployee.fromJson(_asMap(json['employee'])),
      today: DashboardToday.fromJson(_asMap(json['today'])),
      month: _asInt(calendar['month']),
      year: _asInt(calendar['year']),
      days: _asList(calendar['days'])
          .map((item) => DashboardCalendarDay.fromJson(_asMap(item)))
          .toList(),
      events: _uniqueEvents(
        _asList(calendar['events'])
            .map((item) => DashboardEvent.fromJson(_asMap(item))),
      ),
      lopDays: _asInt(_asMap(json['lop'])['days']),
      leaveBalance: DashboardLeaveBalance.fromJson(
        _asMap(json['leave_balance']),
      ),
    );
  }

  final DashboardEmployee employee;
  final DashboardToday today;
  final int month;
  final int year;
  final List<DashboardCalendarDay> days;
  final List<DashboardEvent> events;
  final int lopDays;
  final DashboardLeaveBalance leaveBalance;

  int get presentDays =>
      days.where((day) => day.attendance?.status == 'PRESENT').length;

  int get workMinutes => days.fold(
    0,
    (total, day) => total + (day.attendance?.workMinutes ?? 0),
  );
}

class DashboardEmployee {
  const DashboardEmployee({
    required this.id,
    required this.empCode,
    required this.name,
    required this.designation,
  });

  factory DashboardEmployee.fromJson(Map<String, dynamic> json) {
    return DashboardEmployee(
      id: json['id']?.toString() ?? '',
      empCode: json['emp_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
    );
  }

  final String id;
  final String empCode;
  final String name;
  final String designation;
}

class DashboardToday {
  const DashboardToday({
    required this.date,
    required this.status,
    required this.punchInTime,
    required this.lastPunch,
  });

  factory DashboardToday.fromJson(Map<String, dynamic> json) {
    return DashboardToday(
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',
      punchInTime: _dateTime(json['punch_in_time']),
      lastPunch: _dateTime(json['last_punch']),
    );
  }

  final String date;
  final String status;
  final DateTime? punchInTime;
  final DateTime? lastPunch;
}

class DashboardCalendarDay {
  const DashboardCalendarDay({required this.date, required this.attendance});

  factory DashboardCalendarDay.fromJson(Map<String, dynamic> json) {
    final attendance = json['attendance'];
    return DashboardCalendarDay(
      date: json['date']?.toString() ?? '',
      attendance: attendance is Map
          ? DashboardDayAttendance.fromJson(_asMap(attendance))
          : null,
    );
  }

  final String date;
  final DashboardDayAttendance? attendance;
}

class DashboardDayAttendance {
  const DashboardDayAttendance({
    required this.status,
    required this.workMinutes,
  });

  factory DashboardDayAttendance.fromJson(Map<String, dynamic> json) {
    return DashboardDayAttendance(
      status: json['status']?.toString(),
      workMinutes: _asInt(json['work_min']),
    );
  }

  final String? status;
  final int workMinutes;
}

class DashboardEvent {
  const DashboardEvent({
    required this.type,
    required this.name,
    required this.date,
    required this.fromDate,
    required this.toDate,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? json['type']?.toString() ?? 'Event',
      date: json['date']?.toString(),
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
    );
  }

  final String type;
  final String name;
  final String? date;
  final String? fromDate;
  final String? toDate;

  String get startDate => date ?? fromDate ?? '';
}

class DashboardLeaveBalance {
  const DashboardLeaveBalance({
    required this.available,
    required this.total,
    required this.consumedThisMonth,
    required this.pendingDays,
  });

  factory DashboardLeaveBalance.fromJson(Map<String, dynamic> json) {
    return DashboardLeaveBalance(
      available: _asInt(json['available_balance']),
      total: _asInt(json['total_balance']),
      consumedThisMonth: _asInt(json['consumed_this_month']),
      pendingDays: _asInt(json['pending_days']),
    );
  }

  final int available;
  final int total;
  final int consumedThisMonth;
  final int pendingDays;
}

List<DashboardEvent> _uniqueEvents(Iterable<DashboardEvent> events) {
  final seen = <String>{};
  return events.where((event) {
    final key = '${event.type}|${event.name}|${event.startDate}|${event.toDate}';
    return seen.add(key);
  }).toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

int _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _dateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
