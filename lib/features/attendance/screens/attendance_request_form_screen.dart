import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Kept so existing exports keep compiling; remove if the analyzer reports it unused.
// ignore: unused_import
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/modern_curved_bottom_nav.dart';
import '../../../redux/app_state.dart';
import '../services/attendance_request_service.dart';
// SomaflowTheme (sage green & warm parchment tokens) lives in the attendance screen.
import 'attendance_screen.dart' show SomaflowTheme;

enum AttendanceRequestType { leave, permission, regularization }

/* ------------------------------------------------------------------ */
/*  Text styles (Somaflow tokens)                                      */
/* ------------------------------------------------------------------ */

const TextStyle _sectionTitle = TextStyle(
  color: SomaflowTheme.textCharcoal,
  fontSize: 16,
  fontWeight: FontWeight.w900,
);

const TextStyle _cardTitle = TextStyle(
  color: SomaflowTheme.textCharcoal,
  fontSize: 15,
  fontWeight: FontWeight.w800,
);

const TextStyle _body = TextStyle(
  color: SomaflowTheme.textMuted,
  fontSize: 14,
  height: 1.4,
);

const TextStyle _caption = TextStyle(
  color: SomaflowTheme.textMuted,
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
);

class AttendanceRequestFormScreen extends StatefulWidget {
  const AttendanceRequestFormScreen({
    required this.type,
    required this.initialDate,
    this.onNavigate,
    super.key,
  });

  final AttendanceRequestType type;
  final DateTime? initialDate;
  final ValueChanged<int>? onNavigate;

  @override
  State<AttendanceRequestFormScreen> createState() =>
      _AttendanceRequestFormScreenState();
}

class _AttendanceRequestFormScreenState
    extends State<AttendanceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _permissionMinutesController = TextEditingController(text: '30');
  final _requestService = AttendanceRequestService();
  DateTime? _requestDate;
  DateTime? _toDate;
  TimeOfDay? _permissionStartTime;
  TimeOfDay? _correctedIn;
  TimeOfDay? _correctedOut;
  String? _permissionBalanceToken;
  Future<PermissionBalance>? _permissionBalanceFuture;
  AttendanceRequestReceipt? _submittedRequest;
  bool _requestCancelled = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _requestDate = widget.initialDate;
    _toDate = widget.initialDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.type != AttendanceRequestType.permission) return;
    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token == _permissionBalanceToken) return;
    _permissionBalanceToken = token;
    _permissionBalanceFuture = token == null || token.isEmpty
        ? null
        : _requestService.getPermissionBalance(token: token);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _permissionMinutesController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
    AttendanceRequestType.leave => 'New Leave Request',
    AttendanceRequestType.permission => 'New Permission Request',
    AttendanceRequestType.regularization => 'Attendance Regularization',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaflowTheme.backgroundBottom,
      body: Stack(
        children: [
          // Somaflow organic ripples ambient backdrop
          Positioned.fill(
            child: CustomPaint(painter: _FormBackgroundPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _submittedRequest == null
                      ? Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            children: [
                              _buildHeroCard(),
                              const SizedBox(height: 14),
                              if (widget.type == AttendanceRequestType.leave)
                                _buildLeaveForm(),
                              if (widget.type ==
                                  AttendanceRequestType.permission)
                                _buildPermissionForm(),
                              if (widget.type ==
                                  AttendanceRequestType.regularization)
                                _buildRegularizationForm(),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [_buildSubmittedRequestCard()],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.onNavigate == null
          ? _buildBottomBar()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomBar(),
                ModernCurvedBottomNavBar(
                  currentIndex: 1,
                  onTap: widget.onNavigate!,
                  items: employeeBottomNavItems,
                ),
              ],
            ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATTENDANCE REQUEST',
                  style: TextStyle(
                    color: SomaflowTheme.sagePrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
            tooltip: 'Home',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, size: 24),
            color: SomaflowTheme.sagePrimary,
          ),
        ],
      ),
    );
  }

  /* ----------------------------- HERO CARD --------------------------- */

  Widget _buildHeroCard() {
    final IconData icon;
    final String subtitle;
    switch (widget.type) {
      case AttendanceRequestType.leave:
        icon = Icons.event_available_outlined;
        subtitle = 'Choose your dates and tell us why you need time off.';
      case AttendanceRequestType.permission:
        icon = Icons.description_outlined;
        subtitle = 'Pick a time window and check your monthly balance.';
      case AttendanceRequestType.regularization:
        icon = Icons.edit_calendar_outlined;
        subtitle = 'Correct your punch in and punch out times for the day.';
    }

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
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_requestDate != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
                  child: Text(
                    _formatDate(_requestDate!),
                    style: const TextStyle(
                      color: SomaflowTheme.sageDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /* ------------------------------- FORMS ----------------------------- */

  Widget _buildLeaveForm() {
    return Column(
      children: [
        _formCard(
          title: 'Leave dates',
          icon: Icons.calendar_month_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'FROM',
                    value: _requestDate,
                    onTap: () => _pickDate(isToDate: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateField(
                    label: 'TO',
                    value: _toDate,
                    onTap: () => _pickDate(isToDate: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _reasonCard(isRequired: true),
        const SizedBox(height: 14),
        _attachmentCard(),
      ],
    );
  }

  Widget _buildPermissionForm() {
    return Column(
      children: [
        _buildPermissionBalance(),
        const SizedBox(height: 14),
        _formCard(
          title: 'Permission date',
          icon: Icons.calendar_month_outlined,
          children: [
            _dateField(
              label: 'DATE',
              value: _requestDate,
              onTap: () => _pickDate(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _formCard(
          title: 'Permission time',
          icon: Icons.access_time_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'START TIME',
                    value: _permissionStartTime,
                    onTap: _pickPermissionTime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _permissionMinutesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: SomaflowTheme.textCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _fieldDecoration('MINUTES'),
                    validator: (value) {
                      final minutes = int.tryParse(value?.trim() ?? '');
                      return minutes == null || minutes <= 0
                          ? 'Enter valid minutes'
                          : null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _reasonCard(isRequired: true),
      ],
    );
  }

  Widget _buildPermissionBalance() {
    final future = _permissionBalanceFuture;
    if (future == null) {
      return _formCard(
        title: 'Permission balance',
        icon: Icons.timelapse_rounded,
        children: [
          const Text(
            'Sign in to view your permission balance.',
            style: _body,
          ),
        ],
      );
    }

    return FutureBuilder<PermissionBalance>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Unable to load permission balance.';
          return _formCard(
            title: 'Permission balance',
            icon: Icons.timelapse_rounded,
            children: [
              Text(message, style: _body),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _refreshPermissionBalance,
                  style: TextButton.styleFrom(
                    foregroundColor: SomaflowTheme.sagePrimary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          );
        }

        final balance = snapshot.data;
        if (balance == null) {
          return _formCard(
            title: 'Permission balance',
            icon: Icons.timelapse_rounded,
            children: [
              const Center(
                child: CircularProgressIndicator(
                  color: SomaflowTheme.sagePrimary,
                  strokeWidth: 2,
                ),
              ),
            ],
          );
        }

        return _formCard(
          title: 'Permission balance',
          icon: Icons.timelapse_rounded,
          children: [
            Text(
              '${_monthName(balance.month)} ${balance.year}',
              style: _caption,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _balanceMetric('Monthly limit', balance.monthlyLimit),
                const SizedBox(width: 10),
                _balanceMetric('Used', balance.usedMinutes),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _balanceMetric(
                  'Pending',
                  balance.pendingMinutes,
                  accent: SomaflowTheme.halfDayAmber,
                ),
                const SizedBox(width: 10),
                _balanceMetric(
                  'Remaining',
                  balance.remainingMinutes,
                  accent: SomaflowTheme.statusGreen,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _balanceMetric(
    String label,
    int minutes, {
    Color accent = SomaflowTheme.textCharcoal,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SomaflowTheme.chipBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SomaflowTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _caption),
            const SizedBox(height: 3),
            Text(
              _formatMinutes(minutes),
              style: _cardTitle.copyWith(color: accent, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) =>
      '${minutes ~/ 60}h ${minutes.remainder(60).toString().padLeft(2, '0')}m';

  String _monthName(int month) {
    const months = [
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
    ];
    return month < 1 || month > months.length
        ? 'Month $month'
        : months[month - 1];
  }

  void _refreshPermissionBalance() {
    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token == null || token.isEmpty) {
      _showMessage('Sign in to view your permission balance.');
      return;
    }
    setState(() {
      _permissionBalanceToken = token;
      _permissionBalanceFuture = _requestService.getPermissionBalance(
        token: token,
      );
    });
  }

  Widget _buildRegularizationForm() {
    return Column(
      children: [
        _formCard(
          title: 'Attendance date',
          icon: Icons.calendar_month_outlined,
          children: [
            _dateField(
              label: 'DATE',
              value: _requestDate,
              onTap: () => _pickDate(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _formCard(
          title: 'Correct attendance time',
          icon: Icons.access_time_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'PUNCH IN',
                    value: _correctedIn,
                    onTap: () => _pickTime(isIn: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeField(
                    label: 'PUNCH OUT',
                    value: _correctedOut,
                    onTap: () => _pickTime(isIn: false),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _reasonCard(isRequired: true),
      ],
    );
  }

  Widget _buildSubmittedRequestCard() {
    final request = _submittedRequest!;
    final cancelled = _requestCancelled;
    return _formCard(
      title: cancelled ? 'Request cancelled' : 'Request submitted',
      icon: cancelled
          ? Icons.event_busy_outlined
          : Icons.check_circle_outline_rounded,
      children: [
        Text(request.message, style: _body),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SomaflowTheme.chipBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SomaflowTheme.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Request ID: ${request.id}', style: _caption),
              ),
              _statusChip(
                cancelled ? 'CANCELLED' : 'PENDING',
                fg: cancelled
                    ? SomaflowTheme.absentCoral
                    : SomaflowTheme.halfDayAmber,
                bg: cancelled
                    ? SomaflowTheme.absentBg
                    : SomaflowTheme.halfDayBg,
                border: cancelled
                    ? SomaflowTheme.absentBorder
                    : SomaflowTheme.halfDayBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(
    String label, {
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /* ----------------------------- BUILDING BLOCKS --------------------- */

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SomaflowTheme.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SomaflowTheme.sagePrimary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: _sectionTitle)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value),
                style: TextStyle(
                  color: value == null
                      ? SomaflowTheme.textSubtle
                      : SomaflowTheme.textCharcoal,
                  fontSize: 15,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: SomaflowTheme.sagePrimary,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.format(context) ?? 'Select time',
                style: TextStyle(
                  color: value == null
                      ? SomaflowTheme.textSubtle
                      : SomaflowTheme.textCharcoal,
                  fontSize: 14,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              color: SomaflowTheme.sagePrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonCard({required bool isRequired}) {
    return _formCard(
      title: 'Reason',
      icon: Icons.edit_outlined,
      children: [
        TextFormField(
          controller: _reasonController,
          minLines: 4,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            color: SomaflowTheme.textCharcoal,
            fontSize: 15,
          ),
          decoration: _fieldDecoration(
            isRequired ? 'Why do you need this?' : 'Add a reason (optional)',
          ),
          validator: isRequired
              ? (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a reason'
                    : null
              : null,
        ),
      ],
    );
  }

  Widget _attachmentCard() {
    return _formCard(
      title: 'Attachments',
      icon: Icons.attach_file_rounded,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showMessage('File upload is not configured yet.'),
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Attach file (optional)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: SomaflowTheme.sageDeep,
            backgroundColor: SomaflowTheme.chipBackground,
            side: const BorderSide(color: SomaflowTheme.borderLight),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: SomaflowTheme.textMuted,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: SomaflowTheme.sagePrimary,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: SomaflowTheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SomaflowTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: SomaflowTheme.sagePrimary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SomaflowTheme.absentCoral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: SomaflowTheme.absentCoral,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: SomaflowTheme.absentCoral,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBottomBar() {
    final requestSubmitted = _submittedRequest != null;
    final requestCancelled = _requestCancelled;
    return SafeArea(
      top: false,
      bottom: widget.onNavigate == null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: SomaflowTheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: SomaflowTheme.borderLight)),
        ),
        child: requestSubmitted && requestCancelled
            ? FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: _primaryButtonStyle(),
                child: const Text('Done'),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: SomaflowTheme.textCharcoal,
                        side: const BorderSide(color: SomaflowTheme.borderLight),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(requestSubmitted ? 'Done' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: FilledButton(
                      onPressed: _isBusy
                          ? null
                          : requestSubmitted
                          ? _confirmCancelRequest
                          : _submit,
                      style: _primaryButtonStyle(
                        color: requestSubmitted
                            ? SomaflowTheme.absentCoral
                            : SomaflowTheme.sagePrimary,
                      ),
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              requestSubmitted
                                  ? 'Cancel request'
                                  : 'Submit request',
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({Color color = SomaflowTheme.sagePrimary}) =>
      FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: SomaflowTheme.sageMuted.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );

  /* --------------------------- LOGIC (UNCHANGED) --------------------- */

  Future<void> _pickDate({bool isToDate = false}) async {
    final initial = isToDate ? (_toDate ?? _requestDate) : _requestDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: SomaflowTheme.sagePrimary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isToDate) {
        _toDate = picked;
      } else {
        _requestDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      }
    });
  }

  Future<void> _pickTime({required bool isIn}) async {
    final initialTime = isIn
        ? (_correctedIn ?? const TimeOfDay(hour: 9, minute: 0))
        : (_correctedOut ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await _showTimePicker(initialTime);
    if (picked == null) return;
    setState(() {
      if (isIn) {
        _correctedIn = picked;
      } else {
        _correctedOut = picked;
      }
    });
  }

  Future<void> _pickPermissionTime() async {
    final picked = await _showTimePicker(
      _permissionStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() => _permissionStartTime = picked);
  }

  Future<TimeOfDay?> _showTimePicker(TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: SomaflowTheme.sagePrimary),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _submit() async {
    if (_isBusy || _submittedRequest != null) return;
    if (widget.type == AttendanceRequestType.leave) {
      if (_requestDate == null || _toDate == null) {
        _showMessage('Select the leave dates first.');
        return;
      }
      if (_toDate!.isBefore(_requestDate!)) {
        _showMessage('The end date must be on or after the start date.');
        return;
      }
    }
    if (widget.type == AttendanceRequestType.permission) {
      if (_requestDate == null) {
        _showMessage('Select a permission date first.');
        return;
      }
      if (_permissionStartTime == null) {
        _showMessage('Select a permission start time.');
        return;
      }
    }
    if (widget.type == AttendanceRequestType.regularization) {
      if (_requestDate == null ||
          (_correctedIn == null && _correctedOut == null)) {
        _showMessage('Select a date and at least one corrected punch time.');
        return;
      }
      _showMessage('Regularization submission is not connected yet.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token == null || token.isEmpty) {
      _showMessage('Your session has expired. Sign in again to continue.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final receipt = widget.type == AttendanceRequestType.leave
          ? await _requestService.applyLeave(
              fromDate: _apiDate(_requestDate!),
              toDate: _apiDate(_toDate!),
              reason: _reasonController.text.trim(),
              token: token,
            )
          : await _requestService.applyPermission(
              date: _apiDate(_requestDate!),
              startTime: _apiTime(_permissionStartTime!),
              minutes: int.parse(_permissionMinutesController.text.trim()),
              reason: _reasonController.text.trim(),
              token: token,
            );
      if (!mounted) return;
      setState(() => _submittedRequest = receipt);
      _showMessage(receipt.message);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmCancelRequest() async {
    final request = _submittedRequest;
    if (request == null || _requestCancelled || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SomaflowTheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Cancel request?',
          style: TextStyle(
            color: SomaflowTheme.textCharcoal,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'This will cancel the request you just submitted. Continue?',
          style: TextStyle(color: SomaflowTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: SomaflowTheme.sageDeep,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: SomaflowTheme.absentCoral,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = StoreProvider.of<AppState>(context).state.auth.token;
    if (token == null || token.isEmpty) {
      _showMessage('Your session has expired. Sign in again to continue.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final message = widget.type == AttendanceRequestType.leave
          ? await _requestService.cancelLeave(id: request.id, token: token)
          : await _requestService.cancelPermission(
              id: request.id,
              token: token,
            );
      if (!mounted) return;
      setState(() => _requestCancelled = true);
      _showMessage(message);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _apiTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: SomaflowTheme.sagePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Somaflow ambient organic ripples (same shapes as the attendance screen).
class _FormBackgroundPainter extends CustomPainter {
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