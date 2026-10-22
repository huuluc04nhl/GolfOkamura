import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';
import 'dashboard_widgets/bay_invoice_panel.dart';
import 'dashboard_widgets/fnb_menu_grid.dart';
import 'dashboard_widgets/golf_services_grid.dart';
import 'dashboard_widgets/gsm_timeline_view.dart';
import 'dashboard_widgets/shift_handover_dialog.dart';

/// Màn hình Trung tâm Điều hành & Quản lý Bay Golf Lounge (Admin Operations Suite):
/// - Tích hợp Sidebar điều phối chuyên nghiệp
/// - Đồng bộ thời gian thực hai chiều (Real-time Cloud Sync) với App của khách hàng
/// - Hiển thị badge đơn gọi từ khách, thông báo tức thì khi khách order từ phòng
/// - Chuẩn hóa hình ảnh sản phẩm từ Firebase và quy trình nghiệp vụ Quản lý Lounge
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Chế độ vận hành: 0 = Quản lý Bay & Gọi món, 1 = Lịch trình Đặt Bay Golfzon
  int _adminMode = 0;

  // Bay đang chọn theo dõi và phục vụ
  String _selectedRoomId = 'room_a4';

  // Tab bên phải: 0 = SƠ ĐỒ BAY, 1 = GỌI MÓN (F&B), 2 = DỊCH VỤ GOLF
  int _posRightTab = 0;

  // Tab trên thiết bị di động (< 700px): 0 = Dịch vụ Bay, 1 = Gọi món F&B, 2 = Dịch vụ Golf, 3 = Sơ đồ Bay
  int _mobileTab = 0;


  // Bộ đếm thời gian cập nhật giao diện & Đồng bộ Firebase tự động
  late Timer _clockTimer;
  late Timer _syncTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    // Đồng bộ thời gian thực tự động mỗi 4 giây từ Firebase (tối ưu độ trễ thông báo order và trạng thái Bay)
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

  /// Lấy toàn bộ đơn F&B / dịch vụ của phòng (khớp thông minh cả tên phòng, mã phòng và số phòng)
  List<ServiceOrderModel> _getRoomOrders(BookingProvider provider, RoomModel room) {
    return provider.serviceOrders.where((o) {
      if (o.status == 'cancelled') return false;
      final orderRoom = o.roomName.trim().toLowerCase();
      final rName = room.name.trim().toLowerCase();
      final rPos = room.posName.trim().toLowerCase();
      final rId = room.id.trim().toLowerCase();

      // Khớp chính xác
      if (orderRoom == rName || orderRoom == rPos || orderRoom == rId) return true;

      // Khớp linh hoạt theo số phòng: VD khách order "A4 - Smoking", Admin xem "PHÒNG 4"
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

  double _calculateRoomTotal(BookingModel? booking, List<ServiceOrderModel> orders) {
    double total = booking?.totalPrice ?? 0;
    for (final o in orders) {
      total += o.totalPrice;
    }
    return total;
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
    final grandTotal = _calculateRoomTotal(activeBooking, roomOrders);

    final occupiedCount = rooms.where((r) => _getActiveBooking(provider, r.id) != null).length;
    final pendingOrdersCount = provider.serviceOrders.where((o) => o.status == 'preparing').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1024;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Column(
              children: [
                // Header thương hiệu & thanh công cụ
                _buildLoungeManagerHeader(
                  provider,
                  rooms,
                  selectedRoom,
                  occupiedCount,
                  pendingOrdersCount,
                  isMobile,
                ),

                // Bảng điều hành Responsive theo thiết bị
                Expanded(
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    child: _adminMode == 1
                        ? _buildGsmTimelineView(context, provider, rooms, isMobile)
                        : (isMobile
                            ? _buildMobilePosView(
                                context,
                                provider,
                                rooms,
                                selectedRoom,
                                activeBooking,
                                roomOrders,
                                grandTotal,
                                occupiedCount,
                              )
                            : _buildDesktopPosView(
                                context,
                                provider,
                                rooms,
                                selectedRoom,
                                activeBooking,
                                roomOrders,
                                grandTotal,
                                occupiedCount,
                                isTablet,
                              )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // ===========================================================================
  // 2. THANH TIÊU ĐỀ TRUNG TÂM ĐIỀU HÀNH GOLF LOUNGE
  // ===========================================================================
  Widget _buildLoungeManagerHeader(
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    int occupiedCount,
    int pendingOrdersCount,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 54 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          // Tiêu đề & Trạng thái đồng bộ
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'OKAMURA GOLF LOUNGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '• TRUNG TÂM ĐIỀU HÀNH BAY (GSM)',
                    style: TextStyle(
                      color: Color(0xFFB69568),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ĐANG PHỤC VỤ $occupiedCount/${rooms.length} BAY • $pendingOrdersCount YÊU CẦU DỊCH VỤ TẠI BAY',
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

          // Nút xem nhanh đơn khách gọi từ App (trên Mobile và Header)
          if (pendingOrdersCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _showLiveGuestOrdersModal(context, provider),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Khách Order ($pendingOrdersCount)',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Nút Chốt Ca & Bàn Giao Quầy Thu Ngân
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => ShiftHandoverDialog(provider: provider),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB69568).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFB69568).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.point_of_sale_rounded, color: Color(0xFFB69568), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Chốt Ca & Bàn Giao',
                    style: TextStyle(
                      color: Color(0xFFB69568),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút chuyển chế độ xem nhanh: POS vs Lịch Đặt GSM
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _adminMode = 0),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _adminMode == 0 ? const Color(0xFFB69568) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Phòng Bay',
                      style: TextStyle(
                        color: _adminMode == 0 ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _adminMode = 1),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _adminMode == 1 ? const Color(0xFFB69568) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Lịch GSM',
                      style: TextStyle(
                        color: _adminMode == 1 ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nút đổi Bay nhanh trên header
          PopupMenuButton<String>(
            tooltip: 'Chọn Bay phục vụ',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFB69568).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedRoom.posName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFB69568), size: 16),
                ],
              ),
            ),
            onSelected: (roomId) => setState(() => _selectedRoomId = roomId),
            itemBuilder: (context) => rooms.map((r) {
              final hasGuest = _getActiveBooking(provider, r.id) != null;
              final orders = _getRoomOrders(provider, r);
              return PopupMenuItem(
                value: r.id,
                child: Row(
                  children: [
                    Text(r.posName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (orders.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('${orders.length} đơn', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasGuest ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        hasGuest ? 'Đang chơi' : 'Trống',
                        style: TextStyle(
                          color: hasGuest ? const Color(0xFF10B981) : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. DESKTOP / TABLET VIEW (BỐ CỤC 2 CỘT QUẢN TRỊ VIÊN)
  // ===========================================================================
  Widget _buildDesktopPosView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    BookingModel? activeBooking,
    List<ServiceOrderModel> roomOrders,
    double grandTotal,
    int occupiedCount,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CỘT TRÁI (50% Desktop / 48% Tablet): HÓA ĐƠN & CHI PHÍ PHIÊN CHƠI TẠI BAY
        Expanded(
          flex: isTablet ? 48 : 50,
          child: BayInvoicePanel(
            room: selectedRoom,
            booking: activeBooking,
            orders: roomOrders,
            isTablet: isTablet,
            onTransferRoom: () => _showTransferRoomDialog(context, provider, selectedRoom, activeBooking),
            onGoToFnb: () => setState(() => _posRightTab = 1),
            onGoToServices: () => setState(() => _posRightTab = 2),
            onReleaseBay: () => _showReleaseBayDialog(context, provider, selectedRoom, activeBooking, roomOrders),
          ),
        ),

        // Kẻ viền phân cách
        Container(width: 1, color: const Color(0xFFCBD5E1)),

        // CỘT PHẢI (50% Desktop / 52% Tablet): TABS SƠ ĐỒ BAY | GỌI MÓN F&B | DỊCH VỤ GOLF
        Expanded(
          flex: isTablet ? 52 : 50,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Thanh Tabs nghiệp vụ quản lý (3 Tabs: Sơ đồ Bay | Gọi Món F&B | Dịch Vụ Golf)
                _buildRightTabsBar(occupiedCount, rooms.length),

                // Nội dung Tab được chọn (Sơ đồ Bay, Gọi Món F&B, hoặc Dịch Vụ Golf)
                Expanded(
                  child: _posRightTab == 0
                      ? _buildPosRoomsGridTab(provider, rooms, selectedRoom)
                      : (_posRightTab == 1
                          ? FnbMenuGrid(selectedRoom: selectedRoom)
                          : GolfServicesGrid(selectedRoom: selectedRoom)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. MOBILE POS VIEW (< 700PX) DÀNH CHO THIẾT BỊ DI ĐỘNG CỦA QUẢN LÝ
  // ===========================================================================
  Widget _buildMobilePosView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
    BookingModel? activeBooking,
    List<ServiceOrderModel> roomOrders,
    double grandTotal,
    int occupiedCount,
  ) {
    return Column(
      children: [
        // TabBar chọn phân hệ trên di động (4 phân hệ Vận hành)
        Container(
          height: 42,
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              _buildMobileTabButton(0, 'Hóa Đơn Bay', Icons.receipt_long_rounded),
              _buildMobileTabButton(1, 'Gọi Món F&B', Icons.restaurant_menu_rounded),
              _buildMobileTabButton(2, 'Dịch Vụ Golf', Icons.sports_golf_rounded),
              _buildMobileTabButton(3, 'Sơ Đồ Bay', Icons.meeting_room_rounded),
            ],
          ),
        ),

        // Nội dung Tab Mobile
        Expanded(
          child: IndexedStack(
            index: _mobileTab.clamp(0, 3),
            children: [
              // Tab 0: Hóa Đơn Bay
              BayInvoicePanel(
                room: selectedRoom,
                booking: activeBooking,
                orders: roomOrders,
                isTablet: false,
                onTransferRoom: () => _showTransferRoomDialog(context, provider, selectedRoom, activeBooking),
                onGoToFnb: () => setState(() => _mobileTab = 1),
                onGoToServices: () => setState(() => _mobileTab = 2),
                onReleaseBay: () => _showReleaseBayDialog(context, provider, selectedRoom, activeBooking, roomOrders),
              ),

              // Tab 1: Gọi Món F&B
              FnbMenuGrid(selectedRoom: selectedRoom),

              // Tab 2: Dịch Vụ Golf
              GolfServicesGrid(selectedRoom: selectedRoom),

              // Tab 3: Sơ đồ Bay
              _buildPosRoomsGridTab(provider, rooms, selectedRoom),
            ],
          ),
        ),

        // Thanh thao tác nhanh vận hành ghim đáy trên Mobile
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selectedRoom.posName} • ${roomOrders.length + (activeBooking != null ? 1 : 0)} dịch vụ',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    activeBooking != null ? 'Đang có khách chơi' : 'Phòng đang trống',
                    style: TextStyle(
                      color: activeBooking != null ? const Color(0xFF10B981) : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showReleaseBayDialog(
                  context,
                  provider,
                  selectedRoom,
                  activeBooking,
                  roomOrders,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(
                  'Hoàn tất & Trả Bay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabButton(int index, String title, IconData icon) {
    final isSelected = _mobileTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mobileTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFFB69568) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? const Color(0xFFB69568) : Colors.white60,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 9. CỘT PHẢI: TABS BAR NGHIỆP VỤ & LƯỚI GỌI MÓN F&B / DỊCH VỤ GOLF TÁCH BIỆT
  // ===========================================================================
  Widget _buildRightTabsBar(int occupiedCount, int totalRooms) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      child: Row(
        children: [
          _buildRightPanelTab(0, 'SƠ ĐỒ BAY [$occupiedCount/$totalRooms]', Icons.grid_view_rounded),
          _buildRightPanelTab(1, 'GỌI MÓN (F&B)', Icons.restaurant_menu_rounded),
          _buildRightPanelTab(2, 'DỊCH VỤ GOLF', Icons.sports_golf_rounded),
        ],
      ),
    );
  }

  Widget _buildRightPanelTab(int tabIndex, String title, IconData icon, {bool highlight = false}) {
    final isSelected = _posRightTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _posRightTab = tabIndex),
        child: Container(
          alignment: Alignment.center,
          color: isSelected
              ? Colors.white
              : (highlight ? const Color(0xFFFEF3C7) : Colors.transparent),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : (highlight ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 10. TAB SƠ ĐỒ TRẠNG THÁI BAY GOLFZON
  // ===========================================================================
  Widget _buildPosRoomsGridTab(
    BookingProvider provider,
    List<RoomModel> rooms,
    RoomModel selectedRoom,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: const Row(
            children: [
              Text(
                'Sơ đồ trạng thái vận hành các Bay Golfzon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              itemCount: rooms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final booking = _getActiveBooking(provider, room.id);
                final orders = _getRoomOrders(provider, room);
                final roomTotal = _calculateRoomTotal(booking, orders);
                final isSelected = room.id == selectedRoom.id;

                final Color cardColor = booking != null
                    ? const Color(0xFF065F46) // Emerald: Đang đón khách
                    : const Color(0xFF334155); // Slate: Sẵn sàng phục vụ

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRoomId = room.id;
                      _posRightTab = 1;
                      _mobileTab = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFB69568) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              room.posName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            if (booking != null)
                              const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                          ],
                        ),
                        if (booking != null) ...[
                          Text(
                            booking.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                          Text(
                            Formatters.formatCurrency(roomTotal),
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ] else
                          const Text(
                            'Sẵn sàng đón khách',
                            style: TextStyle(color: Colors.white54, fontSize: 10.5),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 11. VIEW LỊCH ĐẶT CHỖ TIMELINE GSM (LỊCH TRÌNH BAY THEO KHUNG GIỜ)
  // ===========================================================================
  Widget _buildGsmTimelineView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    bool isMobile,
  ) {
    return GsmTimelineView(
      provider: provider,
      rooms: rooms,
      isMobile: isMobile,
      onQuickCheckin: (room) => _showQuickCheckinDialog(context, provider, room),
    );
  }

  // ===========================================================================
  // 13. MODAL XEM DANH SÁCH TẤT CẢ ĐƠN KHÁCH VỪA GỌI TỪ APP (LIVE ORDERS)
  // ===========================================================================
  void _showLiveGuestOrdersModal(BuildContext context, BookingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final pendingOrders = provider.serviceOrders.where((o) => o.status == 'preparing').toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    const Text(
                      'ĐƠN ORDER ĐANG CHỜ PHỤC VỤ TỪ APP',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                if (pendingOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text('Hiện không có đơn nào đang chờ xử lý từ app khách hàng.'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pendingOrders.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, idx) {
                        final order = pendingOrders[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.roomName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.formatCurrency(order.totalPrice),
                                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                order.items.map((i) => "${i['name']} x${i['qty']}").join(", "),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (order.note != null)
                                Text('Ghi chú: ${order.note}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await provider.updateServiceOrderStatus(order.id, 'served');
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã xác nhận phục vụ đơn của ${order.roomName}!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text('Đã Phục Vụ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
  }

  // ===========================================================================
  // 14. HỘP THOẠI NGHIỆP VỤ: ĐỔI BAY, IN PHIẾU TẠM TÍNH, ĐẶT CHỖ
  // ===========================================================================
  void _showTransferRoomDialog(
    BuildContext context,
    BookingProvider provider,
    RoomModel currentRoom,
    BookingModel? booking,
  ) {
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bay hiện tại chưa có phiên chơi đang hoạt động để đổi!')),
      );
      return;
    }

    final availableRooms = provider.rooms.where((r) => r.id != currentRoom.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đổi phiên chơi từ ${currentRoom.posName} sang Bay khác'),
        content: SizedBox(
          width: 320,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableRooms.map((target) {
                  return ListTile(
                    title: Text(target.posName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(target.sensorModel),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
                            SnackBar(content: Text('Đã chuyển phiên chơi và order sang ${target.posName}!')),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể đổi: Bay ${target.posName} đang bận trong khung giờ này!'),
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
            Text('Kết Thúc Phiên: ${room.posName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking != null
                  ? 'Xác nhận khách ${booking.customerName} đã kết thúc phiên chơi tại ${room.posName}?'
                  : 'Xác nhận hoàn tất phiên phục vụ và giải phóng phòng ${room.posName}?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hệ thống sẽ chuyển Bay sang trạng thái Trống để sẵn sàng đón lượt khách tiếp theo.',
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
                    content: Text('Đã hoàn tất phiên chơi và giải phóng ${room.posName}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn Tất & Trả Bay', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final nameCtrl = TextEditingController(text: 'Golfer VIP');
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
          title: const Text('Kích hoạt Bay & Mở phiên chơi mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên Golfer / Khách hàng'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: provider.rooms.any((r) => r.id == selectedRoomId)
                      ? selectedRoomId
                      : (provider.rooms.isNotEmpty ? provider.rooms.first.id : null),
                  items: provider.rooms.map((r) {
                    return DropdownMenuItem(value: r.id, child: Text(r.posName));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedRoomId = v);
                  },
                  decoration: const InputDecoration(labelText: 'Chọn Bay Golfzon'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: slots.contains(selectedSlot)
                      ? selectedSlot
                      : (slots.isNotEmpty ? slots.first : null),
                  items: slots.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedSlot = v);
                  },
                  decoration: const InputDecoration(labelText: 'Khung giờ chơi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final targetRoom = provider.rooms.firstWhere((r) => r.id == selectedRoomId);
                final ok = await provider.createBooking(
                  room: targetRoom,
                  bookingDate: DateTime.now(),
                  timeSlot: selectedSlot,
                  customerName: nameCtrl.text.trim().isEmpty ? 'Golfer VIP' : nameCtrl.text.trim(),
                  customerPhone: phoneCtrl.text.trim().isEmpty ? '0901234567' : phoneCtrl.text.trim(),
                  notes: 'Lounge Manager Check-in',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (ok) {
                  setState(() => _selectedRoomId = targetRoom.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã mở phiên chơi cho ${targetRoom.posName}!')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bay ${targetRoom.posName} đang bận trong khung giờ $selectedSlot!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Mở Phiên Chơi'),
            ),
          ],
        ),
      ),
    );
  }
}
