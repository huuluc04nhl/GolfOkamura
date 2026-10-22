import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/golf_category_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/models/service_order_model.dart';
import '../../../shared/providers/booking_provider.dart';

/// Màn hình GOLFZON Store Manager (GSM) — Quản lý Danh Mục & CRUD Toàn Diện:
/// - Tab 0: Phòng Bay Simulator (CRUD Bay)
/// - Tab 1: Thể Loại & Phân Hạng Golf (CRUD Thể Loại)
/// - Tab 2: Thực Đơn Gọi Món F&B (CRUD Món Ăn, Nước Uống)
/// - Tab 3: Dịch Vụ Golf & Tiện Ích (CRUD Thuê Gậy, Caddie, HLV)
class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  // 0: Phòng Bay Simulator, 1: Thể Loại Golf, 2: Thực Đơn F&B, 3: Dịch Vụ Golf
  int _currentTab = 0;

  // Bộ lọc & Tìm kiếm Tab Thực Đơn F&B
  final _fnbSearchController = TextEditingController();
  String _fnbSearchText = '';
  int _fnbCategoryFilter = -1; // -1: Tất cả, 0: Nước & Đồ uống, 1: Ẩm thực Lounge

  // Bộ lọc & Tìm kiếm Tab Dịch Vụ Golf
  final _serviceSearchController = TextEditingController();
  String _serviceSearchText = '';
  int _serviceCategoryFilter = -1; // -1: Tất cả, 2: Thuê gậy, 3: HLV & Caddie

  @override
  void dispose() {
    _fnbSearchController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final rooms = provider.rooms;
    final categories = provider.golfCategories;
    final fnbItems = provider.serviceItems
        .where((i) => i.category == 0 || i.category == 1)
        .toList();
    final serviceItems = provider.serviceItems
        .where((i) => i.category == 2 || i.category == 3)
        .toList();
    final onlineCount = rooms.where((r) => !r.isUnderMaintenance).length;
    final maintenanceCount = rooms.where((r) => r.isUnderMaintenance).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh chuyển đổi 4 Phân hệ CRUD: Bay | Thể Loại | F&B | Dịch Vụ
            _buildTabSelector(
              rooms.length,
              categories.length,
              fnbItems.length,
              serviceItems.length,
            ),
            const SizedBox(height: 18),

            // Nội dung theo Tab được chọn
            Expanded(
              child: _buildCurrentTabContent(
                context,
                provider,
                rooms,
                categories,
                fnbItems,
                serviceItems,
                onlineCount,
                maintenanceCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    List<GolfCategoryModel> categories,
    List<ServiceItemModel> fnbItems,
    List<ServiceItemModel> serviceItems,
    int onlineCount,
    int maintenanceCount,
  ) {
    switch (_currentTab) {
      case 0:
        return _buildRoomsView(context, provider, rooms, onlineCount, maintenanceCount);
      case 1:
        return _buildGolfCategoriesView(context, provider, categories, rooms);
      case 2:
        return _buildFnbCatalogView(context, provider, fnbItems);
      case 3:
        return _buildGolfServicesCatalogView(context, provider, serviceItems);
      default:
        return _buildRoomsView(context, provider, rooms, onlineCount, maintenanceCount);
    }
  }

  // ===========================================================================
  // 1. THANH CHỌN TAB PHÂN HỆ QUẢN LÝ (4 TABS)
  // ===========================================================================
  Widget _buildTabSelector(
    int roomsCount,
    int categoriesCount,
    int fnbCount,
    int servicesCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(
              index: 0,
              title: 'Phòng Bay Simulator ($roomsCount)',
              icon: Icons.meeting_room_rounded,
            ),
            const SizedBox(width: 4),
            _buildTabButton(
              index: 1,
              title: 'Thể Loại Golf ($categoriesCount)',
              icon: Icons.sports_golf_rounded,
            ),
            const SizedBox(width: 4),
            _buildTabButton(
              index: 2,
              title: 'Thực Đơn F&B ($fnbCount)',
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(width: 4),
            _buildTabButton(
              index: 3,
              title: 'Dịch Vụ Golf & Tiện Ích ($servicesCount)',
              icon: Icons.room_service_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. PHÂN HỆ QUẢN LÝ PHÒNG BAY SIMULATOR (TAB 0)
  // ===========================================================================
  Widget _buildRoomsView(
    BuildContext context,
    BookingProvider provider,
    List<RoomModel> rooms,
    int onlineCount,
    int maintenanceCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header GSM Simulator Bay Management & Nút Thêm Bay CRUD
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GOLFZON STORE MANAGER — QUẢN LÝ PHÒNG BAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Thêm mới, sửa đổi cấu hình và quản lý trạng thái của các phòng Bay Simulator.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatBadge(
                  label: 'Đang mở đón khách',
                  value: '$onlineCount/${rooms.length} Bay',
                  color: const Color(0xFF10B981),
                ),
                _buildStatBadge(
                  label: 'Tạm khóa bảo trì',
                  value: '$maintenanceCount Bay',
                  color: const Color(0xFFF59E0B),
                ),
                ElevatedButton(
                  onPressed: () => _showAddEditRoomDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Thêm Bay Mới',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Danh sách Bay
        Expanded(
          child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final totalRoomBookings = provider.bookings
                  .where((b) => b.roomId == room.id)
                  .length;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C31),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: room.isUnderMaintenance
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.65)
                        : const Color(0xFF1E293B),
                  ),
                ),
                child: Row(
                  children: [
                    // Cột 1: Huy hiệu Bay & Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: room.isUnderMaintenance
                              ? [const Color(0xFF475569), const Color(0xFF1E293B)]
                              : [AppColors.primaryGold, AppColors.darkGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        room.isUnderMaintenance
                            ? Icons.build_circle_rounded
                            : Icons.sports_golf_rounded,
                        color: room.isUnderMaintenance ? Colors.white70 : Colors.black,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Cột 2: Thông tin định danh & Cảm biến
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  room.posName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF26354D)),
                                ),
                                child: Text(
                                  provider.getGolfCategoryName(room.category),
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (room.isSmoking) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Hút thuốc',
                                    style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${room.name} • Cảm biến: ${room.sensorModel} • Tối đa ${room.capacity} golfer',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Cột 3: Đơn giá giờ & Thống kê
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatCurrency(room.pricePerHour),
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tổng: $totalRoomBookings lượt chơi',
                            style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),

                    // Cột 4: Switch trạng thái hoạt động trực tiếp (Realtime)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              room.isUnderMaintenance ? 'Tạm Khóa' : 'Đang Mở',
                              style: TextStyle(
                                color: room.isUnderMaintenance
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              room.isUnderMaintenance ? 'Bảo trì máy' : 'Đón khách',
                              style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: !room.isUnderMaintenance,
                          activeThumbColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                          inactiveThumbColor: const Color(0xFFF59E0B),
                          inactiveTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          onChanged: (val) async {
                            await provider.toggleRoomMaintenance(room.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? 'Đã mở ${room.posName} để đón khách đặt lịch!'
                                        : 'Đã tạm khóa ${room.posName} để bảo trì thiết bị!',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: val ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Cột 5: Nút Sửa & Xóa
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showAddEditRoomDialog(context, provider, room: room),
                          icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryGold),
                          tooltip: 'Chỉnh sửa phòng Bay',
                        ),
                        IconButton(
                          onPressed: () => _showDeleteRoomDialog(context, provider, room),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          tooltip: 'Xóa phòng Bay',
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
    );
  }

  // ===========================================================================
  // 3. PHÂN HỆ QUẢN LÝ THỂ LOẠI & PHÂN HẠNG GOLF (TAB 1) - CRUD HOÀN CHỈNH
  // ===========================================================================
  Widget _buildGolfCategoriesView(
    BuildContext context,
    BookingProvider provider,
    List<GolfCategoryModel> categories,
    List<RoomModel> rooms,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Thể Loại Golf & Nút Thêm Mới
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GOLFZON STORE MANAGER — THỂ LOẠI & PHÂN HẠNG GOLF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cấu hình danh mục thể loại golf, cảm biến chuẩn hóa, mức giá giờ tham chiếu và phân hạng trải nghiệm.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatBadge(
                  label: 'Tổng số thể loại',
                  value: '${categories.length} Hạng mục',
                  color: const Color(0xFF38BDF8),
                ),
                _buildStatBadge(
                  label: 'Đang áp dụng',
                  value: '${rooms.length} Bay Simulator',
                  color: AppColors.primaryGold,
                ),
                ElevatedButton(
                  onPressed: () => _showAddEditGolfCategoryDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Thêm Thể Loại Golf',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Lưới thẻ Thể Loại Golf (Responsive Grid - Chống Tràn Viền Tuyệt Đối)
        Expanded(
          child: categories.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có thể loại golf nào. Nhấn "Thêm Thể Loại Golf" để tạo mới!',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 228,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final linkedRooms = rooms.where((r) => r.category == cat.id).toList();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C31),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cat.badgeColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Thẻ: Icon, Tên, Mã ID, và Nút Sửa/Xóa (chống tràn viền)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cat.badgeColor.withValues(alpha: 0.4)),
                                ),
                                child: Icon(cat.iconData, color: cat.badgeColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF26354D)),
                                          ),
                                          child: Text(
                                            'Mã: ${cat.id}',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 9.5,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cảm biến: ${cat.defaultSensor} • Tối đa ${cat.maxCapacity} golfer',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showAddEditGolfCategoryDialog(context, provider, category: cat),
                                    icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryGold),
                                    tooltip: 'Chỉnh sửa thể loại',
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showDeleteGolfCategoryDialog(context, provider, cat, linkedRooms.length),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                    tooltip: 'Xóa thể loại',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Mô tả thể loại
                          Text(
                            cat.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                          ),
                          const Spacer(),

                          const Divider(color: Color(0xFF1E293B), height: 14),

                          // Chân thẻ: Đơn giá tham chiếu & Các phòng đang áp dụng (chống tràn viền)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Đơn giá tham chiếu:', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                                  Text(
                                    '${Formatters.formatCurrency(cat.basePricePerHour)} / giờ',
                                    style: TextStyle(
                                      color: cat.badgeColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      linkedRooms.isNotEmpty
                                          ? '${linkedRooms.length} Bay áp dụng:'
                                          : 'Chưa có Bay liên kết',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                    ),
                                    const SizedBox(height: 2),
                                    if (linkedRooms.isNotEmpty)
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        alignment: WrapAlignment.end,
                                        children: linkedRooms.take(3).map((r) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F172A),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF1E293B)),
                                            ),
                                            child: Text(
                                              r.posName,
                                              style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    else
                                      const Text('—', style: TextStyle(color: Colors.white24, fontSize: 11)),
                                  ],
                                ),
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
    );
  }

  // ===========================================================================
  // 4. DIALOG CRUD THỂ LOẠI GOLF
  // ===========================================================================
  void _showAddEditGolfCategoryDialog(
    BuildContext context,
    BookingProvider provider, {
    GolfCategoryModel? category,
  }) {
    final isEditing = category != null;
    final idCtrl = TextEditingController(text: category?.id ?? '');
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final priceCtrl = TextEditingController(
      text: category != null ? category.basePricePerHour.toInt().toString() : '400000',
    );
    final sensorCtrl = TextEditingController(
      text: category?.defaultSensor ?? 'Golfzon TwoVision NX 3D Suite',
    );
    final capacityCtrl = TextEditingController(
      text: category != null ? category.maxCapacity.toString() : '4',
    );
    String selectedIcon = category?.iconKey ?? 'golf';
    String selectedColor = category?.badgeColorHex ?? 'B69568';

    final availableColors = [
      {'hex': 'B69568', 'label': 'Vàng Gold'},
      {'hex': '10B981', 'label': 'Xanh Ngọc'},
      {'hex': '38BDF8', 'label': 'Xanh Dương'},
      {'hex': 'EC4899', 'label': 'Hồng Sen'},
      {'hex': 'F59E0B', 'label': 'Cam Amber'},
      {'hex': '8B5CF6', 'label': 'Tím Violet'},
    ];

    final availableIcons = [
      {'key': 'golf', 'label': 'Golf', 'icon': Icons.sports_golf_rounded},
      {'key': 'vip', 'label': 'VIP', 'icon': Icons.workspace_premium_rounded},
      {'key': 'dual', 'label': 'Dual', 'icon': Icons.swap_horiz_rounded},
      {'key': 'connecting', 'label': 'Đôi', 'icon': Icons.meeting_room_rounded},
      {'key': 'range', 'label': 'GDR', 'icon': Icons.track_changes_rounded},
      {'key': 'studio', 'label': 'Studio', 'icon': Icons.psychology_rounded},
      {'key': 'cup', 'label': 'Giải Đấu', 'icon': Icons.emoji_events_rounded},
      {'key': 'star', 'label': 'Signature', 'icon': Icons.star_rounded},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131C31),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.sports_golf_rounded,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Sửa Thể Loại: ${category.name}' : 'Thêm Thể Loại Golf Mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mã thể loại & Tên thể loại
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mã Định Danh (ID):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: idCtrl,
                                  enabled: !isEditing,
                                  style: TextStyle(
                                    color: isEditing ? Colors.white38 : Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: _inputDecoration('VD: tour_nx, range_vip'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tên Thể Loại Golf:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: nameCtrl,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: _inputDecoration('VD: VIP NX Diamond Suite'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Đơn giá giờ tham chiếu & Sức chứa tối đa
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đơn giá giờ tham chiếu (VNĐ):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: _inputDecoration('Đơn giá', suffix: 'đ/h'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sức chứa tối đa:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: capacityCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: _inputDecoration('Số Golfer', suffix: 'người'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cảm biến Golfzon mặc định
                      const Text('Cảm biến Simulator tiêu chuẩn:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sensorCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('VD: Golfzon TwoVision NX 3D Suite'),
                      ),
                      const SizedBox(height: 12),

                      // Chọn Icon
                      const Text('Biểu tượng Icon đại diện:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableIcons.map((ic) {
                            final isCur = selectedIcon == ic['key'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                avatar: Icon(ic['icon'] as IconData, size: 14, color: isCur ? Colors.black : Colors.white70),
                                label: Text(ic['label'] as String),
                                selected: isCur,
                                selectedColor: AppColors.primaryGold,
                                backgroundColor: const Color(0xFF0F172A),
                                labelStyle: TextStyle(
                                  color: isCur ? Colors.black : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => setDialogState(() => selectedIcon = ic['key'] as String),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chọn Màu sắc Badge
                      const Text('Màu sắc huy hiệu (Badge Color):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: availableColors.map((cl) {
                          final isCur = selectedColor == cl['hex'];
                          final colorVal = Color(int.parse('0xFF${cl['hex']}'));
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColor = cl['hex']!),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCur ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isCur
                                    ? [BoxShadow(color: colorVal.withValues(alpha: 0.6), blurRadius: 6)]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Mô tả chi tiết trải nghiệm
                      const Text('Mô tả trải nghiệm thể loại golf:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        decoration: _inputDecoration('VD: Không gian thi đấu chuyên nghiệp với độ chính xác tuyệt đối...'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final id = isEditing
                        ? category.id
                        : (idCtrl.text.trim().isEmpty
                            ? 'cat_${DateTime.now().millisecondsSinceEpoch % 100000}'
                            : idCtrl.text.trim().toLowerCase().replaceAll(' ', '_'));
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 400000;
                    final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
                    final sensor = sensorCtrl.text.trim().isEmpty ? 'Golfzon TwoVision NX 3D' : sensorCtrl.text.trim();
                    final desc = descCtrl.text.trim();

                    if (isEditing) {
                      final updated = category.copyWith(
                        name: name,
                        description: desc,
                        basePricePerHour: price,
                        defaultSensor: sensor,
                        maxCapacity: cap,
                        iconKey: selectedIcon,
                        badgeColorHex: selectedColor,
                      );
                      await provider.updateGolfCategory(updated);
                    } else {
                      final newCat = GolfCategoryModel(
                        id: id,
                        name: name,
                        description: desc,
                        basePricePerHour: price,
                        defaultSensor: sensor,
                        maxCapacity: cap,
                        iconKey: selectedIcon,
                        badgeColorHex: selectedColor,
                      );
                      await provider.addGolfCategory(newCat);
                    }

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Đã cập nhật thể loại golf "$name"!' : 'Đã thêm thể loại golf "$name" thành công!'),
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
                    isEditing ? 'Lưu Thay Đổi' : 'Tạo Thể Loại Mới',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteGolfCategoryDialog(
    BuildContext context,
    BookingProvider provider,
    GolfCategoryModel category,
    int roomsUsingCount,
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
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Xóa Thể Loại Golf',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: roomsUsingCount > 0
            ? Text(
                'Hiện đang có $roomsUsingCount phòng Bay Simulator đang thuộc thể loại "${category.name}".\n\nVui lòng chỉnh sửa và chuyển các phòng Bay này sang thể loại khác trước khi xóa thể loại này khỏi hệ thống.',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              )
            : Text(
                'Bạn có chắc chắn muốn xóa thể loại "${category.name}" khỏi danh mục hệ thống? Thao tác này sẽ xóa vĩnh viễn cấu hình này.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(roomsUsingCount > 0 ? 'Đã Hiểu' : 'Hủy', style: const TextStyle(color: Colors.white60)),
          ),
          if (roomsUsingCount == 0)
            ElevatedButton(
              onPressed: () async {
                await provider.deleteGolfCategory(category.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa thể loại "${category.name}"!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác Nhận Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. DIALOGS CRUD PHÒNG BAY SIMULATOR (DÙNG DANH MỤC THỂ LOẠI GOLF ĐỘNG)
  // ===========================================================================
  void _showAddEditRoomDialog(
    BuildContext context,
    BookingProvider provider, {
    RoomModel? room,
  }) {
    final isEditing = room != null;
    final nameCtrl = TextEditingController(text: room?.name ?? '');
    final priceCtrl = TextEditingController(
      text: room != null ? room.pricePerHour.toInt().toString() : '450000',
    );
    final capacityCtrl = TextEditingController(
      text: room != null ? room.capacity.toString() : '4',
    );
    String selectedCategory = room?.category ?? (provider.golfCategories.isNotEmpty ? provider.golfCategories.first.id : 'standard');
    String selectedSensor = room?.sensorModel ?? 'Golfzon TwoVision NX 3D';
    bool isSmoking = room?.isSmoking ?? false;

    // Danh sách dòng cảm biến Golfzon chuẩn hóa và bảo đảm selectedSensor luôn tồn tại trong items
    final sensorOptions = [
      'Golfzon TwoVision NX 3D',
      'Golfzon TwoVision NX 3D Suite',
      'Golfzon TwoVision Plus 3D',
      'Golfzon TwoVision NX 3D Dual Sensor',
      'Golfzon TwoVision Real Dual Sensor',
      'Golfzon TwoVision NX 3D Panorama',
      'Golfzon TwoVision NX Network Play',
      'GDR Plus Driving Range Simulator',
      'GDR Plus High-Speed AI Simulator',
      'Golfzon NX + TrackMan 4 Studio',
      'Golfzon TwoVision Dual Plate',
      'Dual TwoVision NX Link',
      'Golfzon GDR Plus Driving Range',
      'Golfzon Wave Studio & 3D Plate',
    ];
    if (!sensorOptions.contains(selectedSensor)) {
      sensorOptions.insert(0, selectedSensor);
    }

    // Đảm bảo selectedCategory tồn tại trong provider.golfCategories
    if (!provider.golfCategories.any((c) => c.id == selectedCategory)) {
      if (provider.golfCategories.isNotEmpty) {
        selectedCategory = provider.golfCategories.first.id;
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131C31),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Chỉnh Sửa ${room.posName}' : 'Thêm Phòng Bay Mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên Bay
                      const Text('Tên Phòng Bay (VD: VIP 3 - Suite Luxury):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Nhập tên phòng...'),
                      ),
                      const SizedBox(height: 12),

                      // Phân loại phòng theo Thể loại Golf động & Sức chứa
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thể loại Golf:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF26354D)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: provider.golfCategories.any((c) => c.id == selectedCategory)
                                          ? selectedCategory
                                          : (provider.golfCategories.isNotEmpty
                                              ? provider.golfCategories.first.id
                                              : null),
                                      dropdownColor: const Color(0xFF131C31),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                      items: provider.golfCategories.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat.id,
                                          child: Row(
                                            children: [
                                              Icon(cat.iconData, size: 14, color: cat.badgeColor),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  cat.name,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedCategory = val;
                                            // Tự động gợi ý đơn giá và cảm biến theo thể loại đã chọn nếu tạo mới
                                            if (!isEditing) {
                                              final matchCat = provider.golfCategories.firstWhere((c) => c.id == val);
                                              priceCtrl.text = matchCat.basePricePerHour.toInt().toString();
                                              selectedSensor = matchCat.defaultSensor;
                                              if (!sensorOptions.contains(selectedSensor)) {
                                                sensorOptions.insert(0, selectedSensor);
                                              }
                                              capacityCtrl.text = matchCat.maxCapacity.toString();
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sức chứa tối đa:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: capacityCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: _inputDecoration('Số Golfer', suffix: 'người'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dòng máy Simulator
                      const Text('Dòng máy Simulator:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF26354D)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sensorOptions.contains(selectedSensor)
                                ? selectedSensor
                                : sensorOptions.first,
                            dropdownColor: const Color(0xFF131C31),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5),
                            items: sensorOptions.map((opt) {
                              return DropdownMenuItem(
                                value: opt,
                                child: Text(opt, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedSensor = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Đơn giá thuê giờ (VNĐ)
                      const Text('Đơn giá thuê mỗi giờ (VNĐ):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: _inputDecoration('Giá giờ', suffix: 'đ/h'),
                      ),
                      const SizedBox(height: 12),

                      // Tùy chọn khu vực hút thuốc
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF26354D)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Cho phép hút thuốc (Khu vực riêng):',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            Switch(
                              value: isSmoking,
                              activeThumbColor: AppColors.primaryGold,
                              onChanged: (val) => setDialogState(() => isSmoking = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 450000;
                    final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 4;

                    if (isEditing) {
                      final updated = room.copyWith(
                        name: name,
                        pricePerHour: price,
                        capacity: capacity,
                        category: selectedCategory,
                        sensorModel: selectedSensor,
                        isSmoking: isSmoking,
                      );
                      await provider.updateRoom(updated);
                    } else {
                      final newId = 'room_custom_${DateTime.now().millisecondsSinceEpoch % 100000}';
                      final newRoom = RoomModel(
                        id: newId,
                        name: name,
                        isSmoking: isSmoking,
                        pricePerHour: price,
                        capacity: capacity,
                        sensorModel: selectedSensor,
                        category: selectedCategory,
                      );
                      await provider.addRoom(newRoom);
                    }

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Đã cập nhật cấu hình ${room.posName}!'
                                : 'Đã thêm phòng Bay mới thành công!',
                          ),
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
                    isEditing ? 'Lưu Thay Đổi' : 'Thêm Phòng',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteRoomDialog(
    BuildContext context,
    BookingProvider provider,
    RoomModel room,
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
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Xóa Phòng Bay Simulator',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${room.posName} (${room.name})" khỏi hệ thống?\n\nThao tác này sẽ gỡ bỏ hoàn toàn Bay này khỏi danh sách đón khách và lịch trình.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteRoom(room.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${room.posName}" khỏi danh sách Bay!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác Nhận Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PHÂN HỆ QUẢN LÝ THỰC ĐƠN GỌI MÓN F&B (TAB 2) - CRUD HOÀN CHỈNH
  // ===========================================================================
  Widget _buildFnbCatalogView(
    BuildContext context,
    BookingProvider provider,
    List<ServiceItemModel> fnbItems,
  ) {
    final filtered = fnbItems.where((i) {
      if (_fnbCategoryFilter != -1 && i.category != _fnbCategoryFilter) return false;
      if (_fnbSearchText.isNotEmpty) {
        final q = _fnbSearchText.toLowerCase();
        return i.name.toLowerCase().contains(q) ||
            i.subtitle.toLowerCase().contains(q) ||
            i.tag.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GOLFZON STORE MANAGER — THỰC ĐƠN GỌI MÓN (F&B)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý danh mục món ăn, đồ uống Lounge, giá niêm yết và đồng bộ Firebase Realtime.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatBadge(
                  label: 'Tổng số món F&B',
                  value: '${fnbItems.length} Món',
                  color: const Color(0xFF10B981),
                ),
                ElevatedButton(
                  onPressed: () => _showAddEditFnbDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Thêm Món F&B',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter pills & search
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildCatalogFilterPill(
              label: 'Tất cả F&B (${fnbItems.length})',
              isSelected: _fnbCategoryFilter == -1,
              onTap: () => setState(() => _fnbCategoryFilter = -1),
            ),
            _buildCatalogFilterPill(
              label: 'Nước & Đồ uống (${fnbItems.where((i) => i.category == 0).length})',
              isSelected: _fnbCategoryFilter == 0,
              onTap: () => setState(() => _fnbCategoryFilter = 0),
            ),
            _buildCatalogFilterPill(
              label: 'Ẩm thực Lounge (${fnbItems.where((i) => i.category == 1).length})',
              isSelected: _fnbCategoryFilter == 1,
              onTap: () => setState(() => _fnbCategoryFilter = 1),
            ),
            SizedBox(
              width: 260,
              height: 36,
              child: TextField(
                controller: _fnbSearchController,
                onChanged: (v) => setState(() => _fnbSearchText = v.trim()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: _inputDecoration('Tìm tên món, trà, bia, steak...').copyWith(
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white54),
                  suffixIcon: _fnbSearchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14, color: Colors.white54),
                          onPressed: () {
                            _fnbSearchController.clear();
                            setState(() => _fnbSearchText = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid cards
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy món F&B nào phù hợp.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 130,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildCatalogItemCard(
                      item: item,
                      onEdit: () => _showAddEditFnbDialog(context, provider, item: item),
                      onDelete: () => _showDeleteCatalogItemDialog(context, provider, item, 'món F&B'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. PHÂN HỆ QUẢN LÝ DỊCH VỤ GOLF & TIỆN ÍCH (TAB 3) - CRUD HOÀN CHỈNH
  // ===========================================================================
  Widget _buildGolfServicesCatalogView(
    BuildContext context,
    BookingProvider provider,
    List<ServiceItemModel> serviceItems,
  ) {
    final filtered = serviceItems.where((i) {
      if (_serviceCategoryFilter != -1 && i.category != _serviceCategoryFilter) return false;
      if (_serviceSearchText.isNotEmpty) {
        final q = _serviceSearchText.toLowerCase();
        return i.name.toLowerCase().contains(q) ||
            i.subtitle.toLowerCase().contains(q) ||
            i.tag.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GOLFZON STORE MANAGER — DỊCH VỤ GOLF & TIỆN ÍCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý danh mục thuê gậy TaylorMade, đặt Caddie, Huấn luyện viên cá nhân và tiện ích.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatBadge(
                  label: 'Tổng số dịch vụ',
                  value: '${serviceItems.length} Dịch vụ',
                  color: AppColors.primaryGold,
                ),
                ElevatedButton(
                  onPressed: () => _showAddEditServiceDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Thêm Dịch Vụ',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter pills & search
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildCatalogFilterPill(
              label: 'Tất cả Dịch Vụ (${serviceItems.length})',
              isSelected: _serviceCategoryFilter == -1,
              onTap: () => setState(() => _serviceCategoryFilter = -1),
            ),
            _buildCatalogFilterPill(
              label: 'Thuê Gậy & Đồ Tập (${serviceItems.where((i) => i.category == 2).length})',
              isSelected: _serviceCategoryFilter == 2,
              onTap: () => setState(() => _serviceCategoryFilter = 2),
            ),
            _buildCatalogFilterPill(
              label: 'HLV & Caddie (${serviceItems.where((i) => i.category == 3).length})',
              isSelected: _serviceCategoryFilter == 3,
              onTap: () => setState(() => _serviceCategoryFilter = 3),
            ),
            SizedBox(
              width: 260,
              height: 36,
              child: TextField(
                controller: _serviceSearchController,
                onChanged: (v) => setState(() => _serviceSearchText = v.trim()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: _inputDecoration('Tìm gậy TaylorMade, caddie, HLV...').copyWith(
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white54),
                  suffixIcon: _serviceSearchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14, color: Colors.white54),
                          onPressed: () {
                            _serviceSearchController.clear();
                            setState(() => _serviceSearchText = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid cards
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy dịch vụ nào phù hợp.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 130,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildCatalogItemCard(
                      item: item,
                      onEdit: () => _showAddEditServiceDialog(context, provider, item: item),
                      onDelete: () => _showDeleteCatalogItemDialog(context, provider, item, 'dịch vụ'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCatalogFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : const Color(0xFF131C31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogItemCard({
    required ServiceItemModel item,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          // Image / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 75,
              height: 105,
              child: Image.network(
                item.resolvedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF0F172A),
                  child: Center(
                    child: Icon(item.iconData, color: item.accentColor, size: 28),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.tag.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          item.tag,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle.isNotEmpty ? item.subtitle : 'Mã: ${item.id}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        Formatters.formatCurrency(item.price),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryGold),
                          tooltip: 'Chỉnh sửa',
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          tooltip: 'Xóa',
                          onPressed: onDelete,
                        ),
                      ],
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

  void _showAddEditFnbDialog(BuildContext context, BookingProvider provider, {ServiceItemModel? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final subtitleCtrl = TextEditingController(text: item?.subtitle ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.price.toInt().toString() : '50000');
    final tagCtrl = TextEditingController(text: item?.tag ?? 'F&B');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    int selectedCategory = item?.category ?? (_fnbCategoryFilter == -1 ? 0 : _fnbCategoryFilter);
    if (selectedCategory != 0 && selectedCategory != 1) selectedCategory = 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF1E293B))),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.restaurant_rounded, color: AppColors.primaryGold),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Sửa Món F&B' : 'Thêm Món F&B Mới',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tên món ăn / đồ uống:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('VD: Trà Đào Cam Sả / Steak Bò Úc'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phân loại F&B:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF26354D)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedCategory,
                                  dropdownColor: const Color(0xFF131C31),
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  items: const [
                                    DropdownMenuItem(value: 0, child: Text('0: Nước & Đồ uống')),
                                    DropdownMenuItem(value: 1, child: Text('1: Ẩm thực Lounge')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Đơn giá (VNĐ):', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: _inputDecoration('Đơn giá', suffix: 'đ'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tag nổi bật:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: tagCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: _inputDecoration('VD: HOT, BEST, VIP'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mô tả ngắn:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: subtitleCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: _inputDecoration('VD: Vị thanh mát, lon 330ml'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Link hình ảnh URL:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: imageUrlCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDecoration('https://images.unsplash.com/...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 50000;
                final img = imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim();

                if (isEditing) {
                  final updated = item.copyWith(
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    category: selectedCategory,
                    tag: tagCtrl.text.trim().isEmpty ? 'F&B' : tagCtrl.text.trim(),
                    imageUrl: img,
                  );
                  await provider.updateServiceItem(updated);
                } else {
                  final newId = 'fnb_${DateTime.now().millisecondsSinceEpoch % 100000}';
                  final newItem = ServiceItemModel(
                    id: newId,
                    category: selectedCategory,
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    tag: tagCtrl.text.trim().isEmpty ? 'NEW' : tagCtrl.text.trim(),
                    iconKey: selectedCategory == 0 ? 'coffee' : 'restaurant',
                    imageUrl: img,
                  );
                  await provider.addServiceItem(newItem);
                }

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Đã cập nhật món "$name"!' : 'Đã thêm món "$name" thành công!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
              ),
              child: Text(isEditing ? 'Lưu Thay Đổi' : 'Thêm Món F&B', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditServiceDialog(BuildContext context, BookingProvider provider, {ServiceItemModel? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final subtitleCtrl = TextEditingController(text: item?.subtitle ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.price.toInt().toString() : '200000');
    final tagCtrl = TextEditingController(text: item?.tag ?? 'GOLF');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    int selectedCategory = item?.category ?? (_serviceCategoryFilter == -1 ? 2 : _serviceCategoryFilter);
    if (selectedCategory != 2 && selectedCategory != 3) selectedCategory = 2;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF1E293B))),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.room_service_rounded, color: AppColors.primaryGold),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Sửa Dịch Vụ Golf' : 'Thêm Dịch Vụ Golf Mới',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tên dịch vụ / tiện ích:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('VD: Fullset TaylorMade Qi10 / HLV Cá Nhân PGA'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phân loại Dịch vụ:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF26354D)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedCategory,
                                  dropdownColor: const Color(0xFF131C31),
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  items: const [
                                    DropdownMenuItem(value: 2, child: Text('2: Thuê Gậy & Thiết Bị')),
                                    DropdownMenuItem(value: 3, child: Text('3: HLV & Caddie')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Đơn giá (VNĐ):', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: _inputDecoration('Đơn giá', suffix: 'đ'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tag nổi bật:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: tagCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: _inputDecoration('VD: PRO, GOLF, PREMIUM'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mô tả ngắn:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: subtitleCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: _inputDecoration('VD: Flex S/R, Kèm túi gậy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Link hình ảnh URL:', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: imageUrlCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDecoration('https://images.unsplash.com/...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 200000;
                final img = imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim();

                if (isEditing) {
                  final updated = item.copyWith(
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    category: selectedCategory,
                    tag: tagCtrl.text.trim().isEmpty ? 'GOLF' : tagCtrl.text.trim(),
                    imageUrl: img,
                  );
                  await provider.updateServiceItem(updated);
                } else {
                  final newId = 'service_${DateTime.now().millisecondsSinceEpoch % 100000}';
                  final newItem = ServiceItemModel(
                    id: newId,
                    category: selectedCategory,
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    tag: tagCtrl.text.trim().isEmpty ? 'NEW' : tagCtrl.text.trim(),
                    iconKey: selectedCategory == 2 ? 'sports_golf' : 'support_agent',
                    imageUrl: img,
                  );
                  await provider.addServiceItem(newItem);
                }

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Đã cập nhật dịch vụ "$name"!' : 'Đã thêm dịch vụ "$name" thành công!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
              ),
              child: Text(isEditing ? 'Lưu Thay Đổi' : 'Thêm Dịch Vụ', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCatalogItemDialog(
    BuildContext context,
    BookingProvider provider,
    ServiceItemModel item,
    String itemTypeLabel,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: Text(
          'Xác nhận xóa $itemTypeLabel',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${item.name}" khỏi danh mục hệ thống?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteServiceItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${item.name}" thành công!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác Nhận Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. HELPER DECORATION & BADGES
  // ===========================================================================
  static InputDecoration _inputDecoration(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF26354D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGold),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
