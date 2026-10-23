import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/services/storage_service.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/vietqr_payment_dialog.dart';

/// Màn hình Đặt phòng Golfzon tương tác thực tế:
/// - Nhận ngữ cảnh phòng & chế độ chơi chọn trước từ Trang chủ
/// - Tùy chỉnh trực tiếp Thời lượng chơi (1-4 giờ), Số lượng Golfer, Ghi chú yêu cầu nhanh
/// - Tính giá tiền thời gian thực & đồng bộ trực tiếp lên Firebase Realtime Database
class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  int _currentStep = 1; // 1: Ngày chơi, 2: Khung giờ & Thời lượng, 3: Chọn phòng
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = AppConstants.standardTimeSlots[0];
  String _roomFilter = 'all';
  int _durationHours = 2;
  int _playerCount = 4;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPreviousCustomerProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BookingProvider>();
      if (provider.preselectedCategory != 'all') {
        setState(() => _roomFilter = provider.preselectedCategory);
      }
      if (provider.preselectedRoom != null) {
        setState(() {
          _playerCount = provider.preselectedRoom!.capacity.clamp(1, 4);
        });
      }
    });
  }

  Future<void> _loadPreviousCustomerProfile() async {
    final provider = context.read<BookingProvider>();
    final profile = await StorageService.loadCustomerProfile();
    if (!mounted) return;
    if (profile['name']!.isNotEmpty) {
      _nameController.text = profile['name']!;
    } else if (provider.currentGolfer.isCustomer) {
      _nameController.text = provider.currentGolfer.name;
    }
    if (profile['phone']!.isNotEmpty) {
      _phoneController.text = profile['phone']!;
    } else if (provider.currentGolfer.isCustomer) {
      _phoneController.text = provider.currentGolfer.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isSquarish = Responsive.isSquarishFoldable(context);
    final safeBottom = Responsive.safeBottomPadding(context, extra: 24);
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.userBgDark,
      appBar: AppBar(
        title: const Text('ĐẶT PHÒNG GOLFZON'),
        centerTitle: true,
        backgroundColor: AppColors.userBgDark,
        elevation: 0,
        leading: _currentStep > 1
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.primaryGold,
                ),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Thanh tiến trình 3 bước
            _buildStepIndicator(hPadding),

            // Thanh ngữ cảnh phòng / chế độ chơi được chọn từ Trang chủ (nếu có)
            if (provider.preselectedRoom != null ||
                provider.preselectedGameMode != null)
              _buildPreselectedContextBanner(context, provider, hPadding),

            // Nội dung theo bước: Hỗ trợ vuốt trái/phải để chuyển bước nhanh
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -350 && _currentStep < 3) {
                    setState(() => _currentStep++);
                  } else if (v > 350 && _currentStep > 1) {
                    setState(() => _currentStep--);
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_currentStep),
                    padding: EdgeInsets.fromLTRB(
                      hPadding,
                      16,
                      hPadding,
                      safeBottom,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSquarish ? 750 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentStep == 1) _buildStep1DateSelection(),
                          if (_currentStep == 2) _buildStep2TimeSelection(),
                          if (_currentStep == 3) _buildStep3RoomSelection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner hiển thị phòng hoặc chế độ chơi khách vừa chọn từ Trang chủ, cho phép đặt nhanh 1 chạm
  Widget _buildPreselectedContextBanner(
    BuildContext context,
    BookingProvider provider,
    double hPadding,
  ) {
    final preRoom = provider.preselectedRoom;
    final gameMode = provider.preselectedGameMode;
    final List<String> labels = [];
    if (preRoom != null) labels.add('Phòng: ${preRoom.name}');
    if (gameMode != null) labels.add('Chế độ: $gameMode');

    return Container(
      margin: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withValues(alpha: 0.18),
            AppColors.userCardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labels.join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (preRoom != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showBookingBottomSheet(preRoom),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Đặt ngay',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              provider.clearPreselectedBookingContext();
              setState(() => _roomFilter = 'all');
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh chỉ báo tiến trình 3 bước thu gọn
  Widget _buildStepIndicator(double hPadding) {
    return Container(
      color: AppColors.userCardDark,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStepPill(1, 'Ngày chơi', Icons.calendar_today_rounded),
          ),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.userBorder),
          Expanded(
            child: _buildStepPill(2, 'Khung giờ', Icons.access_time_rounded),
          ),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.userBorder),
          Expanded(
            child: _buildStepPill(3, 'Chọn phòng', Icons.meeting_room_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return GestureDetector(
      onTap: () => setState(() => _currentStep = step),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.primaryGold
                      : isDone
                          ? AppColors.primaryGold.withValues(alpha: 0.2)
                          : Colors.white12,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          size: 13,
                          color: AppColors.primaryGold,
                        )
                      : Text(
                          '$step',
                          style: TextStyle(
                            color:
                                isActive ? Colors.black : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primaryGold
                      : (isDone ? AppColors.textLight : AppColors.textMuted),
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BƯỚC 1: CHỌN NGÀY CHƠI
  // ==========================================
  Widget _buildStep1DateSelection() {
    final now = DateTime.now();
    final upcomingDates = List.generate(14, (i) => now.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. CHỌN NGÀY TRẢI NGHIỆM',
          style: TextStyle(
            color: AppColors.primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn ngày trong 14 ngày tới tại cơ sở Okamura Golfzon Thuận An.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 16),

        // Dải chọn ngày nằm ngang dạng cuộn hiện đại
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: upcomingDates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = upcomingDates[index];
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = index == 0;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 66,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? null : AppColors.userCardDark,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primaryGold, AppColors.darkGold],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGold
                          : isToday
                              ? AppColors.primaryGold.withValues(alpha: 0.4)
                              : AppColors.userBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday
                            ? 'H.nay'
                            : Formatters.formatDayOfWeek(date).split(',')[0],
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'T.${date.month}',
                        style: TextStyle(
                          color:
                              isSelected ? Colors.black87 : AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Thẻ xác nhận ngày đã chọn
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.userCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.userBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngày đã chọn:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatDayOfWeek(_selectedDate)}, ${Formatters.formatDate(_selectedDate)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút tiếp tục
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TIẾP TỤC CHỌN GIỜ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 2: CHỌN KHUNG GIỜ & THỜI LƯỢNG CHƠI
  // ==========================================
  Widget _buildStep2TimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. CHỌN CA CHƠI & THỜI LƯỢNG',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatDate(_selectedDate),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(
                Icons.edit_calendar,
                size: 14,
                color: AppColors.primaryGold,
              ),
              label: const Text(
                'Đổi ngày',
                style: TextStyle(color: AppColors.primaryGold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildTimeCategory(
          'CA SÁNG (08:00 - 12:00)',
          ['08:00 - 10:00', '10:00 - 12:00'],
        ),
        const SizedBox(height: 12),
        _buildTimeCategory(
          'CA CHIỀU (12:00 - 18:00)',
          ['12:00 - 14:00', '14:00 - 16:00', '16:00 - 18:00'],
        ),
        const SizedBox(height: 12),
        _buildTimeCategory(
          'CA TỐI (18:00 - 22:00)',
          ['18:00 - 20:00', '20:00 - 22:00'],
        ),
        const SizedBox(height: 18),

        // Tùy chọn Thời lượng chơi (1h - 4h) & Số lượng Golfer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.userCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.userBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THỜI LƯỢNG CHƠI (TÍNH GIÁ TỰ ĐỘNG)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [1, 2, 3, 4].map((hrs) {
                  final active = _durationHours == hrs;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: hrs < 4 ? 8 : 0),
                      child: InkWell(
                        onTap: () => setState(() => _durationHours = hrs),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryGold
                                : AppColors.userSurfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? AppColors.primaryGold
                                  : AppColors.userBorder,
                            ),
                          ),
                          child: Text(
                            '$hrs Giờ',
                            style: TextStyle(
                              color: active ? Colors.black : AppColors.textLight,
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút tiếp tục
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CHỌN PHÒNG KHUNG $_selectedTimeSlot (${_durationHours}H)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
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
    );
  }

  Widget _buildTimeCategory(String label, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;
            return ChoiceChip(
              label: Text(
                slot,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedTimeSlot = slot),
              selectedColor: AppColors.primaryGold,
              backgroundColor: AppColors.userCardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.userBorder,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 3: CHỌN PHÒNG & XÁC NHẬN
  // ==========================================
  Widget _buildStep3RoomSelection() {
    final provider = context.watch<BookingProvider>();
    final allRooms = provider.rooms;
    final preRoom = provider.preselectedRoom;

    final filteredRooms = allRooms.where((room) {
      if (_roomFilter == 'smoking') return room.isSmoking;
      if (_roomFilter == 'nosmoking') return !room.isSmoking;
      if (_roomFilter == 'vip') return room.isVip;
      if (_roomFilter == 'dual') return room.isDualTee;
      if (_roomFilter == 'connecting') return room.isConnecting;
      if (_roomFilter == 'range') return room.isDrivingRange;
      if (_roomFilter == 'studio') return room.isStudio;
      if (_roomFilter == 'standard') return room.category == 'standard';
      return true;
    }).toList();

    // Đưa phòng đã chọn từ Trang chủ lên đầu danh sách để khách thao tác ngay
    if (preRoom != null) {
      filteredRooms.sort((a, b) {
        if (a.id == preRoom.id) return -1;
        if (b.id == preRoom.id) return 1;
        return 0;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ tóm tắt ngày giờ & thời lượng
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.userCardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_filled,
                color: AppColors.primaryGold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${Formatters.formatDate(_selectedDate)} • $_selectedTimeSlot (${_durationHours}h)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentStep = 2),
                child: const Text(
                  'Đổi giờ',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bộ lọc nhanh phân loại phòng
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill('all', 'Tất cả (${allRooms.length})'),
              const SizedBox(width: 8),
              _buildFilterPill('vip', '👑 VIP Suite'),
              const SizedBox(width: 8),
              _buildFilterPill('standard', '🏌️ Standard 3D'),
              const SizedBox(width: 8),
              _buildFilterPill('dual', '⚡ Dual Tee 2 chiều'),
              const SizedBox(width: 8),
              _buildFilterPill('connecting', '🔗 Connecting Suite'),
              const SizedBox(width: 8),
              _buildFilterPill('range', '🎯 Driving Range AI'),
              const SizedBox(width: 8),
              _buildFilterPill('studio', '🎓 PGA Coaching Studio'),
              const SizedBox(width: 8),
              _buildFilterPill('nosmoking', '🚭 Không hút thuốc'),
              const SizedBox(width: 8),
              _buildFilterPill('smoking', '🚬 Khu hút thuốc'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Danh sách phòng
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredRooms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            final status = provider.getRoomStatus(
              roomId: room.id,
              date: _selectedDate,
              timeSlot: _selectedTimeSlot,
            );
            final isAvailable = status == RoomBookingStatus.available;
            final isMaintenance = status == RoomBookingStatus.maintenance;
            final isPreselected = preRoom?.id == room.id;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.userCardDark,
                gradient: isPreselected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryGold.withValues(alpha: 0.16),
                          AppColors.userCardDark,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPreselected
                      ? AppColors.primaryGold
                      : isAvailable
                          ? AppColors.primaryGold.withValues(alpha: 0.4)
                          : isMaintenance
                              ? Colors.red.withValues(alpha: 0.3)
                              : AppColors.userBorder,
                  width: isPreselected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: room.isVip
                          ? AppColors.primaryGold.withValues(alpha: 0.2)
                          : room.isDrivingRange
                              ? Colors.cyan.withValues(alpha: 0.15)
                              : room.isStudio
                                  ? Colors.purple.withValues(alpha: 0.15)
                                  : room.isSmoking
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : AppColors.primaryGold.withValues(
                                          alpha: 0.12,
                                        ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      room.isVip
                          ? Icons.diamond_outlined
                          : room.isDrivingRange
                              ? Icons.track_changes_rounded
                              : room.isStudio
                                  ? Icons.psychology_outlined
                                  : room.isSmoking
                                      ? Icons.smoking_rooms_rounded
                                      : Icons.sports_golf_rounded,
                      color: room.isVip
                          ? AppColors.primaryGold
                          : room.isDrivingRange
                              ? Colors.cyanAccent
                              : room.isStudio
                                  ? Colors.purpleAccent
                                  : room.isSmoking
                                      ? Colors.orange
                                      : AppColors.primaryGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                room.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isPreselected
                                    ? AppColors.primaryGold
                                    : room.isVip
                                        ? AppColors.primaryGold.withValues(
                                            alpha: 0.2,
                                          )
                                        : Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPreselected ? 'ĐANG CHỌN' : room.categoryLabel,
                                style: TextStyle(
                                  color: isPreselected
                                      ? Colors.black
                                      : room.isVip
                                          ? AppColors.primaryGold
                                          : AppColors.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatCurrency(room.pricePerHour * _durationHours)} / ca ${_durationHours}h',
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMaintenance)
                    const RoomStatusBadge(status: RoomBookingStatus.maintenance)
                  else if (!isAvailable)
                    const RoomStatusBadge(status: RoomBookingStatus.booked)
                  else
                    ElevatedButton(
                      onPressed: () => _showBookingBottomSheet(room),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Chọn phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _roomFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _roomFilter = filterKey),
      selectedColor: AppColors.primaryGold,
      backgroundColor: AppColors.userCardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGold : AppColors.userBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  /// Bottom sheet xác nhận đặt phòng với bộ tùy chỉnh thực tế (Thời lượng, Số Golfer, Ghi chú nhanh)
  void _showBookingBottomSheet(RoomModel room) {
    _playerCount = _playerCount.clamp(1, room.capacity);
    final quickNotes = [
      'Gậy TaylorMade tay phải',
      'Gậy tay trái',
      'Ướp lạnh bia Asahi',
      'Cần Caddie hỗ trợ',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.userCardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final totalPrice = room.pricePerHour * _durationHours;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatCurrency(totalPrice),
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.formatDate(_selectedDate)} • $_selectedTimeSlot • Ca $_durationHours giờ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tùy chỉnh Thời lượng & Số lượng Golfer trực tiếp trên Sheet
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.userSurfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.userBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Thời lượng chơi:',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [1, 2, 3, 4].map((hrs) {
                                  final selected = _durationHours == hrs;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _durationHours = hrs);
                                        setModalState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.primaryGold
                                              : AppColors.userCardDark,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.primaryGold
                                                : AppColors.userBorder,
                                          ),
                                        ),
                                        child: Text(
                                          '${hrs}h',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.black
                                                : AppColors.textMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.userBorder, height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Số lượng Golfer (Tối đa ${room.capacity}):',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.userCardDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryGold.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: _playerCount > 1
                                          ? () {
                                              setState(() => _playerCount--);
                                              setModalState(() {});
                                            }
                                          : null,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 15,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$_playerCount người',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _playerCount < room.capacity
                                          ? () {
                                              setState(() => _playerCount++);
                                              setModalState(() {});
                                            }
                                          : null,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Họ tên
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Họ và tên quý khách',
                        labelStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: AppColors.primaryGold,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.userSurfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Số điện thoại
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại nhận mã vé',
                        labelStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: AppColors.primaryGold,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.userSurfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 9)
                          ? 'Số điện thoại không hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Ghi chú đặc biệt + Chip chọn nhanh 1 chạm
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Yêu cầu đặc biệt (gậy, đồ uống, caddie...)',
                        labelStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primaryGold,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.userSurfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickNotes.map((tag) {
                        final hasTag = _noteController.text.contains(tag);
                        return InkWell(
                          onTap: () {
                            final current = _noteController.text.trim();
                            if (hasTag) {
                              _noteController.text = current
                                  .replaceAll(tag, '')
                                  .replaceAll(', ,', ',')
                                  .trim();
                            } else {
                              _noteController.text =
                                  current.isEmpty ? tag : '$current, $tag';
                            }
                            setModalState(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasTag
                                  ? AppColors.primaryGold.withValues(alpha: 0.2)
                                  : AppColors.userSurfaceDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasTag
                                    ? AppColors.primaryGold
                                    : AppColors.userBorder,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: hasTag
                                    ? AppColors.primaryGold
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Nút bấm xác nhận đặt
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            Navigator.pop(ctx);
                            final success = await context
                                .read<BookingProvider>()
                                .createBooking(
                                  customerName: _nameController.text.trim(),
                                  customerPhone: _phoneController.text.trim(),
                                  room: room,
                                  bookingDate: _selectedDate,
                                  timeSlot: _selectedTimeSlot,
                                  durationHours: _durationHours,
                                  playerCount: _playerCount,
                                  notes: _noteController.text.trim(),
                                );
                            if (success && mounted) {
                              final bookingList = context.read<BookingProvider>().bookings;
                              final newBooking = bookingList.isNotEmpty ? bookingList.first : null;
                              final bId = newBooking?.id ?? 'OGZ-CONFIRMED';

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (qrCtx) => VietQrPaymentDialog(
                                  bookingId: bId,
                                  roomName: room.name,
                                  amount: totalPrice,
                                  customerName: _nameController.text.trim(),
                                  onPaymentConfirmed: () {
                                    context.go('/my-bookings');
                                  },
                                ),
                              ).then((_) {
                                if (mounted) {
                                  context.go('/my-bookings');
                                }
                              });
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Phòng "${room.name}" hiện đang bận hoặc bảo trì trong khung giờ $_selectedTimeSlot. Vui lòng chọn khung giờ khác!',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'XÁC NHẬN GIỮ CHỖ • ${Formatters.formatCurrency(totalPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
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
}
