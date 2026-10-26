import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/golfer_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/services/storage_service.dart';
import '../../shared_widgets/in_bay_timer_widget.dart';
import '../../shared_widgets/vietqr_payment_dialog.dart';

/// Màn hình Order Dịch Vụ & F&B tận phòng (In-Room Concierge & Pro Shop)
/// - Tự động nhận phòng phục vụ từ Trang chủ hoặc Vé của tôi
/// - Hỗ trợ ghi chú món ăn/dịch vụ, theo dõi & cập nhật trạng thái đơn trực tiếp trên Firebase
class UserServicesScreen extends StatefulWidget {
  const UserServicesScreen({super.key});

  @override
  State<UserServicesScreen> createState() => _UserServicesScreenState();
}

class _UserServicesScreenState extends State<UserServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRoomName = 'Room 1 (Standard)';
  final TextEditingController _orderNoteController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  String _selectedPaymentMethod = 'pay_at_bay'; // 'pay_at_bay' hoặc 'vietqr'

  // Giỏ hàng: id món -> số lượng
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedCustomerProfile();
  }

  Future<void> _loadSavedCustomerProfile() async {
    final provider = context.read<BookingProvider>();
    if (provider.isLoggedIn && !provider.isGuest) {
      _customerNameController.text = provider.currentGolfer.name;
      _customerPhoneController.text = provider.currentGolfer.phone;
    } else {
      // Đối với Khách vãng lai: Tuyệt đối KHÔNG tự động nhập sẵn dữ liệu cũ, để trường nhập trống hoàn toàn
      _customerNameController.clear();
      _customerPhoneController.clear();
    }
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<ServiceItemModel> _resolveCatalog(BookingProvider provider) {
    return provider.serviceItems;
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  double _calculateTotalPrice(List<ServiceItemModel> catalog) {
    double sum = 0;
    _cart.forEach((id, qty) {
      final idx = catalog.indexWhere((e) => e.id == id);
      if (idx != -1) {
        sum += catalog[idx].price * qty;
      }
    });
    return sum;
  }

  void _updateQty(String id, int delta) {
    setState(() {
      final current = _cart[id] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final provider = context.watch<BookingProvider>();
    final catalog = _resolveCatalog(provider);
    final totalPrice = _calculateTotalPrice(catalog);

    final roomNames = provider.rooms.map((r) => r.name).toList();

    if (provider.selectedServiceRoomName != null &&
        roomNames.contains(provider.selectedServiceRoomName)) {
      _selectedRoomName = provider.selectedServiceRoomName!;
    } else if (!roomNames.contains(_selectedRoomName) && roomNames.isNotEmpty) {
      _selectedRoomName = roomNames.first;
    }

    final recentOrders = provider.serviceOrders.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.userBgDark,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('services_screen_title'),
                maxLines: 1,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.45),
                  ),
                ),
                child: const Text(
                  'CLOUD',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.userBgDark,
        actions: [
          if (provider.serviceOrders.isNotEmpty)
            IconButton(
              tooltip: 'Đơn dịch vụ đã gọi',
              onPressed: () => _showServiceOrdersSheet(context, provider),
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF10B981),
              ),
            ),
          IconButton(
            tooltip: 'Gọi nhân viên hỗ trợ',
            onPressed: () => _showQuickCallWaiterSheet(context, provider),
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Thanh chọn phòng phục vụ
                Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 10),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF232028), Color(0xFF18171C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: AppColors.primaryGold,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Giao tới:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: roomNames.contains(_selectedRoomName)
                                  ? _selectedRoomName
                                  : null,
                              hint: const Text(
                                'Đang tải danh sách phòng...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              dropdownColor: AppColors.userCardDark,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primaryGold,
                                size: 18,
                              ),
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              items: roomNames.map((name) {
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRoomName = val);
                                  provider.selectRoomForService(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Đồng hồ đếm ngược phiên chơi và tiến độ hố trực tiếp tại phòng (Live In-Bay Timer)
                Builder(
                  builder: (context) {
                    final activeBooking = provider.bookings.where((b) {
                      if (b.status != BookingStatus.confirmed) return false;
                      return b.roomName == _selectedRoomName ||
                          provider.rooms.any((r) => r.id == b.roomId && r.name == _selectedRoomName);
                    }).firstOrNull;

                    if (activeBooking == null) return const SizedBox.shrink();

                    return Padding(
                      padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 10),
                      child: InBayTimerWidget(
                        roomName: _selectedRoomName,
                        timeSlot: activeBooking.timeSlot,
                        bookingDate: activeBooking.bookingDate,
                        onExtendSession: () => _showExtendBaySessionDialog(context, provider, activeBooking),
                      ),
                    );
                  },
                ),

                // 2. Các nút thao tác nhanh 1 chạm tại phòng (đẩy trực tiếp lên Firebase)
                Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 10),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildQuickServiceAction(
                          provider: provider,
                          icon: Icons.room_service_rounded,
                          label: 'Gọi nhân viên',
                          toastMessage:
                              'Nhân viên phục vụ đang tới hỗ trợ tại $_selectedRoomName',
                          accent: AppColors.primaryGold,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickServiceAction(
                          provider: provider,
                          icon: Icons.cleaning_services_rounded,
                          label: 'Khăn lạnh mới',
                          toastMessage:
                              'Đang chuẩn bị khăn lạnh hương sả chanh cho $_selectedRoomName',
                          accent: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickServiceAction(
                          provider: provider,
                          icon: Icons.sports_golf_rounded,
                          label: 'Thêm khay bóng',
                          toastMessage:
                              'Nhân viên đang mang thêm khay bóng tới $_selectedRoomName',
                          accent: const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickServiceAction(
                          provider: provider,
                          icon: Icons.battery_charging_full_rounded,
                          label: 'Mượn sạc pin',
                          toastMessage:
                              'Nhân viên đang mang bộ sạc đa năng tới $_selectedRoomName',
                          accent: const Color(0xFFA855F7),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2b. Thanh theo dõi đơn trực tiếp từ Firebase (Chạm để mở bảng quản lý đơn)
                if (recentOrders.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 10),
                    child: InkWell(
                      onTap: () => _showServiceOrdersSheet(context, provider),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_done_rounded,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đơn (${recentOrders.first.roomName}): ${recentOrders.first.summaryText} • ${recentOrders.first.statusLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Quản lý (${provider.serviceOrders.length}) →',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 3. Thanh Tab danh mục (Hỗ trợ cả bấm và vuốt ngang màn hình)
                Container(
                  height: 42,
                  margin: EdgeInsets.symmetric(horizontal: hPadding),
                  decoration: BoxDecoration(
                    color: AppColors.userCardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.userBorder),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.lightGold, AppColors.primaryGold],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.all(3),
                    tabs: const [
                      Tab(text: 'Đồ uống & Bar'),
                      Tab(text: 'Ẩm thực'),
                      Tab(text: 'Thuê Gậy & Đồ'),
                      Tab(text: 'HLV & Caddie'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Nội dung danh sách món từ Firebase: Hỗ trợ VUỐT NGANG & VUỐT XUỐNG LÀM MỚI
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: List.generate(4, (catIndex) {
                      final items = catalog
                          .where((e) => e.category == catIndex)
                          .toList();
                      return RefreshIndicator(
                        color: AppColors.primaryGold,
                        backgroundColor: AppColors.userCardDark,
                        onRefresh: () async {
                          await provider.refreshFromFirebase();
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            hPadding,
                            4,
                            hPadding,
                            100,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            return _buildUniformServiceCard(items[idx]);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 5. Thanh tổng kết giỏ hàng nổi ở đáy khi có món được chọn
      bottomSheet: _totalItems > 0
          ? Container(
              color: AppColors.userBgDark,
              padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 12),
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: () => _showCartReviewSheet(context, provider, catalog),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.lightGold, AppColors.primaryGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_totalItems món',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Formatters.formatCurrency(totalPrice),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Text(
                          'XEM & GỬI ORDER',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildQuickServiceAction({
    required BookingProvider provider,
    required IconData icon,
    required String label,
    required String toastMessage,
    required Color accent,
  }) {
    return InkWell(
      onTap: () {
        provider.submitQuickRoomRequest(
          roomName: _selectedRoomName,
          requestTitle: label,
        );
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toastMessage),
            backgroundColor: AppColors.userCardDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.16),
              AppColors.userCardDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ dịch vụ đồng nhất kích thước (chiều cao cố định 96px) kết hợp sắc màu градиент riêng từng món
  Widget _buildUniformServiceCard(ServiceItemModel item) {
    final qty = _cart[item.id] ?? 0;
    final accent = item.accentColor;

    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            qty > 0
                ? accent.withValues(alpha: 0.16)
                : accent.withValues(alpha: 0.06),
            AppColors.userCardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qty > 0
              ? AppColors.primaryGold.withValues(alpha: 0.75)
              : accent.withValues(alpha: 0.28),
          width: qty > 0 ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.network(
                item.resolvedImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.userSurfaceDark,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: accent.withValues(alpha: 0.15),
                  child: Icon(
                    item.iconData,
                    color: accent,
                    size: 26,
                  ),
                ),
              ),
            ),
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
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  Formatters.formatCurrency(item.price),
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          if (qty == 0)
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () => _updateQty(item.id, 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Thêm',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            )
          else
            Container(
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.userSurfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _updateQty(item.id, -1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        Icons.remove,
                        size: 15,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () => _updateQty(item.id, 1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        Icons.add,
                        size: 15,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Bottom sheet xem giỏ hàng, nhập thông tin khách vãng lai & thanh toán gửi order
  void _showCartReviewSheet(
    BuildContext context,
    BookingProvider provider,
    List<ServiceItemModel> catalog,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.userCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final entries = _cart.entries.toList();
            final modalTotal = _calculateTotalPrice(catalog);
            final roomNames = provider.rooms.map((r) => r.name).toList();
            final isGuest = provider.isGuest;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.90,
                ),
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tiêu đề & Nút xóa hết
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.room_service_rounded,
                                color: AppColors.primaryGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'XÁC NHẬN ORDER TẬN PHÒNG',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _cart.clear());
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Xóa hết',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Thân cuộn: Chi tiết giỏ hàng & form thông tin khách
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Vị trí phòng phục vụ
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.userSurfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.meeting_room_rounded,
                                    color: AppColors.primaryGold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Vị trí Bay phục vụ:',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: roomNames.contains(_selectedRoomName)
                                                ? _selectedRoomName
                                                : (roomNames.isNotEmpty ? roomNames.first : null),
                                            dropdownColor: const Color(0xFF1E293B),
                                            isDense: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: AppColors.primaryGold,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            items: roomNames.map((name) {
                                              return DropdownMenuItem<String>(
                                                value: name,
                                                child: Text(name),
                                              );
                                            }).toList(),
                                            onChanged: (newVal) {
                                              if (newVal != null) {
                                                setState(() => _selectedRoomName = newVal);
                                                setModalState(() {});
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Danh sách món trong giỏ
                            const Text(
                              'DANH SÁCH MÓN GỌI',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (_, idx) {
                                final entry = entries[idx];
                                final item = catalog.firstWhere(
                                  (e) => e.id == entry.key,
                                  orElse: () =>
                                      StorageService.initialServiceItems.first,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.userSurfaceDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.userBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 38,
                                          height: 38,
                                          child: Image.network(
                                            item.resolvedImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              item.iconData,
                                              color: item.accentColor,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                color: AppColors.textLight,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              Formatters.formatCurrency(item.price),
                                              style: const TextStyle(
                                                color: AppColors.primaryGold,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bộ chỉnh số lượng [- qty +]
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              _updateQty(entry.key, -1);
                                              setModalState(() {});
                                              if (_cart.isEmpty) Navigator.pop(ctx);
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.remove_rounded,
                                                size: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text(
                                              '${entry.value}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              _updateQty(entry.key, 1);
                                              setModalState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGold.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.add_rounded,
                                                size: 14,
                                                color: AppColors.primaryGold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // 3. Thông tin Golfer nhận món
                            const Text(
                              'THÔNG TIN GOLFER NHẬN MÓN',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (!isGuest && provider.isLoggedIn)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.userSurfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primaryGold,
                                      child: Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.black,
                                        size: 18,
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${provider.currentGolfer.phone} • Hạng ${provider.currentGolfer.tier.label}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              // Dành cho Khách vãng lai: Form nhập rõ ràng, capsule bo tròn 24px
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.userSurfaceDark,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.userBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white12,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'KHÁCH VÃNG LAI',
                                            style: TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Nhập để phục vụ đối chiếu tận phòng',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _customerNameController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: 'Họ và tên Golfer (*)',
                                        hintText: 'Nhập họ và tên quý khách...',
                                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGold, size: 18),
                                        filled: true,
                                        fillColor: const Color(0xFF0F172A),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _customerPhoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: 'Số điện thoại nhận hỗ trợ (*)',
                                        hintText: 'Nhập số điện thoại liên hệ...',
                                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGold, size: 18),
                                        filled: true,
                                        fillColor: const Color(0xFF0F172A),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // 4. Ghi chú phục vụ (Ít đá, ít đường, mượn đồ...)
                            const Text(
                              'GHI CHÚ CHO BẾP & QUẦY BAR',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _orderNoteController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'VD: Ít đá, thêm 2 ly, gậy nam Flex S, thêm khăn lạnh...',
                                hintStyle: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.primaryGold,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: AppColors.userSurfaceDark,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 5. Hình thức thanh toán
                            const Text(
                              'HÌNH THỨC THANH TOÁN',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() => _selectedPaymentMethod = 'pay_at_bay');
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _selectedPaymentMethod == 'pay_at_bay'
                                            ? AppColors.primaryGold.withValues(alpha: 0.16)
                                            : AppColors.userSurfaceDark,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _selectedPaymentMethod == 'pay_at_bay'
                                              ? AppColors.primaryGold
                                              : AppColors.userBorder,
                                          width: _selectedPaymentMethod == 'pay_at_bay' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.receipt_long_rounded,
                                                color: _selectedPaymentMethod == 'pay_at_bay'
                                                    ? AppColors.primaryGold
                                                    : Colors.white70,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Gộp hóa đơn Bay',
                                                  style: TextStyle(
                                                    color: _selectedPaymentMethod == 'pay_at_bay'
                                                        ? AppColors.primaryGold
                                                        : Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Thanh toán khi trả phòng',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() => _selectedPaymentMethod = 'vietqr');
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _selectedPaymentMethod == 'vietqr'
                                            ? const Color(0xFF10B981).withValues(alpha: 0.16)
                                            : AppColors.userSurfaceDark,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _selectedPaymentMethod == 'vietqr'
                                              ? const Color(0xFF10B981)
                                              : AppColors.userBorder,
                                          width: _selectedPaymentMethod == 'vietqr' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.qr_code_scanner_rounded,
                                                color: _selectedPaymentMethod == 'vietqr'
                                                    ? const Color(0xFF10B981)
                                                    : Colors.white70,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Quét VietQR',
                                                  style: TextStyle(
                                                    color: _selectedPaymentMethod == 'vietqr'
                                                        ? const Color(0xFF10B981)
                                                        : Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Chuyển khoản ngay 24/7',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Thanh Tổng Tiền & Nút Gửi Order
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(modalTotal),
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final room = _selectedRoomName;
                            final cartSnapshot = Map<String, int>.from(_cart);
                            final noteText = _orderNoteController.text.trim();
                            final custName = _customerNameController.text.trim();
                            final custPhone = _customerPhoneController.text.trim();
                            final payMethod = _selectedPaymentMethod;

                            // Bẫy lỗi nếu khách vãng lai chưa nhập tên
                            if (provider.isGuest && custName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập Họ tên Golfer để phục vụ đối chiếu mang món lên phòng.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _cart.clear();
                              _orderNoteController.clear();
                            });
                            Navigator.pop(ctx);

                            final order = await provider.submitServiceOrder(
                              roomName: room,
                              cartQuantities: cartSnapshot,
                              note: noteText,
                              customerName: custName.isNotEmpty ? custName : null,
                              customerPhone: custPhone.isNotEmpty ? custPhone : null,
                              paymentMethod: payMethod,
                            );

                            if (context.mounted) {
                              _showOrderSuccessDialog(context, provider, order);
                            }
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'GỬI ORDER ĐẾN BẾP',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
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
      },
    );
  }

  /// Dialog thông báo gửi order thành công & hỗ trợ quét VietQR thanh toán tức thì
  void _showOrderSuccessDialog(
    BuildContext context,
    BookingProvider provider,
    ServiceOrderModel order,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF16151D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.primaryGold.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon thành công
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ĐÃ GỬI ORDER THÀNH CÔNG!',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bếp & Quầy Bar đang tiếp nhận và chuẩn bị món cho bạn (dự kiến 5-10 phút).',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // Card tóm tắt đơn
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.userSurfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.userBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mã đơn:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                          Row(
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: order.id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép mã đơn!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vị trí phục vụ:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                          Text(
                            order.roomName,
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Người đặt:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                          Text(
                            order.customerName ?? 'Khách vãng lai',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hình thức:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                          Text(
                            order.paymentMethodLabel,
                            style: TextStyle(
                              color: order.paymentMethod == 'vietqr'
                                  ? const Color(0xFF10B981)
                                  : AppColors.primaryGold,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng:',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(order.totalPrice),
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nếu chọn VietQR, hiển thị nút Quét VietQR ngay
                if (order.paymentMethod == 'vietqr') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => VietQrPaymentDialog(
                            bookingId: order.id,
                            roomName: order.roomName,
                            amount: order.totalPrice,
                            customerName: order.customerName,
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: const Text(
                        'QUÉT MÃ VIETQR THANH TOÁN NGAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showServiceOrdersSheet(context, provider);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side: BorderSide(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Xem đơn',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Hoàn tất',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  /// Bảng quản lý Đơn Dịch Vụ Tận Phòng thời gian thực (cho phép lọc theo phòng hoặc SĐT khách vãng lai)
  void _showServiceOrdersSheet(BuildContext context, BookingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.userCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filterMode = 'all'; // 'all', 'current_room', 'my_phone'

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allOrders = provider.serviceOrders;
            final userPhone = _customerPhoneController.text.trim();

            final filteredOrders = allOrders.where((o) {
              if (filterMode == 'current_room') {
                return o.roomName == _selectedRoomName;
              }
              if (filterMode == 'my_phone' && userPhone.isNotEmpty) {
                final cleanUser = userPhone.replaceAll(RegExp(r'[^\d]'), '');
                final cleanOrder = (o.customerPhone ?? '').replaceAll(RegExp(r'[^\d]'), '');
                return cleanUser.isNotEmpty && cleanOrder == cleanUser;
              }
              return true;
            }).toList();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ĐƠN DỊCH VỤ TẬN PHÒNG',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips: Tất cả | Phòng hiện tại | Đơn theo SĐT
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('Tất cả (${allOrders.length})'),
                            selected: filterMode == 'all',
                            onSelected: (_) => setSheetState(() => filterMode = 'all'),
                            selectedColor: AppColors.primaryGold,
                            labelStyle: TextStyle(
                              color: filterMode == 'all' ? Colors.black : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: AppColors.userSurfaceDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text('$_selectedRoomName (${allOrders.where((o) => o.roomName == _selectedRoomName).length})'),
                            selected: filterMode == 'current_room',
                            onSelected: (_) => setSheetState(() => filterMode = 'current_room'),
                            selectedColor: AppColors.primaryGold,
                            labelStyle: TextStyle(
                              color: filterMode == 'current_room' ? Colors.black : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: AppColors.userSurfaceDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Đơn của tôi'),
                              selected: filterMode == 'my_phone',
                              onSelected: (_) => setSheetState(() => filterMode = 'my_phone'),
                              selectedColor: const Color(0xFF10B981),
                              labelStyle: TextStyle(
                                color: filterMode == 'my_phone' ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: AppColors.userSurfaceDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (filteredOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'Chưa có đơn dịch vụ nào theo bộ lọc.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final order = filteredOrders[index];
                            final isPreparing = order.status == 'preparing';
                            final isServed = order.status == 'served';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.userSurfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isServed
                                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                      : AppColors.userBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              order.roomName,
                                              style: const TextStyle(
                                                color: AppColors.primaryGold,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '• ${order.id}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isServed
                                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                              : isPreparing
                                                  ? AppColors.primaryGold.withValues(alpha: 0.2)
                                                  : Colors.redAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          order.statusLabel,
                                          style: TextStyle(
                                            color: isServed
                                                ? const Color(0xFF10B981)
                                                : isPreparing
                                                    ? AppColors.primaryGold
                                                    : Colors.redAccent,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Người đặt & Hình thức
                                  if (order.customerName != null && order.customerName!.isNotEmpty)
                                    Text(
                                      'Golfer: ${order.customerName} ${order.customerPhone != null ? "(${order.customerPhone})" : ""} • ${order.paymentMethodLabel}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 6),

                                  Text(
                                    order.summaryText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (order.note != null &&
                                      order.note!.isNotEmpty &&
                                      order.orderType == 'fnb_order') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ghi chú: ${order.note}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.totalPrice > 0
                                            ? Formatters.formatCurrency(order.totalPrice)
                                            : 'Miễn phí hỗ trợ',
                                        style: const TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (isPreparing)
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                provider.updateServiceOrderStatus(order.id, 'cancelled');
                                                setSheetState(() {});
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                minimumSize: Size.zero,
                                              ),
                                              child: const Text('Hủy đơn', style: TextStyle(fontSize: 11.5)),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                provider.updateServiceOrderStatus(order.id, 'served');
                                                setSheetState(() {});
                                              },
                                              icon: const Icon(Icons.check_rounded, size: 14),
                                              label: const Text('Đã nhận món', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                minimumSize: Size.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickCallWaiterSheet(
    BuildContext context,
    BookingProvider provider,
  ) {
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
                const Icon(
                  Icons.room_service_rounded,
                  color: AppColors.primaryGold,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  'GỌI NHÂN VIÊN TỚI $_selectedRoomName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhân viên lễ tân & kỹ thuật viên sẽ có mặt tại phòng trong vòng 1 phút.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/booking');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side: const BorderSide(color: AppColors.primaryGold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Gia hạn giờ chơi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.submitQuickRoomRequest(
                            roomName: _selectedRoomName,
                            requestTitle: 'Gọi nhân viên phục vụ trực tiếp',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã gửi tín hiệu gọi nhân viên tới $_selectedRoomName!',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Gọi Phục Vụ Ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showExtendBaySessionDialog(
    BuildContext context,
    BookingProvider provider,
    BookingModel booking,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16151D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.more_time_rounded, color: AppColors.primaryGold),
                SizedBox(width: 8),
                Text(
                  'Yêu Cầu Gia Hạn Phiên Chơi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Phiên chơi hiện tại: ${booking.timeSlot} tại ${booking.roomName}. Chọn thời lượng gia hạn tiếp:',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.submitQuickRoomRequest(
                        roomName: _selectedRoomName,
                        requestTitle: 'Yêu cầu gia hạn +30 phút phiên chơi tại $_selectedRoomName',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã gửi yêu cầu gia hạn +30 phút tới Quản lý Lounge!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGold,
                      side: const BorderSide(color: AppColors.primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+30 Phút (+250k)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.submitQuickRoomRequest(
                        roomName: _selectedRoomName,
                        requestTitle: 'Yêu cầu gia hạn +1 Giờ (60 phút) phiên chơi tại $_selectedRoomName',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã gửi yêu cầu gia hạn +1 Giờ tới Quản lý Lounge!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+1 Giờ (+450k)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
