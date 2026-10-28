import 'package:flutter/material.dart';
import '../../../core/address/address_book.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';

/// View / change the saved delivery address (map pin + street details).
class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _line = TextEditingController();
  PickedLocation? _location;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AddressBook.instance.load().then((saved) {
      if (!mounted || saved == null) return;
      setState(() {
        _location = saved.location;
        _line.text = saved.line;
      });
    });
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked != null && mounted) setState(() => _location = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final location = _location;
    if (location == null) return;
    setState(() => _saving = true);
    await AddressBook.instance.remember(location, _line.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addressSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.addressTitle, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addressHelp, style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _location?.address.isNotEmpty == true ? _location!.address : l10n.checkoutChooseLocation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _location == null ? AppTypography.link : AppTypography.body,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.ink400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _line,
                decoration: InputDecoration(labelText: l10n.checkoutAddressLabel, hintText: l10n.checkoutAddressHint),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _location == null || _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.accountSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
