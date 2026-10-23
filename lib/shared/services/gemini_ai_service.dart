import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/ai_key_vault.dart';
import '../models/chat_message_model.dart';

/// Dịch vụ Trợ lý AI Caddie sử dụng Google Gemini API
class GeminiAiService {
  static const List<String> _models = [
    'gemini-flash-lite-latest',
    'gemini-flash-latest',
    'gemini-3.8-flash',
  ];

  final List<Map<String, dynamic>> _conversationHistory = [];

  /// Reset lại lịch sử hội thoại
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Tạo prompt hệ thống chuyên biệt cho Okamura Golfzon Lounge
  String _buildSystemInstruction({
    String? currentUserName,
    String? userRole,
    int? availableRoomsCount,
    String languageCode = 'vi',
  }) {
    final userLabel = currentUserName ?? 'Quý khách';
    final roleLabel = userRole == 'admin' ? 'Quản trị viên' : (userRole == 'customer' ? 'Hội viên' : 'Khách vãng lai');
    final bayInfo = availableRoomsCount != null ? 'Hiện có $availableRoomsCount phòng đang sẵn sàng đón khách.' : '';

    String langGuideline = 'NGÔN NGỮ PHẢN HỒI: Tiếng Việt chuẩn mực, lịch thiệp.';
    if (languageCode == 'en') {
      langGuideline = 'RESPONSE LANGUAGE: Always respond in natural, professional English.';
    } else if (languageCode == 'ko') {
      langGuideline = '응답 언어: 골프존 전문 용어를 포함하여 정중하고 세련된 한국어로 답변해주세요.';
    } else if (languageCode == 'ja') {
      langGuideline = '回答言語: オカムラゴルフの精神に則り、丁寧で上質な日本語でお答えください。';
    }

    return '''
Bạn là Okamura AI Caddie — Trợ lý ảo & Chuyên gia đồng hành độc quyền của tổ hợp Golf 3D trong nhà cao cấp OKAMURA GOLFZON LOUNGE.
Bạn đang trò chuyện với: $userLabel (Vai trò: $roleLabel). $bayInfo
$langGuideline

PHONG CÁCH GIAO TIẾP:
- Lịch thiệp, tinh tế, niềm nở, chuẩn mực hiếu khách Omotenashi (Nhật Bản) kết hợp phong thái sang trọng của môn thể thao Golf.
- Sử dụng ngôn ngữ chuẩn mực, xưng hô tôn trọng, gọi khách là "Quý khách" hoặc "Anh/Chị $userLabel".
- Trả lời súc tích, ngắn gọn, dùng gạch đầu dòng rõ ràng, tránh nói dông dài.

KIẾN THỨC VẬN HÀNH & DỊCH VỤ CỦA OKAMURA GOLFZON:
1. Hệ thống Bay chơi Golfzon TwoVision NX 3D (12 phòng):
   - VIP Suite: 550.000đ/giờ (Màn cong Panorama, sofa da Ý, quầy bar riêng, cảm biến TwoVision kép).
   - Standard 3D: 350.000đ/giờ (Cảm biến chuẩn quốc tế, phù hợp luyện tập & thi đấu 18 hố).
   - Dual Tee 2 chiều: 400.000đ/giờ (Tee phát bóng 2 chiều, phù hợp cả golfer tay trái và tay phải).
   - Connecting Suite: 750.000đ/giờ (Thông 2 phòng, phục vụ nhóm đông 6-10 người giao lưu).
   - GDR Driving Range AI: 250.000đ/giờ (Làn tập phân tích swing, góc cất bóng, tốc độ đầu gậy bằng AI).
   - PGA Coaching Studio: 600.000đ/giờ (Phòng phân tích swing chuyên sâu cùng HLV PGA).
2. Thời lượng chơi khuyến nghị:
   - 1 người chơi 18 hố: khoảng 1 giờ.
   - 2 người chơi 18 hố: khoảng 1.5 - 2 giờ.
   - Nhóm 3-4 người: khoảng 2.5 - 3 giờ.
3. Trang bị & Đồ dùng:
   - Miễn phí găng tay, giày golf cao cấp.
   - Cho thuê bộ gậy TaylorMade Qi10, Stealth 2 (cả tay phải và tay trái).
4. Menu Ẩm thực & Quầy Bar (phục vụ tận Bay):
   - Đồ uống: Bia Sapporo Tháp Vàng 2.5L (400.000đ), Bia Tiger Bạc (30.000đ/lon), Cà phê pha máy Arabica (45.000đ), Nước ép cam tươi (50.000đ).
   - Đồ ăn: Bò Sirloin Steak Úc nướng đá (295.000đ), Gà rán sốt cay Hàn Quốc (165.000đ), Khoai tây chiên sốt nấm Truffle (85.000đ).
5. Chính sách đặt phòng:
   - Khách có thể đặt online giữ chỗ, thanh toán qua chuyển khoản VietQR tự động hoặc thanh toán tại quầy.
   - Khách vãng lai có thể đặt mà không cần tạo tài khoản (nhập tên, SĐT và email nhận vé).
   - Hội viên tích lũy điểm thưởng VIP để nâng hạng Thẻ Vàng/Kim Cương.

Nếu câu trả lời liên quan đến việc đặt phòng, hãy khuyên khách bấm nút Đặt phòng.
Nếu câu hỏi về đồ uống/món ăn, khuyên khách xem Menu Dịch vụ.
''';
  }

  /// Gửi tin nhắn đến Gemini và nhận phản hồi
  Future<ChatMessageModel> sendMessage({
    required String prompt,
    String? currentUserName,
    String? userRole,
    int? availableRoomsCount,
    String languageCode = 'vi',
  }) async {
    final apiKey = await AiKeyVault.getApiKey();

    if (apiKey.isEmpty) {
      return _generateOfflineFallback(prompt);
    }

    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ]
    });

    final systemInstruction = _buildSystemInstruction(
      currentUserName: currentUserName,
      userRole: userRole,
      availableRoomsCount: availableRoomsCount,
      languageCode: languageCode,
    );

    String? responseText;

    // Thử lần lượt các model trong danh sách failover
    for (final model in _models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final payload = {
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'contents': _conversationHistory,
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        };

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final candidates = decoded['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              responseText = parts[0]['text'] as String?;
              if (responseText != null && responseText.trim().isNotEmpty) {
                // Lưu phản hồi của AI vào lịch sử
                _conversationHistory.add({
                  'role': 'model',
                  'parts': [
                    {'text': responseText}
                  ]
                });
                break;
              }
            }
          }
        } else {
          debugPrint('Gemini Model $model trả về mã lỗi: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Lỗi kết nối Gemini với model $model: $e');
      }
    }

    if (responseText != null && responseText.trim().isNotEmpty) {
      return _createMessageWithIntent(responseText.trim());
    }

    // Nếu các model đều bận hoặc mạng lỗi, sử dụng fallback thông minh
    return _generateOfflineFallback(prompt);
  }

  /// Phân tích nội dung phản hồi để gán CTA Action trực tiếp (Đặt phòng / Order món / Xem vé)
  ChatMessageModel _createMessageWithIntent(String text) {
    final lower = text.toLowerCase();
    String? actionRoute;
    String? actionLabel;
    final List<String> prompts = [];

    if (lower.contains('đặt phòng') || lower.contains('chọn phòng') || lower.contains('giá phòng') || lower.contains('vip suite')) {
      actionRoute = '/booking';
      actionLabel = 'Đặt Bay Chơi Ngay →';
      prompts.addAll(['Phòng VIP còn trống không?', 'Tư vấn gậy TaylorMade', 'Menu quầy Bar']);
    } else if (lower.contains('đồ uống') || lower.contains('bia') || lower.contains('món ăn') || lower.contains('menu') || lower.contains('f&b')) {
      actionRoute = '/services';
      actionLabel = 'Mở Menu Quầy Bar & Bếp →';
      prompts.addAll(['Tháp bia Sapporo giá bao nhiêu?', 'Đặt phòng chơi 2 tiếng', 'Cần Caddie hỗ trợ']);
    } else {
      prompts.addAll(['Bảng giá các loại Bay', 'Hôm nay còn phòng không?', 'Tư vấn set gậy TaylorMade']);
    }

    return ChatMessageModel(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      quickPrompts: prompts,
    );
  }

  /// Bộ câu trả lời offline thông minh khi mất mạng hoặc API gián đoạn
  ChatMessageModel _generateOfflineFallback(String prompt) {
    final p = prompt.toLowerCase();
    String reply = '';
    String? actionRoute;
    String? actionLabel;

    if (p.contains('giá') || p.contains('bảng giá') || p.contains('bao nhiêu')) {
      reply = '''Kính chào Quý khách! Bảng giá giờ chơi tại Okamura Golfzon Lounge:
• Standard 3D: 350.000đ/giờ
• Dual Tee 2 chiều: 400.000đ/giờ
• VIP TwoVision Suite: 550.000đ/giờ
• Connecting Suite (phòng đôi): 750.000đ/giờ
• GDR Driving Range AI: 250.000đ/giờ
Quý khách có thể đặt online nhận phòng ngay hôm nay!''';
      actionRoute = '/booking';
      actionLabel = 'Đặt phòng ngay →';
    } else if (p.contains('đặt phòng') || p.contains('bay') || p.contains('trống')) {
      reply = '''Hệ thống Okamura Golfzon có 12 Bay công nghệ cao TwoVision NX 3D sẵn sàng phục vụ. Quý khách có thể chọn ngày, giờ và thời lượng ca chơi trực tiếp trên ứng dụng.''';
      actionRoute = '/booking';
      actionLabel = 'Xem phòng & Đặt ngay →';
    } else if (p.contains('menu') || p.contains('ăn') || p.contains('uống') || p.contains('bia')) {
      reply = '''Okamura Lounge hân hạnh phục vụ tận Bay:
• Tháp bia Sapporo Vàng 2.5L: 400.000đ
• Bia Tiger Bạc 330ml: 30.000đ
• Cà phê Arabica / Nước ép hoa quả: 45.000đ - 50.000đ
• Bò Bít tết Úc nướng đá & Khoai tây chiên sốt Truffle cao cấp.''';
      actionRoute = '/services';
      actionLabel = 'Xem menu chi tiết →';
    } else {
      reply = '''Dạ, Okamura AI Caddie luôn sẵn sàng hỗ trợ Quý khách về:
• Tư vấn & chọn Bay chơi Golfzon 3D phù hợp
• Bảng giá ca chơi & thời lượng 18 hố
• Cho thuê set gậy TaylorMade Qi10 cao cấp
• Menu ẩm thực & quầy Bar tận phòng.
Quý khách cần hỗ trợ thêm thông tin gì ạ?''';
      actionRoute = '/booking';
      actionLabel = 'Đặt phòng ngay →';
    }

    return ChatMessageModel(
      id: 'ai_fallback_${DateTime.now().microsecondsSinceEpoch}',
      isUser: false,
      text: reply,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      quickPrompts: ['Bảng giá các phòng', 'Xem menu đồ uống', 'Đặt phòng VIP'],
    );
  }
}
