import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/modern_curved_bottom_nav.dart';
import '../../../redux/app_state.dart';
import '../services/attendance_request_service.dart';

enum AttendanceRequestType { leave, permission, regularization }

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
      backgroundColor: HomeTheme.backgroundTop,
      appBar: AppBar(
        backgroundColor: HomeTheme.heroGradientStart,
        foregroundColor: Colors.white,
        title: Text(
          _title,
          style: HomeTheme.headerTitle.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HomeTheme.backgroundTop, HomeTheme.backgroundBottom],
          ),
        ),
        child: _submittedRequest == null
            ? Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    if (widget.type == AttendanceRequestType.leave)
                      _buildLeaveForm(),
                    if (widget.type == AttendanceRequestType.permission)
                      _buildPermissionForm(),
                    if (widget.type == AttendanceRequestType.regularization)
                      _buildRegularizationForm(),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [_buildSubmittedRequestCard()],
              ),
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
          Text(
            'Sign in to view your permission balance.',
            style: HomeTheme.body,
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
              Text(message, style: HomeTheme.body),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _refreshPermissionBalance,
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
                  color: HomeTheme.accentBlue,
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
              style: HomeTheme.caption,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _balanceMetric('Monthly limit', balance.monthlyLimit),
                _balanceMetric('Used', balance.usedMinutes),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _balanceMetric('Pending', balance.pendingMinutes),
                _balanceMetric('Remaining', balance.remainingMinutes),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _balanceMetric(String label, int minutes) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeTheme.caption),
          const SizedBox(height: 3),
          Text(_formatMinutes(minutes), style: HomeTheme.cardTitle),
        ],
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
    return _formCard(
      title: _requestCancelled ? 'Request cancelled' : 'Request submitted',
      icon: _requestCancelled
          ? Icons.event_busy_outlined
          : Icons.check_circle_outline_rounded,
      children: [
        Text(request.message, style: HomeTheme.body),
        const SizedBox(height: 8),
        Text('Request ID: ${request.id}', style: HomeTheme.caption),
        const SizedBox(height: 4),
        Text(
          'Status: ${_requestCancelled ? 'CANCELLED' : 'PENDING'}',
          style: HomeTheme.caption,
        ),
      ],
    );
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HomeTheme.primaryText.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: HomeTheme.chipBlueBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: HomeTheme.heroGradientStart, size: 21),
              ),
              const SizedBox(width: 12),
              Text(title, style: HomeTheme.sectionTitle),
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
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value),
                style: TextStyle(
                  color: value == null
                      ? HomeTheme.secondaryText
                      : HomeTheme.primaryText,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: HomeTheme.secondaryText,
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
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.format(context) ?? 'Select time',
                style: TextStyle(
                  color: value == null
                      ? HomeTheme.secondaryText
                      : HomeTheme.primaryText,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              color: HomeTheme.secondaryText,
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
            foregroundColor: HomeTheme.heroGradientStart,
            backgroundColor: HomeTheme.chipBlueBackground,
            side: BorderSide.none,
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
        color: HomeTheme.secondaryText,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HomeTheme.borderBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HomeTheme.accentBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB42336)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB42336), width: 1.5),
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: HomeTheme.borderBlue)),
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
                        foregroundColor: HomeTheme.primaryText,
                        side: const BorderSide(color: HomeTheme.borderBlue),
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
                      style: _primaryButtonStyle(),
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

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(54),
    backgroundColor: HomeTheme.heroGradientStart,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: HomeTheme.cardTitle.copyWith(color: Colors.white, fontSize: 13),
  );

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
              .copyWith(primary: HomeTheme.accentBlue),
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
              .copyWith(primary: HomeTheme.accentBlue),
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
        title: const Text('Cancel request?'),
        content: const Text(
          'This will cancel the request you just submitted. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42336),
              foregroundColor: Colors.white,
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
      SnackBar(content: Text(message), backgroundColor: HomeTheme.accentBlue),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
