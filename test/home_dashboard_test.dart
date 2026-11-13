import 'package:cobra_shield/core/models.dart';
import 'package:cobra_shield/screens/home_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryItem _item(int id, ScanKind kind, int score, {DateTime? time}) {
  return HistoryItem(
    id: id,
    kind: kind,
    title: 't$id',
    score: score,
    time: time ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('إحصائيات الداشبورد (من السجل الحقيقي)', () {
    test('قائمة فاضية = أصفار (مفيش أرقام تجريبية)', () {
      expect(countThreats(const <HistoryItem>[]), 0);
      expect(countUrlScans(const <HistoryItem>[]), 0);
    });

    test('التهديدات = خطير + احتيال مرجّح فقط', () {
      final items = <HistoryItem>[
        _item(1, ScanKind.url, 0), // low
        _item(2, ScanKind.url, kBandMedium), // medium (مشبوه)
        _item(3, ScanKind.url, kBandHigh), // high
        _item(4, ScanKind.message, kBandCritical), // critical
        _item(5, ScanKind.url, kBandHigh - 1), // medium
        _item(6, ScanKind.message, 100), // critical
      ];
      expect(countThreats(items), 3);
    });

    test('فحوصات الروابط بتتعدّ لوحدها', () {
      final items = <HistoryItem>[
        _item(1, ScanKind.url, 0),
        _item(2, ScanKind.message, 50),
        _item(3, ScanKind.url, 80),
      ];
      expect(countUrlScans(items), 2);
    });

    test('حدود المستويات مطابقة لثوابت النماذج', () {
      expect(_item(1, ScanKind.url, kBandHigh).level, RiskLevel.high);
      expect(_item(1, ScanKind.url, kBandHigh - 1).level, RiskLevel.medium);
      expect(_item(1, ScanKind.url, kBandCritical).level, RiskLevel.critical);
    });
  });

  group('agoText', () {
    final now = DateTime(2026, 6, 1, 12, 0);

    test('أقل من دقيقة', () {
      expect(agoText(now.subtract(const Duration(seconds: 20)), now: now), 'الآن');
    });

    test('دقائق وساعات وأيام', () {
      expect(
        agoText(now.subtract(const Duration(minutes: 5)), now: now),
        'منذ 5 دقيقة',
      );
      expect(
        agoText(now.subtract(const Duration(hours: 3)), now: now),
        'منذ 3 ساعة',
      );
      expect(
        agoText(now.subtract(const Duration(days: 2)), now: now),
        'منذ 2 يوم',
      );
    });
  });
}
