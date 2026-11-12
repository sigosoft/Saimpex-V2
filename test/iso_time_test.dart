import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/store_labels.dart';

/// Server times with an offset are shown in the phone's time zone. No
/// translations are loaded here, so the month shows as its key.
final _lri = String.fromCharCode(0x2066);
final _pdi = String.fromCharCode(0x2069);

void main() {
  String local(String iso) {
    final t = DateTime.parse(iso).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${two(t.day)} svc_month_${t.month}\u200E ${t.year}, '
        '${two(hour)}:${two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  test('ISO step times follow the phone time zone', () {
    expect(
      readableIsoTime('2026-11-03T10:00:00+05:30'),
      local('2026-11-03T10:00:00+05:30'),
    );
    expect(readableIsoTime(null), '');
    expect(readableIsoTime('03 Nov 2026 10:00 AM'), '');
  });

  test('laundry windows show start – end, end date only when it differs', () {
    const start = '2026-11-12T08:00:00+00:00';
    const end = '2026-11-12T10:00:00+00:00';
    final from = local(start);
    final to = local(end);
    final sameDay =
        DateTime.parse(start).toLocal().day == DateTime.parse(end).toLocal().day;
    expect(
      readableWindow({'start_iso': start, 'end_iso': end}),
      '$_lri$from – ${sameDay ? to.split(', ').last : to}$_pdi',
    );
    expect(
      readableWindow({'start_iso': start, 'end_iso': null}),
      '$_lri$from$_pdi',
    );
    expect(readableWindow(null), '');
    expect(readableWindow({'start_iso': null}), '');
  });
}
