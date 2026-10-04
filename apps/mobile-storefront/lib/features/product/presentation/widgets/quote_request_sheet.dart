import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_product.dart';
import '../../data/quote_request_repository.dart';

/// Bottom sheet for "Request quote" — a real form that writes to
/// Firestore via QuoteRequestRepository, with a loading state and error
/// handling, not just a dialog that closes.
Future<void> showQuoteRequestSheet(BuildContext context, HomeProduct product) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _QuoteRequestSheet(product: product),
  );
}

class _QuoteRequestSheet extends StatefulWidget {
  const _QuoteRequestSheet({required this.product});

  final HomeProduct product;

  @override
  State<_QuoteRequestSheet> createState() => _QuoteRequestSheetState();
}

class _QuoteRequestSheetState extends State<_QuoteRequestSheet> {
  final _controller = TextEditingController();
  final _repository = QuoteRequestRepository();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.submit(product: widget.product, note: _controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quoteRequested(widget.product.title))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n.genericConnectionError;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.requestAQuote, style: AppTypography.h1.copyWith(fontSize: 19)),
            const SizedBox(height: 4),
            Text(
              '${widget.product.title} · ${widget.product.vendor}',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.quoteRequestHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: AppColors.warning, fontSize: 12.5)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.sendRequest, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
