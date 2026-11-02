import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/core/update/app_update.dart';

void main() {
  test('version comparison', () {
    expect(AppUpdate.isNewer('2.1', '2.0.3'), isTrue);
    expect(AppUpdate.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(AppUpdate.isNewer('1.0', '1.0.1'), isFalse);
    expect(AppUpdate.isNewer('1.10.0', '1.9.9'), isTrue);
    expect(AppUpdate.isNewer('1.0.0+5', '1.0.0'), isFalse);
  });
}
