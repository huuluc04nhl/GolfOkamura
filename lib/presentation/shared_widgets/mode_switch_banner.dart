import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/golfer_model.dart';
import '../../shared/providers/booking_provider.dart';
import 'golfer_vip_card.dart';

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

    // Với User Mobile: Cụm nút nổi tinh tế ở góc phải trên cùng
    final isActualAdmin = provider.currentGolfer.isAdmin;
    final isGuest = provider.isGuest;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Nếu là Khách vãng lai: Hiển thị duy nhất nút "Đăng nhập"
          if (isGuest)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/login'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.login_rounded, size: 14, color: Colors.black),
                      SizedBox(width: 5),
                      Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // 2. Nếu là Thành viên/Admin: Hiển thị chip tài khoản
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAccountMenu(context, provider),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActualAdmin ? AppColors.primaryGold : provider.currentGolfer.tier.color,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActualAdmin ? Icons.admin_panel_settings : Icons.account_circle,
                        size: 14,
                        color: isActualAdmin ? AppColors.primaryGold : provider.currentGolfer.tier.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        provider.currentGolfer.name.split(' ').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. CHỈ DUY NHẤT TÀI KHOẢN ADMIN MỚI CÓ NÚT CHUYỂN VÀO ADMIN (Khách hàng & Khách vãng lai bị ẩn hoàn toàn)
          if (isActualAdmin) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/admin/dashboard'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.dashboard_rounded, size: 13, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'Về Admin',
                        style: TextStyle(
                          color: Colors.black,
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
        ],
      ),
    );
  }

  void _showAccountMenu(BuildContext context, BookingProvider provider) {
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_note_rounded, color: AppColors.primaryGold),
                title: const Text('Cập nhật thông tin cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Họ tên, SĐT, Email và điểm HCP', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  GolferVipCard.showEditGolferDialog(context, provider);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
