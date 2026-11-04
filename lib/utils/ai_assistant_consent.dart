import 'package:shared_preferences/shared_preferences.dart';

/// Whether the customer agreed that their messages go to the SAIMPEX
/// assistant (Claude by Anthropic) before the first message (store release
/// checklist: Apple requires disclosure and consent before personal data is
/// sent to a third-party AI). Kept on the phone: the API has no consent
/// field, so a new phone or a reinstall asks again.
class AiAssistantConsent {
  AiAssistantConsent._();

  static const _prefsKey = 'ai_assistant_consent_v1';
  static bool? _given;

  static Future<bool> load() async {
    final cached = _given;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    return _given = prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> give() async {
    _given = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
