import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_bottom_sheet.dart';

/// Nút nổi (Floating Action Button) hình tròn biểu tượng chữ "C" kích hoạt Trợ lý ảo AI Caddie
/// Hỗ trợ KÉO THẢ TỰ DO (Draggable) đến mọi vị trí trên màn hình, không che khuất nội dung
class AiFloatingButton extends StatefulWidget {
  final double bottomOffset;
  final double rightOffset;

  const AiFloatingButton({
    super.key,
    this.bottomOffset = 14,
    this.rightOffset = 16,
  });

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton> {
  Offset? _position;
  bool _isDragging = false;
  bool _hasMoved = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    // Khởi tạo vị trí mặc định ở góc dưới bên phải (ngay trên thanh bottom navigation)
    final defaultX = screenSize.width - 50 - widget.rightOffset;
    final defaultY = screenSize.height - 70 - safePadding.bottom - 50 - widget.bottomOffset;

    final currentPos = _position ?? Offset(defaultX, defaultY);

    // Đảm bảo nút luôn nằm trong phạm vi hiển thị an toàn
    final minX = 10.0;
    final maxX = (screenSize.width - 50 - 10.0).clamp(minX, screenSize.width);
    final minY = safePadding.top + 10.0;
    final maxY = (screenSize.height - safePadding.bottom - 50 - 10.0).clamp(minY, screenSize.height);

    final safeX = currentPos.dx.clamp(minX, maxX);
    final safeY = currentPos.dy.clamp(minY, maxY);

    return Positioned(
      left: safeX,
      top: safeY,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
            _hasMoved = false;
          });
        },
        onPanUpdate: (details) {
          if (details.delta.distance > 0.6) {
            _hasMoved = true;
          }
          setState(() {
            final nextX = (currentPos.dx + details.delta.dx).clamp(minX, maxX);
            final nextY = (currentPos.dy + details.delta.dy).clamp(minY, maxY);
            _position = Offset(nextX, nextY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: () {
          if (!_hasMoved) {
            AiChatBottomSheet.show(context);
          }
        },
        child: Tooltip(
          message: 'AI Caddie - Chạm để chat, giữ để kéo thả',
          child: AnimatedScale(
            scale: _isDragging ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF242A38),
                      Color(0xFF111723),
                      Color(0xFF090D15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _isDragging ? const Color(0xFFFFDF7A) : AppColors.primaryGold,
                    width: _isDragging ? 2.2 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(
                        alpha: _isDragging ? 0.65 : 0.38,
                      ),
                      blurRadius: _isDragging ? 22 : 14,
                      offset: Offset(0, _isDragging ? 6 : 4),
                      spreadRadius: _isDragging ? 2 : 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng hào quang vàng nhẹ bên trong
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryGold.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Biểu tượng chữ "C" đại diện cho Caddie / Concierge
                    const Text(
                      'C',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'serif',
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Color(0xFFD4AF37),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),

                    // Ngôi sao lấp lánh AI ở góc trên bên phải chữ "C"
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF090D15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFDF7A),
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
