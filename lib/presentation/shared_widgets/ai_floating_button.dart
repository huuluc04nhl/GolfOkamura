import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_bottom_sheet.dart';

/// Nút nổi (Floating Action Button) kích hoạt Trợ lý ảo AI Caddie
class AiFloatingButton extends StatelessWidget {
  final double bottomOffset;
  final double rightOffset;

  const AiFloatingButton({
    super.key,
    this.bottomOffset = 84,
    this.rightOffset = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomOffset,
      right: rightOffset,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AiChatBottomSheet.show(context),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD4AF37),
                  AppColors.primaryGold,
                  Color(0xFF996515),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryGold,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI CADDIE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
