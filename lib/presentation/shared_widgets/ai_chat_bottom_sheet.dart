import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../shared/models/chat_message_model.dart';
import '../../shared/providers/booking_provider.dart';
import '../../shared/services/gemini_ai_service.dart';
import 'language_selector_pill.dart';

/// Hộp thoại Chatbot Trợ lý AI Caddie phong cách Quiet Luxury cho Okamura Golfzon
/// Hỗ trợ Auto-Execution: Tự động điều hướng và tự động gửi yêu cầu phục vụ thay cho khách hàng
class AiChatBottomSheet extends StatefulWidget {
  const AiChatBottomSheet({super.key});

  /// Hiển thị Chatbot dưới dạng BottomSheet hoặc Dialog tùy theo kích thước màn hình
  static Future<void> show(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const AiChatBottomSheet(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardHeight = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FractionallySizedBox(
                heightFactor: 0.90,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: const AiChatBottomSheet(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AiChatBottomSheet> createState() => _AiChatBottomSheetState();
}

class _AiChatBottomSheetState extends State<AiChatBottomSheet> {
  final GeminiAiService _aiService = GeminiAiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isAiTyping = false;

  // Quản lý cơ chế tự động thực thi thao tác (Auto-Execution)
  Timer? _autoActionTimer;
  int _autoActionCountdown = 0;
  String? _activeAutoRoute;
  String? _activeAutoActionLabel;

  final List<String> _initialSuggestions = [
    'Tư vấn phòng VIP TwoVision',
    'Bảng giá các loại Bay hôm nay',
    'Chơi 18 hố mất mấy tiếng?',
    'Thuê bộ gậy TaylorMade Qi10',
    'Thực đơn bia tháp & ẩm thực tận Bay',
    'Kiểm tra vé & lịch đặt của tôi',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageModel(
        id: 'welcome',
        isUser: false,
        text: 'Dạ kính chào Quý khách đến với **Okamura Golfzon Lounge**! Em là **AI Caddie** đồng hành riêng của mình hôm nay.\n\nEm luôn sẵn sàng hỗ trợ Quý khách:\n• Tư vấn & tự động mở trang đặt Bay TwoVision NX 3D phù hợp\n• Báo giá ca chơi & thời gian hoàn thành 18 hố\n• Tự động gửi yêu cầu gọi phục vụ, xin thêm đá, khăn lạnh tận Bay\n• Đặt món, gọi bia tháp & ẩm thực phục vụ tận phòng\n\nQuý khách chỉ cần trò chuyện, em sẽ tự động xử lý mọi thao tác cho mình ạ!',
        timestamp: DateTime.now(),
        quickPrompts: _initialSuggestions,
        actionRoute: '/booking',
        actionLabel: 'Chuyển Đến Đặt Phòng Ngay →',
      ),
    );
  }

  @override
  void dispose() {
    _autoActionTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Kích hoạt bộ đếm ngược tự động chuyển trang thay vì bắt khách tự bấm
  void _startAutoExecution(String route, String label) {
    _autoActionTimer?.cancel();
    setState(() {
      _autoActionCountdown = 2;
      _activeAutoRoute = route;
      _activeAutoActionLabel = label;
    });

    _autoActionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoActionCountdown > 1) {
        setState(() {
          _autoActionCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _autoActionCountdown = 0;
        });
        Navigator.pop(context);
        context.go(route);
      }
    });
  }

  void _cancelAutoExecution() {
    _autoActionTimer?.cancel();
    setState(() {
      _autoActionCountdown = 0;
      _activeAutoRoute = null;
      _activeAutoActionLabel = null;
    });
  }

  void _executeNow() {
    if (_activeAutoRoute == null) return;
    final target = _activeAutoRoute!;
    _autoActionTimer?.cancel();
    setState(() {
      _autoActionCountdown = 0;
      _activeAutoRoute = null;
    });
    Navigator.pop(context);
    context.go(target);
  }

  Future<void> _handleSendMessage([String? quickText]) async {
    final query = quickText ?? _textController.text.trim();
    if (query.isEmpty || _isAiTyping) return;

    if (quickText == null) {
      _textController.clear();
    }

    _cancelAutoExecution();

    final provider = context.read<BookingProvider>();
    final userName = provider.currentGolfer.name;
    final userRole = provider.currentGolfer.role;
    final availableRooms = provider.rooms.where((r) => !r.isUnderMaintenance).length;

    setState(() {
      _messages.add(
        ChatMessageModel(
          id: 'user_${DateTime.now().microsecondsSinceEpoch}',
          isUser: true,
          text: query,
          timestamp: DateTime.now(),
        ),
      );
      _isAiTyping = true;
    });

    _scrollToBottom();

    try {
      final langCode = Provider.of<AppLanguageProvider?>(context, listen: false)?.languageCode ?? 'vi';
      final aiReply = await _aiService.sendMessage(
        prompt: query,
        currentUserName: userName,
        userRole: userRole,
        availableRoomsCount: availableRooms,
        languageCode: langCode,
      );

      if (!mounted) return;

      // 1. Tự động thao tác gửi yêu cầu hỗ trợ tận phòng nếu khách có nhu cầu
      if (aiReply.serviceRequestTitle != null) {
        String targetRoom = provider.selectedServiceRoomName ?? '';
        if (targetRoom.isEmpty && provider.bookings.isNotEmpty) {
          targetRoom = provider.bookings.first.roomName;
        }
        if (targetRoom.isEmpty) {
          targetRoom = 'PHÒNG VIP 1';
        }
        await provider.submitQuickRoomRequest(
          roomName: targetRoom,
          requestTitle: aiReply.serviceRequestTitle!,
        );
      }

      setState(() {
        _messages.add(aiReply);
        _isAiTyping = false;
      });
      _scrollToBottom();

      // 2. Tự động kích hoạt chuyển trang nếu câu hỏi có ý định điều hướng
      if (aiReply.actionRoute != null) {
        _startAutoExecution(
          aiReply.actionRoute!,
          aiReply.actionLabel ?? 'Chuyển trang ngay',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
      });
    }
  }

  void _resetChatHistory() {
    _cancelAutoExecution();
    _aiService.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessageModel(
          id: 'reset',
          isUser: false,
          text: 'Dạ cuộc trò chuyện đã được làm mới. Em là AI Caddie, Quý khách cần em hỗ trợ gì thêm không ạ?',
          timestamp: DateTime.now(),
          quickPrompts: _initialSuggestions,
          actionRoute: '/booking',
          actionLabel: 'Chuyển Đến Đặt Phòng Ngay →',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final isGuest = provider.isGuest;
    final userName = provider.currentGolfer.name;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: AppColors.primaryGold, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 460;

                return Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGold, Color(0xFFD4AF37)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI CADDIE',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: isCompact ? 13.0 : 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'GEMINI 24/7',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (constraints.maxWidth >= 380) ...[
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    isGuest ? '• Khách' : '• $userName',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bộ chọn ngôn ngữ
                    const LanguageSelectorPill(),
                    const SizedBox(width: 4),

                    // Nút làm mới lịch sử hội thoại
                    IconButton(
                      icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textMuted, size: 18),
                      tooltip: 'Làm mới hội thoại',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: _resetChatHistory,
                    ),
                    const SizedBox(width: 4),

                    // Nút đóng
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                );
              },
            ),
          ),

          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isAiTyping) {
                  return _buildAiTypingIndicator();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Banner tự động thao tác (Auto-Execution Countdown Banner)
          if (_autoActionCountdown > 0 && _activeAutoRoute != null)
            _buildAutoExecutionBanner(),

          // Dàn câu hỏi gợi ý nhanh (Quick Prompts)
          if (!_isAiTyping) _buildQuickPromptsBar(),

          // Thanh nhập câu hỏi
          _buildInputBar(),
        ],
      ),
    );
  }

  /// Banner thông báo AI đang tự động thực thi thao tác cho khách
  Widget _buildAutoExecutionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withValues(alpha: 0.25),
            const Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeAutoActionLabel != null && _activeAutoActionLabel!.isNotEmpty
                  ? 'AI Caddie đang tự động mở: $_activeAutoActionLabel (${_autoActionCountdown}s)...'
                  : 'AI Caddie đang tự động mở trang (${_autoActionCountdown}s)...',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _executeNow,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Mở ngay',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _cancelAutoExecution,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Ở lại chat',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      if (parts[i].isNotEmpty) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              color: isBold ? AppColors.primaryGold : Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGold, Color(0xFFB69568)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.78,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryGold : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.25),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(message.text, isUser),
                      const SizedBox(height: 4),
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isUser ? Colors.black45 : AppColors.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Thẻ xác nhận thao tác tự động gửi yêu cầu phục vụ tận phòng
          if (!isUser && message.serviceRequestTitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '⚡ AI đã tự động gửi: ${message.serviceRequestTitle}',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Action Button CTA nếu có
          if (!isUser && message.actionRoute != null && message.actionLabel != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: InkWell(
                onTap: () {
                  _cancelAutoExecution();
                  Navigator.pop(context);
                  context.go(message.actionRoute!);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGold.withValues(alpha: 0.25),
                        AppColors.primaryGold.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGold),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.primaryGold, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.actionLabel!,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primaryGold,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    final prompts = (lastMessage != null && lastMessage.quickPrompts.isNotEmpty)
        ? lastMessage.quickPrompts
        : _initialSuggestions;

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = prompts[i];
          return ActionChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            label: Text(
              p,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
            side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onPressed: () => _handleSendMessage(p.replaceAll(RegExp(r'^[^\w\s]+'), '').trim()),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    // Tối ưu hóa padding đáy theo bàn phím ảo và tai thỏ thiết bị di động
    final extraBottomPadding = bottomInset > 0 ? 8.0 : (bottomSafeArea > 0 ? bottomSafeArea : 10.0);

    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, extraBottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 5, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('ai_ask_hint'),
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
                },
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isAiTyping ? null : () => _handleSendMessage(),
                borderRadius: BorderRadius.circular(22),
                splashColor: AppColors.primaryGold.withValues(alpha: 0.3),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: _isAiTyping
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFD4AF37), AppColors.primaryGold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _isAiTyping ? Colors.white12 : null,
                    shape: BoxShape.circle,
                    boxShadow: _isAiTyping
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: _isAiTyping ? AppColors.textMuted : Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
