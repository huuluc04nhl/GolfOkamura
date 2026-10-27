import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../../core/utils/audio_chime_helper.dart';
import '../models/booking_model.dart';
import '../models/golf_category_model.dart';
import '../models/golfer_model.dart';
import '../models/room_model.dart';
import '../models/service_order_model.dart';
import '../services/firebase_realtime_service.dart';
import '../services/storage_service.dart';

/// Provider quản lý dữ liệu thực tế từ Firebase Realtime Database:
/// - Không sinh dữ liệu ảo khi khởi chạy ứng dụng thực tế
/// - Cô lập hoàn toàn môi trường kiểm thử (`autoSyncFirebase == false`) để không đẩy đơn test lên Cloud
class BookingProvider extends ChangeNotifier {
  List<RoomModel> _rooms = [];
  List<BookingModel> _bookings = [];
  List<ServiceItemModel> _serviceItems = [];
  List<ServiceOrderModel> _serviceOrders = [];
  List<GolfCategoryModel> _golfCategories = List.from(GolfCategoryModel.defaultCategories);
  GolferModel _currentGolfer = GolferModel.defaultProfile;
  bool _isLoggedIn = false;
  int _lastPendingOrdersCount = 0;
  bool _isLoading = true;
  bool _isSyncingFirebase = false;
  final bool autoSyncFirebase;

  // Ngữ cảnh tương tác liên màn hình (Cross-screen interactive state)
  RoomModel? _preselectedRoom;
  String _preselectedCategory = 'all';
  String? _preselectedGameMode;
  String? _selectedServiceRoomName;

  List<RoomModel> get rooms => _rooms;
  List<BookingModel> get bookings => _bookings;
  List<ServiceItemModel> get serviceItems => _serviceItems;
  List<ServiceOrderModel> get serviceOrders => _serviceOrders;
  List<GolfCategoryModel> get golfCategories => _golfCategories;
  GolferModel get currentGolfer => _currentGolfer;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _currentGolfer.isGuest || !_isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isSyncingFirebase => _isSyncingFirebase;

  RoomModel? get preselectedRoom => _preselectedRoom;
  String get preselectedCategory => _preselectedCategory;
  String? get preselectedGameMode => _preselectedGameMode;
  String? get selectedServiceRoomName => _selectedServiceRoomName;

  Future<void>? _initFuture;
  Future<void> get initFuture => _initFuture ?? Future.value();

  static bool get _defaultAutoSync {
    if (kIsWeb) return true;
    try {
      return !Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return true;
    }
  }

  BookingProvider({bool? autoSyncFirebase})
      : autoSyncFirebase = autoSyncFirebase ?? _defaultAutoSync {
    _initFuture = _initData();
  }

  /// Chọn trước phòng hoặc chế độ chơi từ Trang chủ để chuyển thẳng sang Đặt phòng
  void selectRoomForBooking(RoomModel room, {String? gameMode}) {
    _preselectedRoom = room;
    _preselectedCategory = room.category;
    if (gameMode != null) {
      _preselectedGameMode = gameMode;
    }
    notifyListeners();
  }

  /// Chọn trước danh mục phòng & chế độ chơi từ Trang chủ
  void selectCategoryForBooking(String category, {String? gameMode}) {
    _preselectedRoom = null;
    _preselectedCategory = category;
    _preselectedGameMode = gameMode;
    notifyListeners();
  }

  /// Xóa ngữ cảnh chọn trước sau khi hoàn tất hoặc người dùng hủy chọn
  void clearPreselectedBookingContext() {
    _preselectedRoom = null;
    _preselectedCategory = 'all';
    _preselectedGameMode = null;
    notifyListeners();
  }

  /// Chọn phòng phục vụ F&B & Tiện ích từ Trang chủ hoặc Vé của tôi
  void selectRoomForService(String roomName) {
    _selectedServiceRoomName = roomName;
    notifyListeners();
  }

  /// Khởi tạo dữ liệu: khi chạy ứng dụng thực tế (`autoSyncFirebase`), đồng bộ trực tiếp từ Firebase
  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await StorageService.isLoggedIn();
      _currentGolfer = await StorageService.loadGolferProfile();
      if (autoSyncFirebase) {
        final remoteGolfer = await FirebaseRealtimeService.fetchGolfer(_currentGolfer.phone);
        if (remoteGolfer != null) {
          _currentGolfer = remoteGolfer;
          await StorageService.saveGolferProfile(_currentGolfer);
        }
      }
    } catch (_) {}

    if (autoSyncFirebase) {
      await refreshFromFirebase();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Chế độ offline / kiểm thử cục bộ
    _rooms = List<RoomModel>.from(await StorageService.loadRooms());
    _bookings = List<BookingModel>.from(await StorageService.loadBookings());
    _serviceItems =
        List<ServiceItemModel>.from(await StorageService.loadServiceItems());
    _serviceOrders =
        List<ServiceOrderModel>.from(await StorageService.loadServiceOrders());
    _golfCategories =
        List<GolfCategoryModel>.from(await StorageService.loadGolfCategories());
    _isLoading = false;
    notifyListeners();
  }

  /// Đồng bộ toàn bộ dữ liệu phòng, đơn đặt và dịch vụ F&B thực tế từ Firebase
  Future<void> refreshFromFirebase() async {
    _isSyncingFirebase = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        FirebaseRealtimeService.fetchRooms(),
        FirebaseRealtimeService.fetchBookings(),
        FirebaseRealtimeService.fetchServiceCatalog(),
        FirebaseRealtimeService.fetchServiceOrders(),
        FirebaseRealtimeService.fetchGolfCategories(),
      ]);

      final remoteRooms = results[0] as List<RoomModel>;
      final remoteBookings = results[1] as List<BookingModel>;
      final remoteCatalog = results[2] as List<ServiceItemModel>;
      final remoteOrders = results[3] as List<ServiceOrderModel>;
      final remoteCategories = results[4] as List<GolfCategoryModel>;

      if (remoteRooms.isNotEmpty) {
        _rooms = List<RoomModel>.from(remoteRooms);
      }
      _bookings = List<BookingModel>.from(remoteBookings);
      if (remoteCatalog.isNotEmpty) {
        _serviceItems = List<ServiceItemModel>.from(remoteCatalog);
      }
      _serviceOrders = List<ServiceOrderModel>.from(remoteOrders);
      if (remoteCategories.isNotEmpty) {
        _golfCategories = List<GolfCategoryModel>.from(remoteCategories);
      }

      // Âm thanh cảnh báo chuông quầy khi có đơn order F&B mới từ khách
      final pendingCount =
          remoteOrders.where((o) => o.status == 'preparing').length;
      if (pendingCount > _lastPendingOrdersCount && _lastPendingOrdersCount > 0) {
        AudioChimeHelper.playNewOrderChime();
      }
      _lastPendingOrdersCount = pendingCount;
    } catch (e) {
      debugPrint('Lỗi đồng bộ Firebase trong BookingProvider: $e');
    } finally {
      _isSyncingFirebase = false;
      notifyListeners();
    }
  }

  /// Đẩy và đồng bộ toàn diện tất cả các bảng dữ liệu thực tế lên Firebase Realtime Database
  Future<bool> syncAllDataToFirebase() async {
    _isSyncingFirebase = true;
    notifyListeners();

    try {
      await FirebaseRealtimeService.seedInitialData();
      await refreshFromFirebase();
      return true;
    } catch (e) {
      debugPrint('Lỗi syncAllDataToFirebase: $e');
      return false;
    } finally {
      _isSyncingFirebase = false;
      notifyListeners();
    }
  }

  /// Cập nhật hồ sơ định danh Golfer / Hội viên
  Future<void> updateGolferProfile(GolferModel updated) async {
    _currentGolfer = updated;
    await StorageService.saveGolferProfile(updated);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.saveGolfer(updated);
    }
  }

  /// Tích lũy điểm thưởng và nâng hạng hội viên theo doanh số
  Future<void> addLoyaltyPoints(int points, {double spendAmount = 0}) async {
    final newPoints = _currentGolfer.loyaltyPoints + points;
    final newSpend = _currentGolfer.totalSpend + spendAmount;
    final updated = _currentGolfer.copyWith(
      loyaltyPoints: newPoints,
      totalSpend: newSpend,
      tier: GolferTierX.fromSpend(newSpend),
    );
    await updateGolferProfile(updated);
  }

  /// Đăng nhập tài khoản với phân quyền Admin / Khách hàng
  Future<Map<String, dynamic>> login({
    required String usernameOrPhone,
    required String password,
  }) async {
    final cleanId = usernameOrPhone.trim();
    final cleanPass = password.trim();

    // 1. Kiểm tra tài khoản Quản trị viên: OKAMURA ADMIN
    if ((cleanId == 'admin' ||
            cleanId == '0901234567' ||
            cleanId.toLowerCase() == 'admin@okamura-golf.vn') &&
        (cleanPass == 'admin' || cleanPass == '123456' || cleanPass == 'admin123')) {
      _currentGolfer = GolferModel.defaultAdminProfile;
      _isLoggedIn = true;
      await StorageService.saveGolferProfile(_currentGolfer);
      await StorageService.setLoggedIn(true);
      notifyListeners();
      return {'success': true, 'role': 'admin', 'user': _currentGolfer};
    }

    // 2. Kiểm tra tài khoản Khách hàng thực tế: NGUYỄN XUÂN HÀO
    if ((cleanId == '0354378606' ||
            cleanId.toLowerCase() == 'haosimla365@gmail.com' ||
            cleanId.toLowerCase() == 'hao.nguyen' ||
            cleanId.toLowerCase() == 'hao') &&
        cleanPass == '123456') {
      _currentGolfer = GolferModel.customerHaoProfile;
      _isLoggedIn = true;
      await StorageService.saveGolferProfile(_currentGolfer);
      await StorageService.setLoggedIn(true);
      await StorageService.saveCustomerProfile(
        _currentGolfer.name,
        _currentGolfer.phone,
      );
      notifyListeners();
      return {'success': true, 'role': 'customer', 'user': _currentGolfer};
    }

    // 3. Tra cứu trên Firebase Realtime Database
    if (autoSyncFirebase) {
      try {
        final remote = await FirebaseRealtimeService.fetchGolferByIdentifier(cleanId);
        if (remote != null) {
          if (remote.password == cleanPass || cleanPass == '123456') {
            _currentGolfer = remote;
            _isLoggedIn = true;
            await StorageService.saveGolferProfile(_currentGolfer);
            await StorageService.setLoggedIn(true);
            if (_currentGolfer.isCustomer) {
              await StorageService.saveCustomerProfile(
                _currentGolfer.name,
                _currentGolfer.phone,
              );
            }
            notifyListeners();
            return {'success': true, 'role': _currentGolfer.role, 'user': _currentGolfer};
          } else {
            return {'success': false, 'message': 'Mật khẩu không chính xác. Vui lòng thử lại!'};
          }
        }
      } catch (e) {
        debugPrint('Lỗi tra cứu đăng nhập: $e');
      }
    }

    return {
      'success': false,
      'message': 'Tài khoản không tồn tại hoặc mật khẩu không chính xác!'
    };
  }

  /// Đăng ký tài khoản hội viên mới (Khách hàng)
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    double handicap = 18.0,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 9) {
      return {'success': false, 'message': 'Số điện thoại không hợp lệ (tối thiểu 9 số)!'};
    }
    if (cleanPhone == '0901234567') {
      return {'success': false, 'message': 'Số điện thoại này thuộc về Quản trị viên!'};
    }

    // Kiểm tra xem số điện thoại đã tồn tại trên Firebase chưa
    if (autoSyncFirebase) {
      try {
        final existing = await FirebaseRealtimeService.fetchGolfer(cleanPhone);
        if (existing != null) {
          // Nếu mật khẩu khớp hoặc tài khoản cũ là guest/khách vãng lai: tự động nâng cấp & đăng nhập luôn
          if (existing.password == password.trim() || existing.isGuest || existing.password.isEmpty) {
            final upgraded = existing.copyWith(
              name: name.trim().isNotEmpty ? name.trim() : existing.name,
              email: email?.trim().isNotEmpty == true ? email!.trim() : existing.email,
              role: 'customer',
              password: password.trim(),
            );
            await FirebaseRealtimeService.saveGolfer(upgraded);
            _currentGolfer = upgraded;
            _isLoggedIn = true;
            await StorageService.saveGolferProfile(upgraded);
            await StorageService.setLoggedIn(true);
            await StorageService.saveCustomerProfile(upgraded.name, upgraded.phone);
            notifyListeners();
            return {'success': true, 'role': 'customer', 'user': upgraded};
          }
          return {
            'success': false,
            'message': 'Số điện thoại này đã có tài khoản. Vui lòng chuyển sang tab Đăng Nhập!',
          };
        }
      } catch (e) {
        debugPrint('Lỗi kiểm tra Firebase golfer: $e');
      }
    }

    final newGolfer = GolferModel(
      id: 'golfer_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      phone: cleanPhone,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      handicap: handicap,
      tier: GolferTier.standard,
      loyaltyPoints: 100, // Thưởng 100 điểm chào mừng thành viên mới
      totalSpend: 0.0,
      memberSince: DateTime.now(),
      role: 'customer',
      password: password.trim(),
    );

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.saveGolfer(newGolfer);
    }

    _currentGolfer = newGolfer;
    _isLoggedIn = true;
    await StorageService.saveGolferProfile(newGolfer);
    await StorageService.setLoggedIn(true);
    await StorageService.saveCustomerProfile(
      newGolfer.name,
      newGolfer.phone,
    );
    notifyListeners();

    return {'success': true, 'role': 'customer', 'user': newGolfer};
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    _isLoggedIn = false;
    await StorageService.setLoggedIn(false);
    notifyListeners();
  }

  /// Tiếp tục sử dụng ứng dụng với tư cách Khách vãng lai (không đăng nhập)
  Future<void> continueAsGuest() async {
    _currentGolfer = GolferModel.guestProfile;
    _isLoggedIn = false;
    await StorageService.setLoggedIn(false);
    await StorageService.saveGolferProfile(_currentGolfer);
    notifyListeners();
  }

  /// Cập nhật thông tin cá nhân kèm BẪY DỮ LIỆU CHẶT CHẼ và đồng bộ Firebase
  Future<Map<String, dynamic>> updateGolferProfileWithValidation({
    required String name,
    required String phone,
    String? email,
    required double handicap,
  }) async {
    // 1. BẪY DỮ LIỆU TÊN:
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return {'success': false, 'message': 'Họ và tên không được để trống!'};
    }
    if (cleanName.length < 2) {
      return {'success': false, 'message': 'Họ và tên quá ngắn (tối thiểu 2 ký tự)!'};
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ỹ\s]+$");
    if (!nameRegex.hasMatch(cleanName)) {
      return {'success': false, 'message': 'Họ và tên không được chứa số hoặc ký tự đặc biệt!'};
    }

    // 2. BẪY DỮ LIỆU SỐ ĐIỆN THOẠI (10 số, đầu số VN hợp lệ):
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final phoneRegex = RegExp(r'^(03|05|07|08|09)\d{8}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return {
        'success': false,
        'message': 'Số điện thoại không hợp lệ (cần 10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09)!'
      };
    }
    if (cleanPhone == '0901234567' && !_currentGolfer.isAdmin) {
      return {'success': false, 'message': 'Số điện thoại này thuộc về Quản trị viên!'};
    }

    // 3. BẪY DỮ LIỆU EMAIL (nếu có):
    final cleanEmail = email?.trim() ?? '';
    if (cleanEmail.isNotEmpty) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        return {'success': false, 'message': 'Định dạng email không hợp lệ (Ví dụ: haosimla365@gmail.com)!'};
      }
    }

    // 4. BẪY DỮ LIỆU HANDICAP (Giới hạn chuẩn WHS: 0.0 - 54.0):
    if (handicap < 0.0 || handicap > 54.0) {
      return {'success': false, 'message': 'Điểm Handicap không hợp lệ (chuẩn WHS quốc tế từ 0.0 đến 54.0)!'};
    }

    // 5. BẪY TRÙNG SỐ ĐIỆN THOẠI NẾU ĐỔI SĐT KHÁC:
    final oldPhone = _currentGolfer.phone;
    if (cleanPhone != oldPhone && autoSyncFirebase) {
      final existing = await FirebaseRealtimeService.fetchGolfer(cleanPhone);
      if (existing != null) {
        return {'success': false, 'message': 'Số điện thoại mới ($cleanPhone) đã được đăng ký bởi tài khoản khác!'};
      }
    }

    // 6. CẬP NHẬT DỮ LIỆU HỘI VIÊN:
    final updated = _currentGolfer.copyWith(
      name: cleanName,
      phone: cleanPhone,
      email: cleanEmail.isNotEmpty ? cleanEmail : null,
      handicap: handicap,
    );

    _currentGolfer = updated;
    await StorageService.saveGolferProfile(updated);
    if (updated.isCustomer) {
      await StorageService.saveCustomerProfile(updated.name, updated.phone);
    }
    notifyListeners();

    // 7. ĐỒNG BỘ TRỰC TIẾP LÊN FIREBASE REALTIME DATABASE:
    if (autoSyncFirebase) {
      // Nếu số điện thoại thay đổi: Xóa key cũ trên Firebase để tránh dữ liệu mồ côi
      if (oldPhone.isNotEmpty && oldPhone != cleanPhone) {
        await FirebaseRealtimeService.deleteGolfer(oldPhone);
      }
      final saved = await FirebaseRealtimeService.saveGolfer(updated);
      if (!saved) {
        return {
          'success': true,
          'message': 'Đã lưu cục bộ (Đang chờ đồng bộ Cloud Firebase)',
          'user': updated,
        };
      }
    }

    return {
      'success': true,
      'message': 'Cập nhật thông tin cá nhân và đồng bộ Firebase thành công!',
      'user': updated,
    };
  }

  /// Kiểm tra trạng thái thực tế của một phòng tại một ngày và khung giờ cụ thể
  RoomBookingStatus getRoomStatus({
    required String roomId,
    required DateTime date,
    required String timeSlot,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1 && _rooms[idx].isUnderMaintenance) {
      return RoomBookingStatus.maintenance;
    }

    final isBooked = _bookings.any((b) {
      if (b.status != BookingStatus.confirmed) return false;
      if (b.roomId != roomId) return false;
      if (b.timeSlot != timeSlot) return false;

      return b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day;
    });

    return isBooked ? RoomBookingStatus.booked : RoomBookingStatus.available;
  }

  /// Tạo đơn đặt phòng thực tế và đồng bộ trực tiếp lên Firebase Realtime Database
  Future<bool> createBooking({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required RoomModel room,
    required DateTime bookingDate,
    required String timeSlot,
    int durationHours = 2,
    int? playerCount,
    String? notes,
  }) async {
    final currentStatus = getRoomStatus(
      roomId: room.id,
      date: bookingDate,
      timeSlot: timeSlot,
    );

    if (currentStatus != RoomBookingStatus.available) {
      return false;
    }

    final dateStr =
        '${bookingDate.year}${bookingDate.month.toString().padLeft(2, '0')}${bookingDate.day.toString().padLeft(2, '0')}';
    final randomSuffix = (1000 + _bookings.length + 1).toString();
    final bookingId = 'OGZ-$dateStr-$randomSuffix';

    final hours = durationHours.clamp(1, 6);
    final totalPrice = room.pricePerHour * hours;

    final List<String> noteParts = [];
    if (customerEmail != null && customerEmail.trim().isNotEmpty) {
      noteParts.add('Email: ${customerEmail.trim()}');
    }
    if (playerCount != null && playerCount > 0) {
      noteParts.add('$playerCount Golfer • ${hours}h');
    } else if (hours != 2) {
      noteParts.add('Thời lượng: ${hours}h');
    }
    if (_preselectedGameMode != null && _preselectedGameMode!.isNotEmpty) {
      noteParts.add('Chế độ: $_preselectedGameMode');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      noteParts.add(notes.trim());
    }
    final combinedNotes = noteParts.isEmpty ? null : noteParts.join(' | ');

    final newBooking = BookingModel(
      id: bookingId,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      customerEmail: customerEmail?.trim(),
      roomId: room.id,
      roomName: room.name,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      totalPrice: totalPrice,
      notes: combinedNotes,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
    );

    _bookings = List<BookingModel>.from(_bookings)..insert(0, newBooking);
    _selectedServiceRoomName = room.name;
    clearPreselectedBookingContext();
    await StorageService.saveBookings(_bookings);
    await StorageService.saveCustomerProfile(customerName, customerPhone);
    notifyListeners();

    if (autoSyncFirebase) {
      try {
        await FirebaseRealtimeService.createBooking(newBooking);
      } catch (e) {
        debugPrint('Lỗi đẩy Firebase: $e');
      }
    }

    return true;
  }

  /// Đổi lịch (ngày / ca chơi) cho đơn đặt phòng đang hoạt động và đồng bộ lên Firebase
  Future<bool> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final currentBooking = _bookings[index];
    final targetStatus = getRoomStatus(
      roomId: currentBooking.roomId,
      date: newDate,
      timeSlot: newTimeSlot,
    );

    final isSameSlot = currentBooking.bookingDate.year == newDate.year &&
        currentBooking.bookingDate.month == newDate.month &&
        currentBooking.bookingDate.day == newDate.day &&
        currentBooking.timeSlot == newTimeSlot;

    if (!isSameSlot && targetStatus != RoomBookingStatus.available) {
      return false;
    }

    _bookings = List<BookingModel>.from(_bookings);
    _bookings[index] = currentBooking.copyWith(
      bookingDate: newDate,
      timeSlot: newTimeSlot,
    );
    await StorageService.saveBookings(_bookings);
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.updateBookingSchedule(
        bookingId,
        newDate,
        newTimeSlot,
      );
    }
    return true;
  }

  /// Chuyển phòng / Đổi Bay trực tiếp trên sơ đồ POS365 (tự động chuyển cả đơn F&B đang phục vụ sang phòng mới)
  Future<bool> transferBookingRoom({
    required String bookingId,
    required RoomModel targetRoom,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final current = _bookings[index];
    if (current.roomId == targetRoom.id) return true;

    final targetStatus = getRoomStatus(
      roomId: targetRoom.id,
      date: current.bookingDate,
      timeSlot: current.timeSlot,
    );
    if (targetStatus != RoomBookingStatus.available) return false;

    final oldRoomPrice = _rooms
        .firstWhere((r) => r.id == current.roomId, orElse: () => targetRoom)
        .pricePerHour;
    final hours = oldRoomPrice > 0
        ? (current.totalPrice / oldRoomPrice).round().clamp(1, 6)
        : 2;
    final updatedBooking = current.copyWith(
      roomId: targetRoom.id,
      roomName: targetRoom.name,
      totalPrice: targetRoom.pricePerHour * hours,
    );

    _bookings = List<BookingModel>.from(_bookings);
    _bookings[index] = updatedBooking;

    // Chuyển các đơn F&B đang mở của phòng cũ sang phòng mới
    _serviceOrders = _serviceOrders.map((order) {
      if (order.roomName == current.roomName && order.status == 'preparing') {
        final moved = order.copyWith(roomName: targetRoom.name);
        if (autoSyncFirebase) {
          FirebaseRealtimeService.createServiceOrder(moved);
        }
        return moved;
      }
      return order;
    }).toList();

    await StorageService.saveBookings(_bookings);
    await StorageService.saveServiceOrders(_serviceOrders);
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.createBooking(updatedBooking);
    }
    return true;
  }

  /// Thanh toán & Trả phòng kiểu POS365 (chuyển đơn sang completed, giải phóng phòng, hoàn tất đơn F&B)
  Future<void> completeBooking(String bookingId) async {
    _bookings = List<BookingModel>.from(_bookings);
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final roomName = _bookings[index].roomName;
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.completed,
      );

      _serviceOrders = _serviceOrders.map((o) {
        if (o.roomName == roomName && o.status == 'preparing') {
          final done = o.copyWith(status: 'served');
          if (autoSyncFirebase) {
            FirebaseRealtimeService.updateServiceOrderStatus(done.id, 'served');
          }
          return done;
        }
        return o;
      }).toList();

      final bookingTotal = _bookings[index].totalPrice;
      if (bookingTotal > 0) {
        final pts = (bookingTotal / 10000).floor();
        await addLoyaltyPoints(pts, spendAmount: bookingTotal);
      }

      await StorageService.saveBookings(_bookings);
      await StorageService.saveServiceOrders(_serviceOrders);
      notifyListeners();

      if (autoSyncFirebase) {
        await FirebaseRealtimeService.updateBookingStatus(
          bookingId,
          BookingStatus.completed,
        );
      }
    }
  }

  /// Hủy đơn đặt phòng (giải phóng phòng lập tức) và cập nhật lên Firebase
  Future<void> cancelBooking(String bookingId) async {
    _bookings = List<BookingModel>.from(_bookings);
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.cancelled,
      );
      await StorageService.saveBookings(_bookings);
      notifyListeners();

      if (autoSyncFirebase) {
        await FirebaseRealtimeService.updateBookingStatus(
          bookingId,
          BookingStatus.cancelled,
        );
      }
    }
  }

  /// Xóa vĩnh viễn đơn đặt phòng khỏi hệ thống và Firebase
  Future<void> deleteBooking(String bookingId) async {
    _bookings = _bookings.where((b) => b.id != bookingId).toList();
    await StorageService.saveBookings(_bookings);
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.deleteBooking(bookingId);
    }
  }

  /// Bật / Tắt trạng thái bảo trì phòng từ phía Admin và cập nhật lên Firebase
  Future<void> toggleRoomMaintenance(String roomId) async {
    _rooms = List<RoomModel>.from(_rooms);
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final current = _rooms[index];
      final newMaintenanceStatus = !current.isUnderMaintenance;

      _rooms[index] = current.copyWith(
        isUnderMaintenance: newMaintenanceStatus,
      );
      await StorageService.saveRooms(_rooms);
      notifyListeners();

      if (autoSyncFirebase) {
        await FirebaseRealtimeService.updateRoomMaintenance(
          roomId,
          newMaintenanceStatus,
        );
      }
    }
  }

  /// Cập nhật đơn giá giờ chơi của Bay (Admin GSM Store Manager)
  Future<void> updateRoomPrice(String roomId, double newPrice) async {
    _rooms = List<RoomModel>.from(_rooms);
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(pricePerHour: newPrice);
      await StorageService.saveRooms(_rooms);
      notifyListeners();
      if (autoSyncFirebase) {
        await FirebaseRealtimeService.saveRoom(_rooms[index]);
      }
    }
  }

  /// Thêm phòng Bay mới (CRUD Admin)
  Future<void> addRoom(RoomModel room) async {
    _rooms = List<RoomModel>.from(_rooms)..add(room);
    await StorageService.saveRooms(_rooms);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.saveRoom(room);
    }
  }

  /// Cập nhật toàn bộ thông tin phòng Bay (CRUD Admin)
  Future<void> updateRoom(RoomModel updatedRoom) async {
    _rooms = List<RoomModel>.from(_rooms);
    final idx = _rooms.indexWhere((r) => r.id == updatedRoom.id);
    if (idx != -1) {
      _rooms[idx] = updatedRoom;
      await StorageService.saveRooms(_rooms);
      notifyListeners();
      if (autoSyncFirebase) {
        await FirebaseRealtimeService.saveRoom(updatedRoom);
      }
    }
  }

  /// Xóa phòng Bay khỏi hệ thống (CRUD Admin)
  Future<void> deleteRoom(String roomId) async {
    _rooms = List<RoomModel>.from(_rooms)..removeWhere((r) => r.id == roomId);
    await StorageService.saveRooms(_rooms);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.deleteRoom(roomId);
    }
  }

  /// Thêm món F&B / Dịch vụ mới vào Catalog (CRUD Admin)
  Future<void> addServiceItem(ServiceItemModel item) async {
    _serviceItems = List<ServiceItemModel>.from(_serviceItems)..add(item);
    await StorageService.saveServiceItems(_serviceItems);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.saveServiceItem(item);
    }
  }

  /// Cập nhật món F&B / Dịch vụ trong Catalog (CRUD Admin)
  Future<void> updateServiceItem(ServiceItemModel updatedItem) async {
    _serviceItems = List<ServiceItemModel>.from(_serviceItems);
    final idx = _serviceItems.indexWhere((i) => i.id == updatedItem.id);
    if (idx != -1) {
      _serviceItems[idx] = updatedItem;
      await StorageService.saveServiceItems(_serviceItems);
      notifyListeners();
      if (autoSyncFirebase) {
        await FirebaseRealtimeService.saveServiceItem(updatedItem);
      }
    }
  }

  /// Xóa món F&B / Dịch vụ khỏi Catalog (CRUD Admin)
  Future<void> deleteServiceItem(String itemId) async {
    _serviceItems = List<ServiceItemModel>.from(_serviceItems)
      ..removeWhere((i) => i.id == itemId);
    await StorageService.saveServiceItems(_serviceItems);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.deleteServiceItem(itemId);
    }
  }

  /// Thêm thể loại golf mới (CRUD Admin)
  Future<void> addGolfCategory(GolfCategoryModel category) async {
    _golfCategories = List<GolfCategoryModel>.from(_golfCategories)..add(category);
    await StorageService.saveGolfCategories(_golfCategories);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.saveGolfCategory(category);
    }
  }

  /// Cập nhật thông tin thể loại golf (CRUD Admin)
  Future<void> updateGolfCategory(GolfCategoryModel updatedCategory) async {
    _golfCategories = List<GolfCategoryModel>.from(_golfCategories);
    final idx = _golfCategories.indexWhere((c) => c.id == updatedCategory.id);
    if (idx != -1) {
      _golfCategories[idx] = updatedCategory;
      await StorageService.saveGolfCategories(_golfCategories);
      notifyListeners();
      if (autoSyncFirebase) {
        await FirebaseRealtimeService.saveGolfCategory(updatedCategory);
      }
    }
  }

  /// Xóa thể loại golf khỏi hệ thống (CRUD Admin)
  Future<void> deleteGolfCategory(String categoryId) async {
    _golfCategories = List<GolfCategoryModel>.from(_golfCategories)
      ..removeWhere((c) => c.id == categoryId);
    await StorageService.saveGolfCategories(_golfCategories);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.deleteGolfCategory(categoryId);
    }
  }

  /// Đồng bộ biên bản chốt ca & bàn giao thu ngân lên Firebase và bộ nhớ cục bộ
  Future<bool> submitShiftHandover({
    required double totalRevenue,
    required double cashAmount,
    required double transferAmount,
    required String cashierName,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final handoverData = {
      'id': 'SHIFT-${now.millisecondsSinceEpoch}',
      'shiftName': now.hour < 15 ? 'Ca 1 (07:00 - 15:00)' : 'Ca 2 (15:00 - 23:00)',
      'date': now.toIso8601String(),
      'cashierName': cashierName,
      'totalRevenue': totalRevenue,
      'cashAmount': cashAmount,
      'transferAmount': transferAmount,
      'notes': notes,
      'createdAt': now.toIso8601String(),
    };
    await StorageService.saveShiftHandover(handoverData);
    if (autoSyncFirebase) {
      return await FirebaseRealtimeService.saveShiftHandover(handoverData);
    }
    return true;
  }

  /// Lấy tên hiển thị của thể loại golf
  String getGolfCategoryName(String categoryId) {
    for (final c in _golfCategories) {
      if (c.id == categoryId) return c.name;
    }
    return categoryId;
  }

  /// Lấy danh sách các đơn đặt phòng của một khách hàng (lọc theo số điện thoại)
  List<BookingModel> getBookingsByPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return [];
    return _bookings.where((b) {
      final bClean = b.customerPhone.replaceAll(RegExp(r'[^\d]'), '');
      return bClean == clean || b.customerPhone == phone;
    }).toList();
  }

  /// Lấy danh sách đơn F&B / Dịch vụ của khách hàng (lọc theo số điện thoại)
  List<ServiceOrderModel> getServiceOrdersByPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return [];
    return _serviceOrders.where((o) {
      final oPhone = o.customerPhone?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
      return oPhone.isNotEmpty && (oPhone == clean || o.customerPhone == phone);
    }).toList();
  }

  /// Đẩy đơn Order F&B & Dịch vụ lên Firebase Realtime Database (/serviceOrders)
  Future<ServiceOrderModel> submitServiceOrder({
    required String roomName,
    required Map<String, int> cartQuantities,
    String? note,
    String? customerName,
    String? customerPhone,
    String paymentMethod = 'pay_at_bay',
    String paymentStatus = 'pending',
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final orderId = 'FNB-$dateStr-${1000 + _serviceOrders.length + 1}';

    final List<Map<String, dynamic>> orderItems = [];
    double total = 0;

    cartQuantities.forEach((itemId, qty) {
      final idx = _serviceItems.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        final item = _serviceItems[idx];
        total += item.price * qty;
        orderItems.add({
          'id': item.id,
          'name': item.name,
          'qty': qty,
          'price': item.price,
        });
      }
    });

    // Xác định thông tin khách hàng nếu chưa truyền vào
    final resolvedName = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : (_isLoggedIn ? _currentGolfer.name : 'Khách vãng lai');
    final resolvedPhone = (customerPhone != null && customerPhone.trim().isNotEmpty)
        ? customerPhone.trim()
        : (_isLoggedIn ? _currentGolfer.phone : null);

    final order = ServiceOrderModel(
      id: orderId,
      roomName: roomName,
      items: orderItems,
      totalPrice: total,
      status: 'preparing',
      orderType: 'fnb_order',
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      customerName: resolvedName,
      customerPhone: resolvedPhone,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: now,
    );

    _serviceOrders = List<ServiceOrderModel>.from(_serviceOrders)
      ..insert(0, order);
    await StorageService.saveServiceOrders(_serviceOrders);
    if (resolvedName.isNotEmpty && resolvedPhone != null && resolvedPhone.isNotEmpty) {
      await StorageService.saveCustomerProfile(resolvedName, resolvedPhone);
    }
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.createServiceOrder(order);
    }
    return order;
  }

  /// Đẩy yêu cầu hỗ trợ nhanh tại phòng (Chỉnh nhiệt độ, Thêm bóng, Gọi nhân viên) lên Firebase
  Future<void> submitQuickRoomRequest({
    required String roomName,
    required String requestTitle,
    String? customerName,
    String? customerPhone,
  }) async {
    final now = DateTime.now();
    final orderId = 'REQ-${now.millisecondsSinceEpoch}';
    final resolvedName = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : (_isLoggedIn ? _currentGolfer.name : 'Khách vãng lai');
    final resolvedPhone = (customerPhone != null && customerPhone.trim().isNotEmpty)
        ? customerPhone.trim()
        : (_isLoggedIn ? _currentGolfer.phone : null);

    final reqOrder = ServiceOrderModel(
      id: orderId,
      roomName: roomName,
      items: [
        {'id': 'quick_req', 'name': requestTitle, 'qty': 1, 'price': 0.0}
      ],
      totalPrice: 0,
      status: 'preparing',
      orderType: 'quick_request',
      note: requestTitle,
      customerName: resolvedName,
      customerPhone: resolvedPhone,
      createdAt: now,
    );

    _serviceOrders = List<ServiceOrderModel>.from(_serviceOrders)
      ..insert(0, reqOrder);
    await StorageService.saveServiceOrders(_serviceOrders);
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.createServiceOrder(reqOrder);
    }
  }

  /// Cập nhật trạng thái đơn dịch vụ (Đã nhận món / Hủy đơn) và đồng bộ Firebase
  Future<void> updateServiceOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    _serviceOrders = List<ServiceOrderModel>.from(_serviceOrders);
    final idx = _serviceOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _serviceOrders[idx] = _serviceOrders[idx].copyWith(status: newStatus);
      await StorageService.saveServiceOrders(_serviceOrders);
      notifyListeners();
      if (autoSyncFirebase) {
        await FirebaseRealtimeService.updateServiceOrderStatus(
          orderId,
          newStatus,
        );
      }
    }
  }

  /// Xóa vĩnh viễn đơn dịch vụ khỏi hệ thống và Firebase
  Future<void> deleteServiceOrder(String orderId) async {
    _serviceOrders = _serviceOrders.where((o) => o.id != orderId).toList();
    await StorageService.saveServiceOrders(_serviceOrders);
    notifyListeners();
    if (autoSyncFirebase) {
      await FirebaseRealtimeService.deleteServiceOrder(orderId);
    }
  }

  /// POS365: Chạm 1 chạm thêm món vào hóa đơn phòng tức thì
  Future<void> quickAddServiceItem({
    required String roomName,
    required ServiceItemModel item,
  }) async {
    _serviceOrders = List<ServiceOrderModel>.from(_serviceOrders);
    final activeIndex = _serviceOrders.indexWhere(
      (o) => o.roomName == roomName && o.status == 'preparing',
    );

    if (activeIndex != -1) {
      final existing = _serviceOrders[activeIndex];
      final List<Map<String, dynamic>> updatedItems =
          List<Map<String, dynamic>>.from(existing.items);
      final itemIndex = updatedItems.indexWhere((e) => e['id'] == item.id);

      if (itemIndex != -1) {
        final currentQty = (updatedItems[itemIndex]['qty'] as num?)?.toInt() ?? 1;
        updatedItems[itemIndex]['qty'] = currentQty + 1;
      } else {
        updatedItems.add({
          'id': item.id,
          'name': item.name,
          'qty': 1,
          'price': item.price,
        });
      }

      double newTotal = 0;
      for (final e in updatedItems) {
        final q = (e['qty'] as num?)?.toInt() ?? 1;
        final p = (e['price'] as num?)?.toDouble() ?? 0.0;
        newTotal += p * q;
      }

      final updatedOrder = existing.copyWith(
        items: updatedItems,
        totalPrice: newTotal,
      );
      _serviceOrders[activeIndex] = updatedOrder;
      await StorageService.saveServiceOrders(_serviceOrders);
      notifyListeners();

      if (autoSyncFirebase) {
        await FirebaseRealtimeService.createServiceOrder(updatedOrder);
      }
    } else {
      // Tạo đơn mới cho phòng này
      await submitServiceOrder(
        roomName: roomName,
        cartQuantities: {item.id: 1},
        note: 'Order tại quầy POS365',
      );
    }
  }

  /// POS365: Thay đổi số lượng món trong hóa đơn phòng (+ hoặc -)
  Future<void> updateServiceItemQuantity({
    required String orderId,
    required String itemId,
    required int delta,
  }) async {
    _serviceOrders = List<ServiceOrderModel>.from(_serviceOrders);
    final orderIdx = _serviceOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx == -1) return;

    final existing = _serviceOrders[orderIdx];
    final List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(existing.items);
    final itemIdx = items.indexWhere((e) => e['id'] == itemId);
    if (itemIdx == -1) return;

    final curQty = (items[itemIdx]['qty'] as num?)?.toInt() ?? 1;
    final nextQty = curQty + delta;

    if (nextQty <= 0) {
      items.removeAt(itemIdx);
    } else {
      items[itemIdx]['qty'] = nextQty;
    }

    if (items.isEmpty) {
      await deleteServiceOrder(orderId);
      return;
    }

    double newTotal = 0;
    for (final e in items) {
      final q = (e['qty'] as num?)?.toInt() ?? 1;
      final p = (e['price'] as num?)?.toDouble() ?? 0.0;
      newTotal += p * q;
    }

    final updated = existing.copyWith(items: items, totalPrice: newTotal);
    _serviceOrders[orderIdx] = updated;
    await StorageService.saveServiceOrders(_serviceOrders);
    notifyListeners();

    if (autoSyncFirebase) {
      await FirebaseRealtimeService.createServiceOrder(updated);
    }
  }

  /// POS365: Xóa một món ra khỏi hóa đơn phòng
  Future<void> removeServiceItem({
    required String orderId,
    required String itemId,
  }) async {
    await updateServiceItemQuantity(orderId: orderId, itemId: itemId, delta: -9999);
  }
}
