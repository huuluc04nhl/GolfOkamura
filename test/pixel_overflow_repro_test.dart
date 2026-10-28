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

    Future<void> testBookingFlow(WidgetTester tester, Size size) async {
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
      await tester.pumpAndSettle();

      // 3 Bước chuẩn Quiet Luxury
      expect(find.text('Ngày chơi'), findsOneWidget);
      expect(find.text('Khung giờ'), findsOneWidget);
      expect(find.text('Chọn phòng'), findsOneWidget);
      // Không còn bước 4 rườm rà
      expect(find.text('Nhập TT'), findsNothing);

      // Chuyển sang Bước 2
      await tester.tap(find.text('TIẾP TỤC CHỌN GIỜ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CHỌN PHÒNG KHUNG'), findsOneWidget);

      // Chuyển sang Bước 3 qua nút cuộn tới
      await tester.ensureVisible(find.textContaining('CHỌN PHÒNG KHUNG'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('CHỌN PHÒNG KHUNG'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tất cả ('), findsOneWidget);

      // Mở Phiếu Xác Nhận Đặt Chỗ (BottomSheet)
      final bookButtons = find.text('Đặt phòng');
      expect(bookButtons, findsWidgets);
      await tester.ensureVisible(bookButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(bookButtons.first);
      await tester.pumpAndSettle();

      // Phiếu xác nhận giữ chỗ mở hoàn hảo
      expect(find.textContaining('XÁC NHẬN GIỮ CHỖ'), findsOneWidget);
      expect(find.text('Họ và tên quý khách'), findsOneWidget);
      expect(find.text('Số điện thoại nhận mã vé'), findsOneWidget);

      // Đóng sheet
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();
    }

    testWidgets('Quy trình 3 bước & Phiếu Xác Nhận Đặt Chỗ mượt mà trên iPhone SE (375 x 667)', (tester) async {
      await testBookingFlow(tester, const Size(375, 667));
    });

    testWidgets('Quy trình 3 bước & Phiếu Xác Nhận Đặt Chỗ mượt mà trên iPhone 14/15 Pro (390 x 844)', (tester) async {
      await testBookingFlow(tester, const Size(390, 844));
    });
  });
}
