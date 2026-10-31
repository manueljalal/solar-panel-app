import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// "4.7", or "New" when nothing has been rated yet (instead of a
/// broken-looking "0.0").
String ratingLabel(BuildContext context, double rating) =>
    rating > 0 ? rating.toStringAsFixed(1) : AppLocalizations.of(context).ratingNew;
