import 'package:material_ui/material_ui.dart';

import '../../../core/somaflow_theme.dart';

/* ------------------------------ formatting ------------------------------ */

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String two(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM-dd (API format)
String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// HH:mm (API format)
String fmtTime(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

/// 23 Nov 2026 (display)
String displayDate(DateTime d) => '${two(d.day)} ${_months[d.month - 1]} ${d.year}';

Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initial,
  DateTime? first,
}) {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year - 1);
  var start = initial ?? now;
  if (start.isBefore(firstDate)) start = firstDate;
  return showDatePicker(
    context: context,
    initialDate: start,
    firstDate: firstDate,
    lastDate: DateTime(now.year + 1, 12, 31),
  );
}

Future<TimeOfDay?> pickTime(BuildContext context, {TimeOfDay? initial}) =>
    showTimePicker(context: context, initialTime: initial ?? TimeOfDay.now());

/* ------------------------------- page shell ----------------------------- */

/// Shared page layout for Leave / Permission / Regularization forms.
/// Mirrors the web pages: back link, badge, title, form card, error banner,
/// Cancel + Submit actions, and a success state.
class RequestFormPage extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String stepLabel;
  final String successTag;
  final String successMessage;
  final bool submitted;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;
  final List<Widget> fields;

  const RequestFormPage({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.stepLabel,
    required this.successTag,
    required this.successMessage,
    required this.submitted,
    required this.submitting,
    required this.error,
    required this.onSubmit,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaflowTheme.backgroundBottom,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
          SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _backRow(context),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: SomaflowTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SomaflowTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: SomaflowTheme.sageDark.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: submitted ? _success(context) : _form(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SomaflowTheme.borderLight),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 14, color: SomaflowTheme.textCharcoal),
                SizedBox(width: 6),
                Text('Back to requests',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: SomaflowTheme.textCharcoal,
                    )),
              ],
            ),
          ),
        ),
        Text(stepLabel,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SomaflowTheme.textSubtle,
            )),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: SomaflowTheme.cardTinted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SomaflowTheme.sageLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SomaflowTheme.sageDeep,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(badge.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: SomaflowTheme.sageDeep,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: SomaflowTheme.textCharcoal,
            )),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: SomaflowTheme.textMuted,
            )),
        const SizedBox(height: 14),
        const Divider(height: 1, color: SomaflowTheme.borderSubtle),
        const SizedBox(height: 16),
        ...fields.expand((w) => [w, const SizedBox(height: 14)]),
        if (error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: SomaflowTheme.cancelCoralBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3D2CC)),
            ),
            child: Text(error!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SomaflowTheme.cancelCoral,
                )),
          ),
        const Divider(height: 1, color: SomaflowTheme.borderSubtle),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    submitting ? null : () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SomaflowTheme.textMuted,
                  side: const BorderSide(color: SomaflowTheme.borderLight),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: SomaflowTheme.sageDeep,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('SUBMIT REQUEST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        )),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SomaflowTheme.cardTinted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SomaflowTheme.sageLight),
            ),
            child: const Icon(Icons.check_rounded,
                size: 32, color: SomaflowTheme.sageDeep),
          ),
          const SizedBox(height: 18),
          Text(successTag,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: SomaflowTheme.sagePrimary,
              )),
          const SizedBox(height: 4),
          const Text('Request submitted',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: SomaflowTheme.textCharcoal,
              )),
          const SizedBox(height: 8),
          Text(successMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: SomaflowTheme.textMuted,
              )),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              backgroundColor: SomaflowTheme.sageDeep,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('RETURN TO REQUESTS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ form widgets ---------------------------- */

class FormLabel extends StatelessWidget {
  final String text;
  final bool required;
  final Widget child;
  const FormLabel({
    super.key,
    required this.text,
    this.required = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SomaflowTheme.textCharcoal,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: SomaflowTheme.cancelCoral),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

BoxDecoration _fieldBox() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SomaflowTheme.borderLight),
    );

/// Tappable field used for dates and times.
class PickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  const PickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: _fieldBox(),
        child: Row(
          children: [
            Icon(icon, size: 16, color: SomaflowTheme.sagePrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? placeholder,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w800,
                  color: value == null
                      ? SomaflowTheme.textSubtle
                      : SomaflowTheme.textCharcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldBox(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint ?? 'Select',
              style: const TextStyle(
                fontSize: 12.5,
                color: SomaflowTheme.textSubtle,
              )),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: SomaflowTheme.textMuted),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: SomaflowTheme.textCharcoal,
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class ReasonField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int lines;
  const ReasonField({
    super.key,
    required this.controller,
    required this.hint,
    this.lines = 4,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      maxLines: lines,
      minLines: lines,
      maxLength: 1000,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: SomaflowTheme.textCharcoal,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 12.5, color: SomaflowTheme.textSubtle),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: border(SomaflowTheme.borderLight),
        focusedBorder: border(SomaflowTheme.sageDeep),
        border: border(SomaflowTheme.borderLight),
      ),
    );
  }
}

/* -------------------------------- backdrop ------------------------------ */

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sage = Paint()
      ..color = SomaflowTheme.sageMuted.withValues(alpha: 0.16);
    final sand = Paint()
      ..color = SomaflowTheme.warmSand.withValues(alpha: 0.14);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(size.width * 0.45, 0, size.width * 0.55, size.height * 0.18,
            0, size.height * 0.28)
        ..close(),
      sage,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, 0)
        ..cubicTo(size.width * 0.75, size.height * 0.08, size.width,
            size.height * 0.04, size.width, size.height * 0.20)
        ..lineTo(size.width, 0)
        ..close(),
      sand,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}