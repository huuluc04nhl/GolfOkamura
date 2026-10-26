import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/language_selector_pill.dart';
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
  int _currentStep = 1; // 1: Ngày chơi, 2: Khung giờ & Thời lượng, 3: Chọn phòng, 4: Thông tin khách vãng lai
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = AppConstants.standardTimeSlots[0];
  String _roomFilter = 'all';
  int _durationHours = 2;
  int _playerCount = 4;
  RoomModel? _selectedRoom;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _guestFormKey = GlobalKey<FormState>();

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
          _selectedRoom = provider.preselectedRoom;
          _playerCount = provider.preselectedRoom!.capacity.clamp(1, 4);
        });
      }
    });
  }

  Future<void> _loadPreviousCustomerProfile() async {
    final provider = context.read<BookingProvider>();
    if (!mounted) return;
    if (provider.isLoggedIn && !provider.isGuest) {
      _nameController.text = provider.currentGolfer.name;
      _phoneController.text = provider.currentGolfer.phone;
      _emailController.text = provider.currentGolfer.email ?? '';
    } else {
      // Đối với Khách vãng lai: Tuyệt đối KHÔNG tự động nhập sẵn dữ liệu cũ, để trường nhập trống hoàn toàn
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        title: Text(context.tr('booking_screen_title')),
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
        actions: const [
          LanguageSelectorPill(compact: true),
          SizedBox(width: 10),
        ],
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
                  final maxStep = provider.isGuest ? 4 : 3;
                  final v = details.primaryVelocity ?? 0;
                  if (v < -350 && _currentStep < maxStep) {
                    if (_currentStep == 3 && provider.isGuest && _selectedRoom == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn phòng ở Bước 3 trước khi sang bước nhập thông tin'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      setState(() => _currentStep++);
                    }
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
                          if (_currentStep == 4)
                            _selectedRoom != null
                                ? _buildStep4GuestInfo(_selectedRoom!, provider)
                                : _buildStep3RoomSelection(),
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
              onTap: () {
                if (provider.isGuest) {
                  setState(() {
                    _selectedRoom = preRoom;
                    _currentStep = 4;
                  });
                } else {
                  _showBookingBottomSheet(preRoom);
                }
              },
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

  /// Thanh chỉ báo tiến trình đặt phòng (3 bước cho hội viên, 4 bước cho khách vãng lai)
  Widget _buildStepIndicator(double hPadding) {
    final isGuest = context.watch<BookingProvider>().isGuest;
    return Container(
      color: AppColors.userCardDark,
      padding: EdgeInsets.symmetric(horizontal: hPadding > 12 ? 12 : 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStepPill(1, context.tr('step_1_date'), Icons.calendar_today_rounded),
          ),
          const Icon(Icons.chevron_right, size: 13, color: AppColors.userBorder),
          Expanded(
            child: _buildStepPill(2, context.tr('step_2_time'), Icons.access_time_rounded),
          ),
          const Icon(Icons.chevron_right, size: 13, color: AppColors.userBorder),
          Expanded(
            child: _buildStepPill(3, context.tr('step_3_room'), Icons.meeting_room_rounded),
          ),
          if (isGuest) ...[
            const Icon(Icons.chevron_right, size: 13, color: AppColors.userBorder),
            Expanded(
              child: _buildStepPill(4, context.tr('step_4_info'), Icons.person_pin_rounded),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPill(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return GestureDetector(
      onTap: () {
        if (step == 4 && _selectedRoom == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chọn phòng ở Bước 3 trước khi sang bước nhập thông tin'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        setState(() => _currentStep = step);
      },
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
            final isChosen = isPreselected || (provider.isGuest && _selectedRoom?.id == room.id);

            return InkWell(
              onTap: isAvailable
                  ? () {
                      if (provider.isGuest) {
                        setState(() {
                          _selectedRoom = room;
                          _currentStep = 4;
                        });
                      } else {
                        _showBookingBottomSheet(room);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.userCardDark,
                  gradient: isChosen
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryGold.withValues(alpha: 0.16),
                            AppColors.userCardDark,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isChosen
                        ? AppColors.primaryGold
                        : isAvailable
                            ? AppColors.primaryGold.withValues(alpha: 0.4)
                            : isMaintenance
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppColors.userBorder,
                    width: isChosen ? 1.5 : 1.0,
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
                      onPressed: () {
                        if (provider.isGuest) {
                          setState(() {
                            _selectedRoom = room;
                            _currentStep = 4;
                          });
                        } else {
                          _showBookingBottomSheet(room);
                        }
                      },
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
                      child: Text(
                        provider.isGuest ? 'Chọn phòng' : 'Đặt ngay',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
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
                          const Divider(color: AppColors.userBorder, height: 18, thickness: 1),
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

                    if (context.read<BookingProvider>().isGuest) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, color: Colors.amber, size: 15),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Bạn đang đặt phòng với tư cách Khách vãng lai (không tích lũy điểm VIP)',
                                style: TextStyle(color: Colors.amber, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                                  customerEmail: _emailController.text.trim().isNotEmpty
                                      ? _emailController.text.trim()
                                      : null,
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

  /// Bước 4: Nhập thông tin liên hệ chi tiết dành riêng cho Khách vãng lai
  Widget _buildStep4GuestInfo(RoomModel room, BookingProvider provider) {
    final totalPrice = room.pricePerHour * _durationHours;
    final quickNotes = [
      'Gậy TaylorMade tay phải',
      'Gậy tay trái',
      'Ướp lạnh bia Asahi',
      'Cần Caddie hỗ trợ',
      'Tập Driving Range trước 30p',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bước 4
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: AppColors.primaryGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BƯỚC 4: THÔNG TIN KHÁCH HÀNG',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dành cho khách vãng lai đặt phòng trực tuyến',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = 3),
              icon: const Icon(Icons.edit, size: 14, color: AppColors.primaryGold),
              label: const Text(
                'Đổi phòng',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Banner thông báo khách vãng lai & gợi ý đăng nhập
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đặt phòng với tư cách Khách vãng lai',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Vui lòng nhập chính xác họ tên và số điện thoại để lễ tân gửi mã PIN nhận phòng và liên hệ xác nhận giờ chơi.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () => context.push('/login?tab=register'),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.card_membership_rounded, color: AppColors.primaryGold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Đăng ký Hội viên VIP →',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/login?tab=login'),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.login_rounded, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
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
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card tóm tắt phòng & cấu hình ca chơi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.userCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${room.categoryLabel} • Cảm biến ${room.sensorModel}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalPrice),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.userBorder, height: 20, thickness: 1),

              // Ngày & Giờ
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGold),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.formatDate(_selectedDate),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryGold),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedTimeSlot (${_durationHours}h)',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bộ chỉnh thời lượng
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
                          onTap: () => setState(() => _durationHours = hrs),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryGold : AppColors.userSurfaceDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.primaryGold : AppColors.userBorder,
                              ),
                            ),
                            child: Text(
                              '${hrs}h',
                              style: TextStyle(
                                color: selected ? Colors.black : AppColors.textMuted,
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
              const SizedBox(height: 12),

              // Bộ chỉnh số lượng Golfer
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
                      color: AppColors.userSurfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _playerCount > 1
                              ? () => setState(() => _playerCount--)
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.remove, size: 15, color: AppColors.primaryGold),
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
                              ? () => setState(() => _playerCount++)
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.add, size: 15, color: AppColors.primaryGold),
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
        const SizedBox(height: 18),

        // Form điền thông tin cá nhân bắt buộc (có validation trapping nghiêm ngặt)
        Form(
          key: _guestFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THÔNG TIN LIÊN HỆ ĐẶT PHÒNG (*)',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Họ tên
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Họ và tên quý khách (*)',
                  hintText: 'Ví dụ: Trần Văn Nam',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primaryGold, size: 20),
                  filled: true,
                  fillColor: AppColors.userCardDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Vui lòng nhập họ và tên';
                  if (trimmed.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Số điện thoại
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại nhận mã vé (*)',
                  hintText: 'Ví dụ: 0912345678',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryGold, size: 20),
                  filled: true,
                  fillColor: AppColors.userCardDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.replaceAll(RegExp(r'[\s\.\-]'), '') ?? '';
                  if (trimmed.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (trimmed.length < 9) return 'Số điện thoại tối thiểu 9-10 chữ số';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Email nhận hóa đơn/vé (Không bắt buộc)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Email nhận vé điện tử (Không bắt buộc)',
                  hintText: 'Ví dụ: customer@gmail.com',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGold, size: 20),
                  filled: true,
                  fillColor: AppColors.userCardDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return null; // Không bắt buộc
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(trimmed)) {
                    return 'Email không đúng định dạng (ví dụ: golfer@gmail.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Ghi chú đặc biệt
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Yêu cầu đặc biệt (gậy, đồ uống, caddie...)',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryGold, size: 20),
                  filled: true,
                  fillColor: AppColors.userCardDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.userBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Quick tags
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
                        _noteController.text = current.isEmpty ? tag : '$current, $tag';
                      }
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasTag
                            ? AppColors.primaryGold.withValues(alpha: 0.2)
                            : AppColors.userCardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasTag ? AppColors.primaryGold : AppColors.userBorder,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: hasTag ? AppColors.primaryGold : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Nút xác nhận đặt chỗ & mở mã QR thanh toán
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_guestFormKey.currentState?.validate() ?? false) {
                      final name = _nameController.text.trim();
                      final phone = _phoneController.text.trim();
                      final email = _emailController.text.trim();
                      final notes = _noteController.text.trim();

                      final success = await provider.createBooking(
                        customerName: name,
                        customerPhone: phone,
                        customerEmail: email,
                        room: room,
                        bookingDate: _selectedDate,
                        timeSlot: _selectedTimeSlot,
                        durationHours: _durationHours,
                        playerCount: _playerCount,
                        notes: notes,
                      );

                      if (success && mounted) {
                        final bookingList = provider.bookings;
                        final newBooking = bookingList.isNotEmpty ? bookingList.first : null;
                        final bId = newBooking?.id ?? 'OGZ-CONFIRMED';

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (qrCtx) => VietQrPaymentDialog(
                            bookingId: bId,
                            roomName: room.name,
                            amount: totalPrice,
                            customerName: name,
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
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'XÁC NHẬN GIỮ CHỖ • ${Formatters.formatCurrency(totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nút quay lại chọn phòng
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _currentStep = 3),
                  icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                  label: const Text(
                    'Quay lại bước chọn phòng',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
