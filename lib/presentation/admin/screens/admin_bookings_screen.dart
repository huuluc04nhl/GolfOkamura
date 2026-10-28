import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/status_badge.dart';

/// Màn hình Quản Lý Lịch Đặt Phòng & Đón Khách (GSM Booking Management)
/// Tập trung chuyên biệt vào quản lý lịch hẹn, tiếp đón check-in và thanh toán trả phòng
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';
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

    final pendingFnbCount = provider.serviceOrders
        .where((o) => o.status == 'preparing' || o.status == 'pending')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Quản lý Lịch Đặt Phòng
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'QUẢN LÝ LỊCH ĐẶT PHÒNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${allBookings.length} Lịch Đặt',
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Theo dõi lịch đặt chỗ trực tuyến từ Golfer, tiếp đón check-in và thanh toán phòng chơi.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/orders'),
                  icon: const Icon(Icons.room_service_rounded, size: 15),
                  label: Text(
                    pendingFnbCount > 0
                        ? 'Đơn Dịch Vụ ($pendingFnbCount mới) →'
                        : 'Quản Lý Đơn Dịch Vụ →',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pendingFnbCount > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF1E293B),
                    foregroundColor:
                        pendingFnbCount > 0 ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: pendingFnbCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF334155),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Khung tìm kiếm & Bảng dữ liệu Lịch đặt phòng
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
                    // Thanh tìm kiếm & Bộ lọc trạng thái đặt chỗ
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

                    // Bảng dữ liệu Lịch đặt phòng
                    Expanded(
                      child: _buildBookingsTable(provider, filteredBookings),
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
                                  content: Text(
                                    'Đã hoàn tất thanh toán đơn ${b.id}!',
                                  ),
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
                                  content: Text(
                                    'Đã hủy đơn đặt phòng ${b.id}!',
                                  ),
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
}
