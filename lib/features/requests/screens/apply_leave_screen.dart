import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../redux/app_state.dart';
import '../models/request_models.dart';
import '../redux/request_actions.dart';
import 'request_form_widgets.dart';

/// Flutter version of the web "Apply for leave" page.
/// Like the web page, only from_date / to_date / reason are sent to the API;
/// session type and attendance type are collected for the UI only.
class ApplyLeaveScreen extends StatefulWidget {
  /// Optional pre-selected date (web: ?date=yyyy-MM-dd).
  final DateTime? initialDate;
  const ApplyLeaveScreen({super.key, this.initialDate});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  static const _sessions = {
    'FULL_DAY': 'Full day',
    'FIRST_HALF': 'First half',
    'SECOND_HALF': 'Second half',
  };
  static const _attendanceTypes = {
    'CASUAL_LEAVE': 'Casual leave',
    'SICK_LEAVE': 'Sick leave',
    'EARNED_LEAVE': 'Earned leave',
    'OTHER': 'Other',
  };

  final _reason = TextEditingController();
  String _session = 'FULL_DAY';
  String? _attendanceType;
  DateTime? _from;
  DateTime? _to;

  String? _error;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _from = widget.initialDate;
    _to = widget.initialDate;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();

    if (_from == null || _to == null) {
      return setState(() => _error = 'Please select the from and to dates.');
    }
    if (_attendanceType == null) {
      return setState(() => _error = 'Please select an attendance type.');
    }
    if (reason.isEmpty) {
      return setState(
          () => _error = 'Please enter a reason for your leave request.');
    }
    if (_to!.isBefore(_from!)) {
      return setState(
          () => _error = 'The end date must be on or after the start date.');
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    StoreProvider.of<AppState>(context, listen: false).dispatch(
      ApplyLeaveAction(
        LeaveRequestPayload(
          fromDate: fmtDate(_from!),
          toDate: fmtDate(_to!),
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
      badge: 'Leave Application',
      title: 'Apply for leave',
      subtitle:
          'Complete the fields below to schedule planned time off or submit a medical absence.',
      stepLabel: 'Step 1 of 1 · Leave Application',
      successTag: 'APPLICATION PROCESSED',
      successMessage:
          'Your leave request has been submitted successfully to your manager for approval. You can track its live status in your request history.',
      submitted: _submitted,
      submitting: _submitting,
      error: _error,
      onSubmit: _submit,
      fields: [
        FormLabel(
          text: 'Session type',
          child: AppDropdown<String>(
            value: _session,
            items: _sessions,
            onChanged: (v) => setState(() => _session = v ?? _session),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormLabel(
                text: 'From date',
                child: PickerField(
                  value: _from == null ? null : displayDate(_from!),
                  placeholder: 'Select date',
                  icon: Icons.calendar_today_rounded,
                  onTap: () async {
                    final d = await pickDate(context, initial: _from);
                    if (d == null) return;
                    setState(() {
                      _from = d;
                      if (_to == null || _to!.isBefore(d)) _to = d;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FormLabel(
                text: 'To date',
                child: PickerField(
                  value: _to == null ? null : displayDate(_to!),
                  placeholder: 'Select date',
                  icon: Icons.event_rounded,
                  onTap: () async {
                    final d = await pickDate(context,
                        initial: _to ?? _from, first: _from);
                    if (d != null) setState(() => _to = d);
                  },
                ),
              ),
            ),
          ],
        ),
        FormLabel(
          text: 'Attendance type',
          child: AppDropdown<String>(
            value: _attendanceType,
            hint: 'Select an attendance type',
            items: _attendanceTypes,
            onChanged: (v) => setState(() => _attendanceType = v),
          ),
        ),
        FormLabel(
          text: 'Reason',
          child: ReasonField(
            controller: _reason,
            lines: 5,
            hint: 'Enter the reason for your leave request...',
          ),
        ),
      ],
    );
  }
}