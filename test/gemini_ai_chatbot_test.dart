import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/config/ai_key_vault.dart';
import 'package:golf_booking/presentation/shared_widgets/ai_chat_bottom_sheet.dart';
import 'package:golf_booking/presentation/shared_widgets/ai_floating_button.dart';
import 'package:golf_booking/presentation/user/screens/user_ai_assistant_screen.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:golf_booking/shared/services/gemini_ai_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử Bảo mật Khóa & Trợ lý Okamura AI Caddie (Gemini AI)', () {
    test('AiKeyVault giải mã an toàn khóa mặc định và hỗ trợ ghi đè khóa tùy chỉnh', () async {
      // 1. Kiểm tra khóa mặc định được giải mã thành công từ masked seed
      final defaultKey = await AiKeyVault.getApiKey();
      expect(defaultKey.isNotEmpty, true);
      expect(defaultKey.startsWith('AQ.'), true);
      expect(await AiKeyVault.isUsingCustomKey(), false);

      // 2. Thử thiết lập khóa tùy chỉnh của người dùng
      const customKey = 'CUSTOM_KEY_TEST_12345';
      await AiKeyVault.setCustomApiKey(customKey);
      expect(await AiKeyVault.isUsingCustomKey(), true);
      expect(await AiKeyVault.getApiKey(), customKey);

      // 3. Khôi phục lại khóa mặc định
      await AiKeyVault.setCustomApiKey(null);
      expect(await AiKeyVault.isUsingCustomKey(), false);
      expect(await AiKeyVault.getApiKey(), defaultKey);
    });

    test('GeminiAiService phản hồi fallback thông minh và nhận diện ý định điều hướng', () async {
      final service = GeminiAiService();

      // Test câu hỏi về giá phòng -> Nhận diện action /booking
      final priceMessage = await service.sendMessage(
        prompt: 'Bảng giá các phòng VIP là bao nhiêu?',
        currentUserName: 'Nguyễn Xuân Hào',
        userRole: 'customer',
      );
      expect(priceMessage.text.isNotEmpty, true);
      expect(priceMessage.isUser, false);
      expect(priceMessage.actionRoute, '/booking');

      // Test câu hỏi về quầy bar & bia -> Nhận diện action /services
      final fnbMessage = await service.sendMessage(
        prompt: 'Menu bia tháp Sapporo và đồ uống',
        currentUserName: 'Nguyễn Xuân Hào',
        userRole: 'customer',
      );
      expect(fnbMessage.text.isNotEmpty, true);
      expect(fnbMessage.actionRoute, '/services');
    });

    testWidgets('Giao diện AiChatBottomSheet hiển thị đầy đủ avatar, lời chào và gợi ý câu hỏi', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<BookingProvider>.value(
              value: provider,
              child: const AiChatBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Xác nhận các thành phần cốt lõi của Chatbot xuất hiện
      expect(find.text('AI CADDIE'), findsOneWidget);
      expect(find.text('Trực tuyến 24/7'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Xác nhận các gợi ý câu hỏi nhanh thân thiện (Friendly Quick Prompts)
      expect(find.text('Tư vấn chọn phòng chơi phù hợp'), findsOneWidget);
      expect(find.text('Bảng giá thuê phòng hôm nay'), findsOneWidget);
    });

    testWidgets('Giao diện AiChatBottomSheet tối ưu khung hình Mobile và không lộ cấu hình API Key', (tester) async {
      // Giả lập màn hình mobile tiêu chuẩn (iPhone SE / Android nhỏ 375 x 667)
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<BookingProvider>.value(
              value: provider,
              child: const AiChatBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và huy hiệu hiển thị gọn gàng, không bị tràn (overflow)
      expect(find.text('AI CADDIE'), findsOneWidget);
      expect(find.text('Trực tuyến 24/7'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Đảm bảo nút Làm mới hội thoại và nút Đóng hiện diện trang nhã
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tuyệt đối không để lộ nút hay giao diện cấu hình API Key cho người dùng
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
      expect(find.text('Cấu hình Gemini API'), findsNothing);
      expect(find.text('Khóa Google Gemini API Key:'), findsNothing);
    });

    test('GeminiAiService tự động sinh gợi ý tiếp theo và gắn thẻ thao tác trực tiếp', () async {
      final service = GeminiAiService();

      // 1. Khách hỏi về tra cứu vé & lịch đặt phòng -> AI tự gắn action /my-bookings
      final ticketReply = await service.sendMessage(
        prompt: 'Tôi muốn xem vé đã đặt và mã PIN mở phòng',
        currentUserName: 'Nguyễn Xuân Hào',
        userRole: 'customer',
      );
      expect(ticketReply.actionRoute, '/my-bookings');
      expect(ticketReply.actionLabel, contains('Xem Vé & Lịch Đặt'));
      expect(ticketReply.quickPrompts.isNotEmpty, true);

      // 2. Khách hỏi về menu đồ ăn thức uống -> AI tự gắn action /services
      final fnbReply = await service.sendMessage(
        prompt: 'Tôi muốn gọi bia tháp Sapporo và đồ ăn vào phòng',
        currentUserName: 'Nguyễn Xuân Hào',
        userRole: 'customer',
      );
      expect(fnbReply.actionRoute, '/services');
      expect(fnbReply.actionLabel, contains('Mở Thực Đơn'));
      expect(fnbReply.quickPrompts.isNotEmpty, true);
    });

    testWidgets('Giao diện AiChatBottomSheet an toàn trên màn hình siêu hẹp (320 x 568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<BookingProvider>.value(
              value: provider,
              child: const AiChatBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('AI CADDIE'), findsOneWidget);
      expect(find.text('Trực tuyến 24/7'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('AiFloatingButton hiển thị chuẩn phong cách Quiet Luxury hình tròn chữ C', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AiFloatingButton(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('C'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('AiFloatingButton hỗ trợ kéo thả và tự động dock sang mép trái', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AiFloatingButton(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Kéo nút từ bên phải sang mép bên trái bằng TestGesture
      final buttonFinder = find.byType(AiFloatingButton);
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Sau khi buông tay ở nửa trái, nút tự hít mép trái và vẫn giữ nguyên chữ C
      expect(find.text('C'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('Giao diện UserAiAssistantScreen hiển thị chi tiết trung tâm hỗ trợ AI và các chủ đề chuyên sâu', (tester) async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BookingProvider>.value(
            value: provider,
            child: const UserAiAssistantScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TRỢ LÝ OKAMURA'), findsOneWidget);
      expect(find.text('Chọn phòng phù hợp'), findsOneWidget);
      expect(find.text('Bảng giá & Giờ đẹp'), findsOneWidget);
      expect(find.text('Đồ ăn & Nước uống'), findsOneWidget);
      expect(find.text('Ưu đãi thành viên'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
