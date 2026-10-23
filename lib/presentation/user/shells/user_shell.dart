import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../shared_widgets/ai_floating_button.dart';
import '../../shared_widgets/mode_switch_banner.dart';

/// Khung điều hướng chuẩn 100% Mobile App cho Khách hàng (User)
/// Luôn luôn sử dụng Bottom Navigation Bar trên mọi thiết bị (kể cả xem trước trên Web/Desktop),
/// tuyệt đối không dùng Sidebar cho luồng User.
class UserShell extends StatelessWidget {
  final Widget child;

  const UserShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final String location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/booking')) return 1;
      if (location.startsWith('/services')) return 2;
      if (location.startsWith('/my-bookings')) return 3;
    } catch (_) {}
    return 0; // Trang chủ
  }

  void _onItemTapped(int index, BuildContext context) {
    try {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/booking');
          break;
        case 2:
          context.go('/services');
          break;
        case 3:
          context.go('/my-bookings');
          break;
      }
    } catch (_) {}
  }

  void _onHorizontalSwipe(DragEndDetails details, int currentIndex, BuildContext context) {
    final velocity = details.primaryVelocity ?? 0;
    // Vuốt sang trái (chuyển sang tab kế tiếp)
    if (velocity < -450 && currentIndex < 3) {
      _onItemTapped(currentIndex + 1, context);
    }
    // Vuốt sang phải (quay về tab trước)
    else if (velocity > 450 && currentIndex > 0) {
      _onItemTapped(currentIndex - 1, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isWideScreen = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.userBgDark,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) =>
            _onHorizontalSwipe(details, selectedIndex, context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Nội dung chính: Căn giữa với bề ngang tối đa 600dp trên màn hình rộng / desktop / tablet
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 600 : double.infinity,
                ),
                child: SizedBox.expand(
                  child: DecoratedBox(
                    decoration: isWideScreen
                        ? BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: AppColors.primaryGold.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : const BoxDecoration(),
                    child: child,
                  ),
                ),
              ),
            ),

            // Nút chuyển chế độ Admin dạng floating góc trên bên phải
            const ModeSwitchFloatingButton(isAdminMode: false),

            // Nút trợ lý AI Caddie nổi góc dưới bên phải
            const AiFloatingButton(),
          ],
        ),
      ),

      // THANH ĐIỀU HƯỚNG ĐÁY (4 TAB ĐỒNG ĐỀU KÍCH THƯỚC 100%)
      bottomNavigationBar: Container(
        width: double.infinity,
        color: AppColors.userBgDark,
        alignment: Alignment.bottomCenter,
        height: 70 + MediaQuery.paddingOf(context).bottom,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 600 : double.infinity,
          ),
          child: Container(
            height: 70 + MediaQuery.paddingOf(context).bottom,
            decoration: BoxDecoration(
              color: AppColors.userCardDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: const BorderSide(color: AppColors.userBorder, width: 1),
                left: isWideScreen
                    ? BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2), width: 1)
                    : BorderSide.none,
                right: isWideScreen
                    ? BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2), width: 1)
                    : BorderSide.none,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        selectedIndex: selectedIndex,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Trang chủ',
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        selectedIndex: selectedIndex,
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month_rounded,
                        label: 'Đặt phòng',
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        selectedIndex: selectedIndex,
                        icon: Icons.room_service_outlined,
                        activeIcon: Icons.room_service_rounded,
                        label: 'Dịch vụ',
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildNavItem(
                        index: 3,
                        selectedIndex: selectedIndex,
                        icon: Icons.confirmation_number_outlined,
                        activeIcon: Icons.confirmation_number_rounded,
                        label: 'Vé của tôi',
                        context: context,
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

  /// Mọi tab điều hướng có cùng chiều cao (54px) và tỷ lệ cân đối tuyệt đối
  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required BuildContext context,
  }) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryGold.withValues(alpha: 0.22),
                    AppColors.darkGold.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
