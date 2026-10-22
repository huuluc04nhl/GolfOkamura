import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';

/// Màn hình GOLFZON Store Manager (GSM) — Báo Cáo & Thống Kê Doanh Thu Chi Tiết
class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  int _timeFilterIndex = 0; // 0: Tất cả, 1: Hôm nay, 2: Tháng này

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final rooms = provider.rooms;
    final allBookings = provider.bookings;
    final allOrders = provider.serviceOrders.where((o) => o.status != 'cancelled').toList();

    // Tính toán số liệu doanh thu
    final double totalRoomRevenue = allBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
    final double totalServiceRevenue = allOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
    final double grandTotalRevenue = totalRoomRevenue + totalServiceRevenue;

    // Doanh thu hôm nay (mô phỏng theo ngày hiện tại)
    final now = DateTime.now();
    final todayBookings = allBookings.where((b) {
      return b.bookingDate.year == now.year && b.bookingDate.month == now.month && b.bookingDate.day == now.day;
    }).toList();
    final double todayRoomRevenue = todayBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
    final double todayServiceRevenue = totalServiceRevenue * 0.35; // Tỷ trọng ngày ước tính
    final double todayTotalRevenue = todayRoomRevenue + todayServiceRevenue;

    // Tỷ lệ lấp đầy Bay hiện tại
    final activeBookingsCount = allBookings.where((b) => b.status == BookingStatus.confirmed).length;
    final double occupancyRate = rooms.isEmpty ? 0 : (activeBookingsCount / rooms.length) * 100;

    // Thống kê doanh thu theo từng Bay
    final Map<String, double> bayRevenueMap = {};
    for (final r in rooms) {
      double bayTotal = 0;
      for (final b in allBookings.where((b) => b.roomId == r.id)) {
        bayTotal += b.totalPrice;
      }
      for (final o in allOrders) {
        if (o.roomName.trim().toLowerCase() == r.name.trim().toLowerCase() ||
            o.roomName.trim().toLowerCase() == r.posName.trim().toLowerCase()) {
          bayTotal += o.totalPrice;
        }
      }
      bayRevenueMap[r.posName] = bayTotal;
    }
    final sortedBays = bayRevenueMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Thống kê Top Món & Dịch vụ bán chạy nhất
    final Map<String, int> itemQtyMap = {};
    final Map<String, double> itemRevenueMap = {};
    for (final o in allOrders) {
      for (final item in o.items) {
        final name = (item['name'] ?? '').toString();
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        itemQtyMap[name] = (itemQtyMap[name] ?? 0) + qty;
        itemRevenueMap[name] = (itemRevenueMap[name] ?? 0) + (price * qty);
      }
    }
    final topItems = itemRevenueMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Thống Kê & Bộ lọc thời gian (Wrap responsive tránh tràn viền mobile)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'TRUNG TÂM PHÂN TÍCH & THỐNG KÊ DOANH THU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Theo dõi doanh thu phòng Bay Golfzon, F&B ẩm thực và hiệu suất kinh doanh thời gian thực.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterPill(0, 'Tất cả'),
                        _buildFilterPill(1, 'Hôm nay'),
                        _buildFilterPill(2, 'Tháng này'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hàng 4 Thẻ KPI Doanh Thu Chính
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  final cardWidth = isNarrow
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 36) / 4;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildKpiCard(
                        width: cardWidth,
                        title: 'TỔNG DOANH THU',
                        value: Formatters.formatCurrency(
                          _timeFilterIndex == 1 ? todayTotalRevenue : grandTotalRevenue,
                        ),
                        subtitle: '${allBookings.length + allOrders.length} lượt giao dịch',
                        icon: Icons.payments_rounded,
                        accentColor: AppColors.primaryGold,
                        badgeText: '+18.5%',
                      ),
                      _buildKpiCard(
                        width: cardWidth,
                        title: 'DOANH THU BAY GOLFZON',
                        value: Formatters.formatCurrency(
                          _timeFilterIndex == 1 ? todayRoomRevenue : totalRoomRevenue,
                        ),
                        subtitle: '${allBookings.length} phiên chơi simulator',
                        icon: Icons.sports_golf_rounded,
                        accentColor: const Color(0xFF38BDF8),
                        badgeText: '${((totalRoomRevenue / (grandTotalRevenue == 0 ? 1 : grandTotalRevenue)) * 100).toInt()}% tổng thu',
                      ),
                      _buildKpiCard(
                        width: cardWidth,
                        title: 'DOANH THU F&B & DỊCH VỤ',
                        value: Formatters.formatCurrency(
                          _timeFilterIndex == 1 ? todayServiceRevenue : totalServiceRevenue,
                        ),
                        subtitle: '${allOrders.length} đơn ẩm thực & thuê đồ',
                        icon: Icons.restaurant_rounded,
                        accentColor: const Color(0xFF10B981),
                        badgeText: '${((totalServiceRevenue / (grandTotalRevenue == 0 ? 1 : grandTotalRevenue)) * 100).toInt()}% tổng thu',
                      ),
                      _buildKpiCard(
                        width: cardWidth,
                        title: 'TỶ LỆ LẤP ĐẦY BAY',
                        value: '${occupancyRate.toStringAsFixed(0)}%',
                        subtitle: '$activeBookingsCount/${rooms.length} Bay đang có khách',
                        icon: Icons.meeting_room_rounded,
                        accentColor: const Color(0xFFF59E0B),
                        badgeText: 'Live',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Bố cục 2 Cột: Bảng xếp hạng doanh thu từng Bay vs Top Món F&B
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTwoColumns = constraints.maxWidth >= 900;
                  if (!isTwoColumns) {
                    return Column(
                      children: [
                        _buildBayRevenueLeaderboard(sortedBays, grandTotalRevenue),
                        const SizedBox(height: 16),
                        _buildTopItemsLeaderboard(topItems, itemQtyMap),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột 1: Xếp hạng doanh thu theo Bay
                      Expanded(
                        flex: 5,
                        child: _buildBayRevenueLeaderboard(sortedBays, grandTotalRevenue),
                      ),
                      const SizedBox(width: 16),
                      // Cột 2: Top Món & Dịch vụ bán chạy nhất
                      Expanded(
                        flex: 5,
                        child: _buildTopItemsLeaderboard(topItems, itemQtyMap),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Bảng kê chi tiết các giao dịch / phiên chơi đã ghi nhận
              _buildRecentTransactionsTable(allBookings, allOrders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _timeFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _timeFilterIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBayRevenueLeaderboard(
    List<MapEntry<String, double>> sortedBays,
    double grandTotalRevenue,
  ) {
    final maxRevenue = sortedBays.isEmpty
        ? 1.0
        : (sortedBays.first.value == 0 ? 1.0 : sortedBays.first.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: AppColors.primaryGold, size: 20),
              SizedBox(width: 8),
              Text(
                'DOANH THU THEO PHÒNG BAY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Xếp hạng hiệu quả kinh doanh của các phòng Simulator trong hệ thống.',
            style: TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
          const SizedBox(height: 16),
          if (sortedBays.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có dữ liệu phòng', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ...sortedBays.take(6).map((entry) {
              final ratio = (entry.value / maxRevenue).clamp(0.05, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(entry.value),
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 7,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.key.contains('VIP')
                              ? AppColors.primaryGold
                              : const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopItemsLeaderboard(
    List<MapEntry<String, double>> topItems,
    Map<String, int> itemQtyMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'TOP MÓN & DỊCH VỤ SINH LỢI CAO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Các mặt hàng ẩm thực, đồ uống và đồ thuê có doanh số dẫn đầu.',
            style: TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
          const SizedBox(height: 16),
          if (topItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có order F&B', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ...topItems.take(5).map((entry) {
              final qty = itemQtyMap[entry.key] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.fastfood_rounded, color: Color(0xFF10B981), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Đã bán: $qty phần',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(entry.value),
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(
    List<BookingModel> bookings,
    List<ServiceOrderModel> orders,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_edu_rounded, color: AppColors.primaryGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'NHẬT KÝ DOANH THU & PHIÊN PHỤC VỤ GẦN ĐÂY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Tổng: ${bookings.length + orders.length} giao dịch',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
              columns: const [
                DataColumn(label: Text('Mã Phiên', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Phòng Bay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Khách hàng / Golfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Loại Giao Dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Thời Gian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Doanh Thu (VNĐ)', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Trạng Thái', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
              rows: [
                ...bookings.take(5).map((b) => DataRow(
                  cells: [
                    DataCell(Text(b.id, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(b.roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text(b.customerName, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(const Text('Phiên chơi Simulator', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12))),
                    DataCell(Text('${Formatters.formatDate(b.bookingDate)} • ${b.timeSlot}', style: const TextStyle(color: Colors.white60, fontSize: 11))),
                    DataCell(Text(Formatters.formatCurrency(b.totalPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Ghi nhận', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )),
                ...orders.take(5).map((o) => DataRow(
                  cells: [
                    DataCell(Text(o.id, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(o.roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text(o.note != null && o.note!.isNotEmpty ? 'Khách tại ${o.roomName} (${o.note})' : 'Khách tại ${o.roomName}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text('F&B (${o.items.length} món)', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12))),
                    DataCell(Text(Formatters.formatDateTime(o.createdAt), style: const TextStyle(color: Colors.white60, fontSize: 11))),
                    DataCell(Text(Formatters.formatCurrency(o.totalPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Ghi nhận', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
