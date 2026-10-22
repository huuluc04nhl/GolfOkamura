import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/theme/user_theme.dart';
import 'package:golf_booking/presentation/admin/screens/admin_rooms_screen.dart';
import 'package:golf_booking/presentation/user/screens/user_booking_screen.dart';
import 'package:golf_booking/presentation/user/screens/user_home_screen.dart';
import 'package:golf_booking/presentation/user/screens/user_my_bookings_screen.dart';
import 'package:golf_booking/presentation/user/screens/user_services_screen.dart';
import 'package:golf_booking/presentation/user/shells/user_shell.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildResponsiveTestHarness(Widget child, BookingProvider provider) {
  return ChangeNotifierProvider<BookingProvider>.value(
    value: provider,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UserTheme.theme,
      home: UserShell(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử giao diện Responsive trên toàn bộ các loại thiết bị di động', () {
    // 1. iPhone SE / Dòng máy nhỏ (< 380px)
    testWidgets('Kiểm thử hiển thị hoàn hảo trên iPhone SE (375 x 667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
      expect(find.text('DANH SÁCH PHÒNG CHƠI', skipOffstage: false), findsOneWidget);
    });

    // 2. Samsung Galaxy Z Flip / Màn hình gập dọc siêu dài (Tỉ lệ > 2.2)
    testWidgets('Kiểm thử hiển thị hoàn hảo trên Galaxy Z Flip (412 x 915)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
      expect(find.text('DANH SÁCH PHÒNG CHƠI', skipOffstage: false), findsOneWidget);
    });

    // 3. Samsung Galaxy Z Fold / Màn hình vuông gập mở (768 x 884)
    testWidgets('Kiểm thử hiển thị hoàn hảo trên Galaxy Z Fold mở rộng (768 x 884)', (tester) async {
      tester.view.physicalSize = const Size(768, 884);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
      expect(find.text('DANH SÁCH PHÒNG CHƠI', skipOffstage: false), findsOneWidget);
    });

    // 4. iPhone 15/16 Pro Max / Flagship màn hình lớn (430 x 932)
    testWidgets('Kiểm thử hiển thị trên Flagship iPhone Pro Max (430 x 932)', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
      expect(find.text('DANH SÁCH PHÒNG CHƠI', skipOffstage: false), findsOneWidget);
    });

    // 5. Android màn hình nhỏ đời cũ (320 x 568)
    testWidgets('Kiểm thử an toàn trên Android màn siêu nhỏ (320 x 568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
      expect(find.text('DANH SÁCH PHÒNG CHƠI', skipOffstage: false), findsOneWidget);
    });

    // 6. Màn hình Đặt phòng (UserBookingScreen) trên iPhone SE
    testWidgets('Kiểm thử UserBookingScreen trên iPhone SE (375 x 667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserBookingScreen(), provider));
      await tester.pump();

      expect(find.text('TIẾP TỤC CHỌN GIỜ'), findsOneWidget);
    });

    // 7. Màn hình Vé của tôi (UserMyBookingsScreen) trên Z Flip
    testWidgets('Kiểm thử UserMyBookingsScreen trên Galaxy Z Flip (412 x 915)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserMyBookingsScreen(), provider));
      await tester.pump();

      expect(find.text('VÉ & LỊCH ĐẶT PHÒNG CỦA TÔI'), findsOneWidget);
    });

    // 8. Màn hình Desktop / Windows (1280 x 800) - đảm bảo body không bị bottomNavigationBar che khuất
    testWidgets('Kiểm thử hiển thị trên Desktop Windows (1280 x 800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserHomeScreen(), provider));
      await tester.pumpAndSettle();

      final homeBox = tester.renderObject<RenderBox>(find.byType(UserHomeScreen));
      expect(homeBox.size.height, greaterThan(600));
      expect(find.text('OKAMURA GOLFZON'), findsWidgets);
      expect(find.text('ĐẶT PHÒNG NGAY'), findsWidgets);
    });

    // 9. Màn hình Order Dịch Vụ (UserServicesScreen) & thao tác vuốt chuyển danh mục
    testWidgets('Kiểm thử UserServicesScreen & vuốt ngang danh mục trên iPhone SE (375 x 667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(_buildResponsiveTestHarness(const UserServicesScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('ORDER DỊCH VỤ & TIỆN ÍCH'), findsOneWidget);
      expect(find.text('Iced Americano Arabica'), findsOneWidget);

      // Bấm thêm 1 món vào giỏ hàng
      await tester.tap(find.text('Thêm').first);
      await tester.pumpAndSettle();
      expect(find.text('1 món'), findsOneWidget);
    });

    // 10. Màn hình Quản Lý Phòng Bay (AdminRoomsScreen) - mở dialog Sửa Bay với cảm biến TwoVision NX 3D không bị crash
    testWidgets('Kiểm thử AdminRoomsScreen mở dialog Sửa Bay với cảm biến TwoVision NX 3D không bị crash', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider();
      await provider.initFuture;

      await tester.pumpWidget(
        ChangeNotifierProvider<BookingProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: AdminRoomsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GOLFZON STORE MANAGER — QUẢN LÝ PHÒNG BAY'), findsOneWidget);

      // Bấm nút sửa phòng Bay đầu tiên (PHÒNG 1 với Golfzon TwoVision NX 3D)
      final editButton = find.byTooltip('Chỉnh sửa phòng Bay').first;
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Kiểm tra dialog mở thành công, không bị lỗi assertion của DropdownButton
      expect(find.textContaining('Chỉnh Sửa'), findsOneWidget);
      expect(find.text('Dòng máy Simulator:'), findsOneWidget);
    });
  });
}
