import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/ai_chat_bottom_sheet.dart';
import '../../shared_widgets/language_selector_pill.dart';
import '../../shared_widgets/mode_switch_banner.dart';

/// Màn hình Trang chủ User cao cấp:
/// - Giàu hiệu ứng thị giác (Ambient Glow, Pulsing Radar, Auto-sliding Hero Carousel, Live Telemetry Ticker)
/// - Đồng bộ 100% dữ liệu trực tiếp với Firebase Realtime Database
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  int _currentHeroSlide = 0;
  final PageController _heroPageController = PageController();
  late final AnimationController _pulseController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      value: 0.6,
    );

    // Tự động chuyển slide Hero & hiệu ứng nhịp thở khi chạy ứng dụng thực tế
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BookingProvider>();
      if (provider.autoSyncFirebase) {
        _pulseController.repeat(reverse: true);
        _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (!mounted || !_heroPageController.hasClients) return;
          final next = (_currentHeroSlide + 1) % 3;
          _heroPageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pulseController.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isSquarish = Responsive.isSquarishFoldable(context);
    final safeBottom = Responsive.safeBottomPadding(context, extra: 20);

    return Stack(
      children: [
        // Hiệu ứng ánh sáng Ambient Orbs tạo chiều sâu không gian Lounge
        Positioned(
          top: -60,
          left: -40,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryGold.withValues(
                          alpha: 0.12 + (_pulseController.value * 0.08),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 260,
          right: -70,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryGold,
            backgroundColor: AppColors.userCardDark,
            onRefresh: () =>
                context.read<BookingProvider>().refreshFromFirebase(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Top Bar cao cấp kèm trạng thái đồng bộ Firebase trực tiếp
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 14),
                    child: _buildTopHeader(context),
                  ),
                ),

                // 2. Nội dung chính: Tự thích ứng bố cục 1 cột hoặc 2 cột
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: isSquarish
                        ? _buildDualPaneLayout(context)
                        : _buildSingleColumnLayout(context),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(height: safeBottom),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Header sang trọng: Logo phát sáng + Trạng thái Firebase Live + Đa ngôn ngữ + Tài khoản
  Widget _buildTopHeader(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final availableCount =
        provider.rooms.where((r) => !r.isUnderMaintenance).length;
    final isSmall = Responsive.isSmallMobile(context);

    return Row(
      children: [
        // Biểu tượng thương hiệu có viền phát sáng nhịp thở
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE5C899),
                    AppColors.primaryGold,
                    AppColors.darkGold,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(
                      alpha: 0.25 + (_pulseController.value * 0.25),
                    ),
                    blurRadius: 8 + (_pulseController.value * 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const Center(
            child: Icon(Icons.sports_golf_rounded, color: Colors.black, size: 20),
          ),
        ),
        const SizedBox(width: 8),

        // Tên thương hiệu & Trạng thái hoạt động
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'OKAMURA GOLFZON',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      provider.isSyncingFirebase ? 'SYNC' : 'LIVE',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  // Chấm xanh nhịp thở báo hoạt động trực tiếp
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(
                                alpha: 0.4 + (_pulseController.value * 0.5),
                              ),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$availableCount/${provider.rooms.length} phòng sẵn sàng',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Cụm điều khiển góc phải: Bộ đổi ngôn ngữ (màn >= 360) + Tài khoản
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSmall) ...[
              const LanguageSelectorPill(compact: true),
              const SizedBox(width: 6),
            ],
            ModeSwitchFloatingButton.buildUserAccountCluster(context, provider),
          ],
        ),
      ],
    );
  }

  /// Bố cục 1 cột tối ưu cho mọi loại điện thoại
  Widget _buildSingleColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(context),
        const SizedBox(height: 14),
        _buildAiCaddieCard(context),
        const SizedBox(height: 14),
        _buildLiveTelemetryStrip(context),
        const SizedBox(height: 16),
        _buildQuickPerksBar(context),
        const SizedBox(height: 20),
        _buildGolfGameModesSection(context),
        const SizedBox(height: 22),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('room_list_title'),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/booking'),
              child: Row(
                children: [
                  Text(
                    context.tr('view_schedule'),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primaryGold),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildCategoryFilterBar(),
        const SizedBox(height: 12),
        _buildLiveRoomsGrid(context),
        const SizedBox(height: 20),
        _buildCompactLocationFooter(context),
      ],
    );
  }

  /// Bố cục 2 cột cân xứng cho màn hình vuông gập mở (Galaxy Z Fold / Tablet)
  Widget _buildDualPaneLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(context),
              const SizedBox(height: 12),
              _buildAiCaddieCard(context),
              const SizedBox(height: 12),
              _buildLiveTelemetryStrip(context),
              const SizedBox(height: 14),
              _buildQuickPerksBar(context),
              const SizedBox(height: 16),
              _buildGolfGameModesSection(context),
              const SizedBox(height: 16),
              _buildCompactLocationFooter(context),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'DANH SÁCH PHÒNG CHƠI',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/booking'),
                    icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGold),
                    label: const Text(
                      'Đặt theo giờ',
                      style: TextStyle(color: AppColors.primaryGold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCategoryFilterBar(),
              const SizedBox(height: 10),
              _buildLiveRoomsGrid(context),
            ],
          ),
        ),
      ],
    );
  }

  /// Thẻ gọi nhanh Trợ lý AI Caddie trên Trang chủ
  Widget _buildAiCaddieCard(BuildContext context) {
    return InkWell(
      onTap: () => AiChatBottomSheet.show(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E293B),
              AppColors.primaryGold.withValues(alpha: 0.15),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGold, Color(0xFFB69568)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('ask_ai_caddie_title'),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('ask_ai_caddie_desc'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('chat_now'),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGold, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh chỉ số Live Telemetry trực tiếp từ dữ liệu Firebase (tương tác 1 chạm thực tế)
  Widget _buildLiveTelemetryStrip(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final availableCount =
        provider.rooms.where((r) => !r.isUnderMaintenance).length;
    final activeBookingsCount = provider.bookings
        .where((b) => b.status.name == 'confirmed')
        .length;
    final fnbCount = provider.serviceItems.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F1C18),
            AppColors.userCardDark.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _buildTelemetryMetric(
            icon: Icons.sensors_rounded,
            value: '$availableCount Phòng trống',
            label: 'Chạm đồng bộ',
            color: const Color(0xFF10B981),
            onTap: () async {
              setState(() => _selectedCategory = 'all');
              await provider.refreshFromFirebase();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã đồng bộ Firebase: $availableCount/${provider.rooms.length} phòng sẵn sàng!',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          Container(width: 1, height: 24, color: AppColors.userBorder),
          _buildTelemetryMetric(
            icon: Icons.event_available_rounded,
            value: '$activeBookingsCount Lịch đặt',
            label: 'Xem vé Cloud →',
            color: AppColors.primaryGold,
            onTap: () => context.go('/my-bookings'),
          ),
          Container(width: 1, height: 24, color: AppColors.userBorder),
          _buildTelemetryMetric(
            icon: Icons.restaurant_menu_rounded,
            value: '$fnbCount Dịch vụ',
            label: 'Mở Menu F&B →',
            color: const Color(0xFF38BDF8),
            onTap: () => context.go('/services'),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero Carousel 3 trang vuốt ngang giàu hiệu ứng ánh sáng & watermark nghệ thuật
  Widget _buildHeroBanner(BuildContext context) {
    final slides = [
      {
        'badge': 'CÔNG NGHỆ TWOWISION NX 3D',
        'title': 'Phòng Golf 3D Chuẩn Tour PGA',
        'desc': 'Cảm biến quang học kép 4K nhận diện xoáy bóng, địa hình Swing Plate 8 hướng siêu thực.',
        'cta': 'ĐẶT PHÒNG NGAY',
        'route': '/booking',
        'icon': Icons.calendar_month_rounded,
        'bgIcon': Icons.sports_golf_rounded,
        'colors': [const Color(0xFF332411), const Color(0xFF1B1815), const Color(0xFF121216)],
        'accent': AppColors.primaryGold,
      },
      {
        'badge': 'IN-ROOM CONCIERGE & F&B',
        'title': 'Order Ẩm Thực & Thuê Gậy Tận Phòng',
        'desc': 'Thưởng thức bia thủ công Asahi, món Nhật - Hàn, thuê gậy TaylorMade Qi10 & gọi Caddie 1 chạm.',
        'cta': 'MỞ MENU DỊCH VỤ',
        'route': '/services',
        'icon': Icons.room_service_rounded,
        'bgIcon': Icons.local_bar_rounded,
        'colors': [const Color(0xFF142923), const Color(0xFF151C1B), const Color(0xFF121216)],
        'accent': const Color(0xFF10B981),
      },
      {
        'badge': 'ƯU ĐÃI HAPPY HOUR & ACADEMY',
        'title': 'Luyện Tập GDR Plus & Chỉnh Swing AI',
        'desc': 'Phân tích 24 thông số cú đánh tốc độ 2000fps cùng huấn luyện viên PGA chuyên nghiệp.',
        'cta': 'CHỌN LÀN TẬP NGAY',
        'route': '/booking',
        'icon': Icons.analytics_rounded,
        'bgIcon': Icons.speed_rounded,
        'colors': [const Color(0xFF172336), const Color(0xFF161922), const Color(0xFF121216)],
        'accent': const Color(0xFF38BDF8),
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 216,
          child: PageView.builder(
            controller: _heroPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: slides.length,
            onPageChanged: (idx) => setState(() => _currentHeroSlide = idx),
            itemBuilder: (context, index) {
              final slide = slides[index];
              final accent = slide['accent'] as Color;
              final gradColors = slide['colors'] as List<Color>;

              return Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: gradColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Họa tiết vòng sáng & biểu tượng chìm góc phải tạo chiều sâu Luxury
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 48,
                      child: Icon(
                        Icons.sports_golf_rounded,
                        size: 92,
                        color: accent.withValues(alpha: 0.07),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, color: accent, size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        slide['badge'] as String,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slide['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                slide['desc'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => context.go(slide['route'] as String),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                foregroundColor: Colors.black,
                                elevation: 6,
                                shadowColor: AppColors.primaryGold.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(slide['icon'] as IconData, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      slide['cta'] as String,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final active = _currentHeroSlide == idx;
            return GestureDetector(
              onTap: () => _heroPageController.animateToPage(
                idx,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryGold : AppColors.userBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 4 Tiện ích cốt lõi có hiệu ứng màu sắc riêng biệt & chạm tương tác trực tiếp
  Widget _buildQuickPerksBar(BuildContext context) {
    final perks = [
      {
        'icon': Icons.videocam_rounded,
        'label': 'Đồ họa 4K',
        'color': AppColors.primaryGold,
        'action': () => setState(() => _selectedCategory = 'vip'),
      },
      {
        'icon': Icons.sports_golf_rounded,
        'label': 'Thuê Gậy Pro',
        'color': const Color(0xFF10B981),
        'action': () => context.go('/services'),
      },
      {
        'icon': Icons.smoke_free_rounded,
        'label': 'Phòng riêng',
        'color': const Color(0xFF38BDF8),
        'action': () => setState(() => _selectedCategory = 'standard'),
      },
      {
        'icon': Icons.room_service_rounded,
        'label': 'F&B tận phòng',
        'color': const Color(0xFFF59E0B),
        'action': () => context.go('/services'),
      },
    ];

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.userCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.userBorder),
      ),
      child: Row(
        children: perks.map((item) {
          final color = item['color'] as Color;
          return Expanded(
            child: InkWell(
              onTap: item['action'] as VoidCallback,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Các thể loại & chế độ chơi Golf đa dạng với dải màu градиент sinh động
  Widget _buildGolfGameModesSection(BuildContext context) {
    final gameModes = [
      {
        'title': 'Stroke & Match Play',
        'subtitle': '18 Hố 200 sân thế giới',
        'badge': 'Phổ biến nhất',
        'icon': Icons.golf_course_rounded,
        'color': const Color(0xFF10B981),
        'desc': 'Chơi tính gậy tiêu chuẩn hoặc đấu tay đôi Match Play trên các sân huyền thoại: St Andrews, Pebble Beach, TPC Sawgrass với chuẩn gió và địa hình thực tế.',
      },
      {
        'title': 'GDR Plus Academy',
        'subtitle': 'Luyện tập phân tích AI',
        'badge': 'Chuyên nghiệp',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF38BDF8),
        'desc': 'Phân tích thông số cú đánh chuyên sâu: Ball Speed, Club Path, Face Angle, Spin Axis và Smash Factor qua camera cảm biến tốc độ cao 2.000 fps.',
      },
      {
        'title': 'Skins & Longest Drive',
        'subtitle': 'Mini Tournament',
        'badge': 'Đối kháng vui',
        'icon': Icons.emoji_events_outlined,
        'color': AppColors.primaryGold,
        'desc': 'Thử thách phát bóng xa nhất (Long Drive), đánh gần cờ nhất (Near Pin) và chia tiền thưởng ảo từng hố với bạn bè.',
      },
      {
        'title': 'Family & Kid Arcade',
        'subtitle': 'Golf giải trí gia đình',
        'badge': 'Dễ tiếp cận',
        'icon': Icons.family_restroom_rounded,
        'color': const Color(0xFFA855F7),
        'desc': 'Chế độ đồ họa vui nhộn, mini golf hoạt hình thích hợp cho cả gia đình, người mới bắt đầu và trẻ em làm quen với môn golf.',
      },
      {
        'title': 'Night Neon Golf',
        'subtitle': 'Party âm nhạc & đèn Neon',
        'badge': 'Sau 19:00',
        'icon': Icons.nightlife_rounded,
        'color': const Color(0xFFEC4899),
        'desc': 'Trải nghiệm không gian golf buổi tối với hiệu ứng đèn neon, âm nhạc lounge thư giãn và đồ uống cocktail cao cấp.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'THỂ LOẠI & CHẾ ĐỘ CHƠI GOLF',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Vuốt ngang →',
              style: TextStyle(
                color: AppColors.primaryGold.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: gameModes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mode = gameModes[index];
              final accent = mode['color'] as Color;
              return InkWell(
                onTap: () => _showGameModeDetails(context, mode),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.16),
                        AppColors.userCardDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              mode['icon'] as IconData,
                              color: accent,
                              size: 18,
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mode['badge'] as String,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode['subtitle'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showGameModeDetails(BuildContext context, Map<String, dynamic> mode) {
    final accent = (mode['color'] as Color?) ?? AppColors.primaryGold;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.userCardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(mode['icon'] as IconData, color: accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            mode['subtitle'] as String,
                            style: TextStyle(color: accent, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.userBorder),
                  ),
                  child: Text(
                    mode['desc'] as String,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = mode['title'] as String;
                      String targetCat = 'all';
                      if (title.contains('GDR')) {
                        targetCat = 'range';
                      } else if (title.contains('Neon') || title.contains('Skins')) {
                        targetCat = 'vip';
                      } else if (title.contains('Family')) {
                        targetCat = 'connecting';
                      }
                      context.read<BookingProvider>().selectCategoryForBooking(
                            targetCat,
                            gameMode: title,
                          );
                      Navigator.pop(ctx);
                      context.go('/booking');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'ĐẶT PHÒNG TRẢI NGHIỆM NGAY',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Thanh lọc danh mục phòng chơi linh hoạt
  Widget _buildCategoryFilterBar() {
    final categories = [
      {'id': 'all', 'label': 'Tất cả'},
      {'id': 'standard', 'label': 'Tiêu chuẩn'},
      {'id': 'vip', 'label': 'VIP Suite'},
      {'id': 'dual', 'label': 'Dual Tee (Tay trái)'},
      {'id': 'connecting', 'label': 'Phòng đôi'},
      {'id': 'range', 'label': 'Làn GDR Plus'},
      {'id': 'studio', 'label': 'PGA Studio'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat['id']!),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.userCardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGold
                        : AppColors.userBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Lưới danh sách phòng thời gian thực (Live Rooms Grid)
  Widget _buildLiveRoomsGrid(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
          );
        }

        final allRooms = provider.rooms;
        final rooms = allRooms.where((r) {
          if (_selectedCategory == 'all') return true;
          if (_selectedCategory == 'standard') return r.category == 'standard';
          if (_selectedCategory == 'vip') return r.isVip;
          if (_selectedCategory == 'dual') return r.isDualTee;
          if (_selectedCategory == 'connecting') return r.isConnecting;
          if (_selectedCategory == 'range') return r.isDrivingRange;
          if (_selectedCategory == 'studio') return r.isStudio;
          return true;
        }).toList();

        final isSmall = Responsive.isSmallMobile(context);

        if (rooms.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.userCardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.userBorder),
            ),
            child: const Text(
              'Không tìm thấy phòng phù hợp trong danh mục này',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _buildRoomTile(context, room, isSmall);
          },
        );
      },
    );
  }

  /// Thẻ phòng ngang cao cấp, có dải viền màu phân loại & đồng bộ trạng thái Firebase
  Widget _buildRoomTile(BuildContext context, RoomModel room, bool isSmall) {
    final isMaintenance = room.isUnderMaintenance;

    Color badgeColor;
    IconData roomIcon;
    if (room.isVip) {
      badgeColor = AppColors.primaryGold;
      roomIcon = Icons.workspace_premium_rounded;
    } else if (room.isDualTee) {
      badgeColor = const Color(0xFF06B6D4);
      roomIcon = Icons.sync_alt_rounded;
    } else if (room.isConnecting) {
      badgeColor = const Color(0xFFA855F7);
      roomIcon = Icons.connect_without_contact_rounded;
    } else if (room.isDrivingRange) {
      badgeColor = const Color(0xFF3B82F6);
      roomIcon = Icons.analytics_rounded;
    } else if (room.isStudio) {
      badgeColor = const Color(0xFFF59E0B);
      roomIcon = Icons.school_rounded;
    } else if (room.isSmoking) {
      badgeColor = Colors.orange;
      roomIcon = Icons.smoking_rooms_rounded;
    } else {
      badgeColor = const Color(0xFF10B981);
      roomIcon = Icons.sports_golf_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRoomDetailsSheet(context, room),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withValues(alpha: 0.10),
                const Color(0xFF1A191E),
                const Color(0xFF151418),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMaintenance
                  ? Colors.redAccent.withValues(alpha: 0.35)
                  : badgeColor.withValues(alpha: 0.32),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      badgeColor.withValues(alpha: 0.28),
                      badgeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
                ),
                child: Icon(roomIcon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
                            ),
                            child: Text(
                              room.categoryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${room.capacity} chỗ • ${room.sensorModel}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    Text(
                      '${Formatters.formatCurrency(room.pricePerHour)}/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              if (isMaintenance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Bảo trì',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.read<BookingProvider>().selectRoomForBooking(room);
                    context.go('/booking');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Đặt chỗ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị bảng chi tiết phòng siêu sang (Luxury Bottom Sheet)
  void _showRoomDetailsSheet(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF18171B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 32,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  room.categoryLabel,
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: room.isUnderMaintenance
                                      ? Colors.redAccent
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                room.isUnderMaintenance ? 'Đang bảo trì' : 'Khả dụng đặt lịch',
                                style: TextStyle(
                                  color: room.isUnderMaintenance
                                      ? Colors.redAccent
                                      : const Color(0xFF10B981),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.userCardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.userBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailFeatureItem(
                          Icons.videocam_rounded,
                          'Cảm biến',
                          room.sensorModel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailFeatureItem(
                          Icons.airline_seat_recline_extra_rounded,
                          'Swing Plate',
                          'Địa hình 8 hướng',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.userCardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.userBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailFeatureItem(
                          Icons.groups_rounded,
                          'Sức chứa',
                          '${room.capacity} Golfer',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailFeatureItem(
                          room.isSmoking ? Icons.smoking_rooms_rounded : Icons.smoke_free_rounded,
                          'Khu vực',
                          room.isSmoking ? 'Có hút thuốc' : 'Không hút thuốc',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MÔ TẢ KHÔNG GIAN & TIỆN NGHI',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  room.description,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GIÁ THUÊ PHÒNG',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${Formatters.formatCurrency(room.pricePerHour)}/h',
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<BookingProvider>().selectRoomForService(room.name);
                        Navigator.pop(ctx);
                        context.go('/services');
                      },
                      icon: const Icon(Icons.room_service_outlined, size: 16),
                      label: const Text('Order F&B'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGold,
                        side: const BorderSide(color: AppColors.primaryGold),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: room.isUnderMaintenance
                            ? null
                            : () {
                                context.read<BookingProvider>().selectRoomForBooking(room);
                                Navigator.pop(ctx);
                                context.go('/booking');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'ĐẶT PHÒNG',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Chân trang địa chỉ và thông tin cơ sở (Chạm để sao chép địa chỉ nhanh)
  Widget _buildCompactLocationFooter(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(const ClipboardData(text: AppConstants.address));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép địa chỉ Okamura Golfzon vào bộ nhớ tạm!'),
            backgroundColor: AppColors.userCardDark,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.userCardDark.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.userBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.address,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showHotlineDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryGold, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Hotline',
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
          ],
        ),
      ),
    );
  }

  void _showHotlineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.userCardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HOTLINE LỄ TÂN & ĐẶT SÂN',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.hotline,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Phục vụ từ 08:00 đến 23:00 hàng ngày',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: AppConstants.hotline));
                      context.read<BookingProvider>().submitQuickRoomRequest(
                            roomName: 'Quầy Lễ Tân',
                            requestTitle: 'Yêu cầu gọi lại tư vấn đặt sân (${AppConstants.hotline})',
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã sao chép SĐT 093 399 21 00 & gửi yêu cầu lễ tân hỗ trợ lên Cloud!',
                          ),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('GỌI & YÊU CẦU LỄ TÂN HỖ TRỢ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
