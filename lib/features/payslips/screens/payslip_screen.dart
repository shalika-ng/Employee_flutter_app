import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/somaflow_theme.dart';
import '../models/payslip.dart';
import '../services/payslip_service.dart';
import 'payslip_preview.dart';

typedef PayslipLoader = Future<PayslipCollection> Function(String token);
typedef PayslipDownloader = Future<Uint8List> Function(
  Payslip payslip,
  String token,
);
typedef PayslipSaver = Future<String?> Function(Uint8List bytes, String name);
typedef PayslipPdfBuilder = Widget Function(
  BuildContext context,
  Uint8List bytes,
);

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({
    required this.token,
    this.loader,
    this.downloader,
    this.saver,
    this.previewBuilder,
    this.active = true,
    super.key,
  });

  final String? token;
  final PayslipLoader? loader;
  final PayslipDownloader? downloader;
  final PayslipSaver? saver;
  final PayslipPdfBuilder? previewBuilder;
  final bool active;

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final _service = PayslipService();
  Future<PayslipCollection>? _future;
  String _query = '';
  int? _year;
  String? _downloadingId;
  Payslip? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PayslipScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token || oldWidget.loader != widget.loader) {
      _year = null;
      _preview = null;
      _load();
    }
  }

  void _load() {
    final token = widget.token;
    _future = token == null || token.isEmpty
        ? null
        : widget.loader?.call(token) ?? _service.getMyPayslips(token: token);
  }

  Future<void> _download(Payslip payslip) async {
    final token = widget.token;
    if (token == null || token.isEmpty || _downloadingId != null) return;
    setState(() => _downloadingId = payslip.id);
    try {
      final bytes = widget.downloader != null
          ? await widget.downloader!(payslip, token)
          : await _service.download(payslip, token: token);
      if (!mounted || widget.token != token) return;
      final name =
          'payslip-${payslip.year}-${payslip.month.toString().padLeft(2, '0')}-${payslip.id}';
      final path = widget.saver != null
          ? await widget.saver!(bytes, name)
          : await FileSaver.instance.saveAs(
              name: name,
              bytes: bytes,
              fileExtension: 'pdf',
              mimeType: MimeType.pdf,
            );
      if (!mounted || widget.token != token || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payslip saved successfully.')),
      );
    } on ApiException catch (error) {
      if (mounted && widget.token == token) {
        _showError(error.message);
      }
    } catch (error, stack) {
      debugPrint('Payslip save failed: $error\n$stack');
      if (mounted && widget.token == token) {
        _showError('Unable to save payslip. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SomaflowTheme.cancelCoral,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview != null && widget.token != null && widget.token!.isNotEmpty) {
      final token = widget.token!;
      return PopScope(
        canPop: !widget.active,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && widget.active) setState(() => _preview = null);
        },
        child: PayslipPreview(
          key: ValueKey(preview.id),
          payslip: preview,
          load: () => widget.downloader != null
              ? widget.downloader!(preview, token)
              : _service.download(preview, token: token),
          onClose: () => setState(() => _preview = null),
          viewerBuilder: widget.previewBuilder,
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: FutureBuilder<PayslipCollection>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FINANCE & PAYROLL ARCHIVE',
                  style: TextStyle(
                    color: SomaflowTheme.sageDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Payslips & Salary Statements',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View or download your published statements.',
                  style: TextStyle(
                    color: SomaflowTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                if (_future == null)
                  _notice('Sign in to view your payslips.')
                else if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: SomaflowTheme.sageDeep,
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  _notice(
                    snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Unable to load payslips. Please try again.',
                    retry: () => setState(_load),
                  )
                else if (data != null)
                  _content(context, data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, PayslipCollection data) {
    final localizations = MaterialLocalizations.of(context);
    final years = data.payslips.map((slip) => slip.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final slips = data.payslips.where((slip) {
      final period = localizations.formatMonthYear(
        DateTime(slip.year, slip.month),
      );
      final matchesYear = _year == null || slip.year == _year;
      return matchesYear &&
          (period.toLowerCase().contains(_query.toLowerCase().trim()) ||
              slip.id.toLowerCase().contains(_query.toLowerCase().trim()));
    }).toList()..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF65755D), Color(0xFF42513F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TOTAL PUBLISHED',
                      style: TextStyle(
                        color: Color(0xFFDCE6D9),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.description_outlined,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${data.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Statements on record',
                style: TextStyle(color: Color(0xFFE0E9DD), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (data.payslips.isEmpty)
          _notice('No payslips have been published yet.')
        else ...[
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search month, year or slip ID',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: SomaflowTheme.sageMuted,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _yearChip(
                  'All years',
                  _year == null,
                  () => setState(() => _year = null),
                ),
                for (final year in years)
                  _yearChip(
                    '$year',
                    _year == year,
                    () => setState(() => _year = year),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your statements',
                  style: TextStyle(
                    color: SomaflowTheme.textCharcoal,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${slips.length} shown',
                style: const TextStyle(
                  color: SomaflowTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Latest published first',
            style: TextStyle(color: SomaflowTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (slips.isEmpty)
            _notice('No statements match your search.')
          else
            for (final payslip in slips) _payslipCard(context, payslip),
        ],
      ],
    );
  }

  Widget _payslipCard(BuildContext context, Payslip payslip) {
    final localizations = MaterialLocalizations.of(context);
    final period = localizations.formatMonthYear(
      DateTime(payslip.year, payslip.month),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SomaflowTheme.borderLight),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SomaflowTheme.sageWash,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: SomaflowTheme.sageDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: SomaflowTheme.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'SLIP-${payslip.id}',
                      style: const TextStyle(
                        color: SomaflowTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: SomaflowTheme.sagePrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Published ${localizations.formatMediumDate(payslip.publishedAt.toLocal())}',
                style: const TextStyle(
                  color: SomaflowTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _preview = payslip),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SomaflowTheme.sageDeep,
                  side: const BorderSide(color: SomaflowTheme.borderLight),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _downloadingId == null
                    ? () => _download(payslip)
                    : null,
                icon: _downloadingId == payslip.id
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _downloadingId == payslip.id ? 'Downloading' : 'Save PDF',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SomaflowTheme.sageDeep,
                  side: const BorderSide(color: SomaflowTheme.borderLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _yearChip(String label, bool selected, VoidCallback onTap) => Padding(
  padding: const EdgeInsets.only(right: 8),
  child: ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: SomaflowTheme.sageDeep,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : SomaflowTheme.textMuted,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    ),
    showCheckmark: false,
    side: const BorderSide(color: SomaflowTheme.borderLight),
  ),
);

Widget _notice(String message, {VoidCallback? retry}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: SomaflowTheme.borderLight),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message, style: const TextStyle(color: SomaflowTheme.textMuted)),
      if (retry != null)
        TextButton(onPressed: retry, child: const Text('Retry')),
    ],
  ),
);
