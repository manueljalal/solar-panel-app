import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/city/city_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/iraq_cities.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import '../../../shared/widgets/city_picker.dart';
import '../data/services_repository.dart';
import '../domain/service_request.dart';

/// Booking form for an installation or a panel cleaning: map location,
/// address, city, optional preferred date, a size hint and a note. Pops
/// `true` once sent.
class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key, required this.type, required this.repository});

  final ServiceType type;
  final ServicesRepository repository;

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _address = TextEditingController();
  final _size = TextEditingController();
  final _note = TextEditingController();
  PickedLocation? _location;
  String? _cityId = CityController.instance.value;
  DateTime? _date;
  bool _submitting = false;
  String? _error;

  bool get _cleaning => widget.type == ServiceType.cleaning;

  @override
  void dispose() {
    _address.dispose();
    _size.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _location = picked;
      if (_address.text.trim().isEmpty) _address.text = picked.address;
      _cityId ??= matchIraqCity(picked.address.split(',').first)?.id;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final location = _location;
    if (location == null) return setState(() => _error = l10n.checkoutLocationRequired);
    if (_address.text.trim().length < 3) return setState(() => _error = l10n.checkoutAddressRequired);
    final sizeText = _size.text.trim();
    final size = sizeText.isEmpty ? null : double.tryParse(sizeText);
    if (sizeText.isNotEmpty && (size == null || size <= 0)) return setState(() => _error = l10n.bulkInvalidNumber);

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.repository.request(
        type: widget.type,
        address: _address.text.trim(),
        city: iraqCityById(_cityId)?.en ?? '',
        location: location,
        preferredDate: _date,
        panelCount: _cleaning ? size : null,
        systemSizeKw: _cleaning ? null : size,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyFunctionError(e, l10n.serviceFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.serviceFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final dateLabel = _date == null ? l10n.serviceAnyDate : MaterialLocalizations.of(context).formatMediumDate(_date!);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _cleaning ? l10n.serviceRequestTitleCleaning : l10n.serviceRequestTitleInstallation,
          style: AppTypography.h1.copyWith(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          _label(l10n.serviceLocation),
          _tappable(
            icon: Icons.location_on_outlined,
            text: _location?.address.isNotEmpty == true ? _location!.address : l10n.checkoutChooseLocation,
            placeholder: _location == null,
            onTap: _pickLocation,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _address,
            decoration: InputDecoration(labelText: l10n.checkoutAddressLabel, hintText: l10n.checkoutAddressHint),
          ),
          const SizedBox(height: AppSpacing.md),
          _label(l10n.cityLabel),
          _tappable(
            icon: Icons.location_city_outlined,
            text: iraqCityById(_cityId)?.nameFor(lang) ?? l10n.cityChoose,
            placeholder: _cityId == null,
            onTap: () async {
              final picked = await showIraqCityPicker(context, selectedId: _cityId);
              if (picked != null && picked.isNotEmpty) setState(() => _cityId = picked);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _label(l10n.servicePreferredDate),
          _tappable(icon: Icons.event_outlined, text: dateLabel, placeholder: _date == null, onTap: _pickDate),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _size,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(labelText: _cleaning ? l10n.servicePanelCount : l10n.serviceSystemSize),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _note, maxLines: 3, decoration: InputDecoration(labelText: l10n.serviceNote)),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.serviceSubmit, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
      );

  Widget _tappable({required IconData icon, required String text, required bool placeholder, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: placeholder ? AppTypography.link : AppTypography.body,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}
