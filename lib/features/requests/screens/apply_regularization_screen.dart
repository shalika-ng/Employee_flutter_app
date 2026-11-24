import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../redux/app_state.dart';
import '../models/request_models.dart';
import '../redux/request_actions.dart';
import 'request_form_widgets.dart';

/// Flutter version of the web "Regularize a punch" page.
/// Timestamps are sent exactly like the web app:
///   claimed_in / claimed_out = "<work_date>T<HH:mm>:00+05:30" (IST).
class ApplyRegularizationScreen extends StatefulWidget {
  final DateTime? initialDate;

  /// MISSED_IN | MISSED_OUT | BOTH (web: ?type=...)
  final String initialType;

  const ApplyRegularizationScreen({
    super.key,
    this.initialDate,
    this.initialType = 'MISSED_IN',
  });

  @override
  State<ApplyRegularizationScreen> createState() =>
      _ApplyRegularizationScreenState();
}

class _ApplyRegularizationScreenState extends State<ApplyRegularizationScreen> {
  static const _types = {
    'MISSED_IN': 'Missed check-in only',
    'MISSED_OUT': 'Missed check-out only',
    'BOTH': 'Both check-in and check-out',
  };

  final _reason = TextEditingController();
  DateTime? _workDate;
  late String _type;
  TimeOfDay? _claimedIn;
  TimeOfDay? _claimedOut;

  String? _error;
  bool _submitting = false;
  bool _submitted = false;

  bool get _needsIn => _type == 'MISSED_IN' || _type == 'BOTH';
  bool get _needsOut => _type == 'MISSED_OUT' || _type == 'BOTH';

  @override
  void initState() {
    super.initState();
    _workDate = widget.initialDate;
    _type = regularizationTypes.contains(widget.initialType)
        ? widget.initialType
        : 'MISSED_IN';
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _istStamp(DateTime date, TimeOfDay t) =>
      '${fmtDate(date)}T${fmtTime(t)}:00+05:30';

  void _submit() {
    final reason = _reason.text.trim();

    if (_workDate == null ||
        reason.isEmpty ||
        (_needsIn && _claimedIn == null) ||
        (_needsOut && _claimedOut == null)) {
      return setState(() => _error =
          'Please complete the work date, required punch times, and reason.');
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    StoreProvider.of<AppState>(context, listen: false).dispatch(
      ApplyRegularizationAction(
        RegularizationRequestPayload(
          workDate: fmtDate(_workDate!),
          type: _type,
          claimedIn: _needsIn ? _istStamp(_workDate!, _claimedIn!) : null,
          claimedOut: _needsOut ? _istStamp(_workDate!, _claimedOut!) : null,
          reason: reason,
        ),
        onDone: (err) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            if (err == null) {
              _submitted = true;
            } else {
              _error = err;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RequestFormPage(
      badge: 'Attendance Regularization',
      title: 'Regularize a punch',
      subtitle:
          'Select the work date and missing punches. Timestamps will be formatted in India Standard Time (IST, UTC+05:30).',
      stepLabel: 'Step 1 of 1 · Attendance Correction',
      successTag: 'CORRECTION RECORD SUBMITTED',
      successMessage:
          'Your regularization request has been submitted for approval. You can return to your request history.',
      submitted: _submitted,
      submitting: _submitting,
      error: _error,
      onSubmit: _submit,
      fields: [
        FormLabel(
          text: 'Work date',
          child: PickerField(
            value: _workDate == null ? null : displayDate(_workDate!),
            placeholder: 'Select date',
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              final d = await pickDate(context, initial: _workDate);
              if (d != null) setState(() => _workDate = d);
            },
          ),
        ),
        FormLabel(
          text: 'Missing punch type',
          child: AppDropdown<String>(
            value: _type,
            items: _types,
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
        ),
        if (_needsIn)
          FormLabel(
            text: 'Claimed check-in time',
            child: PickerField(
              value: _claimedIn?.format(context),
              placeholder: 'Select time',
              icon: Icons.login_rounded,
              onTap: () async {
                final t = await pickTime(context, initial: _claimedIn);
                if (t != null) setState(() => _claimedIn = t);
              },
            ),
          ),
        if (_needsOut)
          FormLabel(
            text: 'Claimed check-out time',
            child: PickerField(
              value: _claimedOut?.format(context),
              placeholder: 'Select time',
              icon: Icons.logout_rounded,
              onTap: () async {
                final t = await pickTime(context, initial: _claimedOut);
                if (t != null) setState(() => _claimedOut = t);
              },
            ),
          ),
        FormLabel(
          text: 'Reason for correction',
          child: ReasonField(
            controller: _reason,
            hint:
                'Explain why the punch was missed (e.g. biometric reader failure, client location visit, badge lost)...',
          ),
        ),
      ],
    );
  }
}