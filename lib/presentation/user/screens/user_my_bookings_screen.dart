import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/services/storage_service.dart';
import '../../shared_widgets/golfer_vip_card.dart';
import '../../shared_widgets/language_selector_pill.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/vietqr_payment_dialog.dart';

/// Màn hình Quản lý Vé & Lịch sử đặt phòng của khách hàng
/// - Bộ lọc trạng thái vé trực tiếp (Tất cả, Đang giữ chỗ, Đã hủy)
/// - Chức năng Đổi ngày/giờ chơi (Reschedule) trực tiếp trên Firebase
/// - Chuyển thẳng sang Order F&B đúng phòng đã đặt & Sao chép mã vé Check-in
class UserMyBookingsScreen extends StatefulWidget {
  const UserMyBookingsScreen({super.key});

  @override
  State<UserMyBookingsScreen> createState() => _UserMyBookingsScreenState();
}

class _UserMyBookingsScreenState extends State<UserMyBookingsScreen> {
  final _searchPhoneController = TextEditingController();
  String _filterPhone = '';
  String _statusFilter = 'all'; // 'all', 'confirmed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final provider = context.read<BookingProvider>();
    final profile = await StorageService.loadCustomerProfile();
    var phone = profile['phone'] ?? '';
    if (phone.isEmpty && provider.currentGolfer.isCustomer) {
      phone = provider.currentGolfer.phone;
    }
    if (phone.isNotEmpty && mounted) {
      setState(() {
        _searchPhoneController.text = phone;
        _filterPhone = phone;
      });
    }
  }

  @override
  void dispose() {
    _searchPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final allBookings = provider.bookings;

    final displayedBookings = allBookings.where((b) {
      final matchesPhone = _filterPhone.trim().isEmpty ||
          b.customerPhone.contains(_filterPhone.trim()) ||
          b.customerName.toLowerCase().contains(
                _filterPhone.trim().toLowerCase(),
              );
      if (!matchesPhone) return false;
      if (_statusFilter == 'confirmed') {
        return b.status == BookingStatus.confirmed;
      }
      if (_statusFilter == 'cancelled') {
        return b.status == BookingStatus.cancelled;
      }
      return true;
    }).toList();

    final hPadding = Responsive.horizontalPadding(context);
    final safeBottom = Responsive.safeBottomPadding(context, extra: 16);

    return Scaffold(
      backgroundColor: AppColors.userBgDark,
      appBar: AppBar(
        title: Text(context.tr('my_bookings_title')),
        centerTitle: true,
        backgroundColor: AppColors.userBgDark,
        actions: const [
          LanguageSelectorPill(compact: true),
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Thanh tìm kiếm nhanh theo số điện thoại hoặc tên khách
            Padding(
              padding: EdgeInsets.fromLTRB(hPadding, 10, hPadding, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.userCardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.userBorder),
                ),
                child: TextField(
                  controller: _searchPhoneController,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tra cứu theo SĐT hoặc họ tên Quý khách...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    icon: const Icon(
                      Icons.search,
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                    suffixIcon: _searchPhoneController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchPhoneController.clear();
                                _filterPhone = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filterPhone = val;
                    });
                  },
                ),
              ),
            ),

            // Bộ lọc trạng thái vé trực tiếp dạng cuộn ngang êm ái
            Padding(
              padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildStatusFilterChip('all', 'Tất cả (${allBookings.length})'),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(
                      'confirmed',
                      'Đang giữ chỗ (${allBookings.where((b) => b.status == BookingStatus.confirmed).length})',
                    ),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(
                      'cancelled',
                      'Đã hủy (${allBookings.where((b) => b.status == BookingStatus.cancelled).length})',
                    ),
                  ],
                ),
              ),
            ),

            // Thẻ Hạng Hội Viên Golfer VIP hoặc Banner Khách Vãng Lai
            if (provider.isGuest)
              Padding(
                padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C31),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Duyệt với tư cách Khách Vãng Lai',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Đăng nhập để tích lũy điểm thưởng VIP, hưởng ưu đãi giờ chơi và lưu mã QR vé.',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 4),
                child: GolferVipCard(
                  golfer: provider.currentGolfer,
                  onEditProfile: () => GolferVipCard.showEditGolferDialog(context, provider),
                ),
              ),

            // Danh sách vé đặt phòng thực tế: Hỗ trợ vuốt xuống làm mới & vuốt ngang thẻ vé
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGold,
                backgroundColor: AppColors.userCardDark,
                onRefresh: () => provider.refreshFromFirebase(),
                child: displayedBookings.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          hPadding,
                          8,
                          hPadding,
                          safeBottom,
                        ),
                        itemCount: displayedBookings.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final booking = displayedBookings[index];
                          final isCancelled =
                              booking.status == BookingStatus.cancelled;
                          return Dismissible(
                            key: ValueKey(
                              '${booking.id}_${booking.status.name}',
                            ),
                            direction: isCancelled
                                ? DismissDirection.none
                                : DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _showQRCodeDialog(context, booking);
                                return false;
                              } else {
                                _confirmCancelBooking(context, booking);
                                return false;
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_rounded,
                                    color: AppColors.primaryGold,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mở QR Check-in',
                                    style: TextStyle(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Hủy đặt phòng',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                            child: _buildBookingTicketCard(context, booking),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final active = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGold : AppColors.userCardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primaryGold : AppColors.userBorder,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Trạng thái khi chưa có đơn nào
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.userSurfaceDark,
                border: Border.all(color: AppColors.userBorder),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có đơn đặt phòng nào',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các vé đặt phòng thực tế của bạn sẽ xuất hiện tại đây kèm mã QR check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/booking'),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Đặt phòng ngay',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ vé Golfzon sang trọng phong cách Boarding Pass
  Widget _buildBookingTicketCard(BuildContext context, BookingModel booking) {
    final isCancelled = booking.status == BookingStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.userCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? AppColors.userBorder
              : AppColors.primaryGold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Phần đầu vé
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_golf,
                          color: AppColors.primaryGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.id,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    BookingStatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  booking.roomName,
                  style: TextStyle(
                    color:
                        isCancelled ? AppColors.textMuted : AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatDayOfWeek(booking.bookingDate),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.timeSlot,
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.customerName} - ${booking.customerPhone}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ghi chú: ${booking.notes}',
                    style: const TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Đường đục lỗ vé Boarding Pass
          _buildTicketDivider(),

          // Phần đuôi vé: Giá tiền, Đổi giờ, Order F&B, Mã QR Check-in và Nút hủy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng chi phí:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      Formatters.formatCurrency(booking.totalPrice),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isCancelled)
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nút Đổi giờ chơi trực tiếp trên Cloud
                          InkWell(
                            onTap: () => _showRescheduleSheet(context, booking),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.userSurfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.userBorder),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 14,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đổi giờ',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Nút Gọi dịch vụ đúng phòng của vé
                          InkWell(
                            onTap: () {
                              context
                                  .read<BookingProvider>()
                                  .selectRoomForService(booking.roomName);
                              context.go('/services');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.userSurfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.userBorder),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.room_service_outlined,
                                    size: 14,
                                    color: AppColors.primaryGold,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Order F&B',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showQRCodeDialog(context, booking),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 14,
                                    color: AppColors.primaryGold,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'QR Vé',
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
                          const SizedBox(width: 6),
                          // Nút Thanh toán VietQR động
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => VietQrPaymentDialog(
                                  bookingId: booking.id,
                                  roomName: booking.roomName,
                                  amount: booking.totalPrice,
                                  customerName: booking.customerName,
                                  onPaymentConfirmed: () async {
                                    final prov = context.read<BookingProvider>();
                                    await prov.completeBooking(booking.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã xác nhận thanh toán thành công cho mã ${booking.id}!'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'VietQR',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Hủy vé này',
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AppColors.statusBooked,
                              size: 20,
                            ),
                            onPressed: () =>
                                _confirmCancelBooking(context, booking),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () =>
                        context.read<BookingProvider>().deleteBooking(booking.id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Xóa vé',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Đường đục lỗ chia nửa thẻ vé
  Widget _buildTicketDivider() {
    return Row(
      children: [
        Container(
          width: 10,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.userBgDark,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount =
                  (constraints.constrainWidth() / (dashWidth + dashSpace))
                      .floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  dashCount,
                  (_) => const SizedBox(
                    width: dashWidth,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.userBorder),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 10,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.userBgDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  /// Bảng Đổi Ngày & Khung Giờ Chơi trực tiếp trên Firebase
  void _showRescheduleSheet(BuildContext context, BookingModel booking) {
    DateTime tempDate = booking.bookingDate;
    String tempSlot = booking.timeSlot;
    final now = DateTime.now();
    final upcomingDates = List.generate(14, (i) => now.add(Duration(days: i)));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.userCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ĐỔI LỊCH CHƠI • ${booking.roomName}',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: upcomingDates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final d = upcomingDates[idx];
                          final selected = tempDate.year == d.year &&
                              tempDate.month == d.month &&
                              tempDate.day == d.day;
                          return InkWell(
                            onTap: () => setModalState(() => tempDate = d),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 58,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryGold
                                    : AppColors.userSurfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primaryGold
                                      : AppColors.userBorder,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${d.day}/${d.month}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    idx == 0
                                        ? 'H.nay'
                                        : Formatters.formatDayOfWeek(d)
                                            .split(',')[0],
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.black87
                                          : AppColors.textMuted,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.standardTimeSlots.map((slot) {
                        final selected = tempSlot == slot;
                        return ChoiceChip(
                          label: Text(
                            slot,
                            style: TextStyle(
                              color:
                                  selected ? Colors.black : AppColors.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setModalState(() => tempSlot = slot),
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: AppColors.userSurfaceDark,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await context
                              .read<BookingProvider>()
                              .rescheduleBooking(
                                bookingId: booking.id,
                                newDate: tempDate,
                                newTimeSlot: tempSlot,
                              );
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Đã đổi lịch sang $tempSlot (${Formatters.formatDate(tempDate)}) & đồng bộ Firebase!'
                                    : 'Khung giờ này đã có người đặt hoặc đang bảo trì!',
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF10B981)
                                  : Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text(
                          'LƯU LỊCH MỚI LÊN CLOUD',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      },
    );
  }

  /// Hiển thị mã QR Check-in tại quầy lễ tân (kèm nút Sao chép mã vé)
  void _showQRCodeDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.userCardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
          ),
          title: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.sports_golf,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
                const SizedBox(height: 6),
                const Text(
                  'MÃ CHECK-IN TẠI QUẦY',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.id,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 160, color: Colors.black),
                    const SizedBox(height: 6),
                    Text(
                      booking.id,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Phòng: ${booking.roomName}\nGiờ: ${booking.timeSlot} (${Formatters.formatDate(booking.bookingDate)})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: booking.id));
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép mã vé ${booking.id}!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.primaryGold,
              ),
              label: const Text(
                'Sao chép mã',
                style: TextStyle(color: AppColors.primaryGold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Xác nhận hủy đặt phòng
  void _confirmCancelBooking(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.userCardDark,
          title: const Text(
            'Xác nhận hủy đặt phòng?',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn hủy đơn đặt ${booking.roomName} lúc ${booking.timeSlot} ngày ${Formatters.formatDate(booking.bookingDate)}?\nKhung giờ này sẽ được giải phóng cho khách khác.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Không hủy',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final provider = context.read<BookingProvider>();
                await provider.cancelBooking(booking.id);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã hủy đơn đặt phòng thành công. Khung giờ đã được giải phóng.',
                    ),
                    backgroundColor: AppColors.statusBooked,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusBooked,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận Hủy'),
            ),
          ],
        );
      },
    );
  }
}
