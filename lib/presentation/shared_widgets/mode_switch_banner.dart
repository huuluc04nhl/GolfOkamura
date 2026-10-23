import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/golfer_model.dart';
import '../../shared/providers/booking_provider.dart';

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

    // Với User Mobile: Cụm nút nổi tinh tế ở góc phải trên cùng (Tài khoản + Nút Admin có phân quyền)
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Tài khoản & Đăng xuất
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAccountMenu(context, provider),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.primaryGold),
                    const SizedBox(width: 4),
                    Text(
                      provider.currentGolfer.name.split(' ').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Nút Admin (Kiểm tra quyền truy cập)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (provider.currentGolfer.isAdmin) {
                  context.go('/admin/dashboard');
                } else {
                  _showAdminAccessDialog(context, provider);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
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
                    SizedBox(width: 4),
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

  void _showAdminAccessDialog(BuildContext context, BookingProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.lock_person_rounded, color: AppColors.primaryGold, size: 22),
            SizedBox(width: 10),
            Text('Phân Quyền Hệ Thống', style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        content: Text(
          'Tài khoản hiện tại (${provider.currentGolfer.name}) là Khách hàng (Hội viên).\n\nKhu vực Quản trị POS & Thiết bị chỉ dành riêng cho Admin Okamura. Bạn có muốn đăng nhập tài khoản Quản trị viên không?',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Ở lại App Khách', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Đăng nhập Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
