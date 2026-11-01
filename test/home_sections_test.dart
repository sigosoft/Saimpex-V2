// Home section titles: the server sends English only (`title_en`), so in
// French and Arabic the app's own translation must be used instead of the
// English text (it showed "Recent Orders" on the Arabic home).

import 'package:flutter_test/flutter_test.dart';

import 'package:saimpex_v2/models/general_repository.dart';

void main() {
  const fromServer = [
    {'key': 'recent_orders', 'title_en': 'Recent Orders', 'see_all': 'orders'},
    {'key': 'new_section', 'title_en': 'Brand new', 'see_all': 'food'},
    {
      'key': 'translated',
      'title_en': 'Deals',
      'title_ar': 'العروض',
      'see_all': 'food',
    },
  ];

  test('English keeps the server title', () {
    final s = GeneralRepository.homeSectionsFrom(fromServer, 'en');
    expect(s['recent_orders']!['title'], 'Recent Orders');
    expect(s['recent_orders']!['seeAll'], 'orders');
  });

  test('Arabic: no server title in Arabic, so the app translates', () {
    final s = GeneralRepository.homeSectionsFrom(fromServer, 'ar');
    // Empty title -> HomeController.sectionTitle uses 'core_home_recent_orders'.tr.
    expect(s['recent_orders']!['title'], '');
    expect(s['recent_orders']!['title_en'], 'Recent Orders');
    // A section the app has no key for still has the English as last resort.
    expect(s['new_section']!['title_en'], 'Brand new');
    // A server title in Arabic wins.
    expect(s['translated']!['title'], 'العروض');
  });

  test('not a list -> no sections', () {
    expect(GeneralRepository.homeSectionsFrom(null, 'ar'), isEmpty);
  });
}
