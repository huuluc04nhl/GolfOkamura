import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';
import 'dashboard_widgets/fnb_menu_grid.dart';
import 'dashboard_widgets/golf_services_grid.dart';
import 'dashboard_widgets/gsm_timeline_view.dart';

/// Màn hình Trung tâm Điều hành & Quản trị Vận hành Tổ hợp Golf (Admin Operations & Facility Workflow Hub)
/// Tập trung vào luồng nghiệp vụ quản lý ca chơi, giám sát phòng thời gian thực và điều phối phục vụ
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Chế độ xem: 0 = Sơ đồ & Điều phối Vận hành, 1 = Lịch Đặt Chỗ Trong Ngày
  int _viewMode = 0;

  // Phòng đang chọn để theo dõi và điều phối
  String _selectedRoomId = 'room_a4';

  // Bộ lọc trạng thái phòng: 'all', 'occupied', 'available', 'maintenance'
  String _roomStatusFilter = 'all';

  // Tab di động (< 850px): 0 = Sơ đồ phòng, 1 = Điều phối phòng đang chọn
  int _mobileTab = 0;

  late Timer _clockTimer;
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    // Đồng bộ thời gian thực mỗi 4 giây từ Firebase Cloud
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        final provider = context.read<BookingProvider>();
        if (provider.autoSyncFirebase && !provider.isSyncingFirebase) {
          provider.refreshFromFirebase();
        }
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _syncTimer.cancel();
    super.dispose();
  }

  BookingModel? _getActiveBooking(BookingProvider provider, String roomId) {
    for (final b in provider.bookings) {
      if (b.status == BookingStatus.confirmed && b.roomId == roomId) {
        return b;
      }
    }
    return null;
  }

  List<ServiceOrderModel> _getRoomOrders(BookingProvider provider, RoomModel room) {
    return provider.serviceOrders.where((o) {
      if (o.status == 'cancelled') return false;
      final orderRoom = o.roomName.trim().toLowerCase();
      final rName = room.name.trim().toLowerCase();
      final rPos = room.posName.trim().toLowerCase();
      final rId = room.id.trim().toLowerCase();

      if (orderRoom == rName || orderRoom == rPos || orderRoom == rId) return true;

      if (rPos.contains('phòng 4') && (orderRoom.contains('a4') || orderRoom.contains('phòng 4'))) return true;
      if (rPos.contains('phòng 1') && (orderRoom.contains('a1') || orderRoom.contains('phòng 1'))) return true;
      if (rPos.contains('phòng 2') && (orderRoom.contains('a2') || orderRoom.contains('phòng 2'))) return true;
      if (rPos.contains('phòng 3') && (orderRoom.contains('a3') || orderRoom.contains('phòng 3'))) return true;
      if (rPos.contains('phòng 5') && (orderRoom.contains('a5') || orderRoom.contains('phòng 5'))) return true;
      if (rPos.contains('phòng 6') && (orderRoom.contains('a6') || orderRoom.contains('phòng 6'))) return true;
      if (rPos.contains('vip 1') && orderRoom.contains('vip 1')) return true;
      if (rPos.contains('vip 2') && orderRoom.contains('vip 2')) return true;

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final rooms = provider.rooms;

    if (rooms.isNotEmpty && !rooms.any((r) => r.id == _selectedRoomId)) {
      _selectedRoomId = rooms.first.id;
    }

    final selectedRoom = rooms.firstWhere(
      (r) => r.id == _selectedRoomId,
      orElse: () => rooms.isNotEmpty
          ? rooms.first
          : const RoomModel(
              id: 'room_a4',
              name: 'PHÒNG 4',
              isSmoking: false,
              pricePerHour: 550000,
            ),
    );

    final activeBooking = _getActiveBooking(provider, selectedRoom.id);
    final roomOrders = _getRoomOrders(provider, selectedRoom);

    final occupiedCount = rooms.where((r) => _getActiveBooking(provider, r.id) != null).length;
    final pendingOrdersCount = provider.serviceOrders.where((o) => o.status == 'preparing').length;
    final totalBookingsToday = provider.bookings.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return Scaffold(
          backgroundColor: const Color(0xFF090D18),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Thanh tiêu đề trung tâm điều hành
                _buildOperationsHeader(
                  provider,
                  rooms,
                  selectedRoom,
                  occupiedCount,
                  pendingOrdersCount,
                  isMobile,
                ),

                // 2. Dải chỉ số vận hành cấp cao (Operations KPI Ribbon)
                _buildKpiRibbon(
                  occupiedCount,
                  rooms.length,
                  totalBookingsToday,
                  pendingOrdersCount,
                  isMobile,
                ),

                // 3. Nội dung điều hành
                Expanded(
                  child: _viewMode == 1
                      ? GsmTimelineView(
                          provider: provider,
                          rooms: rooms,
                          isMobile: isMobile,
                          onQuickCheckin: (room) => _showQuickCheckinDialog(context, provider, room),
                        )
                      : (isMobile
                          ? _buildMobileWorkflowView(
                              context,
                              provider,
                              rooms,
                              selectedRoom,
                              activeBooking,
                              roomOrders,
                              occupiedCount,
                            )
                          : _buildDesktopWorkflowView(
                              context,
                              provider,
                              rooms,
                              selectedRoom,
                              activeBooking,
                              roomOrders,
                              occupiedCount,
                            )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. THANH TIÊU ĐỀ TRUNG TÂM ĐIỀU HÀNH
  // ===========================================================================
  Widget _buildOperationsHeader(
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    int occupiedCount,
    int pendingOrdersCount,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 54 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1322),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          // Tiêu đề & trạng thái vận hành
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'OKAMURA GOLFZON',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'TRUNG TÂM ĐIỀU HÀNH VẬN HÀNH',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: occupiedCount > 0 ? const Color(0xFF10B981) : AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ĐANG PHỤC VỤ $occupiedCount/${rooms.length} PHÒNG • $pendingOrdersCount YÊU CẦU CẦN ĐIỀU PHỐI',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Thông báo yêu cầu phục vụ từ khách tại phòng
          if (pendingOrdersCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _showLiveGuestOrdersModal(context, provider),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Yêu cầu phòng ($pendingOrdersCount)',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chuyển đổi chế độ: Sơ Đồ Phòng vs Lịch Đặt Hôm Nay
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _viewMode = 0),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _viewMode == 0 ? AppColors.primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 13,
                          color: _viewMode == 0 ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sơ Đồ Phòng',
                          style: TextStyle(
                            color: _viewMode == 0 ? Colors.black : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _viewMode = 1),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _viewMode == 1 ? AppColors.primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: _viewMode == 1 ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Lịch Đặt Hôm Nay',
                          style: TextStyle(
                            color: _viewMode == 1 ? Colors.black : Colors.white70,
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
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DẢI CHỈ SỐ VẬN HÀNH CẤP CAO (OPERATIONS KPI RIBBON)
  // ===========================================================================
  Widget _buildKpiRibbon(
    int occupiedCount,
    int totalRooms,
    int totalBookingsToday,
    int pendingRequests,
    bool isMobile,
  ) {
    final occupancyPct = totalRooms > 0 ? (occupiedCount / totalRooms * 100).round() : 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 8 : 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiItem(
              label: 'Công Suất Phòng',
              value: '$occupiedCount / $totalRooms',
              subtext: '$occupancyPct% công suất',
              icon: Icons.meeting_room_rounded,
              accentColor: occupiedCount > 0 ? const Color(0xFF10B981) : AppColors.primaryGold,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFF1E293B)),
          Expanded(
            child: _buildKpiItem(
              label: 'Lịch Đặt Trong Ngày',
              value: '$totalBookingsToday',
              subtext: 'Ca đặt chơi',
              icon: Icons.event_available_rounded,
              accentColor: const Color(0xFF38BDF8),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFF1E293B)),
          Expanded(
            child: _buildKpiItem(
              label: 'Yêu Cầu Tận Phòng',
              value: '$pendingRequests',
              subtext: pendingRequests > 0 ? 'Cần điều phối' : 'Đã xử lý xong',
              icon: Icons.room_service_rounded,
              accentColor: pendingRequests > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
          ),
          if (!isMobile) ...[
            Container(width: 1, height: 32, color: const Color(0xFF1E293B)),
            Expanded(
              child: _buildKpiItem(
                label: 'Tình Trạng Hệ Thống',
                value: 'Hoạt Động Tốt',
                subtext: 'Đồng bộ Cloud 24/7',
                icon: Icons.cloud_done_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '($subtext)',
                        style: TextStyle(color: accentColor, fontSize: 10.5, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. GIAO DIỆN DESKTOP: SƠ ĐỒ PHÒNG (62%) + BẢNG ĐIỀU PHỐI (38%)
  // ===========================================================================
  Widget _buildDesktopWorkflowView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    BookingModel? activeBooking,
    List<ServiceOrderModel> roomOrders,
    int occupiedCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cột trái: Sơ đồ ma trận toàn bộ phòng chơi thời gian thực (62%)
        Expanded(
          flex: 62,
          child: Container(
            color: const Color(0xFF090D18),
            child: Column(
              children: [
                // Thanh lọc trạng thái phòng
                _buildRoomStatusFilterBar(rooms),

                // Lưới 12 phòng
                Expanded(
                  child: _buildFacilityRoomsGrid(provider, rooms, selectedRoom),
                ),
              ],
            ),
          ),
        ),

        // Đường phân tách tinh tế
        Container(width: 1, color: const Color(0xFF1E293B)),

        // Cột phải: Bảng điều phối nghiệp vụ phòng đang chọn (38%)
        Expanded(
          flex: 38,
          child: Container(
            color: const Color(0xFF0D1322),
            child: _buildRoomControlConsole(
              context,
              provider,
              selectedRoom,
              activeBooking,
              roomOrders,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. GIAO DIỆN DI ĐỘNG: TAB SƠ ĐỒ PHÒNG VÀ ĐIỀU PHỐI
  // ===========================================================================
  Widget _buildMobileWorkflowView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    BookingModel? activeBooking,
    List<ServiceOrderModel> roomOrders,
    int occupiedCount,
  ) {
    return Column(
      children: [
        Container(
          height: 42,
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _mobileTab = 0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _mobileTab == 0 ? AppColors.primaryGold : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Sơ Đồ Phòng (${rooms.length})',
                      style: TextStyle(
                        color: _mobileTab == 0 ? AppColors.primaryGold : Colors.white60,
                        fontWeight: _mobileTab == 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _mobileTab = 1),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _mobileTab == 1 ? AppColors.primaryGold : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Điều Phối ${selectedRoom.posName}',
                      style: TextStyle(
                        color: _mobileTab == 1 ? AppColors.primaryGold : Colors.white60,
                        fontWeight: _mobileTab == 1 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _mobileTab == 0
              ? Column(
                  children: [
                    _buildRoomStatusFilterBar(rooms),
                    Expanded(
                      child: _buildFacilityRoomsGrid(provider, rooms, selectedRoom),
                    ),
                  ],
                )
              : _buildRoomControlConsole(
                  context,
                  provider,
                  selectedRoom,
                  activeBooking,
                  roomOrders,
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. BỘ LỌC TRẠNG THÁI PHÒNG
  // ===========================================================================
  Widget _buildRoomStatusFilterBar(List<RoomModel> rooms) {
    final provider = context.watch<BookingProvider>();
    final occupied = rooms.where((r) => _getActiveBooking(provider, r.id) != null).length;
    final available = rooms.where((r) => _getActiveBooking(provider, r.id) == null && !r.isUnderMaintenance).length;
    final maintenance = rooms.where((r) => r.isUnderMaintenance).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F172A).withValues(alpha: 0.5),
      child: Row(
        children: [
          const Text(
            'Lọc phòng:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          _buildFilterChip('all', 'Tất cả (${rooms.length})'),
          const SizedBox(width: 6),
          _buildFilterChip('occupied', 'Đang chơi ($occupied)'),
          const SizedBox(width: 6),
          _buildFilterChip('available', 'Sẵn sàng ($available)'),
          const SizedBox(width: 6),
          _buildFilterChip('maintenance', 'Bảo trì ($maintenance)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _roomStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _roomStatusFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGold : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. MA TRẬN 12 PHÒNG CHƠI THỜI GIAN THỰC (FACILITY MATRIX GRID)
  // ===========================================================================
  Widget _buildFacilityRoomsGrid(
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
  ) {
    final filteredRooms = rooms.where((r) {
      final isOccupied = _getActiveBooking(provider, r.id) != null;
      if (_roomStatusFilter == 'occupied') return isOccupied;
      if (_roomStatusFilter == 'available') return !isOccupied && !r.isUnderMaintenance;
      if (_roomStatusFilter == 'maintenance') return r.isUnderMaintenance;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: filteredRooms.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final room = filteredRooms[index];
          final booking = _getActiveBooking(provider, room.id);
          final orders = _getRoomOrders(provider, room);
          final isSelected = room.id == selectedRoom.id;
          final isOccupied = booking != null;
          final isMaintenance = room.isUnderMaintenance;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedRoomId = room.id;
                _mobileTab = 1; // Trên mobile tự chuyển sang tab chi tiết điều phối
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOccupied
                    ? const Color(0xFF0F231D)
                    : (isMaintenance ? const Color(0xFF1E1E24) : const Color(0xFF111827)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGold
                      : (isOccupied ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF1E293B)),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGold.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hàng tiêu đề phòng & trạng thái
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.posName,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryGold : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOccupied
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : (isMaintenance
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOccupied
                              ? 'ĐANG CHƠI'
                              : (isMaintenance ? 'BẢO TRÌ' : 'SẴN SÀNG'),
                          style: TextStyle(
                            color: isOccupied
                                ? const Color(0xFF10B981)
                                : (isMaintenance ? Colors.redAccent : Colors.white70),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Thông tin chi tiết phòng
                  if (isOccupied) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 12, color: AppColors.primaryGold),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.customerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giờ chơi: ${booking.timeSlot}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      room.sensorModel,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Chân thẻ: Dịch vụ hoặc giá phòng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isOccupied && orders.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${orders.length} đơn dịch vụ',
                            style: const TextStyle(color: Colors.orange, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Text(
                          '${Formatters.currency(room.pricePerHour)}/h',
                          style: const TextStyle(color: AppColors.primaryGold, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isSelected ? AppColors.primaryGold : Colors.white30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 7. BẢNG ĐIỀU PHỐI NGHIỆP VỤ PHÒNG ĐANG CHỌN (ROOM WORKFLOW CONSOLE)
  // ===========================================================================
  Widget _buildRoomControlConsole(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
    BookingModel? booking,
    List<ServiceOrderModel> orders,
  ) {
    final isOccupied = booking != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Phòng đang chọn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.posName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${room.sensorModel} • ${Formatters.currency(room.pricePerHour)}/giờ',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOccupied
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : (room.isUnderMaintenance
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOccupied
                        ? const Color(0xFF10B981)
                        : (room.isUnderMaintenance ? Colors.redAccent : const Color(0xFF38BDF8)),
                    width: 1,
                  ),
                ),
                child: Text(
                  isOccupied
                      ? 'ĐANG PHỤC VỤ'
                      : (room.isUnderMaintenance ? 'ĐANG BẢO TRÌ' : 'PHÒNG TRỐNG'),
                  style: TextStyle(
                    color: isOccupied
                        ? const Color(0xFF10B981)
                        : (room.isUnderMaintenance ? Colors.redAccent : const Color(0xFF38BDF8)),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // Khối hồ sơ ca chơi
          if (isOccupied) ...[
            _buildActiveSessionCard(context, provider, room, booking),
          ] else ...[
            _buildEmptyRoomCard(context, provider, room),
          ],

          const SizedBox(height: 20),

          // Cụm nghiệp vụ điều phối quản trị (Admin Workflow Actions)
          const Text(
            'ĐIỀU PHỐI VẬN HÀNH',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildWorkflowActionButtons(context, provider, room, booking, orders),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // Danh sách yêu cầu phục vụ & đơn dịch vụ của phòng này
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DỊCH VỤ PHỤC VỤ PHÒNG (${orders.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () => _showAddServiceModal(context, room),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.primaryGold),
                      SizedBox(width: 4),
                      Text(
                        'Thêm món/dịch vụ',
                        style: TextStyle(color: AppColors.primaryGold, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRoomOrdersList(context, provider, orders),
        ],
      ),
    );
  }

  /// Thẻ ca chơi đang hoạt động
  Widget _buildActiveSessionCard(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
    BookingModel booking,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.primaryGold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'SĐT: ${booking.customerPhone} • Khung giờ: ${booking.timeSlot}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mã ca chơi:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  booking.id,
                  style: const TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ khi phòng đang trống
  Widget _buildEmptyRoomCard(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          const Icon(Icons.meeting_room_outlined, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Phòng đang sẵn sàng đón khách',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bạn có thể tiếp nhận ca chơi mới hoặc chuyển khách từ phòng khác sang.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showQuickCheckinDialog(context, provider, room),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Nhận Phòng & Mở Ca Chơi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Cụm nút hành động điều phối vận hành (Admin Actions)
  Widget _buildWorkflowActionButtons(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
    BookingModel? booking,
    List<ServiceOrderModel> orders,
  ) {
    final isOccupied = booking != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isOccupied) ...[
          // Gia hạn ca chơi +30p
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã gia hạn thêm 30 phút cho ${room.posName}!')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGold,
              side: const BorderSide(color: AppColors.primaryGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.more_time_rounded, size: 15),
            label: const Text('Gia Hạn (+30p)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),

          // Điều chuyển phòng
          OutlinedButton.icon(
            onPressed: () => _showTransferRoomDialog(context, provider, room, booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Điều Chuyển Phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),

          // Kết thúc ca & Bật dọn phòng
          ElevatedButton.icon(
            onPressed: () => _showReleaseBayDialog(context, provider, room, booking, orders),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
            label: const Text('Kết Thúc Ca & Dọn Phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],

        // Bật / tắt bảo trì kỹ thuật
        OutlinedButton.icon(
          onPressed: () async {
            await provider.toggleRoomMaintenance(room.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(room.isUnderMaintenance
                      ? 'Đã mở lại hoạt động cho ${room.posName}!'
                      : 'Đã chuyển ${room.posName} sang trạng thái bảo trì!'),
                ),
              );
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: room.isUnderMaintenance ? const Color(0xFF10B981) : Colors.redAccent,
            side: BorderSide(color: room.isUnderMaintenance ? const Color(0xFF10B981) : Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(room.isUnderMaintenance ? Icons.check_rounded : Icons.build_rounded, size: 14),
          label: Text(
            room.isUnderMaintenance ? 'Mở Lại Phòng' : 'Tạm Dừng Bảo Trì',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Danh sách yêu cầu phục vụ & đơn dịch vụ của phòng
  Widget _buildRoomOrdersList(
    BuildContext context,
    BookingProvider provider,
    List<ServiceOrderModel> orders,
  ) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131C31),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            'Phòng này chưa có yêu cầu dịch vụ nào.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        final isPreparing = order.status == 'preparing';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF131C31),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPreparing ? Colors.orange.withValues(alpha: 0.5) : const Color(0xFF1E293B),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isPreparing ? Colors.orange : const Color(0xFF10B981)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPreparing ? Icons.hourglass_top_rounded : Icons.check_rounded,
                  size: 14,
                  color: isPreparing ? Colors.orange : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.summaryText,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${Formatters.currency(order.totalPrice)} • ${isPreparing ? 'Đang chờ phục vụ' : 'Đã phục vụ'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isPreparing)
                TextButton(
                  onPressed: () async {
                    await provider.updateServiceOrderStatus(order.id, 'served');
                  },
                  child: const Text('Hoàn tất', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 8. CÁC DIALOG NGHIỆP VỤ ĐIỀU PHỐI (WORKFLOW DIALOGS)
  // ===========================================================================

  void _showLiveGuestOrdersModal(BuildContext context, BookingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final pending = provider.serviceOrders.where((o) => o.status == 'preparing').toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('YÊU CẦU DỊCH VỤ PHÒNG CHỜ XỬ LÝ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white60, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: Color(0xFF1E293B)),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Tất cả yêu cầu phòng đã được nhân viên phục vụ hoàn tất.', style: TextStyle(color: AppColors.textMuted))),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, idx) {
                      final order = pending[idx];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.room_service, size: 16, color: Colors.white)),
                        title: Text('${order.roomName} • ${order.summaryText}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Tổng: ${Formatters.currency(order.totalPrice)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await provider.updateServiceOrderStatus(order.id, 'served');
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          child: const Text('Bàn giao', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddServiceModal(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thêm dịch vụ cho ${room.posName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: AppColors.primaryGold,
                  labelColor: AppColors.primaryGold,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: 'Ẩm thực & Nước uống'),
                    Tab(text: 'Dịch vụ Golf & Gậy'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      FnbMenuGrid(selectedRoom: room),
                      GolfServicesGrid(selectedRoom: room),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferRoomDialog(
    BuildContext context,
    BookingProvider provider,
    RoomModel currentRoom,
    BookingModel? booking,
  ) {
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phòng hiện tại chưa có ca chơi để điều chuyển!')),
      );
      return;
    }

    final availableRooms = provider.rooms.where((r) => r.id != currentRoom.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Text('Điều chuyển ca chơi từ ${currentRoom.posName}', style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableRooms.map((target) {
                return ListTile(
                  title: Text(target.posName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(target.sensorModel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryGold),
                  onTap: () async {
                    final ok = await provider.transferBookingRoom(
                      bookingId: booking.id,
                      targetRoom: target,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (ok) {
                      setState(() => _selectedRoomId = target.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã điều chuyển ca chơi sang ${target.posName}!')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không thể chuyển: Phòng ${target.posName} đang bận!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showReleaseBayDialog(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
    BookingModel? booking,
    List<ServiceOrderModel> orders,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('Kết thúc ca: ${room.posName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking != null
                  ? 'Xác nhận khách ${booking.customerName} đã kết thúc ca chơi tại ${room.posName}?'
                  : 'Xác nhận hoàn tất phiên phục vụ và giải phóng phòng ${room.posName}?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hệ thống sẽ hoàn tất ca chơi và đưa phòng về trạng thái sẵn sàng đón lượt khách tiếp theo.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (booking != null) {
                await provider.completeBooking(booking.id);
              } else {
                for (final o in orders) {
                  await provider.updateServiceOrderStatus(o.id, 'served');
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã hoàn tất ca chơi tại ${room.posName}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác Nhận & Hoàn Tất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickCheckinDialog(
    BuildContext context,
    BookingProvider provider,
    RoomModel defaultRoom,
  ) {
    final nameCtrl = TextEditingController(text: 'Khách Chơi Golf');
    final phoneCtrl = TextEditingController(text: '0901234567');
    String selectedRoomId = defaultRoom.id;

    final slots = AppConstants.standardTimeSlots;
    final nowHour = DateTime.now().hour;
    String selectedSlot = slots.firstWhere(
      (s) {
        final startH = int.tryParse(s.split(':').first) ?? 8;
        return nowHour >= startH && nowHour < startH + 2;
      },
      orElse: () => slots.first,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF1E293B))),
          title: const Text('Nhận Phòng & Kích Hoạt Ca Chơi Mới', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tên Khách Hàng / Golfer', labelStyle: TextStyle(color: AppColors.textMuted)),
                ),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ', labelStyle: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: provider.rooms.any((r) => r.id == selectedRoomId)
                      ? selectedRoomId
                      : (provider.rooms.isNotEmpty ? provider.rooms.first.id : null),
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: provider.rooms.map((r) {
                    return DropdownMenuItem(value: r.id, child: Text(r.posName, style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedRoomId = v);
                  },
                  decoration: const InputDecoration(labelText: 'Chọn Phòng Chơi', labelStyle: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: slots.contains(selectedSlot)
                      ? selectedSlot
                      : (slots.isNotEmpty ? slots.first : null),
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: slots.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedSlot = v);
                  },
                  decoration: const InputDecoration(labelText: 'Khung Giờ Chơi', labelStyle: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              onPressed: () async {
                final targetRoom = provider.rooms.firstWhere((r) => r.id == selectedRoomId);
                final ok = await provider.createBooking(
                  room: targetRoom,
                  bookingDate: DateTime.now(),
                  timeSlot: selectedSlot,
                  customerName: nameCtrl.text.trim().isEmpty ? 'Khách Chơi Golf' : nameCtrl.text.trim(),
                  customerPhone: phoneCtrl.text.trim().isEmpty ? '0901234567' : phoneCtrl.text.trim(),
                  notes: 'Lounge Manager Check-in',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (ok) {
                  setState(() => _selectedRoomId = targetRoom.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã kích hoạt ca chơi cho ${targetRoom.posName}!')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phòng ${targetRoom.posName} đang bận trong khung giờ $selectedSlot!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
              child: const Text('Kích Hoạt Ca Chơi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
