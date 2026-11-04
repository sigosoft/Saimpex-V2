import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/ai_assistant_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'the assistant asks until the customer agrees, then remembers',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AiAssistantConsent.load(), isFalse);

      await AiAssistantConsent.give();
      expect(await AiAssistantConsent.load(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ai_assistant_consent_v1'), isTrue);
    },
  );
}
