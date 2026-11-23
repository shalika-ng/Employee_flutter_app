// Dart port of the TypeScript interfaces in the web requestSlice.

String _s(dynamic v) => v?.toString() ?? '';
String? _sn(dynamic v) => v?.toString();
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

enum RequestKind { leave, permission, regularization }

class RequestMonthFilter {
  final int month;
  final int year;
  const RequestMonthFilter({required this.month, required this.year});

  String get query => '?month=$month&year=$year';

  @override
  bool operator ==(Object other) =>
      other is RequestMonthFilter && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

/* ------------------------------- LEAVE ---------------------------------- */

class LeaveRequestPayload {
  final String fromDate; // yyyy-MM-dd
  final String toDate;
  final String reason;
  const LeaveRequestPayload({
    required this.fromDate,
    required this.toDate,
    required this.reason,
  });

  Map<String, dynamic> toJson() =>
      {'from_date': fromDate, 'to_date': toDate, 'reason': reason};
}

class LeaveRequest {
  final String id;
  final String userId;
  final String fromDate;
  final String toDate;
  final String days;
  final String reason;
  final bool isRetroactive;
  final String status;
  final String createdAt;
  final String? updatedAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    required this.isRetroactive,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: _s(j['id']),
        userId: _s(j['user_id']),
        fromDate: _s(j['from_date']),
        toDate: _s(j['to_date']),
        days: _s(j['days']),
        reason: _s(j['reason']),
        isRetroactive: j['is_retroactive'] == true,
        status: _s(j['status']),
        createdAt: _s(j['created_at']),
        updatedAt: _sn(j['updated_at']),
      );
}

class LeaveBalance {
  final double current;
  final double pendingReserved;
  final double availableAfterReservation;

  const LeaveBalance({
    required this.current,
    required this.pendingReserved,
    required this.availableAfterReservation,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> j) => LeaveBalance(
        current: _d(j['current']),
        pendingReserved: _d(j['pending_reserved']),
        availableAfterReservation: _d(j['available_after_reservation']),
      );
}

class LeaveApplyResult {
  final LeaveRequest leaveRequest;
  final LeaveBalance balance;
  const LeaveApplyResult(this.leaveRequest, this.balance);

  factory LeaveApplyResult.fromJson(Map<String, dynamic> j) => LeaveApplyResult(
        LeaveRequest.fromJson(j['leave_request'] as Map<String, dynamic>),
        LeaveBalance.fromJson(j['balance'] as Map<String, dynamic>),
      );
}

/* ----------------------------- PERMISSION ------------------------------- */

class PermissionBalance {
  final int month;
  final int year;
  final int monthlyLimit;
  final int usedMinutes;
  final int pendingMinutes;
  final int remainingMinutes;

  const PermissionBalance({
    required this.month,
    required this.year,
    required this.monthlyLimit,
    required this.usedMinutes,
    required this.pendingMinutes,
    required this.remainingMinutes,
  });

  factory PermissionBalance.fromJson(Map<String, dynamic> j) =>
      PermissionBalance(
        month: _i(j['month']),
        year: _i(j['year']),
        monthlyLimit: _i(j['monthly_limit']),
        usedMinutes: _i(j['used_minutes']),
        pendingMinutes: _i(j['pending_minutes']),
        remainingMinutes: _i(j['remaining_minutes']),
      );

  PermissionBalance copyWith({
    int? usedMinutes,
    int? pendingMinutes,
    int? remainingMinutes,
  }) =>
      PermissionBalance(
        month: month,
        year: year,
        monthlyLimit: monthlyLimit,
        usedMinutes: usedMinutes ?? this.usedMinutes,
        pendingMinutes: pendingMinutes ?? this.pendingMinutes,
        remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      );
}

class PermissionRequestPayload {
  final String permDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final int minutes;
  final String reason;
  const PermissionRequestPayload({
    required this.permDate,
    required this.startTime,
    required this.minutes,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'perm_date': permDate,
        'start_time': startTime,
        'minutes': minutes,
        'reason': reason,
      };
}

class PermissionRequest {
  final String id;
  final String userId;
  final String permDate;
  final String startTime;
  final int minutes;
  final String reason;
  final bool isRetroactive;
  final String status;
  final String createdAt;
  final String? updatedAt;

  const PermissionRequest({
    required this.id,
    required this.userId,
    required this.permDate,
    required this.startTime,
    required this.minutes,
    required this.reason,
    required this.isRetroactive,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> j) =>
      PermissionRequest(
        id: _s(j['id']),
        userId: _s(j['user_id']),
        permDate: _s(j['perm_date']),
        startTime: _s(j['start_time']),
        minutes: _i(j['minutes']),
        reason: _s(j['reason']),
        isRetroactive: j['is_retroactive'] == true,
        status: _s(j['status']),
        createdAt: _s(j['created_at']),
        updatedAt: _sn(j['updated_at']),
      );
}

class PermissionApplyBalance {
  final int monthlyLimit;
  final int approvedMinutes;
  final int pendingMinutes;
  final int remainingAfterReservation;

  const PermissionApplyBalance({
    required this.monthlyLimit,
    required this.approvedMinutes,
    required this.pendingMinutes,
    required this.remainingAfterReservation,
  });

  factory PermissionApplyBalance.fromJson(Map<String, dynamic> j) =>
      PermissionApplyBalance(
        monthlyLimit: _i(j['monthly_limit']),
        approvedMinutes: _i(j['approved_minutes']),
        pendingMinutes: _i(j['pending_minutes']),
        remainingAfterReservation: _i(j['remaining_after_reservation']),
      );
}

class PermissionApplyResult {
  final PermissionRequest permissionRequest;
  final PermissionApplyBalance balance;
  const PermissionApplyResult(this.permissionRequest, this.balance);

  factory PermissionApplyResult.fromJson(Map<String, dynamic> j) =>
      PermissionApplyResult(
        PermissionRequest.fromJson(
            j['permission_request'] as Map<String, dynamic>),
        PermissionApplyBalance.fromJson(j['balance'] as Map<String, dynamic>),
      );
}

/* --------------------------- REGULARIZATION ----------------------------- */

/// Must match backend values: MISSED_IN | MISSED_OUT | BOTH
const regularizationTypes = ['MISSED_IN', 'MISSED_OUT', 'BOTH'];

class RegularizationRequestPayload {
  final String workDate; // yyyy-MM-dd
  final String type;
  final String? claimedIn;
  final String? claimedOut;
  final String reason;

  const RegularizationRequestPayload({
    required this.workDate,
    required this.type,
    this.claimedIn,
    this.claimedOut,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'work_date': workDate,
        'type': type,
        if (claimedIn != null) 'claimed_in': claimedIn,
        if (claimedOut != null) 'claimed_out': claimedOut,
        'reason': reason,
      };
}

class RegularizationRequest {
  final String id;
  final String userId;
  final String workDate;
  final String type;
  final String? claimedIn;
  final String? claimedOut;
  final String reason;
  final String status;
  final String? decidedBy;
  final String? decidedAt;
  final String? decisionNote;
  final String createdAt;
  final String? updatedAt;

  const RegularizationRequest({
    required this.id,
    required this.userId,
    required this.workDate,
    required this.type,
    this.claimedIn,
    this.claimedOut,
    required this.reason,
    required this.status,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    required this.createdAt,
    this.updatedAt,
  });

  factory RegularizationRequest.fromJson(Map<String, dynamic> j) =>
      RegularizationRequest(
        id: _s(j['id']),
        userId: _s(j['user_id']),
        workDate: _s(j['work_date']),
        type: _s(j['type']),
        claimedIn: _sn(j['claimed_in']),
        claimedOut: _sn(j['claimed_out']),
        reason: _s(j['reason']),
        status: _s(j['status']),
        decidedBy: _sn(j['decided_by']),
        decidedAt: _sn(j['decided_at']),
        decisionNote: _sn(j['decision_note']),
        createdAt: _s(j['created_at']),
        updatedAt: _sn(j['updated_at']),
      );
}