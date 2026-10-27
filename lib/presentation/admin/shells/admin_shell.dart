import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/mode_switch_banner.dart';

/// Khung điều hướng chuẩn GOLFZON Store Manager (GSM) × POS365.VN
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin/bookings')) return 1;
    if (location.startsWith('/admin/orders')) return 2;
    if (location.startsWith('/admin/rooms')) return 3;
    if (location.startsWith('/admin/revenue')) return 4;
    return 0; // Điều Hành Phòng Bay
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/bookings');
        break;
      case 2:
        context.go('/admin/orders');
        break;
      case 3:
        context.go('/admin/rooms');
        break;
      case 4:
        context.go('/admin/revenue');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = Responsive.isDesktop(context);
    final provider = context.watch<BookingProvider>();

    final activeBookingsCount = provider.bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final pendingOrdersCount = provider.serviceOrders
        .where((o) => o.status == 'preparing')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Column(
        children: [
          // Banner chuyển đổi nhanh giữa Admin GSM/POS365 và App Khách (User)
          const ModeSwitchBanner(isAdminMode: true),

          Expanded(
            child: Row(
              children: [
                // Sidebar chuyên nghiệp chuẩn GOLFZON GSM × POS365
                Container(
                  width: isDesktop ? 260 : 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      right: BorderSide(color: Color(0xFF1E293B)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Thương hiệu GOLFZON GSM × POS365
                      Container(
                        height: 76,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 18 : 12,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: isDesktop
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryGold,
                                    AppColors.darkGold,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.sports_golf_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'OKAMURA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'QUẢN TRỊ VẬN HÀNH',
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      const SizedBox(height: 14),

                      // Danh sách Menu điều hướng
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          children: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.dashboard_outlined,
                              selectedIcon: Icons.dashboard_rounded,
                              label: 'Trung Tâm Điều Hành',
                              subtitle: 'Sơ đồ phòng & Ca chơi',
                              badgeText: activeBookingsCount > 0
                                  ? '$activeBookingsCount đang chơi'
                                  : null,
                              badgeColor: const Color(0xFF10B981),
                              isSelected: selectedIndex == 0,
                              onTap: () => _onItemTapped(0, context),
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 8),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.calendar_month_outlined,
                              selectedIcon: Icons.calendar_month_rounded,
                              label: 'Lịch Đặt & Tiếp Đón',
                              subtitle: 'Lịch đặt & Đón khách',
                              badgeText: activeBookingsCount > 0
                                  ? '$activeBookingsCount đặt'
                                  : null,
                              badgeColor: const Color(0xFF38BDF8),
                              isSelected: selectedIndex == 1,
                              onTap: () => _onItemTapped(1, context),
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 8),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.room_service_outlined,
                              selectedIcon: Icons.room_service_rounded,
                              label: 'Quản Lý Đơn Dịch Vụ',
                              subtitle: 'Tiếp nhận & Điều phối F&B',
                              badgeText: pendingOrdersCount > 0
                                  ? '$pendingOrdersCount đơn mới'
                                  : null,
                              badgeColor: const Color(0xFFF59E0B),
                              isSelected: selectedIndex == 2,
                              onTap: () => _onItemTapped(2, context),
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 8),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.meeting_room_outlined,
                              selectedIcon: Icons.meeting_room_rounded,
                              label: 'Quản Lý Phòng & Dịch Vụ',
                              subtitle: 'Cấu hình phòng & Thực đơn',
                              badgeText:
                                  '${provider.rooms.length} Phòng • ${provider.serviceItems.length} Món',
                              badgeColor: const Color(0xFF38BDF8),
                              isSelected: selectedIndex == 3,
                              onTap: () => _onItemTapped(3, context),
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 8),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.insights_outlined,
                              selectedIcon: Icons.insights_rounded,
                              label: 'Báo Cáo & Thống Kê',
                              subtitle: 'Hiệu suất vận hành & Doanh thu',
                              badgeColor: AppColors.primaryGold,
                              isSelected: selectedIndex == 4,
                              onTap: () => _onItemTapped(4, context),
                              isDesktop: isDesktop,
                            ),
                          ],
                        ),
                      ),

                      // Thông tin quản trị viên ở chân sidebar
                      if (isDesktop)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFF131C31),
                            border: Border(
                              top: BorderSide(color: Color(0xFF1E293B)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryGold,
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.black,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.currentGolfer.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Hotline: ${AppConstants.hotline}',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                                tooltip: 'Đăng xuất tài khoản',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  await provider.logout();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      if (!isDesktop)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 20),
                            tooltip: 'Đăng xuất tài khoản',
                            onPressed: () async {
                              await provider.logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Nội dung chính
                Expanded(
                  child: Container(
                    color: const Color(0xFF0B1120),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String subtitle,
    String? badgeText,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return Tooltip(
      message: isDesktop ? '' : label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 12 : 8,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFB69568), Color(0xFF917349)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.lightGold.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.2)
                          : badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isSelected ? Colors.black : badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
