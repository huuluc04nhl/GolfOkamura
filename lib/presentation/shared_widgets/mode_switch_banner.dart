import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Nút chuyển đổi chế độ xem nổi (Floating Pill) tinh tế, không làm vỡ giao diện Mobile của User
typedef ModeSwitchBanner = ModeSwitchFloatingButton;

class ModeSwitchFloatingButton extends StatelessWidget {
  final bool isAdminMode;

  const ModeSwitchFloatingButton({super.key, required this.isAdminMode});

  @override
  Widget build(BuildContext context) {
    // Với Admin Web: hiển thị thanh gọn trên cùng
    if (isAdminMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.adminSidebar,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'WEB ADMIN MODE',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                try {
                  context.go('/');
                } catch (_) {}
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.phone_iphone, size: 14, color: Colors.black),
                    SizedBox(width: 6),
                    Text(
                      'Xem App Khách (User)',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Với User Mobile: nút nổi tinh tế ở góc phải trên cùng hoặc trong header
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              context.go('/admin');
            } catch (_) {}
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.admin_panel_settings_outlined, size: 13, color: AppColors.primaryGold),
                SizedBox(width: 5),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
