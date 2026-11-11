import 'package:get/get.dart' show Trans;

/// Amount with the currency in the app language: "260 MRU" in English and
/// French, "260 أوقية" in Arabic (translation key `mru`).
String mruAmount(Object? amount) => 'mru'.trParams({'amount': '$amount'});

/// The currency name alone in the app language ("MRU" / "أوقية").
String mruUnit() => mruAmount('').trim();

final _codeAfter = RegExp(r'^\s*([-+]?[\d.,]+)\s*MRU\s*$', caseSensitive: false);
final _codeBefore = RegExp(r'^\s*MRU\s*([-+]?[\d.,]+)\s*$', caseSensitive: false);
final _code = RegExp(r'\bMRU\b', caseSensitive: false);

/// A price text the server sent ("260 MRU", "MRU 260") in the app language.
/// Text with no "MRU" in it is returned as it is.
String localizeMru(String text) {
  final after = _codeAfter.firstMatch(text) ?? _codeBefore.firstMatch(text);
  if (after != null) return mruAmount(after.group(1));
  return text.replaceAll(_code, mruUnit());
}
