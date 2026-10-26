import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_bottom_sheet.dart';

/// Nút nổi (Floating Action Button) hình tròn biểu tượng chữ "C" kích hoạt Trợ lý ảo AI Caddie
/// Thiết kế siêu gọn (50x50dp), chuẩn Quiet Luxury, nép sát mép trên thanh bottom navigation
class AiFloatingButton extends StatelessWidget {
  final double bottomOffset;
  final double rightOffset;

  const AiFloatingButton({
    super.key,
    this.bottomOffset = 14,
    this.rightOffset = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomOffset,
      right: rightOffset,
      child: Tooltip(
        message: 'AI Caddie - Trợ lý thông minh',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => AiChatBottomSheet.show(context),
            borderRadius: BorderRadius.circular(28),
            splashColor: AppColors.primaryGold.withValues(alpha: 0.3),
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
                  color: AppColors.primaryGold,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
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
    );
  }
}
