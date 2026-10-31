import 'package:get/get.dart';

/// UI strings in English, French and Arabic. Use them as `'key'.tr` (or
/// `'key'.trParams({...})` for `@name` placeholders). Add every new
/// user-facing string here in all three languages.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': _en,
    'fr': _fr,
    'ar': _ar,
  };
}

const _en = {
  'language_switched': 'Language switched to @language',
  'cancel': 'Cancel',
  'retry': 'Retry',
  'close': 'Close',
  'loading': 'Loading…',
  'mru': '@amount MRU',
};

const _fr = {
  'language_switched': 'Langue changée : @language',
  'cancel': 'Annuler',
  'retry': 'Réessayer',
  'close': 'Fermer',
  'loading': 'Chargement…',
  'mru': '@amount MRU',
};

const _ar = {
  'language_switched': 'تم تغيير اللغة إلى @language',
  'cancel': 'إلغاء',
  'retry': 'إعادة المحاولة',
  'close': 'إغلاق',
  'loading': 'جارٍ التحميل…',
  'mru': '@amount أوقية',
};
