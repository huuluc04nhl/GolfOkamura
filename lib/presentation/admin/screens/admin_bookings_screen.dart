import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/status_badge.dart';

/// Màn hình Quản lý Lịch Đặt Phòng (GSM Reservations) & Điều phối Bếp/Bar (KDS Service Queue)
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';
  int _activeTab = 0; // 0: Đơn đặt phòng GSM, 1: Điều phối Bếp/Bar KDS
  String _bookingStatusFilter = 'all'; // all, confirmed, completed, cancelled

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final allBookings = provider.bookings;
    final allOrders = provider.serviceOrders;

    final filteredBookings = allBookings.where((b) {
      if (_bookingStatusFilter != 'all' &&
          b.status.name != _bookingStatusFilter) {
        return false;
      }
      if (_searchKeyword.isEmpty) return true;
      final query = _searchKeyword.toLowerCase();
      return b.id.toLowerCase().contains(query) ||
          b.customerName.toLowerCase().contains(query) ||
          b.customerPhone.contains(query) ||
          b.roomName.toLowerCase().contains(query);
    }).toList();

    final filteredOrders = allOrders.where((o) {
      if (_searchKeyword.isEmpty) return true;
      final query = _searchKeyword.toLowerCase();
      return o.id.toLowerCase().contains(query) ||
          o.roomName.toLowerCase().contains(query) ||
          o.summaryText.toLowerCase().contains(query);
    }).toList();

    final pendingFnbCount =
        allOrders.where((o) => o.status == 'preparing').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header & Chuyển đổi giữa Lịch Đặt Phòng GSM và Điều phối Bếp/Bar KDS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'QUẢN LÝ LỊCH ĐẶT (GSM) & ĐIỀU PHỐI BẾP/BAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Theo dõi vé đặt phòng từ App Khách, thanh toán trả phòng và xử lý order F&B thời gian thực.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegmentButton(
                      index: 0,
                      icon: Icons.calendar_month_rounded,
                      label: 'Đơn Đặt Phòng (${allBookings.length})',
                    ),
                    const SizedBox(width: 8),
                    _buildSegmentButton(
                      index: 1,
                      icon: Icons.room_service_rounded,
                      label: 'Bếp / Bar & Dịch vụ (${allOrders.length})',
                      badge: pendingFnbCount > 0 ? '$pendingFnbCount chờ' : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Khung tìm kiếm & Bảng dữ liệu
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C31),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh tìm kiếm & Bộ lọc trạng thái
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 380,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Tìm theo Mã đơn, Tên khách, SĐT hoặc Phòng...',
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primaryGold,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF26354D),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (val) =>
                                setState(() => _searchKeyword = val.trim()),
                          ),
                        ),
                        if (_activeTab == 0)
                          ...[
                            {'id': 'all', 'label': 'Tất cả'},
                            {'id': 'confirmed', 'label': 'Đang mở / Đã đặt'},
                            {'id': 'completed', 'label': 'Đã thanh toán'},
                            {'id': 'cancelled', 'label': 'Đã hủy'},
                          ].map((f) {
                            final selected = _bookingStatusFilter == f['id'];
                            return ChoiceChip(
                              label: Text(f['label']!),
                              selected: selected,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: selected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                              onSelected: (_) => setState(
                                () => _bookingStatusFilter = f['id']!,
                              ),
                            );
                          }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nội dung bảng theo Tab
                    Expanded(
                      child: _activeTab == 0
                          ? _buildBookingsTable(provider, filteredBookings)
                          : _buildServiceOrdersList(provider, filteredOrders),
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

  Widget _buildSegmentButton({
    required int index,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : const Color(0xFF151F32),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFF26354D),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryGold : Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTable(
    BookingProvider provider,
    List<BookingModel> filtered,
  ) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy đơn đặt phòng nào phù hợp.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
          columns: const [
            DataColumn(label: Text('Mã đơn')),
            DataColumn(label: Text('Khách hàng')),
            DataColumn(label: Text('Số điện thoại')),
            DataColumn(label: Text('Phòng / Bay')),
            DataColumn(label: Text('Ngày chơi')),
            DataColumn(label: Text('Khung giờ')),
            DataColumn(label: Text('Tiền phòng')),
            DataColumn(label: Text('Trạng thái')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: filtered.map((b) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    b.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightGold,
                    ),
                  ),
                ),
                DataCell(Text(b.customerName)),
                DataCell(Text(b.customerPhone)),
                DataCell(
                  Text(
                    b.roomName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(Text(Formatters.formatDate(b.bookingDate))),
                DataCell(Text(b.timeSlot)),
                DataCell(
                  Text(
                    Formatters.formatCurrency(b.totalPrice),
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DataCell(BookingStatusBadge(status: b.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (b.status == BookingStatus.confirmed) ...[
                        TextButton(
                          onPressed: () async {
                            await provider.completeBooking(b.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã hoàn tất thanh toán đơn ${b.id}!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Thanh toán',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await provider.cancelBooking(b.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã hủy đơn đặt phòng ${b.id}!'),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Hủy đơn',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      ] else
                        TextButton(
                          onPressed: () async {
                            await provider.deleteBooking(b.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa vĩnh viễn đơn ${b.id}!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Xóa đơn',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceOrdersList(
    BookingProvider provider,
    List<ServiceOrderModel> orders,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có đơn gọi món F&B hoặc yêu cầu hỗ trợ phòng nào.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final order = orders[index];
        final isPreparing = order.status == 'preparing';
        final isServed = order.status == 'served';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPreparing
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : const Color(0xFF1E293B),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPreparing
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  order.orderType == 'quick_request'
                      ? Icons.support_agent_rounded
                      : Icons.restaurant_menu_rounded,
                  color: isPreparing
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.roomName,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Mã: ${order.id}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.summaryText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (order.note != null && order.note!.isNotEmpty)
                      Text(
                        'Ghi chú: ${order.note}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                Formatters.formatCurrency(order.totalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 14),
              if (isPreparing) ...[
                ElevatedButton(
                  onPressed: () =>
                      provider.updateServiceOrderStatus(order.id, 'served'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Giao xong',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () =>
                      provider.updateServiceOrderStatus(order.id, 'cancelled'),
                  child: const Text(
                    'Hủy món',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isServed
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: isServed
                          ? const Color(0xFF34D399)
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa đơn khỏi Firebase',
                  onPressed: () async {
                    await provider.deleteServiceOrder(order.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa đơn dịch vụ ${order.id}!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
