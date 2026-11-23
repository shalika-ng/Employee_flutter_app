import '../models/request_models.dart';
import '../redux/request_state.dart';

/// Unified card model used by RequestsScreen (same fields as your mock).
class RequestItemData {
  final String rawId; // real backend id (used for cancel)
  final String id; // short display id
  final String type; // LEAVE | PERMISSION | REGULARIZE
  final String categoryTag;
  final String status; // PENDING | APPROVED | CANCELLED | REJECTED
  final String impact;
  final String dateRange;
  final String subInfo;
  final String reason;
  final String appliedOn;
  final String actionLabel;
  final bool isCancelable;
  final DateTime sortKey;

  const RequestItemData({
    required this.rawId,
    required this.id,
    required this.type,
    required this.categoryTag,
    required this.status,
    required this.impact,
    required this.dateRange,
    required this.subInfo,
    required this.reason,
    required this.appliedOn,
    required this.actionLabel,
    required this.isCancelable,
    required this.sortKey,
  });
}

class RequestPageService {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static String formatDate(String raw, {bool withYear = false}) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final l = raw.contains('T') ? d.toLocal() : d;
    final base = '${l.day.toString().padLeft(2, '0')} ${_months[l.month - 1]}';
    return withYear ? '$base ${l.year}' : base;
  }

  /// Accepts "16:00", "16:00:00" or a full ISO timestamp.
  static String formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    int? h, m;
    final dt = DateTime.tryParse(raw);
    if (dt != null && raw.contains('T')) {
      final l = dt.toLocal();
      h = l.hour;
      m = l.minute;
    } else {
      final p = raw.split(':');
      if (p.length >= 2) {
        h = int.tryParse(p[0]);
        m = int.tryParse(p[1]);
      }
    }
    if (h == null || m == null) return raw;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  static String _dateTime(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${formatDate(raw)}, ${formatTime(raw)}';
  }

  static String _shortId(String prefix, String id) {
    final clean = id.replaceAll('-', '');
    final tail = clean.length > 4 ? clean.substring(0, 4) : clean;
    return '#$prefix-${tail.toUpperCase()}';
  }

  static String _dayLabel(String days) {
    final n = double.tryParse(days);
    if (n == null) return days;
    final txt = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
    return '$txt ${n == 1 ? 'Day' : 'Days'}';
  }

  static String _minLabel(int m) {
    if (m % 60 == 0 && m >= 60) {
      final h = m ~/ 60;
      return '$h ${h == 1 ? 'Hour' : 'Hours'}';
    }
    return '$m Mins';
  }

  static String _regType(String t) {
    switch (t.toUpperCase()) {
      case 'MISSED_IN':
        return 'Missed In';
      case 'MISSED_OUT':
        return 'Missed Out';
      case 'BOTH':
        return 'Missed In & Out';
      default:
        return t;
    }
  }

  static DateTime _sort(String raw) =>
      DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);

  static List<RequestItemData> buildItems(RequestState s) {
    final items = <RequestItemData>[];

    for (final r in s.leaveRequests) {
      final status = r.status.toUpperCase();
      final same = r.fromDate == r.toDate;
      items.add(RequestItemData(
        rawId: r.id,
        id: _shortId('LR', r.id),
        type: 'LEAVE',
        categoryTag: r.isRetroactive ? 'Retroactive Leave' : 'Leave Request',
        status: status,
        impact: '-${_dayLabel(r.days)}',
        dateRange: same
            ? formatDate(r.fromDate, withYear: true)
            : '${formatDate(r.fromDate)} – ${formatDate(r.toDate, withYear: true)}',
        subInfo: _dayLabel(r.days),
        reason: r.reason,
        appliedOn: 'Applied ${_dateTime(r.createdAt)}',
        actionLabel: status == 'PENDING' ? 'Cancel request' : _statusNote(status),
        isCancelable: status == 'PENDING',
        sortKey: _sort(r.createdAt),
      ));
    }

    for (final r in s.permissionRequests) {
      final status = r.status.toUpperCase();
      items.add(RequestItemData(
        rawId: r.id,
        id: _shortId('PR', r.id),
        type: 'PERMISSION',
        categoryTag: r.isRetroactive ? 'Retroactive Permission' : 'Short Permission',
        status: status,
        impact: '-${r.minutes} Mins',
        dateRange: formatDate(r.permDate, withYear: true),
        subInfo: '${formatTime(r.startTime)} (${_minLabel(r.minutes)})',
        reason: r.reason,
        appliedOn: 'Applied ${_dateTime(r.createdAt)}',
        actionLabel: status == 'PENDING' ? 'Cancel request' : _statusNote(status),
        isCancelable: status == 'PENDING',
        sortKey: _sort(r.createdAt),
      ));
    }

    for (final r in s.regularizationRequests) {
      final status = r.status.toUpperCase();
      final parts = <String>[];
      if (r.claimedIn != null) parts.add('IN: ${formatTime(r.claimedIn)}');
      if (r.claimedOut != null) parts.add('OUT: ${formatTime(r.claimedOut)}');
      items.add(RequestItemData(
        rawId: r.id,
        id: _shortId('RR', r.id),
        type: 'REGULARIZE',
        categoryTag: 'Punch Correction',
        status: status,
        impact: _regType(r.type),
        dateRange: formatDate(r.workDate, withYear: true),
        subInfo: parts.isEmpty ? '—' : '${parts.join(' · ')} (Claimed)',
        reason: r.reason,
        appliedOn: status == 'PENDING'
            ? 'Awaiting manager review'
            : (r.decidedAt != null
                ? 'Decided ${_dateTime(r.decidedAt!)}'
                : _statusNote(status)),
        actionLabel: r.decisionNote?.isNotEmpty == true
            ? r.decisionNote!
            : _statusNote(status),
        isCancelable: false, // web slice has no regularization cancel API
        sortKey: _sort(r.createdAt),
      ));
    }

    items.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return items;
  }

  static String _statusNote(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}