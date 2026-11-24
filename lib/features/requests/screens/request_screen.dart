import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../core/somaflow_theme.dart';
import '../../../redux/app_state.dart';
import '../models/request_models.dart';
import '../redux/request_actions.dart';
import '../redux/request_state.dart';
import '../services/request_page_service.dart';
import 'apply_leave_screen.dart';
import 'apply_permission_screen.dart';
import 'apply_regularization_screen.dart';

class RequestsScreen extends StatefulWidget {
  /// When true (used inside the home tab shell) the screen renders only its
  /// scrollable body: no Scaffold, background painter or SafeArea.
  final bool embedded;
  const RequestsScreen({super.key, this.embedded = false});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _activeCategory = 'ALL';
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  RequestMonthFilter get _filter =>
      RequestMonthFilter(month: _month.month, year: _month.year);

  void _reload(Store<AppState> store) {
    store.dispatch(FetchLeaveRequestsAction(_filter));
    store.dispatch(FetchPermissionRequestsAction(_filter));
    store.dispatch(FetchRegularizationRequestsAction(_filter));
    store.dispatch(FetchPermissionBalanceAction());
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RequestState>(
      onInit: _reload,
      converter: (store) => store.state.request,
      builder: (context, rs) {
        final all = RequestPageService.buildItems(rs);
        final filtered = _activeCategory == 'ALL'
            ? all
            : all.where((r) => r.type == _activeCategory).toList();

        final content = RefreshIndicator(
          color: SomaflowTheme.sageDeep,
          onRefresh: () async =>
              _reload(StoreProvider.of<AppState>(context, listen: false)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(16, widget.embedded ? 4 : 16, 16, 24),
            children: [
              _buildTitleRow(),
              const SizedBox(height: 16),
              _buildQuickActionTriggers(),
              const SizedBox(height: 16),
              _buildBalanceCards(rs),
              const SizedBox(height: 16),
              _buildFilterPills(all),
              const SizedBox(height: 14),
              if (rs.isLoading && all.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: SomaflowTheme.sageDeep,
                    ),
                  ),
                )
              else if (rs.firstListError != null && all.isEmpty)
                _buildErrorState(rs.firstListError!)
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map(
                  (req) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRequestCard(req),
                  ),
                ),
            ],
          ),
        );

        if (widget.embedded) return content;

        return Scaffold(
          backgroundColor: SomaflowTheme.backgroundBottom,
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SomaflowBackgroundPainter()),
              ),
              SafeArea(child: content),
            ],
          ),
        );
      },
    );
  }

  /* -------------------------- 1. TITLE & MONTH ROW ------------------------ */

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'WORKSPACE',
              style: TextStyle(
                color: SomaflowTheme.sageDeep,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Requests Hub',
              style: TextStyle(
                color: SomaflowTheme.textCharcoal,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _pickMonth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: SomaflowTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SomaflowTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: SomaflowTheme.sagePrimary),
                const SizedBox(width: 6),
                Text(
                  RequestPageService.monthLabel(_month),
                  style: const TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: SomaflowTheme.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _pickMonth() {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    final store = StoreProvider.of<AppState>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SomaflowTheme.surfaceOatmeal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: months.map((m) {
            final selected = m.year == _month.year && m.month == _month.month;
            return ListTile(
              title: Text(
                RequestPageService.monthLabel(m),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  color: SomaflowTheme.textCharcoal,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: SomaflowTheme.sageDeep)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _month = m);
                _reload(store);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /* ----------------------- 2. QUICK ACTION BUTTONS ---------------------- */

  Widget _buildQuickActionTriggers() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: '+ Leave',
            icon: Icons.calendar_month_rounded,
            isPrimary: true,
            onTap: () => _openForm('LEAVE'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: '+ Permission',
            icon: Icons.access_time_rounded,
            isPrimary: false,
            onTap: () => _openForm('PERMISSION'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: '+ Regularize',
            icon: Icons.fingerprint_rounded,
            isPrimary: false,
            onTap: () => _openForm('REGULARIZE'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? SomaflowTheme.sageDeep : SomaflowTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? SomaflowTheme.sageDeep : SomaflowTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? SomaflowTheme.sageDeep.withValues(alpha: 0.22)
                  : SomaflowTheme.sageDark.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: isPrimary ? Colors.white : SomaflowTheme.sageDeep),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isPrimary ? Colors.white : SomaflowTheme.textCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(String type) {
    final Widget page;
    switch (type.toUpperCase()) {
      case 'LEAVE':
        page = const ApplyLeaveScreen();
        break;
      case 'PERMISSION':
        page = const ApplyPermissionScreen();
        break;
      default:
        page = const ApplyRegularizationScreen();
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /* ------------------------- 3. BALANCE TRACKER CARDS ----------------------- */

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildBalanceCards(RequestState rs) {
    final leave = rs.leaveBalance;
    final perm = rs.permissionBalance;
    final pendingReg = rs.regularizationRequests
        .where((r) => r.status.toUpperCase() == 'PENDING')
        .length;
    final totalReg = rs.regularizationRequests.length;

    return SizedBox(
      height: 94,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _balanceCard(
            title: 'Annual Leave',
            value: leave != null ? _num(leave.availableAfterReservation) : '--',
            sub: leave != null ? 'Days left' : 'Apply to view',
            progress: (leave != null && leave.current > 0)
                ? (leave.availableAfterReservation / leave.current).clamp(0.0, 1.0)
                : 0,
            icon: Icons.spa_outlined,
          ),
          const SizedBox(width: 10),
          _balanceCard(
            title: 'Permission',
            value: perm != null ? '${perm.remainingMinutes}' : '--',
            sub: 'Mins left',
            progress: (perm != null && perm.monthlyLimit > 0)
                ? (perm.remainingMinutes / perm.monthlyLimit).clamp(0.0, 1.0)
                : 0,
            icon: Icons.timelapse_rounded,
          ),
          const SizedBox(width: 10),
          _balanceCard(
            title: 'Regularize',
            value: pendingReg.toString().padLeft(2, '0'),
            sub: 'Pending',
            progress: totalReg > 0 ? pendingReg / totalReg : 0,
            icon: Icons.sync_rounded,
          ),
        ],
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String value,
    required String sub,
    required double progress,
    required IconData icon,
  }) {
    return Container(
      width: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SomaflowTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SomaflowTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: SomaflowTheme.sageDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              Text(title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: SomaflowTheme.sageDeep,
                  )),
              Icon(icon, size: 14, color: SomaflowTheme.sagePrimary),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: SomaflowTheme.textCharcoal,
                  )),
              const SizedBox(width: 4),
              Flexible(
                child: Text(sub,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SomaflowTheme.textMuted,
                    )),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: SomaflowTheme.cardTinted,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  SomaflowTheme.sagePrimary),
            ),
          ),
        ],
      ),
    );
  }

  /* --------------------------- 4. FILTER PILL BAR --------------------------- */

  Widget _buildFilterPills(List<RequestItemData> all) {
    int count(String t) => all.where((r) => r.type == t).length;
    final filters = [
      {'key': 'ALL', 'label': 'All (${all.length})'},
      {'key': 'LEAVE', 'label': 'Leave (${count('LEAVE')})'},
      {'key': 'PERMISSION', 'label': 'Permission (${count('PERMISSION')})'},
      {'key': 'REGULARIZE', 'label': 'Regularize (${count('REGULARIZE')})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeCategory == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SomaflowTheme.sageDeep
                      : SomaflowTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? SomaflowTheme.sageDeep
                        : SomaflowTheme.borderLight,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : SomaflowTheme.textCharcoal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /* ---------------------------- 5. REQUEST CARDS ---------------------------- */

  (Color fg, Color bg) _statusColors(String status) {
    switch (status) {
      case 'APPROVED':
        return (SomaflowTheme.statusGreen, SomaflowTheme.statusGreenBg);
      case 'CANCELLED':
      case 'REJECTED':
        return (SomaflowTheme.cancelCoral, SomaflowTheme.cancelCoralBg);
      default:
        return (SomaflowTheme.pendingAmber, SomaflowTheme.pendingAmberBg);
    }
  }

  Widget _buildRequestCard(RequestItemData req) {
    final isApproved = req.status == 'APPROVED';
    final (statusFg, statusBg) = _statusColors(req.status);
    final initial = req.type == 'LEAVE'
        ? 'L'
        : req.type == 'PERMISSION'
            ? 'P'
            : 'R';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SomaflowTheme.cardTinted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SomaflowTheme.borderLight),
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: SomaflowTheme.sageDeep,
                      )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(req.id,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: SomaflowTheme.textCharcoal,
                            )),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(req.status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusFg,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(req.categoryTag,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: SomaflowTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: SomaflowTheme.sageWash,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(req.impact,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SomaflowTheme.sageDeep,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SomaflowTheme.cardTinted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: SomaflowTheme.sagePrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(req.dateRange,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SomaflowTheme.textCharcoal,
                      )),
                ),
                Flexible(
                  child: Text(req.subInfo,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SomaflowTheme.textMuted,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(req.reason,
              style: const TextStyle(
                fontSize: 12.5,
                color: SomaflowTheme.textCharcoal,
                height: 1.4,
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isApproved
                          ? Icons.verified_outlined
                          : Icons.schedule_rounded,
                      size: 13,
                      color: isApproved
                          ? SomaflowTheme.statusGreen
                          : SomaflowTheme.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(req.appliedOn,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: SomaflowTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ],
                ),
              ),
              if (req.isCancelable)
                GestureDetector(
                  onTap: () => _confirmCancellation(req),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: SomaflowTheme.cancelCoralBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF3D2CC)),
                    ),
                    child: Text(req.actionLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: SomaflowTheme.cancelCoral,
                        )),
                  ),
                )
              else
                Text(req.actionLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isApproved
                          ? SomaflowTheme.sageDeep
                          : SomaflowTheme.textMuted,
                    )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => _messageCard(
        'No requests found for this filter.',
        SomaflowTheme.textMuted,
      );

  Widget _buildErrorState(String message) {
    return Column(
      children: [
        _messageCard(message, SomaflowTheme.cancelCoral),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () =>
              _reload(StoreProvider.of<AppState>(context, listen: false)),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
          style: TextButton.styleFrom(foregroundColor: SomaflowTheme.sageDeep),
        ),
      ],
    );
  }

  Widget _messageCard(String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SomaflowTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SomaflowTheme.borderLight),
        ),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ),
      );

  /* -------------------------- 6. CANCEL HANDLER ------------------------- */

  void _confirmCancellation(RequestItemData req) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: SomaflowTheme.surfaceOatmeal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: SomaflowTheme.cancelCoral, size: 20),
                  const SizedBox(width: 8),
                  Text('Cancel Request ${req.id}?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: SomaflowTheme.textCharcoal,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to cancel this ${req.type.toLowerCase()} request? This action cannot be reversed.',
                style: const TextStyle(
                  fontSize: 13,
                  color: SomaflowTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SomaflowTheme.textCharcoal,
                        side: const BorderSide(color: SomaflowTheme.borderLight),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Keep request',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        void done(String? error) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(error ??
                                'Request ${req.id} cancelled successfully.'),
                            backgroundColor: error == null
                                ? SomaflowTheme.sageDeep
                                : SomaflowTheme.cancelCoral,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }

                        if (req.type == 'LEAVE') {
                          store.dispatch(
                              CancelLeaveAction(req.rawId, onDone: done));
                        } else if (req.type == 'PERMISSION') {
                          store.dispatch(
                              CancelPermissionAction(req.rawId, onDone: done));
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: SomaflowTheme.cancelCoral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm Cancel',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Somaflow ambient organic ripples background
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
        ..cubicTo(size.width * 0.45, 0, size.width * 0.55, size.height * 0.18,
            0, size.height * 0.28)
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