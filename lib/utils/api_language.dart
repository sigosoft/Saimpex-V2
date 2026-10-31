import '../l10n/app_locale.dart';

/// The API language code (`en`, `fr` or `ar`): the language the app is in.
String apiLanguageCode() => AppLocale.code;

/// Convenience alias for [apiLanguageCode].
String currentApiLanguage() => apiLanguageCode();
