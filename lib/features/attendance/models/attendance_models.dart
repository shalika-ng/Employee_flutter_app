class AttendanceEmployee {
  const AttendanceEmployee({
    required this.id,
    required this.empCode,
    required this.name,
    required this.designation,
  });

  factory AttendanceEmployee.fromJson(Map<String, dynamic> json) {
    return AttendanceEmployee(
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

class AttendanceMonthData {
  const AttendanceMonthData({
    required this.employee,
    required this.month,
    required this.year,
    required this.days,
    required this.today,
    required this.totals,
  });

  factory AttendanceMonthData.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthData(
      employee: AttendanceEmployee.fromJson(_asMap(json['employee'])),
      month: _asInt(json['month']),
      year: _asInt(json['year']),
      days: _asList(json['day_summaries'])
          .map((item) => AttendanceDaySummary.fromJson(_asMap(item)))
          .toList(),
      today: AttendanceToday.fromJson(_asMap(json['today'])),
      totals: AttendanceTotals.fromJson(_asMap(json['totals'])),
    );
  }

  final AttendanceEmployee employee;
  final int month;
  final int year;
  final List<AttendanceDaySummary> days;
  final AttendanceToday today;
  final AttendanceTotals totals;
}

class AttendanceDaySummary {
  const AttendanceDaySummary({
    required this.id,
    required this.workDate,
    required this.status,
    required this.firstIn,
    required this.lastOut,
    required this.workMinutes,
    required this.breakMinutes,
    required this.permissionMinutes,
    required this.isLate,
    required this.excessBreak,
    required this.needsRegularization,
    required this.lopValue,
    required this.isLocked,
  });

  factory AttendanceDaySummary.fromJson(Map<String, dynamic> json) {
    return AttendanceDaySummary(
      id: json['id']?.toString() ?? '',
      workDate: _dateTime(json['work_date']),
      status: json['status']?.toString() ?? 'UNKNOWN',
      firstIn: _dateTime(json['first_in']),
      lastOut: _dateTime(json['last_out']),
      workMinutes: _asInt(json['work_min']),
      breakMinutes: _asInt(json['break_min']),
      permissionMinutes: _asInt(json['permission_min']),
      isLate: json['is_late'] == true,
      excessBreak: json['excess_break'] == true,
      needsRegularization: json['needs_regularization'] == true,
      lopValue: json['lop_value']?.toString() ?? '0.00',
      isLocked: json['is_locked'] == true,
    );
  }

  final String id;
  final DateTime? workDate;
  final String status;
  final DateTime? firstIn;
  final DateTime? lastOut;
  final int workMinutes;
  final int breakMinutes;
  final int permissionMinutes;
  final bool isLate;
  final bool excessBreak;
  final bool needsRegularization;
  final String lopValue;
  final bool isLocked;
}

class AttendanceToday {
  const AttendanceToday({
    required this.date,
    required this.status,
    required this.lastPunch,
  });

  factory AttendanceToday.fromJson(Map<String, dynamic> json) {
    return AttendanceToday(
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',
      lastPunch: _dateTime(json['last_punch']),
    );
  }

  final String date;
  final String status;
  final DateTime? lastPunch;
}

class AttendanceTotals {
  const AttendanceTotals({
    required this.present,
    required this.half,
    required this.absent,
    required this.leave,
    required this.holiday,
    required this.weeklyOff,
    required this.insufficient,
    required this.lateCount,
    required this.workMinutes,
  });

  factory AttendanceTotals.fromJson(Map<String, dynamic> json) {
    final workMinutes = json['work_minutes'];
    return AttendanceTotals(
      present: _asInt(json['present']),
      half: _asInt(json['half']),
      absent: _asInt(json['absent']),
      leave: _asInt(json['leave']),
      holiday: _asInt(json['holiday']),
      weeklyOff: _asInt(json['weekly_off']),
      insufficient: _asInt(json['insufficient']),
      lateCount: _asInt(json['late_count']),
      workMinutes: workMinutes == null
          ? _asInt(json['work_hours']) * 60
          : _asInt(workMinutes),
    );
  }

  final int present;
  final int half;
  final int absent;
  final int leave;
  final int holiday;
  final int weeklyOff;
  final int insufficient;
  final int lateCount;
  final int workMinutes;
}

class AttendanceDayData {
  const AttendanceDayData({
    required this.employee,
    required this.date,
    required this.summary,
    required this.sessions,
    required this.punches,
    required this.breakGaps,
    required this.flags,
    required this.permissions,
  });

  factory AttendanceDayData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    return AttendanceDayData(
      employee: AttendanceEmployee.fromJson(_asMap(json['employee'])),
      date: json['date']?.toString() ?? '',
      summary: summary is Map
          ? AttendanceDaySummary.fromJson(_asMap(summary))
          : null,
      sessions: _asList(json['sessions'])
          .map((item) => AttendanceSession.fromJson(_asMap(item)))
          .toList(),
      punches: _asList(json['punches'])
          .map((item) => AttendancePunch.fromJson(_asMap(item)))
          .toList(),
      breakGaps: _asList(json['break_gaps']).map(_asMap).toList(),
      flags: AttendanceFlags.fromJson(_asMap(json['flags'])),
      permissions: _asList(json['permissions']).map(_asMap).toList(),
    );
  }

  final AttendanceEmployee employee;
  final String date;
  final AttendanceDaySummary? summary;
  final List<AttendanceSession> sessions;
  final List<AttendancePunch> punches;
  final List<Map<String, dynamic>> breakGaps;
  final AttendanceFlags flags;
  final List<Map<String, dynamic>> permissions;
}

class AttendanceSession {
  const AttendanceSession({
    required this.inAt,
    required this.outAt,
    required this.durationMinutes,
    required this.flag,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      inAt: _dateTime(json['in_at']),
      outAt: _dateTime(json['out_at']),
      durationMinutes: json['duration_min'] == null
          ? null
          : _asInt(json['duration_min']),
      flag: json['flag']?.toString(),
    );
  }

  final DateTime? inAt;
  final DateTime? outAt;
  final int? durationMinutes;
  final String? flag;
}

class AttendancePunch {
  const AttendancePunch({
    required this.punchedAt,
    required this.direction,
    required this.sourceType,
    required this.isCorrection,
    required this.reason,
  });

  factory AttendancePunch.fromJson(Map<String, dynamic> json) {
    return AttendancePunch(
      punchedAt: _dateTime(json['punched_at']),
      direction: json['direction']?.toString() ?? 'UNKNOWN',
      sourceType: json['source_type']?.toString() ?? '',
      isCorrection: json['is_correction'] == true,
      reason: json['reason']?.toString(),
    );
  }

  final DateTime? punchedAt;
  final String direction;
  final String sourceType;
  final bool isCorrection;
  final String? reason;
}

class AttendanceFlags {
  const AttendanceFlags({
    required this.needsRegularization,
    required this.isLate,
    required this.excessBreak,
    required this.isLocked,
  });

  factory AttendanceFlags.fromJson(Map<String, dynamic> json) {
    return AttendanceFlags(
      needsRegularization: json['needs_regularization'] == true,
      isLate: json['is_late'] == true,
      excessBreak: json['excess_break'] == true,
      isLocked: json['is_locked'] == true,
    );
  }

  final bool needsRegularization;
  final bool isLate;
  final bool excessBreak;
  final bool isLocked;
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
