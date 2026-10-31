import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/l10n/app_translations.dart';

/// Keeps the EN/FR/AR translations in step with each other and with the code.
void main() {
  final keys = AppTranslations().keys;
  final en = keys['en']!;

  Set<String> placeholders(String text) =>
      RegExp(r'@(\w+)').allMatches(text).map((m) => m.group(1)!).toSet();

  test('French and Arabic have exactly the English keys', () {
    for (final language in ['fr', 'ar']) {
      final other = keys[language]!;
      expect(
        en.keys.toSet().difference(other.keys.toSet()),
        isEmpty,
        reason: 'missing in $language',
      );
      expect(
        other.keys.toSet().difference(en.keys.toSet()),
        isEmpty,
        reason: 'only in $language',
      );
    }
  });

  test('every translation keeps the English @placeholders', () {
    final mismatches = <String>[];
    for (final language in ['fr', 'ar']) {
      for (final entry in en.entries) {
        final text = keys[language]![entry.key] ?? '';
        if (!placeholders(text).containsAll(placeholders(entry.value))) {
          mismatches.add('$language:${entry.key}');
        }
      }
    }
    expect(mismatches, isEmpty);
  });

  test('every key the code translates is defined', () {
    final used = <String>{};
    final pattern = RegExp(r"'([a-z][a-z0-9_]*)'\s*\.\s*tr(?:Params)?\b");
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final match in pattern.allMatches(line)) {
          used.add(match.group(1)!);
        }
      }
    }
    expect(used.difference(en.keys.toSet()), isEmpty);
  });
}
