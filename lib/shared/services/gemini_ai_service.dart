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

    String langGuideline = 'NGÔN NGỮ PHẢN HỒI: Tiếng Việt chuẩn mực, thân thiện, lịch thiệp.';
    if (languageCode == 'en') {
      langGuideline = 'RESPONSE LANGUAGE: Always respond in natural, friendly, professional English.';
    } else if (languageCode == 'ko') {
      langGuideline = '응답 언어: 골프존 전문 용어를 포함하여 친절하고 세련된 한국어로 답변해주세요.';
    } else if (languageCode == 'ja') {
      langGuideline = '回答言語: オカムラゴルフの精神に則り、親切で上質な日本語でお答えください。';
    }

    return '''
Bạn là AI Caddie — Trợ lý ảo & Chuyên gia đồng hành độc quyền của tổ hợp Golf 3D trong nhà cao cấp OKAMURA GOLFZON LOUNGE (Thuận An, Bình Dương).
Bạn đang trò chuyện với: $userLabel (Vai trò: $roleLabel). $bayInfo
$langGuideline

PHONG CÁCH GIAO TIẾP (THÂN THIỆN, NIỀM NỞ & TINH TẾ CHUẨN OMOTENASHI):
- Luôn giữ thái độ thân thiện, ấm áp, tận tình, xưng hô "Em" hoặc "Okamura AI", gọi khách là "Quý khách" hoặc "Anh/Chị $userLabel".
- Lắng nghe chu đáo, giải đáp rõ ràng, dễ hiểu, dùng các gạch đầu dòng trực quan, tránh câu chữ dài dòng hoặc máy móc.
- Chủ động đề xuất giải pháp tốt nhất để phục vụ khách hàng chu đáo nhất.

KIẾN THỨC VẬN HÀNH & DỊCH VỤ CỦA OKAMURA GOLFZON:
1. Hệ thống Bay chơi Golfzon TwoVision NX 3D (12 phòng):
   - VIP TwoVision Suite: 550.000đ/giờ (Màn cong Panorama, sofa da Ý, quầy bar riêng, cảm biến phân tích cú đánh 3D kép).
   - Standard 3D: 350.000đ/giờ (Cảm biến chuẩn quốc tế, phù hợp luyện tập & thi đấu 18 hố).
   - Dual Tee 2 chiều: 400.000đ/giờ (Tee phát bóng 2 chiều, phù hợp cả golfer tay trái và tay phải).
   - Connecting Suite: 750.000đ/giờ (Thông 2 phòng, phục vụ nhóm 6-10 golfer giao lưu tiệc rượu).
   - GDR Driving Range AI: 250.000đ/giờ (Làn tập phân tích swing, góc cất bóng, tốc độ đầu gậy AI).
   - PGA Coaching Studio: 600.000đ/giờ (Phòng phân tích swing chuyên sâu cùng HLV PGA).
2. Thời lượng chơi khuyến nghị:
   - 1 golfer chơi 18 hố: khoảng 1 giờ.
   - 2 golfer chơi 18 hố: khoảng 1.5 - 2 giờ.
   - Nhóm 3-4 golfer: khoảng 2.5 - 3 giờ.
3. Trang bị & Đồ dùng:
   - Miễn phí găng tay, giày golf cao cấp.
   - Cho thuê bộ gậy TaylorMade Qi10, Stealth 2 (cả tay phải và tay trái).
4. Thực đơn Lounge & Quầy Bar (phục vụ tận Bay):
   - Đồ uống: Bia Sapporo Tháp Vàng 2.5L (400.000đ), Bia Tiger Bạc (30.000đ/lon), Cà phê pha máy Arabica (45.000đ), Nước ép hoa quả tươi (50.000đ).
   - Đồ ăn: Bò Sirloin Steak Úc nướng đá (295.000đ), Gà rán sốt cay Hàn Quốc (165.000đ), Khoai tây chiên sốt nấm Truffle (85.000đ).
5. Chính sách đặt phòng & Vé:
   - Khách có thể đặt online giữ chỗ, thanh toán qua chuyển khoản VietQR tự động hoặc thanh toán tại quầy.
   - Khách vãng lai có thể đặt mà không cần tạo tài khoản.
   - Khách có thể đổi ngày giờ chơi, xem mã PIN mở phòng tại mục "Vé của tôi".

QUY TẮC TỰ ĐỘNG THAO TÁC HỆ THỐNG (ACTION AUTO-DISPATCH):
Nếu nội dung câu hỏi/câu trả lời liên quan đến việc đặt phòng, mở menu gọi món, xem vé, gọi phục vụ hoặc về trang chủ, bạn PHẢI chèn thẻ điều hướng hành động tương ứng ở cuối câu trả lời:
- [ACTION:BOOKING] nếu khách muốn đặt phòng, kiểm tra phòng trống, chọn Bay, hỏi giá phòng.
- [ACTION:SERVICES] nếu khách muốn xem menu, gọi đồ ăn, bia tháp, nước uống, thuê gậy, caddie.
- [ACTION:MY_BOOKINGS] nếu khách muốn xem vé, đổi giờ chơi, hủy vé, tra cứu mã PIN mở phòng.
- [ACTION:CALL_WAITER] nếu khách muốn gọi nhân viên, gọi phục vụ, xin thêm khăn lạnh, thêm đá, chỉnh nhiệt độ điều hòa, báo lỗi cảm biến, thêm bóng.
- [ACTION:HOME] nếu khách muốn về trang chủ hoặc xem tổng quan tổ hợp.

QUY TẮC TỰ ĐỘNG GỢI Ý CÂU HỎI TIẾP THEO (DYNAMIC FOLLOW-UP SUGGESTIONS):
Ở dòng cuối cùng của câu trả lời, bạn BẮT BUỘC chèn thẻ gợi ý 3 câu hỏi tiếp theo bám sát theo ngữ cảnh câu hỏi của khách và câu trả lời của bạn theo cú pháp:
[SUGGESTIONS: Gợi ý 1 | Gợi ý 2 | Gợi ý 3]
Ví dụ:
[SUGGESTIONS: Đặt phòng VIP ngay | Bảng giá các loại Bay | Menu đồ uống quầy Bar]
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
      return _createMessageWithIntent(responseText.trim(), prompt);
    }

    // Nếu các model đều bận hoặc mạng lỗi, sử dụng fallback thông minh
    return _generateOfflineFallback(prompt);
  }

  /// Phân tích nội dung phản hồi để gán CTA Action trực tiếp (Đặt phòng / Order món / Xem vé / Gọi phục vụ)
  /// và bóc tách các gợi ý câu hỏi tiếp theo dựa trên câu hỏi + câu trả lời
  ChatMessageModel _createMessageWithIntent(String text, String userPrompt) {
    String cleanText = text;
    String? actionRoute;
    String? actionLabel;
    String? serviceRequestTitle;
    List<String> dynamicSuggestions = [];

    // 1. Phân tích thẻ gợi ý động [SUGGESTIONS: ...] do AI sinh ra
    final suggestionsRegex = RegExp(r'\[SUGGESTIONS:\s*(.*?)\]', caseSensitive: false);
    final suggestionsMatch = suggestionsRegex.firstMatch(cleanText);
    if (suggestionsMatch != null) {
      final rawSuggestions = suggestionsMatch.group(1) ?? '';
      final parts = rawSuggestions
          .split('|')
          .map((s) => s.trim().replaceAll(RegExp(r'^[^\w\s\u00C0-\u1EF9]+'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        dynamicSuggestions = parts;
      }
      cleanText = cleanText.replaceAll(suggestionsRegex, '').trim();
    }

    // 2. Phân tích thẻ hành động trực tiếp [ACTION:...] do AI sinh ra
    final actionRegex = RegExp(r'\[ACTION:\s*(BOOKING|SERVICES|MY_BOOKINGS|CALL_WAITER|HOME)\]', caseSensitive: false);
    final actionMatch = actionRegex.firstMatch(cleanText);
    if (actionMatch != null) {
      final actionType = actionMatch.group(1)?.toUpperCase();
      cleanText = cleanText.replaceAll(actionRegex, '').trim();
      switch (actionType) {
        case 'BOOKING':
          actionRoute = '/booking';
          actionLabel = 'Đặt phòng chơi ngay →';
          break;
        case 'SERVICES':
          actionRoute = '/services';
          actionLabel = 'Mở Thực Đơn Quầy Bar & Bếp →';
          break;
        case 'MY_BOOKINGS':
          actionRoute = '/my-bookings';
          actionLabel = 'Xem Vé & Lịch Đặt Của Bạn →';
          break;
        case 'CALL_WAITER':
          serviceRequestTitle = 'Nhân viên hỗ trợ tận phòng';
          break;
        case 'HOME':
          actionRoute = '/';
          actionLabel = 'Về trang chủ →';
          break;
      }
    }

    // 3. Phân tích ý định tự động nếu khách muốn gọi phục vụ / nhân viên / khăn lạnh / đá / cảm biến
    final lowerCombined = '$userPrompt $cleanText'.toLowerCase();
    if (serviceRequestTitle == null) {
      if (lowerCombined.contains('gọi phục vụ') ||
          lowerCombined.contains('gọi nhân viên') ||
          lowerCombined.contains('hỗ trợ tận bay') ||
          lowerCombined.contains('khăn lạnh') ||
          lowerCombined.contains('thêm đá') ||
          lowerCombined.contains('nước đá') ||
          lowerCombined.contains('chỉnh điều hòa') ||
          lowerCombined.contains('chỉnh nhiệt độ') ||
          lowerCombined.contains('thêm khay bóng') ||
          lowerCombined.contains('lỗi cảm biến') ||
          lowerCombined.contains('chỉnh cảm biến')) {
        if (lowerCombined.contains('khăn lạnh')) {
          serviceRequestTitle = 'Yêu cầu mang thêm Khăn Lạnh';
        } else if (lowerCombined.contains('đá') || lowerCombined.contains('nước đá')) {
          serviceRequestTitle = 'Yêu cầu thêm Xô Đá & Ly';
        } else if (lowerCombined.contains('nhiệt độ') || lowerCombined.contains('điều hòa')) {
          serviceRequestTitle = 'Yêu cầu chỉnh nhiệt độ điều hòa phòng';
        } else if (lowerCombined.contains('cảm biến') || lowerCombined.contains('bóng')) {
          serviceRequestTitle = 'Yêu cầu hỗ trợ kỹ thuật cảm biến & khay bóng';
        } else {
          serviceRequestTitle = 'Yêu cầu nhân viên đến hỗ trợ tận phòng';
        }
      }
    }

    // 4. Fallback phân tích ý định điều hướng dựa trên từ khóa nếu chưa có actionRoute
    if (actionRoute == null && serviceRequestTitle == null) {
      if (lowerCombined.contains('đặt phòng') ||
          lowerCombined.contains('chọn phòng') ||
          lowerCombined.contains('giá phòng') ||
          lowerCombined.contains('phòng trống') ||
          lowerCombined.contains('bảng giá') ||
          lowerCombined.contains('vip suite') ||
          lowerCombined.contains('bay ')) {
        actionRoute = '/booking';
        actionLabel = 'Đặt phòng chơi ngay →';
      } else if (lowerCombined.contains('đồ uống') ||
          lowerCombined.contains('tháp bia') ||
          lowerCombined.contains('bia') ||
          lowerCombined.contains('món ăn') ||
          lowerCombined.contains('menu') ||
          lowerCombined.contains('f&b') ||
          lowerCombined.contains('thuê gậy') ||
          lowerCombined.contains('caddie')) {
        actionRoute = '/services';
        actionLabel = 'Mở Thực Đơn Quầy Bar & Bếp →';
      } else if (lowerCombined.contains('vé của tôi') ||
          lowerCombined.contains('lịch đặt') ||
          lowerCombined.contains('mã pin') ||
          lowerCombined.contains('đổi giờ') ||
          lowerCombined.contains('hủy phòng')) {
        actionRoute = '/my-bookings';
        actionLabel = 'Xem Vé & Lịch Đặt Của Bạn →';
      }
    }

    // 5. Nếu AI chưa sinh gợi ý động, tự sinh gợi ý theo ngữ cảnh câu hỏi + câu trả lời
    if (dynamicSuggestions.isEmpty) {
      if (serviceRequestTitle != null) {
        dynamicSuggestions = [
          'Thực đơn bia tháp & ẩm thực tận Bay',
          'Tư vấn luật chơi 18 hố Golfzon',
          'Kiểm tra vé & lịch đặt của tôi',
        ];
      } else if (lowerCombined.contains('đặt phòng') || lowerCombined.contains('giá') || lowerCombined.contains('bay')) {
        dynamicSuggestions = [
          'Tư vấn phòng VIP TwoVision',
          'Chơi 18 hố mất mấy tiếng?',
          'Xem thực đơn bia & đồ ăn nhẹ',
        ];
      } else if (lowerCombined.contains('menu') || lowerCombined.contains('bia') || lowerCombined.contains('ăn')) {
        dynamicSuggestions = [
          'Tháp bia Sapporo giá bao nhiêu?',
          'Đặt phòng chơi 2 tiếng',
          'Có cho thuê set gậy không?',
        ];
      } else if (lowerCombined.contains('vé') || lowerCombined.contains('lịch') || lowerCombined.contains('mã pin')) {
        dynamicSuggestions = [
          'Cách nhận mã PIN mở Bay',
          'Hướng dẫn đổi giờ chơi',
          'Đặt thêm 1 Bay mới',
        ];
      } else {
        dynamicSuggestions = [
          'Bảng giá các loại Bay hôm nay',
          'Tư vấn chọn Bay cho 2 người',
          'Thực đơn đồ uống quầy Bar',
        ];
      }
    }

    return ChatMessageModel(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
      isUser: false,
      text: cleanText,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      serviceRequestTitle: serviceRequestTitle,
      autoExecuteCountdown: (actionRoute != null || serviceRequestTitle != null) ? 2 : null,
      quickPrompts: dynamicSuggestions,
    );
  }

  /// Bộ câu trả lời offline thông minh khi mất mạng hoặc API gián đoạn
  ChatMessageModel _generateOfflineFallback(String prompt) {
    final p = prompt.toLowerCase();
    String reply = '';
    String? actionRoute;
    String? actionLabel;
    String? serviceRequestTitle;
    List<String> dynamicSuggestions = [];

    if (p.contains('phục vụ') || p.contains('nhân viên') || p.contains('khăn lạnh') || p.contains('đá') || p.contains('cảm biến')) {
      if (p.contains('khăn lạnh')) {
        serviceRequestTitle = 'Yêu cầu mang thêm Khăn Lạnh';
      } else if (p.contains('đá')) {
        serviceRequestTitle = 'Yêu cầu thêm Xô Đá & Ly';
      } else if (p.contains('cảm biến')) {
        serviceRequestTitle = 'Yêu cầu hỗ trợ kỹ thuật cảm biến Bay';
      } else {
        serviceRequestTitle = 'Yêu cầu nhân viên đến hỗ trợ tận phòng';
      }
      reply = 'Dạ em đã tự động kích hoạt chuyển yêu cầu **$serviceRequestTitle** đến Quầy Lễ Tân & Bếp ngay lập tức! Nhân viên sẽ có mặt hỗ trợ Quý khách trong tích tắc.';
      dynamicSuggestions = [
        'Gọi tháp bia Sapporo ướp lạnh',
        'Kiểm tra vé & lịch đặt của tôi',
        'Tư vấn chế độ chơi TwoVision',
      ];
    } else if (p.contains('giá') || p.contains('bảng giá') || p.contains('bao nhiêu')) {
      reply = '''Dạ, em xin gửi Quý khách bảng giá thuê phòng chơi golf 3D hôm nay:

• Phòng tiêu chuẩn 3D: 350.000đ/giờ (chơi 18 hố như ngoài sân thật)
• Phòng chơi 2 chiều: 400.000đ/giờ (thoải mái cho cả người thuận tay trái)
• Phòng VIP màn hình lớn: 550.000đ/giờ (màn cong sắc nét, ghế sofa êm ái)
• Phòng tiệc đôi: 750.000đ/giờ (thông 2 phòng cho nhóm bạn 6-10 người)
• Làn tập riêng: 250.000đ/giờ (chuyên tập đánh xa và chỉnh tư thế)

Em đang mở trang Đặt phòng để Quý khách xem khung giờ và giữ chỗ ngay nhé ạ!''';
      actionRoute = '/booking';
      actionLabel = 'Đặt phòng chơi ngay →';
      dynamicSuggestions = [
        'Đặt phòng VIP màn hình lớn',
        'Chơi 18 hố mất mấy tiếng?',
        'Xem menu đồ uống mang tận phòng',
      ];
    } else if (p.contains('đặt phòng') || p.contains('bay') || p.contains('trống') || p.contains('chọn phòng')) {
      reply = '''Dạ hiện quán có sẵn các phòng chơi golf 3D màn hình lớn với đầy đủ trang thiết bị gậy, bóng và giày tập miễn phí. Em đang mở trang Đặt phòng để Quý khách chọn giờ chơi ưng ý nhé ạ!''';
      actionRoute = '/booking';
      actionLabel = 'Đặt phòng chơi ngay →';
      dynamicSuggestions = [
        'Bảng giá các loại phòng',
        'Có sẵn gậy tập không?',
        'Menu đồ ăn và bia tươi',
      ];
    } else if (p.contains('menu') || p.contains('ăn') || p.contains('uống') || p.contains('bia') || p.contains('bar')) {
      reply = '''Dạ quán có phục vụ đồ ăn và nước uống mang tận phòng chơi cho Quý khách:

• Tháp bia Sapporo tươi 2.5L mát lạnh: 400.000đ
• Bia lon Tiger Bạc ướp lạnh: 30.000đ
• Cà phê pha máy thơm ngon: 45.000đ
• Bò Bít tết nướng đá & Gà rán giòn sốt cay.

Em đang mở Thực đơn để Quý khách chọn món nhé ạ!''';
      actionRoute = '/services';
      actionLabel = 'Mở Thực Đơn Quầy Bar & Bếp →';
      dynamicSuggestions = [
        'Tháp bia có sẵn không?',
        'Đặt phòng chơi 2 tiếng',
        'Có gậy tập cho mượn không?',
      ];
    } else if (p.contains('vé') || p.contains('lịch') || p.contains('mã pin') || p.contains('hủy') || p.contains('đổi')) {
      reply = '''Dạ em đang mở mục xem lịch đặt phòng để Quý khách kiểm tra mã mở phòng hoặc đổi sang giờ chơi khác trực tiếp ạ.''';
      actionRoute = '/my-bookings';
      actionLabel = 'Xem Vé & Lịch Đặt Của Bạn →';
      dynamicSuggestions = [
        'Hướng dẫn đổi giờ chơi',
        'Cách nhận phòng khi đến quán',
        'Đặt thêm phòng mới',
      ];
    } else {
      reply = '''Dạ em là Trợ lý ảo của Okamura — luôn sẵn sàng hỗ trợ Quý khách 24/7!

Em có thể giúp Quý khách:
• Gợi ý phòng chơi 3D phù hợp với bạn
• Báo giá thuê phòng & thời gian chơi
• Cho mượn gậy tập, giày tập miễn phí
• Gọi nhân viên mang thêm đá, khăn lạnh tận phòng
• Mở thực đơn đồ ăn & nước uống mang tận nơi.

Quý khách muốn em hỗ trợ điều gì trước ạ?''';
      actionRoute = '/booking';
      actionLabel = 'Đặt phòng chơi ngay →';
      dynamicSuggestions = [
        'Bảng giá thuê phòng hôm nay',
        'Tư vấn chọn phòng VIP',
        'Xem menu đồ uống mang tận phòng',
      ];
    }

    return ChatMessageModel(
      id: 'ai_fallback_${DateTime.now().microsecondsSinceEpoch}',
      isUser: false,
      text: reply,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      serviceRequestTitle: serviceRequestTitle,
      autoExecuteCountdown: (actionRoute != null || serviceRequestTitle != null) ? 2 : null,
      quickPrompts: dynamicSuggestions,
    );
  }
}
