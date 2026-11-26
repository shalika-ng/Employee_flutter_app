import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/network/api_client.dart';
import '../../../core/somaflow_theme.dart';
import '../models/payslip.dart';

class PayslipPreview extends StatefulWidget {
  const PayslipPreview({
    required this.payslip,
    required this.load,
    required this.onClose,
    this.viewerBuilder,
    super.key,
  });

  final Payslip payslip;
  final Future<Uint8List> Function() load;
  final VoidCallback onClose;
  final Widget Function(BuildContext context, Uint8List bytes)? viewerBuilder;

  @override
  State<PayslipPreview> createState() => _PayslipPreviewState();
}

class _PayslipPreviewState extends State<PayslipPreview> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final period = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(widget.payslip.year, widget.payslip.month));
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to payslips',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: SomaflowTheme.sageDeep,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period,
                        style: const TextStyle(
                          color: SomaflowTheme.textCharcoal,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Payslip · SLIP-${widget.payslip.id}',
                        style: const TextStyle(
                          color: SomaflowTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: SomaflowTheme.sageDeep,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return _PreviewError(
                    message: error is ApiException
                        ? error.message
                        : 'Unable to load payslip. Please try again.',
                    onRetry: _retry,
                  );
                }
                final bytes = snapshot.requireData;
                return widget.viewerBuilder?.call(context, bytes) ??
                    PdfViewer.data(
                      bytes,
                      sourceName: 'payslip-${widget.payslip.id}',
                      maxSizeToCacheOnMemory: bytes.length,
                      params: PdfViewerParams(
                        backgroundColor: SomaflowTheme.sageWash,
                        errorBannerBuilder: (context, error, stackTrace, _) =>
                            _PreviewError(
                              message: 'Unable to display this PDF.',
                              onRetry: _retry,
                            ),
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            color: SomaflowTheme.cancelCoral,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
