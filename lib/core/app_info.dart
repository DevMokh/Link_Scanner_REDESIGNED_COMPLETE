/// اسم التطبيق الظاهر للمستخدم: "كاشف الروابط | Link Scanner".
///
/// (المعرّفات الداخلية ما اتغيّرتش عمدًا عشان بيانات المستخدمين الحاليين ما تضيعش:
/// اسم الحزمة `com.cobrashield.cobra_shield`، واسم المشروع في pubspec `cobra_shield`،
/// ومفاتيح SharedPreferences `cobra.*`.)
const String kAppNameAr = 'كاشف الروابط';
const String kAppNameEn = 'Link Scanner';
const String kAppName = '$kAppNameAr | $kAppNameEn';

/// رقم إصدار التطبيق (اسم الإصدار فقط، من غير build number).
///
/// لازم يطابق `version:` في pubspec.yaml، وفيه اختبار (`app_info_test.dart`) بيفشل لو اتخالفوا.
/// بيتبعت كـ clientVersion لخدمة Google Safe Browsing، فمش لازم يفضل رقم قديم.
const String kAppVersion = '1.11.1';

/// رقم البناء (الجزء بعد `+` في `version:` في pubspec.yaml). بيظهر في القائمة الجانبية فقط،
/// ومتغطّي بنفس اختبار [kAppVersion].
const int kAppBuild = 14;
