import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/theme/user_theme.dart';
import 'package:golf_booking/presentation/auth/screens/auth_screen.dart';
import 'package:golf_booking/shared/models/golfer_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử Xác thực & Phân quyền Đăng nhập (Auth & Role-Based Routing)', () {
    test('Đăng nhập tài khoản Quản trị viên (OKAMURA ADMIN)', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final result = await provider.login(
        usernameOrPhone: 'admin',
        password: '123456',
      );

      expect(result['success'], true);
      expect(result['role'], 'admin');
      expect(provider.currentGolfer.isAdmin, true);
      expect(provider.currentGolfer.name, 'OKAMURA ADMIN');
      expect(provider.isLoggedIn, true);
    });

    test('Đăng nhập tài khoản Khách hàng thực tế (Nguyễn Xuân Hào)', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final result = await provider.login(
        usernameOrPhone: '0354378606',
        password: '123456',
      );

      expect(result['success'], true);
      expect(result['role'], 'customer');
      expect(provider.currentGolfer.isCustomer, true);
      expect(provider.currentGolfer.name, 'Nguyễn Xuân Hào');
      expect(provider.currentGolfer.phone, '0354378606');
      expect(provider.currentGolfer.email, 'haosimla365@gmail.com');
      expect(provider.currentGolfer.tier, GolferTier.gold);
      expect(provider.isLoggedIn, true);

      // Đăng nhập bằng Email
      final emailResult = await provider.login(
        usernameOrPhone: 'haosimla365@gmail.com',
        password: '123456',
      );
      expect(emailResult['success'], true);
    });

    test('Đăng nhập sai mật khẩu phải trả về lỗi rõ ràng', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final result = await provider.login(
        usernameOrPhone: '0354378606',
        password: 'wrong_password_999',
      );

      expect(result['success'], false);
      expect(result['message'], isNotEmpty);
    });

    test('Đăng ký tài khoản hội viên mới thành công', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final regResult = await provider.register(
        name: 'Trần Văn Nam',
        phone: '0912334455',
        email: 'nam.tran@gmail.com',
        password: 'mypassword123',
        handicap: 14.5,
      );

      expect(regResult['success'], true);
      expect(regResult['role'], 'customer');
      expect(provider.currentGolfer.name, 'Trần Văn Nam');
      expect(provider.currentGolfer.isCustomer, true);
      expect(provider.currentGolfer.loyaltyPoints, 100);
      expect(provider.isLoggedIn, true);
    });

    test('Không cho phép đăng ký trùng số điện thoại Admin', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final regResult = await provider.register(
        name: 'Giả Mạo Admin',
        phone: '0901234567',
        password: '123',
      );

      expect(regResult['success'], false);
    });

    test('Tiếp tục sử dụng ứng dụng với tư cách Khách vãng lai', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await provider.continueAsGuest();
      expect(provider.isGuest, true);
      expect(provider.isLoggedIn, false);
      expect(provider.currentGolfer.name, 'Khách vãng lai');
    });

    test('Bẫy lỗi dữ liệu khi cập nhật thông tin cá nhân (Validation Trapping)', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      // Đăng nhập tài khoản anh Hào
      await provider.login(usernameOrPhone: '0354378606', password: '123456');

      // 1. Tên chứa số / ký tự đặc biệt -> Phải thất bại
      final res1 = await provider.updateGolferProfileWithValidation(
        name: 'Hao 123@#',
        phone: '0354378606',
        email: 'haosimla365@gmail.com',
        handicap: 15.6,
      );
      expect(res1['success'], false);
      expect(res1['message'].toString().contains('ký tự đặc biệt'), true);

      // 2. Số điện thoại sai định dạng (chỉ có 8 số) -> Phải thất bại
      final res2 = await provider.updateGolferProfileWithValidation(
        name: 'Nguyễn Xuân Hào',
        phone: '09123456',
        email: 'haosimla365@gmail.com',
        handicap: 15.6,
      );
      expect(res2['success'], false);
      expect(res2['message'].toString().contains('Số điện thoại không hợp lệ'), true);

      // 3. Email sai cú pháp -> Phải thất bại
      final res3 = await provider.updateGolferProfileWithValidation(
        name: 'Nguyễn Xuân Hào',
        phone: '0354378606',
        email: 'haosimla-sai-dinh-dang',
        handicap: 15.6,
      );
      expect(res3['success'], false);
      expect(res3['message'].toString().contains('email'), true);

      // 4. Điểm Handicap vượt trần WHS (> 54.0) -> Phải thất bại
      final res4 = await provider.updateGolferProfileWithValidation(
        name: 'Nguyễn Xuân Hào',
        phone: '0354378606',
        email: 'haosimla365@gmail.com',
        handicap: 75.0,
      );
      expect(res4['success'], false);
      expect(res4['message'].toString().contains('Handicap'), true);

      // 5. Cập nhật thông tin chuẩn -> Phải thành công
      final resSuccess = await provider.updateGolferProfileWithValidation(
        name: 'Nguyễn Xuân Hào VIP',
        phone: '0354378606',
        email: 'haosimla365@gmail.com',
        handicap: 14.8,
      );
      expect(resSuccess['success'], true);
      expect(provider.currentGolfer.name, 'Nguyễn Xuân Hào VIP');
      expect(provider.currentGolfer.handicap, 14.8);
    });

    test('Đăng xuất tài khoản', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await provider.login(usernameOrPhone: 'admin', password: '123456');
      expect(provider.isLoggedIn, true);

      await provider.logout();
      expect(provider.isLoggedIn, false);
    });

    testWidgets('Giao diện AuthScreen hiển thị form sang trọng và nút Tiếp tục mà không cần đăng nhập', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await tester.pumpWidget(
        ChangeNotifierProvider<BookingProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: UserTheme.theme,
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OKAMURA GOLFZON LOUNGE'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
      expect(find.text('ĐĂNG KÝ HỘI VIÊN'), findsOneWidget);
      expect(find.text('Tiếp tục mà không cần đăng nhập'), findsOneWidget);
    });
  });
}
