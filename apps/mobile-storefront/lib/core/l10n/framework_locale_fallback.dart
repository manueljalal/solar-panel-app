import 'package:flutter/material.dart';

/// Flutter's built-in Material/Widgets/Cupertino localizations ship no
/// Sorani Kurdish ('ckb') data at all — GlobalMaterialLocalizations.delegate
/// (and the Widgets/Cupertino equivalents) simply can't resolve it, which
/// throws "No MaterialLocalizations found" and takes down the whole
/// widget tree the moment the app locale is set to ckb (confirmed via a
/// live crash — ckb matches nothing in Flutter's own generated locale
/// list). This wraps one of those three delegates and substitutes Arabic
/// for ckb specifically — same script family and RTL direction, so
/// framework chrome (date pickers, "OK"/"Cancel", drawer semantics
/// labels) stays readable and correctly right-to-left, while every
/// app-visible string still comes from our own real ckb translations via
/// AppLocalizations, which has no such gap.
class FrameworkLocaleFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const FrameworkLocaleFallbackDelegate(this._delegate);

  final LocalizationsDelegate<T> _delegate;

  static const _fallbacks = {'ckb': Locale('ar')};

  @override
  bool isSupported(Locale locale) =>
      _delegate.isSupported(_fallbacks[locale.languageCode] ?? locale);

  @override
  Future<T> load(Locale locale) => _delegate.load(_fallbacks[locale.languageCode] ?? locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}
