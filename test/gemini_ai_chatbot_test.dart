import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/config/ai_key_vault.dart';
import 'package:golf_booking/presentation/shared_widgets/ai_chat_bottom_sheet.dart';
import 'package:golf_booking/presentation/shared_widgets/ai_floating_button.dart';
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
      expect(find.text('OKAMURA AI CADDIE'), findsOneWidget);
      expect(find.text('GEMINI 24/7'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Xác nhận các gợi ý câu hỏi nhanh (Quick Prompts)
      expect(find.text('👑 Phòng VIP có gì đặc biệt?'), findsOneWidget);
      expect(find.text('💰 Bảng giá các loại Bay 3D'), findsOneWidget);
    });

    testWidgets('AiFloatingButton hiển thị chuẩn phong cách Quiet Luxury', (tester) async {
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
      expect(find.text('AI CADDIE'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}
