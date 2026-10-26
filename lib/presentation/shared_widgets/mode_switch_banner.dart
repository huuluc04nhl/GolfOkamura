import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/golfer_model.dart';
import '../../shared/providers/booking_provider.dart';
import 'ai_chat_bottom_sheet.dart';
import 'golfer_vip_card.dart';
import 'language_selector_pill.dart';

/// Nút chuyển đổi chế độ xem nổi (Floating Pill) tinh tế, phân quyền rõ ràng giữa Khách hàng và Admin
typedef ModeSwitchBanner = ModeSwitchFloatingButton;

class ModeSwitchFloatingButton extends StatelessWidget {
  final bool isAdminMode;

  const ModeSwitchFloatingButton({super.key, required this.isAdminMode});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

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
              onTap: () => AiChatBottomSheet.show(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryGold),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('ai_caddie'),
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
            const SizedBox(width: 10),
            const LanguageSelectorPill(),
            const SizedBox(width: 10),
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
                  children: [
                    const Icon(Icons.phone_iphone, size: 14, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('view_user_app'),
                      style: const TextStyle(
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

    // Với User Mobile: Cụm nút tài khoản tinh tế
    return buildUserAccountCluster(context, provider);
  }

  /// Cụm tài khoản chuẩn Mobile
  static Widget buildUserAccountCluster(BuildContext context, BookingProvider provider) {
    final isActualAdmin = provider.currentGolfer.isAdmin;
    final isGuest = provider.isGuest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Nếu là Khách vãng lai: Nút "Đăng nhập" sang trọng
        if (isGuest)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/login'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.lightGold, AppColors.primaryGold],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.login_rounded, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('auth_login'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        // 2. Nếu là Thành viên/Admin: Chip tài khoản VIP
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showAccountMenu(context, provider),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1A22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActualAdmin
                        ? AppColors.primaryGold
                        : provider.currentGolfer.tier.color.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActualAdmin ? Icons.shield_rounded : Icons.account_circle,
                      size: 14,
                      color: isActualAdmin
                          ? AppColors.primaryGold
                          : provider.currentGolfer.tier.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActualAdmin
                          ? 'ADMIN'
                          : provider.currentGolfer.name.split(' ').last,
                      style: TextStyle(
                        color: isActualAdmin ? AppColors.primaryGold : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Mở Menu Quản lý Tài khoản (Hội viên / Admin / Đăng xuất)
  static void showAccountMenu(BuildContext context, BookingProvider provider) {
    final isActualAdmin = provider.currentGolfer.isAdmin;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: provider.currentGolfer.tier.color.withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: provider.currentGolfer.tier.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.currentGolfer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${provider.currentGolfer.phone} • ${provider.currentGolfer.tier.label}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF1E293B)),

              // Dành riêng cho Quản trị viên
              if (isActualAdmin) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primaryGold,
                  ),
                  title: const Text(
                    'Chuyển sang trang Quản trị viên',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Điều hành Bay, thu ngân POS & lịch trình GSM',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.go('/admin/dashboard');
                  },
                ),
                const Divider(color: Color(0xFF1E293B)),
              ],

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_note_rounded, color: AppColors.primaryGold),
                title: const Text(
                  'Cập nhật thông tin cá nhân',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Họ tên, SĐT, Email và điểm Handicap',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  GolferVipCard.showEditGolferDialog(context, provider);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981)),
                title: const Text(
                  'Hotline Lễ Tân & Hỗ trợ 24/7',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  '0901 888 888 • 1900 9999 (Phục vụ 24/7)',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.userCardDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryGold),
                          SizedBox(width: 8),
                          Text('Hotline Okamura Golfzon', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      content: const Text(
                        'Tổng đài CSKH & Đặt phòng:\n• Hotline 1: 0901 888 888\n• Hotline 2: 1900 9999\n• Email: booking@okamuragolf.vn',
                        style: TextStyle(color: AppColors.textLight, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đóng', style: TextStyle(color: AppColors.primaryGold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await provider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
