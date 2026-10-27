import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';

/// Màn hình Trung Tâm Điều Phối & Quản Lý Đơn Dịch Vụ Tận Phòng (Service Orders Dispatch Hub)
/// Đóng vai trò là bộ não điều hành 2 chiều giữa Khách Hàng (User App) và Quản trị viên (Admin Workflow)
class AdminServiceOrdersScreen extends StatefulWidget {
  final String? initialRoomFilter;

  const AdminServiceOrdersScreen({super.key, this.initialRoomFilter});

  @override
  State<AdminServiceOrdersScreen> createState() =>
      _AdminServiceOrdersScreenState();
}

class _AdminServiceOrdersScreenState extends State<AdminServiceOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _statusFilter = 'all'; // all, pending, processing, delivering, served, cancelled
  String _roomFilter = 'all'; // all, hoặc roomName cụ thể
  final String _typeFilter = 'all'; // all, fnb_order, quick_request

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomFilter != null &&
        widget.initialRoomFilter!.isNotEmpty) {
      _roomFilter = widget.initialRoomFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final allOrders = provider.serviceOrders;

    // Lọc danh sách theo các tiêu chí điều hành
    final filteredOrders = allOrders.where((order) {
      // Lọc trạng thái
      if (_statusFilter != 'all') {
        if (_statusFilter == 'pending') {
          if (order.status != 'pending' && order.status != 'preparing') {
            return false;
          }
        } else if (order.status != _statusFilter) {
          return false;
        }
      }

      // Lọc phòng
      if (_roomFilter != 'all') {
        if (order.roomName.trim().toLowerCase() !=
            _roomFilter.trim().toLowerCase()) {
          return false;
        }
      }

      // Lọc loại đơn
      if (_typeFilter != 'all') {
        if (order.orderType != _typeFilter) return false;
      }

      // Lọc từ khóa tìm kiếm
      if (_searchKeyword.isNotEmpty) {
        final q = _searchKeyword.toLowerCase();
        final matchId = order.id.toLowerCase().contains(q);
        final matchRoom = order.roomName.toLowerCase().contains(q);
        final matchCustomer =
            (order.customerName ?? '').toLowerCase().contains(q);
        final matchPhone = (order.customerPhone ?? '').contains(q);
        final matchSummary = order.summaryText.toLowerCase().contains(q);
        final matchNote = (order.note ?? '').toLowerCase().contains(q);
        return matchId ||
            matchRoom ||
            matchCustomer ||
            matchPhone ||
            matchSummary ||
            matchNote;
      }

      return true;
    }).toList();

    // Sắp xếp đơn: Đơn chờ xử lý lên trước, tiếp đến thời gian tạo mới nhất
    filteredOrders.sort((a, b) {
      final aPriority = (a.status == 'pending' || a.status == 'preparing')
          ? 0
          : a.status == 'processing'
              ? 1
              : a.status == 'delivering'
                  ? 2
                  : 3;
      final bPriority = (b.status == 'pending' || b.status == 'preparing')
          ? 0
          : b.status == 'processing'
              ? 1
              : b.status == 'delivering'
                  ? 2
                  : 3;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return b.createdAt.compareTo(a.createdAt);
    });

    // Thống kê nhanh KPI
    final totalOrdersCount = allOrders.length;
    final pendingCount = allOrders
        .where((o) => o.status == 'pending' || o.status == 'preparing')
        .length;
    final processingCount =
        allOrders.where((o) => o.status == 'processing').length;
    final deliveringCount =
        allOrders.where((o) => o.status == 'delivering').length;
    final servedCount = allOrders.where((o) => o.status == 'served').length;

    double todayFnbRevenue = 0;
    for (final o in allOrders) {
      if (o.status == 'served') {
        todayFnbRevenue += o.totalPrice;
      }
    }

    // Danh sách các phòng từ danh sách phòng hiện có
    final roomOptions = <String>['all'];
    for (final r in provider.rooms) {
      if (!roomOptions.contains(r.name)) roomOptions.add(r.name);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D18),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header & Điều phối hành động
            _buildHeader(context, provider, pendingCount),
            const SizedBox(height: 16),

            // 2. Ribbon chỉ số điều phối vận hành (KPI Ribbon)
            _buildKpiRibbon(
              totalCount: totalOrdersCount,
              pendingCount: pendingCount,
              processingCount: processingCount,
              deliveringCount: deliveringCount,
              servedCount: servedCount,
              revenue: todayFnbRevenue,
            ),
            const SizedBox(height: 16),

            // 3. Khung bảng điều khiển & Bộ lọc
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh tìm kiếm và bộ lọc đa tầng
                    _buildFilterToolbar(roomOptions),
                    const SizedBox(height: 14),

                    // Danh sách đơn hàng
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? _buildEmptyState()
                          : _buildOrdersList(provider, filteredOrders),
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

  /// 1. Header chính
  Widget _buildHeader(
      BuildContext context, BookingProvider provider, int pendingCount) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.room_service_rounded,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ĐIỀU PHỐI ĐƠN DỊCH VỤ & F&B TẬN PHÒNG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFEF4444),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$pendingCount đơn cần phục vụ',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Luồng tiếp nhận thời gian thực trực tiếp từ App Khách Hàng tại các phòng bay, phục vụ ẩm thực, set gậy và yêu cầu hỗ trợ.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút Đồng bộ lại từ Firebase
            OutlinedButton.icon(
              onPressed: provider.isSyncingFirebase
                  ? null
                  : () async {
                      await provider.refreshFromFirebase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Đã đồng bộ đơn hàng mới nhất từ Firebase!'),
                            backgroundColor: Color(0xFF10B981),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: Icon(
                provider.isSyncingFirebase
                    ? Icons.sync
                    : Icons.refresh_rounded,
                size: 16,
                color: AppColors.primaryGold,
              ),
              label: Text(
                provider.isSyncingFirebase ? 'Đang đồng bộ...' : 'Làm mới đơn',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF334155)),
                backgroundColor: const Color(0xFF1E293B),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Nút Tạo đơn phục vụ mới tại quầy
            ElevatedButton.icon(
              onPressed: () => _showCreateOrderDialog(context, provider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                '+ Đặt món cho phòng',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. KPI Ribbon
  Widget _buildKpiRibbon({
    required int totalCount,
    required int pendingCount,
    required int processingCount,
    required int deliveringCount,
    required int servedCount,
    required double revenue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'TỔNG ĐƠN HÔM NAY',
              value: '$totalCount đơn',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF94A3B8),
              width: isSmall ? (constraints.maxWidth - 12) / 2 : 160,
            ),
            _buildKpiCard(
              title: 'CHỜ TIẾP NHẬN',
              value: '$pendingCount đơn',
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFFF59E0B),
              highlight: pendingCount > 0,
              width: isSmall ? (constraints.maxWidth - 12) / 2 : 160,
            ),
            _buildKpiCard(
              title: 'ĐANG CHUẨN BỊ',
              value: '$processingCount đơn',
              icon: Icons.blender_rounded,
              color: const Color(0xFF38BDF8),
              width: isSmall ? (constraints.maxWidth - 12) / 2 : 160,
            ),
            _buildKpiCard(
              title: 'ĐANG GIAO PHÒNG',
              value: '$deliveringCount đơn',
              icon: Icons.delivery_dining_rounded,
              color: const Color(0xFF818CF8),
              width: isSmall ? (constraints.maxWidth - 12) / 2 : 160,
            ),
            _buildKpiCard(
              title: 'ĐÃ PHỤC VỤ XONG',
              value: '$servedCount đơn',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              width: isSmall ? (constraints.maxWidth - 12) / 2 : 160,
            ),
            _buildKpiCard(
              title: 'DOANH THU DỊCH VỤ',
              value: Formatters.formatCurrency(revenue),
              icon: Icons.monetization_on_rounded,
              color: AppColors.primaryGold,
              width: isSmall ? constraints.maxWidth : 210,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
    bool highlight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.12)
            : const Color(0xFF111C33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? color : const Color(0xFF1E293B),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Thanh công cụ tìm kiếm và bộ lọc
  Widget _buildFilterToolbar(List<String> roomOptions) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Tìm kiếm
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm theo Mã đơn, Golfer, SĐT, Tên món...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primaryGold,
                size: 18,
              ),
              suffixIcon: _searchKeyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchKeyword = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF090D18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF26354D)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) => setState(() => _searchKeyword = val.trim()),
          ),
        ),

        // Lọc theo phòng
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF090D18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF26354D)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _roomFilter,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.primaryGold, size: 20),
              items: roomOptions.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r == 'all' ? 'Tất cả phòng' : r),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _roomFilter = val);
              },
            ),
          ),
        ),

        // Chips trạng thái
        ...[
          {'id': 'all', 'label': 'Tất cả'},
          {'id': 'pending', 'label': 'Chờ tiếp nhận'},
          {'id': 'processing', 'label': 'Đang chuẩn bị'},
          {'id': 'delivering', 'label': 'Đang giao'},
          {'id': 'served', 'label': 'Đã hoàn tất'},
          {'id': 'cancelled', 'label': 'Đã hủy'},
        ].map((f) {
          final isSelected = _statusFilter == f['id'];
          return ChoiceChip(
            label: Text(f['label']!),
            selected: isSelected,
            selectedColor: AppColors.primaryGold,
            backgroundColor: const Color(0xFF090D18),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
            onSelected: (_) => setState(() => _statusFilter = f['id']!),
          );
        }),
      ],
    );
  }

  /// 4. Danh sách đơn hàng
  Widget _buildOrdersList(
      BookingProvider provider, List<ServiceOrderModel> orders) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final order = orders[index];
        return _buildOrderCard(context, provider, order);
      },
    );
  }

  /// 5. Thẻ đơn hàng điều hành chuyên sâu
  Widget _buildOrderCard(
      BuildContext context, BookingProvider provider, ServiceOrderModel order) {
    final isPending = order.isPending;
    final isProcessing = order.isProcessing;
    final isDelivering = order.isDelivering;
    final isServed = order.isServed;
    final isCancelled = order.isCancelled;

    Color statusColor;
    IconData statusIcon;
    if (isServed) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (isDelivering) {
      statusColor = const Color(0xFF818CF8);
      statusIcon = Icons.delivery_dining_rounded;
    } else if (isProcessing) {
      statusColor = const Color(0xFF38BDF8);
      statusIcon = Icons.blender_rounded;
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_top_rounded;
    }

    final diffMinutes = DateTime.now().difference(order.createdAt).inMinutes;
    final timeAgo = diffMinutes < 1
        ? 'Vừa xong'
        : diffMinutes < 60
            ? '$diffMinutes phút trước'
            : '${(diffMinutes / 60).floor()} giờ trước';

    final isLongWaiting = isPending && diffMinutes >= 10;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLongWaiting
              ? const Color(0xFFEF4444)
              : isPending
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                  : const Color(0xFF1E293B),
          width: isLongWaiting ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ Header: Tên phòng, Mã đơn, Trạng thái, Thời gian
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF1E293B),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icon trạng thái
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
                const SizedBox(width: 10),

                // Tên phòng bay & Mã đơn
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        order.roomName,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${order.id}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $timeAgo',
                        style: TextStyle(
                          color: isLongWaiting
                              ? const Color(0xFFEF4444)
                              : Colors.white54,
                          fontSize: 11.5,
                          fontWeight: isLongWaiting
                              ? FontWeight.w900
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge Trạng thái
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body thông tin: Khách hàng + Món gọi + Ghi chú
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khách hàng & Hình thức thanh toán
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: Colors.white60),
                    const SizedBox(width: 6),
                    Text(
                      order.customerName != null &&
                              order.customerName!.isNotEmpty
                          ? '${order.customerName} ${order.customerPhone != null && order.customerPhone!.isNotEmpty ? "(${order.customerPhone})" : ""}'
                          : 'Khách tại phòng bay (Vãng lai)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.paymentMethod == 'vietqr'
                                ? Icons.qr_code_2_rounded
                                : Icons.tab_rounded,
                            size: 12,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentMethodLabel,
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Danh sách các món ăn/dịch vụ
                if (order.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      children: order.items.map((item) {
                        final name = (item['name'] ?? '').toString();
                        final qty = item['qty'] ?? 1;
                        final price = (item['price'] is num)
                            ? (item['price'] as num).toDouble()
                            : double.tryParse(item['price']?.toString() ?? '0') ??
                                0;
                        final itemTotal = price * qty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${qty}x',
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(itemTotal),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Ghi chú của khách hàng
                if (order.note != null && order.note!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yêu cầu đặc biệt: ${order.note}',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Dòng tổng tiền & Luồng thao tác chuyển trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TỔNG TIỀN DỊCH VỤ',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(order.totalPrice),
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    // Nhóm nút tương tác 1 chạm luồng Admin <-> Khách
                    _buildOrderActions(context, provider, order),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nút tương tác quy trình nghiệp vụ 1 chạm
  Widget _buildOrderActions(
      BuildContext context, BookingProvider provider, ServiceOrderModel order) {
    if (order.isPending) {
      return Wrap(
        spacing: 8,
        children: [
          // Nút Hủy đơn
          OutlinedButton(
            onPressed: () => _confirmCancelOrder(context, provider, order),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hủy đơn', style: TextStyle(fontSize: 11.5)),
          ),

          // Nút Tiếp nhận (Chuẩn bị / chế biến)
          ElevatedButton.icon(
            onPressed: () async {
              await provider.updateServiceOrderStatus(order.id, 'processing');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã tiếp nhận đơn ${order.id}. Bếp & Bar bắt đầu chuẩn bị!'),
                    backgroundColor: const Color(0xFF38BDF8),
                  ),
                );
              }
            },
            icon: const Icon(Icons.soup_kitchen_rounded, size: 14),
            label: const Text(
              'Tiếp nhận & Chuẩn bị',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Nút Giao phòng ngay
          ElevatedButton.icon(
            onPressed: () async {
              await provider.updateServiceOrderStatus(order.id, 'served');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã giao xong đơn ${order.id} tới ${order.roomName}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 14),
            label: const Text(
              'Giao xong ngay',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }

    if (order.isProcessing) {
      return Wrap(
        spacing: 8,
        children: [
          // Chuyển sang đang giao
          ElevatedButton.icon(
            onPressed: () async {
              await provider.updateServiceOrderStatus(order.id, 'delivering');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đang mang món đơn ${order.id} đến ${order.roomName}!'),
                    backgroundColor: const Color(0xFF818CF8),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delivery_dining_rounded, size: 14),
            label: const Text(
              'Bắt đầu giao phòng',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF818CF8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Xác nhận hoàn tất
          ElevatedButton.icon(
            onPressed: () async {
              await provider.updateServiceOrderStatus(order.id, 'served');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã phục vụ hoàn tất đơn ${order.id} tại ${order.roomName}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 14),
            label: const Text(
              'Đã giao xong',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }

    if (order.isDelivering) {
      return ElevatedButton.icon(
        onPressed: () async {
          await provider.updateServiceOrderStatus(order.id, 'served');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Đã xác nhận phục vụ hoàn tất đơn ${order.id} tại ${order.roomName}!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        },
        icon: const Icon(Icons.check_rounded, size: 14),
        label: const Text(
          'Xác nhận đã giao tới phòng',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    // Đã phục vụ hoặc Đã hủy
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Xóa đơn khỏi hệ thống',
          onPressed: () async {
            await provider.deleteServiceOrder(order.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã dọn dẹp đơn ${order.id}!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.white38, size: 18),
        ),
      ],
    );
  }

  /// Hộp thoại xác nhận hủy đơn
  void _confirmCancelOrder(
      BuildContext context, BookingProvider provider, ServiceOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Xác nhận hủy đơn phục vụ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn #${order.id} của ${order.roomName}?\nThao tác này sẽ đồng bộ ngay lập tức lên ứng dụng của Golfer.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Quay lại', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateServiceOrderStatus(order.id, 'cancelled');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã hủy đơn ${order.id}!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  /// Trạng thái trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.room_service_outlined,
              size: 48,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Không tìm thấy đơn dịch vụ nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thử thay đổi bộ lọc phòng, trạng thái hoặc kiểm tra kết nối Firebase.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại Tạo đơn phục vụ nhanh cho phòng từ Admin
  void _showCreateOrderDialog(BuildContext context, BookingProvider provider) {
    String selectedRoom = provider.rooms.isNotEmpty
        ? provider.rooms.first.name
        : 'Room 1 (Standard)';
    final Map<String, int> orderCart = {};
    final noteCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            double totalCartPrice = 0;
            for (final entry in orderCart.entries) {
              final item = provider.serviceItems.firstWhere(
                (i) => i.id == entry.key,
                orElse: () => provider.serviceItems.first,
              );
              totalCartPrice += item.price * entry.value;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF26354D)),
              ),
              title: Row(
                children: const [
                  Icon(Icons.add_shopping_cart_rounded,
                      color: AppColors.primaryGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TẠO ĐƠN DỊCH VỤ / F&B TẬN PHÒNG',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chọn phòng bay
                      const Text(
                        'Phòng nhận phục vụ:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090D18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF26354D)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedRoom,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            items: provider.rooms.map((r) {
                              return DropdownMenuItem<String>(
                                value: r.name,
                                child: Text(r.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedRoom = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Thông tin Golfer (không bắt buộc)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Tên khách (nếu có)',
                                labelStyle: TextStyle(
                                    color: Colors.white54, fontSize: 11),
                                filled: true,
                                fillColor: Color(0xFF090D18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'SĐT khách (nếu có)',
                                labelStyle: TextStyle(
                                    color: Colors.white54, fontSize: 11),
                                filled: true,
                                fillColor: Color(0xFF090D18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chọn món từ Menu
                      const Text(
                        'Thực đơn & Đồ uống:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090D18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: ListView.separated(
                          itemCount: provider.serviceItems.length,
                          separatorBuilder: (_, _) => const Divider(
                            color: Color(0xFF1E293B),
                            height: 1,
                          ),
                          itemBuilder: (_, i) {
                            final item = provider.serviceItems[i];
                            final qty = orderCart[item.id] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(item.iconData,
                                      size: 16, color: item.accentColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(item.price),
                                          style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (qty == 0)
                                    TextButton(
                                      onPressed: () {
                                        setDialogState(
                                            () => orderCart[item.id] = 1);
                                      },
                                      child: const Text('+ Thêm',
                                          style: TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 12)),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setDialogState(() {
                                              if (qty <= 1) {
                                                orderCart.remove(item.id);
                                              } else {
                                                orderCart[item.id] = qty - 1;
                                              }
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                              color: Colors.white60),
                                        ),
                                        Text(
                                          '$qty',
                                          style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setDialogState(() {
                                              orderCart[item.id] = qty + 1;
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                              color: AppColors.primaryGold),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ghi chú
                      TextField(
                        controller: noteCtrl,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText:
                              'Ghi chú pha chế / phục vụ (VD: Ít đá, mang thêm ly...)',
                          hintStyle:
                              TextStyle(color: Colors.white38, fontSize: 11.5),
                          filled: true,
                          fillColor: Color(0xFF090D18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: orderCart.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await provider.submitServiceOrder(
                            roomName: selectedRoom,
                            cartQuantities: orderCart,
                            customerName: nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim()
                                : null,
                            customerPhone: phoneCtrl.text.trim().isNotEmpty
                                ? phoneCtrl.text.trim()
                                : null,
                            note: noteCtrl.text.trim().isNotEmpty
                                ? noteCtrl.text.trim()
                                : null,
                            paymentMethod: 'pay_at_bay',
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Đã tạo đơn dịch vụ cho $selectedRoom thành công!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Xác nhận tạo đơn (${Formatters.formatCurrency(totalCartPrice)})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
