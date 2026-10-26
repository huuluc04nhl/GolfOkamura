import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/chat_message_model.dart';
import '../../../shared/models/golfer_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/services/gemini_ai_service.dart';

/// Màn hình Trung tâm Trợ lý AI Caddie Chuyên Sâu (Dedicated AI Concierge Screen)
/// Cung cấp giao diện hỗ trợ toàn diện thay thế chatbox popup ngắn:
/// - Phân tích & tư vấn chọn phòng chuẩn công nghệ TwoVision NX theo trình độ Golfer
/// - Tra cứu thực đơn F&B tận phòng, bảng giá khung giờ vàng
/// - Hội thoại tương tác sâu với Gemini AI và gắn nút hành động trực tiếp
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
    {'id': 'rooms', 'label': 'Tư vấn phòng Bay'},
    {'id': 'pricing', 'label': 'Bảng giá & Giờ vàng'},
    {'id': 'fnb', 'label': 'Thực đơn F&B'},
    {'id': 'membership', 'label': 'Hạng hội viên'},
  ];

  final List<String> _quickPrompts = [
    'Tư vấn chọn phòng VIP TwoVision NX phù hợp nhóm 4 người',
    'Bảng giá thuê phòng hôm nay và các khung giờ ưu đãi',
    'Combo bia Sapporo tháp và món ăn nhẹ phục vụ tận phòng',
    'Đặc quyền hạng hội viên Diamond và cách tích điểm',
    'Hướng dẫn đặt phòng vãng lai và quy trình check-in tại quầy',
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
        text: 'Xin chào Quý khách! Tôi là AI Caddie - Trợ lý ảo Golfzon 24/7 của tổ hợp Okamura.\n\n'
            'Tôi có thể giúp Quý khách:\n'
            '• Phân tích & gợi ý phòng tập theo trình độ Handicap\n'
            '• Tra cứu bảng giá, khung giờ vàng & chương trình ưu đãi\n'
            '• Đặt dịch vụ ăn uống F&B phục vụ tận phòng\n'
            '• Hướng dẫn đặt phòng nhanh chóng\n\n'
            'Quý khách cần tôi hỗ trợ điều gì hôm nay?',
        isUser: false,
        timestamp: DateTime.now(),
        quickPrompts: [
          'Gợi ý phòng VIP hôm nay',
          'Bảng giá thuê Bay',
          'Menu đồ uống F&B',
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
              text: 'Rất tiếc, kết nối trợ lý AI tạm thời bị gián đoạn. Quý khách vui lòng thử lại hoặc liên hệ hotline để được phục vụ ngay.',
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
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Thẻ trạng thái hội viên & AI Concierge Status
            _buildGolferAiHeader(golfer.name, golfer.tier.label),

            // Thanh phân loại chủ đề hỗ trợ nhanh (Pill categories)
            _buildCategoryFilter(),

            // Danh sách tin nhắn hội thoại toàn màn hình
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

            // Thanh nhập câu hỏi AI Caddie
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
                'AI CADDIE CHUYÊN SÂU',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Golfzon Super Concierge 24/7',
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
          tooltip: 'Làm mới cuộc trò chuyện',
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

  /// Thẻ trạng thái thông tin người dùng và lời chào AI
  Widget _buildGolferAiHeader(String name, String tier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassBg.withValues(alpha: 0.8),
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
                  'Hỗ trợ đặt Bay TwoVision NX, menu đồ ăn & ưu đãi cá nhân',
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
                  'Online',
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
        _sendMessage('Tư vấn cho tôi các loại phòng Bay TwoVision NX và phòng VIP');
        break;
      case 'pricing':
        _sendMessage('Bảng giá thuê phòng hôm nay và các khung giờ ưu đãi là gì?');
        break;
      case 'fnb':
        _sendMessage('Thực đơn F&B đồ ăn và đồ uống phục vụ tận phòng gồm những gì?');
        break;
      case 'membership':
        _sendMessage('Quyền lợi và điều kiện nâng hạng hội viên Golfzon Okamura');
        break;
    }
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGold
                    : AppColors.glassBg.withValues(alpha: 0.92),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? const Color(0xFF1A1A1A) : AppColors.textLight,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (message.actionRoute != null && message.actionLabel != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.go(message.actionRoute!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                            Text(
                              message.actionLabel!,
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E293B),
              ),
              child: const Icon(Icons.person, color: AppColors.primaryGold, size: 18),
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
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141C2B),
              border: Border.all(color: AppColors.primaryGold, width: 1.2),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(color: AppColors.primaryGold, fontSize: 15, fontWeight: FontWeight.w900),
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
                  'AI Caddie đang suy nghĩ...',
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Hỏi AI Caddie về phòng Bay, F&B, ưu đãi...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
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
