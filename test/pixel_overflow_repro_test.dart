import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/theme/user_theme.dart';
import 'package:golf_booking/presentation/shared_widgets/vietqr_payment_dialog.dart';
import 'package:golf_booking/presentation/user/screens/user_booking_screen.dart';
import 'package:golf_booking/presentation/user/screens/user_services_screen.dart';
import 'package:golf_booking/presentation/user/shells/user_shell.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử triệt tiêu 100% lỗi Pixel Overflow trên toàn bộ các dòng máy điện thoại', () {
    final phoneScreenSizes = [
      const Size(320, 568), // iPhone 5SE / Màn Android siêu nhỏ
      const Size(360, 640), // Android tầm trung phổ biến
      const Size(375, 667), // iPhone SE / iPhone 8
      const Size(390, 844), // iPhone 12 / 13 / 14
      const Size(412, 915), // Samsung Galaxy Z Flip
    ];

    testWidgets('VietQrPaymentDialog không bao giờ bị RenderFlex overflow', (tester) async {
      for (final size in phoneScreenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: UserTheme.theme,
            home: const Scaffold(
              body: VietQrPaymentDialog(
                bookingId: 'OGZ-20261027-9999',
                roomName: 'VIP Lounge Diamond 01 Luxury Suite',
                amount: 15500000,
                customerName: 'Nguyễn Văn Hào Siêu VIP Golfer',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('THANH TOÁN VIETQR 24/7', skipOffstage: false), findsOneWidget);
        expect(find.text('OKAMURA GOLF LOUNGE', skipOffstage: false), findsOneWidget);
        expect(find.text('Tôi đã chuyển khoản xong', skipOffstage: false), findsOneWidget);
      }
    });

    testWidgets('UserServicesScreen và Cart Bottom Sheet không bị RenderFlex overflow trên màn hình 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(
        ChangeNotifierProvider<BookingProvider>.value(
          value: provider,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: UserTheme.theme,
            home: const UserShell(child: UserServicesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Thêm món vào giỏ
      final addButtons = find.text('Thêm');
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Mở Cart Review Sheet
      await tester.tap(find.text('XEM & GỬI ORDER'));
      await tester.pumpAndSettle();

      expect(find.text('XÁC NHẬN ORDER TẬN PHÒNG'), findsOneWidget);
      expect(find.text('GỬI ORDER ĐẾN BẾP'), findsOneWidget);

      // Đóng sheet
      await tester.tap(find.text('Xóa hết'));
      await tester.pumpAndSettle();
    });

    testWidgets('UserBookingScreen không bị RenderFlex overflow trên màn hình 360x640 và 320x568', (tester) async {
      for (final size in [const Size(320, 568), const Size(360, 640)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final provider = BookingProvider();
        await provider.initFuture;

        await tester.pumpWidget(
          ChangeNotifierProvider<BookingProvider>.value(
            value: provider,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: UserTheme.theme,
              home: const UserShell(child: UserBookingScreen()),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('TIẾP TỤC CHỌN GIỜ'), findsOneWidget);
      }
    });
  });
}
