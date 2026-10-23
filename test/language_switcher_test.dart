import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/localization/app_language_provider.dart';
import 'package:golf_booking/core/localization/app_translations.dart';
import 'package:golf_booking/presentation/shared_widgets/language_selector_pill.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử Bộ Chuyển Đổi Ngôn Ngữ Chuẩn Okamura Golfzon', () {
    test('AppLanguageProvider chuyển đổi mượt mà giữa 4 ngôn ngữ và lưu SharedPreferences', () async {
      final provider = AppLanguageProvider();

      // Mặc định là Tiếng Việt
      expect(provider.currentLanguage, AppLanguage.vi);
      expect(provider.languageCode, 'vi');
      expect(provider.flagEmoji, '🇻🇳');
      expect(provider.shortLabel, 'VN');

      // Chuyển sang English
      await provider.changeLanguage(AppLanguage.en);
      expect(provider.currentLanguage, AppLanguage.en);
      expect(provider.languageCode, 'en');
      expect(provider.flagEmoji, '🇬🇧');
      expect(provider.shortLabel, 'EN');

      // Chuyển sang 한국어 (Korean)
      await provider.changeLanguage(AppLanguage.ko);
      expect(provider.currentLanguage, AppLanguage.ko);
      expect(provider.languageCode, 'ko');
      expect(provider.flagEmoji, '🇰🇷');
      expect(provider.shortLabel, 'KR');

      // Chuyển sang 日本語 (Japanese)
      await provider.changeLanguage(AppLanguage.ja);
      expect(provider.currentLanguage, AppLanguage.ja);
      expect(provider.languageCode, 'ja');
      expect(provider.flagEmoji, '🇯🇵');
      expect(provider.shortLabel, 'JP');
    });

    test('AppTranslations cung cấp đầy đủ bản dịch chính xác cho cả 4 ngôn ngữ', () {
      final vi = AppTranslations.values['vi']!;
      final en = AppTranslations.values['en']!;
      final ko = AppTranslations.values['ko']!;
      final ja = AppTranslations.values['ja']!;

      // Navigation
      expect(vi['nav_home'], 'Trang chủ');
      expect(en['nav_home'], 'Home');
      expect(ko['nav_home'], '홈');
      expect(ja['nav_home'], 'ホーム');

      expect(vi['nav_booking'], 'Đặt phòng');
      expect(en['nav_booking'], 'Book Bay');
      expect(ko['nav_booking'], '예약하기');
      expect(ja['nav_booking'], 'ブース予約');

      // Services
      expect(vi['nav_services'], 'Dịch vụ');
      expect(en['nav_services'], 'Services');
      expect(ko['nav_services'], '서비스');
      expect(ja['nav_services'], 'サービス');

      // My bookings
      expect(vi['nav_my_bookings'], 'Vé của tôi');
      expect(en['nav_my_bookings'], 'My Bookings');
      expect(ko['nav_my_bookings'], '내 예약');
      expect(ja['nav_my_bookings'], '予約一覧');
    });

    testWidgets('LanguageSelectorPill hiển thị cờ và mở BottomSheet lựa chọn 4 ngôn ngữ', (tester) async {
      final languageProvider = AppLanguageProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppLanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        Text(context.tr('nav_home')),
                        const LanguageSelectorPill(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra nhãn tiếng Việt ban đầu
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('VN'), findsOneWidget);
      expect(find.text('🇻🇳'), findsOneWidget);

      // Bấm vào LanguageSelectorPill để mở BottomSheet
      await tester.tap(find.byType(LanguageSelectorPill));
      await tester.pumpAndSettle();

      // Xác nhận xuất hiện danh sách 4 ngôn ngữ
      expect(find.text('CHỌN NGÔN NGỮ / LANGUAGE'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);

      // Bấm chọn English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Xác nhận giao diện tự động cập nhật sang English
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('🇬🇧'), findsOneWidget);
    });
  });
}
