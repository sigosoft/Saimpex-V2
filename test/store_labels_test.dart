import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/store_labels.dart';

void main() {
  test('ratings show at most one decimal', () {
    expect(ratingLabel('4.666667'), '4.7');
    expect(ratingLabel(5), '5');
    expect(ratingLabel('4.0'), '4');
    expect(ratingLabel(null), '');
    expect(ratingLabel('New'), 'New');
  });
}
