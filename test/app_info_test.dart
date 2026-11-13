import 'dart:io';

import 'package:cobra_shield/core/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kAppVersion مطابق لـ version في pubspec.yaml (من غير build number)', () {
    final text = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$', multiLine: true)
        .firstMatch(text);
    expect(m, isNotNull, reason: 'سطر version غير موجود أو بصيغة غير متوقعة');
    expect(kAppVersion, m!.group(1));
  });

  test('kAppBuild مطابق لرقم البناء (بعد +) في pubspec.yaml', () {
    final text = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$', multiLine: true)
        .firstMatch(text);
    expect(m, isNotNull, reason: 'سطر version غير موجود أو بصيغة غير متوقعة');
    expect(kAppBuild, int.parse(m!.group(2)!));
  });

  test('اسم التطبيق الظاهر: كاشف الروابط | Link Scanner', () {
    expect(kAppNameAr, 'كاشف الروابط');
    expect(kAppNameEn, 'Link Scanner');
    expect(kAppName, 'كاشف الروابط | Link Scanner');
  });
}
