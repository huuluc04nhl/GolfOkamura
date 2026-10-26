import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/chat_message_model.dart';
import '../../../shared/models/golfer_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/services/gemini_ai_service.dart';

/// Màn hình Trợ lý Ảo Hỗ Trợ Khách Hàng (Dedicated AI Concierge Screen)
/// Giao diện thân thiện, ấm áp, hoàn toàn không dùng thuật ngữ chuyên ngành khó hiểu
class UserAiAssistantScreen extends StatefulWidget {
  const UserAiAssistantScreen({super.key});

  @override
  State<UserAiAssistantScreen> createState() => _UserAiAssistantScreenState();
}

class _UserAiAssistantScreenState extends State<UserAiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiAiService _aiService = GeminiAiService();
  final List<ChatMessageModel> _messages = [];

  bool _isLoading = false;
  String _activeCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'rooms', 'label': 'Chọn phòng phù hợp'},
    {'id': 'pricing', 'label': 'Bảng giá & Giờ đẹp'},
    {'id': 'fnb', 'label': 'Đồ ăn & Nước uống'},
    {'id': 'membership', 'label': 'Ưu đãi thành viên'},
  ];

  final List<String> _quickPrompts = [
    'Phòng nào chơi thoải mái cho nhóm 4 người?',
    'Bảng giá thuê phòng hôm nay thế nào?',
    'Thực đơn đồ uống và đồ nhắm mang tận phòng',
    'Quyền lợi thành viên và cách tích điểm',
    'Lần đầu đến chơi thì đặt phòng thế nào?',
  ];

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    _messages.add(
      ChatMessageModel(
        id: 'welcome',
        text: 'Dạ xin chào Quý khách! Em là Trợ lý ảo của Okamura Golfzon.\n\n'
            'Em luôn sẵn sàng hỗ trợ Quý khách:\n'
            '• Gợi ý phòng chơi 3D phù hợp nhất (người mới tập hay đã chơi lâu)\n'
            '• Báo giá thuê phòng & các khung giờ đẹp trong ngày\n'
            '• Gọi đồ ăn, tháp bia & nước uống mang tận phòng\n'
            '• Hướng dẫn giữ chỗ và giải đáp mọi thắc mắc\n\n'
            'Quý khách đang cần em hỗ trợ điều gì hôm nay ạ?',
        isUser: false,
        timestamp: DateTime.now(),
        quickPrompts: [
          'Gợi ý phòng đẹp hôm nay',
          'Bảng giá thuê phòng',
          'Menu đồ ăn & nước uống',
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
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

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: 'user_${DateTime.now().microsecondsSinceEpoch}',
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    final provider = Provider.of<BookingProvider>(context, listen: false);
    final userName = provider.currentGolfer.name;
    final userRole = provider.currentGolfer.role;

    try {
      final reply = await _aiService.sendMessage(
        prompt: text,
        currentUserName: userName,
        userRole: userRole,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageModel(
              id: 'err_${DateTime.now().microsecondsSinceEpoch}',
              text: 'Dạ đường truyền tạm thời bị gián đoạn một chút. Quý khách vui lòng thử lại hoặc gọi hotline quán để được phục vụ ngay nhé ạ!',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final golfer = provider.currentGolfer;

    return Scaffold(
      backgroundColor: AppColors.userBgDark,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Thẻ người dùng và lời chào thân thiện
            _buildGolferAiHeader(golfer.name, golfer.tier.label),

            // Thanh chủ đề hỗ trợ nhanh
            _buildCategoryFilter(),

            // Danh sách tin nhắn hội thoại toàn màn hình
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildThinkingBubble();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Gợi ý câu hỏi nhanh (nếu tin nhắn cuối có quickPrompts)
            _buildQuickPromptsBar(),

            // Thanh nhập câu hỏi
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.userBgDark,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryGold, size: 20),
        tooltip: 'Quay lại',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6), width: 1.2),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 16),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TRỢ LÝ OKAMURA',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Luôn sẵn sàng hỗ trợ bạn 24/7',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 22),
          tooltip: 'Trò chuyện lại từ đầu',
          onPressed: () {
            setState(() {
              _messages.clear();
              _initWelcomeMessage();
            });
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.primaryGold.withValues(alpha: 0.18),
          height: 1,
        ),
      ),
    );
  }

  /// Thẻ trạng thái thông tin người dùng và lời chào
  Widget _buildGolferAiHeader(String name, String tier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2A364F), Color(0xFF141C2B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primaryGold, width: 1.2),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        tier,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tư vấn chọn phòng, đặt món ăn & nhận ưu đãi',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: Color(0xFF10B981), radius: 3),
                SizedBox(width: 5),
                Text(
                  'Sẵn sàng',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Danh mục chủ đề hỗ trợ nhanh
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _activeCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                cat['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textLight,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.glassBg,
              selectedColor: AppColors.primaryGold,
              checkmarkColor: Colors.black,
              side: BorderSide(
                color: isSelected ? AppColors.primaryGold : AppColors.glassBorder,
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              onSelected: (selected) {
                setState(() {
                  _activeCategory = cat['id']!;
                });
                _handleCategoryPrompt(cat['id']!);
              },
            ),
          );
        },
      ),
    );
  }

  void _handleCategoryPrompt(String categoryId) {
    switch (categoryId) {
      case 'rooms':
        _sendMessage('Tư vấn cho tôi các loại phòng chơi golf 3D và phòng VIP');
        break;
      case 'pricing':
        _sendMessage('Bảng giá thuê phòng hôm nay và các khung giờ giảm giá là gì?');
        break;
      case 'fnb':
        _sendMessage('Thực đơn đồ ăn và nước uống mang tận phòng gồm những gì?');
        break;
      case 'membership':
        _sendMessage('Xem quyền lợi hội viên và cách tích điểm');
        break;
    }
  }

  /// Định dạng text thông minh, loại bỏ dấu ** thô và làm nổi bật từ khóa
  Widget _buildFormattedText(String text, bool isUser) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 13.5,
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
              color: isBold ? AppColors.primaryGold : AppColors.textLight,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              fontSize: 13.5,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A364F), Color(0xFF0F1522)],
                ),
                border: Border.all(color: AppColors.primaryGold, width: 1.2),
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (screenWidth * 0.80).clamp(240.0, 520.0),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGold
                    : AppColors.glassBg.withValues(alpha: 0.94),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFFFFE599)
                      : AppColors.primaryGold.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(message.text, isUser),
                  if (message.actionRoute != null && message.actionLabel != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.go(message.actionRoute!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryGold, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_circle_right_rounded, color: AppColors.primaryGold, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                message.actionLabel!,
                                style: const TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E293B),
              ),
              child: const Icon(Icons.person, color: AppColors.primaryGold, size: 17),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141C2B),
              border: Border.all(color: AppColors.primaryGold, width: 1.2),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(color: AppColors.primaryGold, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Đang tìm câu trả lời cho bạn...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    final prompts = (lastMessage != null && !lastMessage.isUser && lastMessage.quickPrompts.isNotEmpty)
        ? lastMessage.quickPrompts
        : _quickPrompts.take(3).toList();

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _sendMessage(prompt),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFFDF7A), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      prompt,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.userBgDark,
        border: Border(
          top: BorderSide(
            color: AppColors.primaryGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Nhắn cho trợ lý (ví dụ: giá phòng, đồ uống)...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isLoading ? null : () => _sendMessage(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGold, Color(0xFFC79E58)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
