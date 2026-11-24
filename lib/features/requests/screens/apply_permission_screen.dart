import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../core/somaflow_theme.dart';
import '../../../redux/app_state.dart';
import '../models/request_models.dart';
import '../redux/request_actions.dart';
import 'request_form_widgets.dart';

/// Flutter version of the web "Request permission" page.
/// Sent to the API: perm_date, start_time (HH:mm), minutes (end - start), reason.
/// Session type and permission count are UI-only, same as the web page.
class ApplyPermissionScreen extends StatefulWidget {
  final DateTime? initialDate;
  const ApplyPermissionScreen({super.key, this.initialDate});

  @override
  State<ApplyPermissionScreen> createState() => _ApplyPermissionScreenState();
}

class _ApplyPermissionScreenState extends State<ApplyPermissionScreen> {
  static const _sessions = {
    'IN': 'In (Morning / Late Arrival)',
    'OUT': 'Out (Evening / Early Departure)',
  };
  static const _counts = {
    1: '1 Slot',
    2: '2 Slots',
    3: '3 Slots',
    4: '4 Slots',
  };

  final _reason = TextEditingController();
  DateTime? _date;
  String _session = 'IN';
  int _count = 1;
  TimeOfDay? _start;
  TimeOfDay? _end;

  String? _error;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _minutes {
    if (_start == null || _end == null) return 0;
    return (_end!.hour * 60 + _end!.minute) -
        (_start!.hour * 60 + _start!.minute);
  }

  void _submit() {
    final reason = _reason.text.trim();

    if (_date == null) {
      return setState(() => _error = 'Please select the permission date.');
    }
    if (_start == null || _end == null) {
      return setState(() => _error = 'Please select the start and end times.');
    }
    if (reason.isEmpty) {
      return setState(
          () => _error = 'Please enter a reason for your permission request.');
    }
    if (_minutes <= 0) {
      return setState(() => _error = 'End time must be later than start time.');
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    StoreProvider.of<AppState>(context, listen: false).dispatch(
      ApplyPermissionAction(
        PermissionRequestPayload(
          permDate: fmtDate(_date!),
          startTime: fmtTime(_start!),
          minutes: _minutes,
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
    final m = _minutes;
    return RequestFormPage(
      badge: 'Short Leave / Permission',
      title: 'Request permission',
      subtitle:
          'Specify the date, exact time duration, and reason for your scheduled out-of-office slot.',
      stepLabel: 'Step 1 of 1 · Short Time Permission',
      successTag: 'PERMISSION REQUEST PROCESSED',
      successMessage:
          'Your short time permission request has been submitted successfully. Your reporting manager will review it shortly.',
      submitted: _submitted,
      submitting: _submitting,
      error: _error,
      onSubmit: _submit,
      fields: [
        FormLabel(
          text: 'Permission date',
          child: PickerField(
            value: _date == null ? null : displayDate(_date!),
            placeholder: 'Select date',
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              final d = await pickDate(context, initial: _date);
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: FormLabel(
                text: 'Session type',
                child: AppDropdown<String>(
                  value: _session,
                  items: const {'IN': 'In', 'OUT': 'Out'},
                  onChanged: (v) => setState(() => _session = v ?? _session),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: FormLabel(
                text: 'Permission count',
                child: AppDropdown<int>(
                  value: _count,
                  items: _counts,
                  onChanged: (v) => setState(() => _count = v ?? _count),
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormLabel(
                text: 'Start time',
                child: PickerField(
                  value: _start?.format(context),
                  placeholder: 'Select time',
                  icon: Icons.access_time_rounded,
                  onTap: () async {
                    final t = await pickTime(context, initial: _start);
                    if (t != null) setState(() => _start = t);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FormLabel(
                text: 'End time',
                child: PickerField(
                  value: _end?.format(context),
                  placeholder: 'Select time',
                  icon: Icons.access_time_filled_rounded,
                  onTap: () async {
                    final t = await pickTime(context, initial: _end ?? _start);
                    if (t != null) setState(() => _end = t);
                  },
                ),
              ),
            ),
          ],
        ),
        // Live duration pill (same as web "Calculated duration")
        FormLabel(
          text: 'Calculated duration',
          required: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: SomaflowTheme.cardTinted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SomaflowTheme.sageLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Time',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: SomaflowTheme.sagePrimary,
                    )),
                Text(
                  m > 0 ? '$m mins (${(m / 60).toStringAsFixed(1)} hrs)' : '—',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: SomaflowTheme.sageDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
        FormLabel(
          text: 'Reason',
          child: ReasonField(
            controller: _reason,
            hint:
                'Enter the specific reason for requesting this permission slot...',
          ),
        ),
      ],
    );
  }
}