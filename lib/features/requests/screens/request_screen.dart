import 'package:flutter/material.dart';

/// Exact Somaflow Sage Green & Warm Parchment Design Tokens
class SomaflowTheme {
  // Atmospheric Backgrounds
  static const Color backgroundTop = Color(0xFFBACAB7);
  static const Color backgroundBottom = Color(0xFFF3EFE9);
  static const Color surfaceOatmeal = Color(0xFFFCFAF7);
  static const Color surfaceCard = Color(0xF8FFFFFF);
  static const Color cardTinted = Color(0xFFEFF4ED);

  // Somaflow Sage Greens
  static const Color sagePrimary = Color(0xFF6B8268);
  static const Color sageDeep = Color(0xFF51644F);
  static const Color sageDark = Color(0xFF384736);
  static const Color sageMuted = Color(0xFF869984);
  static const Color sageLight = Color(0xFFD6E0D3);
  static const Color sageWash = Color(0xFFEAF0E8);

  // Soft Borders & Warm Accents
  static const Color borderLight = Color(0xFFD6DDD4);
  static const Color borderSubtle = Color(0xFFE6ECE4);
  static const Color warmSand = Color(0xFFD8C7B5);

  // Status Badges & Alerts
  static const Color statusGreen = Color(0xFF388E3C);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color pendingAmber = Color(0xFF9E7B3B);
  static const Color pendingAmberBg = Color(0xFFFAF4E8);
  static const Color cancelCoral = Color(0xFFC25D4E);
  static const Color cancelCoralBg = Color(0xFFFDF0ED);

  // Typography
  static const Color textCharcoal = Color(0xFF2C352B);
  static const Color textMuted = Color(0xFF687467);
  static const Color textSubtle = Color(0xFF8E9B8D);
}

// Data Model for unified request items
class RequestItemData {
  final String id;
  final String type; // 'LEAVE', 'PERMISSION', 'REGULARIZE'
  final String categoryTag;
  final String status; // 'PENDING', 'APPROVED', 'CANCELLED', 'REJECTED'
  final String impact;
  final String dateRange;
  final String subInfo;
  final String reason;
  final String appliedOn;
  final String actionLabel;
  final bool isCancelable;

  const RequestItemData({
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
  });
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _activeCategory = 'ALL';
  String _selectedMonth = 'Oct 2026';

  // Request records matching your Somaflow requests hub
  final List<RequestItemData> _requests = const [
    RequestItemData(
      id: '#LR-104',
      type: 'LEAVE',
      categoryTag: 'Annual Rest Entitlement',
      status: 'PENDING',
      impact: '-3 Days',
      dateRange: '28 Oct – 30 Oct 2026',
      subInfo: '3 full days',
      reason: 'Family medical checkup and travel arrangements.',
      appliedOn: 'Applied 24 Oct, 09:30 AM',
      actionLabel: 'Cancel request',
      isCancelable: true,
    ),
    RequestItemData(
      id: '#PR-88',
      type: 'PERMISSION',
      categoryTag: 'Mindful Short Leave',
      status: 'APPROVED',
      impact: '-60 Mins',
      dateRange: '25 Oct 2026',
      subInfo: '04:00 PM (1 Hour)',
      reason: 'Doctor follow-up appointment in city medical wing.',
      appliedOn: 'Approved by Sarah (Lead)',
      actionLabel: 'View receipt ↗',
      isCancelable: false,
    ),
    RequestItemData(
      id: '#RR-52',
      type: 'REGULARIZE',
      categoryTag: 'Punch Correction',
      status: 'PENDING',
      impact: 'Missed Out',
      dateRange: '22 Oct 2026',
      subInfo: 'Scheduled Shift · IN: 09:10 AM · OUT: 06:15 PM (Claimed)',
      reason: 'Biometric sensor failure during floor power transition.',
      appliedOn: 'Awaiting manager review',
      actionLabel: 'Edit Log',
      isCancelable: false,
    ),
    RequestItemData(
      id: '#LR-99',
      type: 'LEAVE',
      categoryTag: 'Wellness Day',
      status: 'APPROVED',
      impact: '-1 Day',
      dateRange: '14 Oct 2026',
      subInfo: '1 day logged',
      reason: 'Personal errands and mindful wellness pause.',
      appliedOn: 'Completed cycle',
      actionLabel: 'Deducted from balance',
      isCancelable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((req) {
      if (_activeCategory == 'ALL') return true;
      return req.type == _activeCategory;
    }).toList();

    return Scaffold(
      backgroundColor: SomaflowTheme.backgroundBottom,
      body: Stack(
        children: [
          // Background organic ambient ripples
          Positioned.fill(
            child: CustomPaint(painter: _SomaflowBackgroundPainter()),
          ),

          // Main Screen Content (No top header bar, no bottom navigation)
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildTitleRow(),
                const SizedBox(height: 16),
                _buildQuickActionTriggers(),
                const SizedBox(height: 16),
                _buildBalanceCards(),
                const SizedBox(height: 16),
                _buildFilterPills(),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
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
          ),
        ],
      ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: SomaflowTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaflowTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: SomaflowTheme.sageDark.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: SomaflowTheme.sagePrimary,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedMonth,
                style: const TextStyle(
                  color: SomaflowTheme.textCharcoal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: SomaflowTheme.textMuted,
              ),
            ],
          ),
        ),
      ],
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
            onTap: () => _openForm('Leave'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: '+ Permission',
            icon: Icons.access_time_rounded,
            isPrimary: false,
            onTap: () => _openForm('Permission'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: '+ Regularize',
            icon: Icons.fingerprint_rounded,
            isPrimary: false,
            onTap: () => _openForm('Regularize'),
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
            Icon(
              icon,
              size: 14,
              color: isPrimary ? Colors.white : SomaflowTheme.sageDeep,
            ),
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

  /* ------------------------- 3. BALANCE TRACKER CARDS ----------------------- */

  Widget _buildBalanceCards() {
    return SizedBox(
      height: 94,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _balanceCard(
            title: 'Annual Leave',
            value: '12',
            sub: '/18 Days',
            progress: 0.66,
            icon: Icons.spa_outlined,
          ),
          const SizedBox(width: 10),
          _balanceCard(
            title: 'Permission',
            value: '90',
            sub: 'Mins left',
            progress: 0.75,
            icon: Icons.timelapse_rounded,
          ),
          const SizedBox(width: 10),
          _balanceCard(
            title: 'Regularize',
            value: '02',
            sub: 'Pending',
            progress: 0.40,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: SomaflowTheme.sageDeep,
                ),
              ),
              Icon(icon, size: 14, color: SomaflowTheme.sagePrimary),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: SomaflowTheme.textCharcoal,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SomaflowTheme.textMuted,
                ),
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
                SomaflowTheme.sagePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* --------------------------- 4. FILTER PILL BAR --------------------------- */

  Widget _buildFilterPills() {
    final filters = [
      {'key': 'ALL', 'label': 'All (6)'},
      {'key': 'LEAVE', 'label': 'Leave (3)'},
      {'key': 'PERMISSION', 'label': 'Permission (2)'},
      {'key': 'REGULARIZE', 'label': 'Regularize (1)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...filters.map((f) {
            final isSelected = _activeCategory == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeCategory = f['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
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
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: SomaflowTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SomaflowTheme.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, size: 14, color: SomaflowTheme.textMuted),
                SizedBox(width: 4),
                Text(
                  'All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SomaflowTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------------------- 5. REQUEST CARDS ---------------------------- */

  Widget _buildRequestCard(RequestItemData req) {
    final isApproved = req.status == 'APPROVED';
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
          // Row 1: Monogram avatar, ID, Status pill, and Impact badge
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
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: SomaflowTheme.sageDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        req.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: SomaflowTheme.textCharcoal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? SomaflowTheme.statusGreenBg
                              : SomaflowTheme.pendingAmberBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          req.status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isApproved
                                ? SomaflowTheme.statusGreen
                                : SomaflowTheme.pendingAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    req.categoryTag,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: SomaflowTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: SomaflowTheme.sageWash,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  req.impact,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SomaflowTheme.sageDeep,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Date interval container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SomaflowTheme.cardTinted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: SomaflowTheme.sagePrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.dateRange,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SomaflowTheme.textCharcoal,
                    ),
                  ),
                ),
                Text(
                  req.subInfo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SomaflowTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 3: Reason narrative
          Text(
            req.reason,
            style: const TextStyle(
              fontSize: 12.5,
              color: SomaflowTheme.textCharcoal,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Row 4: Status footer & contextual actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isApproved ? Icons.verified_outlined : Icons.schedule_rounded,
                    size: 13,
                    color: isApproved
                        ? SomaflowTheme.statusGreen
                        : SomaflowTheme.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    req.appliedOn,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SomaflowTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (req.isCancelable)
                GestureDetector(
                  onTap: () => _confirmCancellation(req),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: SomaflowTheme.cancelCoralBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF3D2CC)),
                    ),
                    child: Text(
                      req.actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SomaflowTheme.cancelCoral,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  req.actionLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isApproved
                        ? SomaflowTheme.sageDeep
                        : SomaflowTheme.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SomaflowTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SomaflowTheme.borderLight),
      ),
      child: const Center(
        child: Text(
          'No requests found for this filter.',
          style: TextStyle(
            color: SomaflowTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /* -------------------------- 6. ACTION HANDLERS ------------------------- */

  void _openForm(String formType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $formType application form...'),
        backgroundColor: SomaflowTheme.sageDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmCancellation(RequestItemData req) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: SomaflowTheme.surfaceOatmeal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  color: SomaflowTheme.cancelCoral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cancel Request ${req.id}?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: SomaflowTheme.textCharcoal,
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Keep request',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Request ${req.id} cancelled successfully.',
                          ),
                          backgroundColor: SomaflowTheme.cancelCoral,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: SomaflowTheme.cancelCoral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Confirm Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        ..cubicTo(
          size.width * 0.45,
          0,
          size.width * 0.55,
          size.height * 0.18,
          0,
          size.height * 0.28,
        )
        ..close(),
      paintSage,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, 0)
        ..cubicTo(
          size.width * 0.75,
          size.height * 0.08,
          size.width,
          size.height * 0.04,
          size.width,
          size.height * 0.20,
        )
        ..lineTo(size.width, 0)
        ..close(),
      paintSand,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}