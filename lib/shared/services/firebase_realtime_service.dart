import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/golf_category_model.dart';
import '../models/golfer_model.dart';
import '../models/room_model.dart';
import '../models/service_order_model.dart';
import 'storage_service.dart';

/// Dịch vụ kết nối và đồng bộ trực tiếp với Firebase Realtime Database
/// URL: https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app/
class FirebaseRealtimeService {
  static final String _baseUrl = AppConstants.firebaseDatabaseUrl;

  /// Lấy danh sách phòng chơi thực tế từ Firebase
  static Future<List<RoomModel>> fetchRooms() async {
    try {
      final url = Uri.parse('$_baseUrl/rooms.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body != 'null') {
        final decodedString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedString);

        final List<RoomModel> rooms = [];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final roomMap = Map<String, dynamic>.from(value);
            roomMap['id'] ??= key;
            rooms.add(RoomModel.fromMap(roomMap));
          }
        });

        if (rooms.isNotEmpty) {
          await StorageService.saveRooms(rooms);
          return rooms;
        }
      }

      await seedInitialData();
      return StorageService.initialRooms.toList();
    } catch (e) {
      debugPrint('Lỗi fetchRooms từ Firebase (sử dụng cache cục bộ): $e');
      return await StorageService.loadRooms();
    }
  }

  /// Lấy toàn bộ đơn đặt phòng thực tế từ Firebase (nếu trống trên Cloud thì xóa cache cũ)
  static Future<List<BookingModel>> fetchBookings() async {
    try {
      final url = Uri.parse('$_baseUrl/bookings.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body == 'null' || response.body.trim().isEmpty) {
          await StorageService.saveBookings(const []);
          return [];
        }
        final decodedString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedString);

        final List<BookingModel> bookings = [];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final bookingMap = Map<String, dynamic>.from(value);
            bookingMap['id'] ??= key;
            try {
              bookings.add(BookingModel.fromMap(bookingMap));
            } catch (err) {
              debugPrint('Lỗi parse đơn đặt: $err');
            }
          }
        });

        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await StorageService.saveBookings(bookings);
        return bookings;
      }
      return await StorageService.loadBookings();
    } catch (e) {
      debugPrint('Lỗi fetchBookings từ Firebase (sử dụng cache): $e');
      return await StorageService.loadBookings();
    }
  }

  /// Lấy danh mục dịch vụ F&B, thuê gậy & HLV từ Firebase (/serviceCatalog)
  static Future<List<ServiceItemModel>> fetchServiceCatalog() async {
    try {
      final url = Uri.parse('$_baseUrl/serviceCatalog.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body != 'null') {
        final decodedString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedString);

        final List<ServiceItemModel> items = [];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final itemMap = Map<String, dynamic>.from(value);
            itemMap['id'] ??= key;
            items.add(ServiceItemModel.fromMap(itemMap));
          }
        });

        if (items.isNotEmpty) {
          await StorageService.saveServiceItems(items);
          return items;
        }
      }

      await seedServiceCatalog();
      return StorageService.initialServiceItems.toList();
    } catch (e) {
      debugPrint('Lỗi fetchServiceCatalog từ Firebase: $e');
      return await StorageService.loadServiceItems();
    }
  }

  /// Lấy danh sách đơn gọi món / yêu cầu hỗ trợ phòng thực tế từ Firebase (/serviceOrders)
  static Future<List<ServiceOrderModel>> fetchServiceOrders() async {
    try {
      final url = Uri.parse('$_baseUrl/serviceOrders.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body == 'null' || response.body.trim().isEmpty) {
          await StorageService.saveServiceOrders(const []);
          return [];
        }
        final decodedString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedString);

        final List<ServiceOrderModel> orders = [];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final orderMap = Map<String, dynamic>.from(value);
            orderMap['id'] ??= key;
            orders.add(ServiceOrderModel.fromMap(orderMap));
          }
        });

        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await StorageService.saveServiceOrders(orders);
        return orders;
      }
      return await StorageService.loadServiceOrders();
    } catch (e) {
      debugPrint('Lỗi fetchServiceOrders từ Firebase: $e');
      return await StorageService.loadServiceOrders();
    }
  }

  /// Đẩy đơn Order F&B hoặc yêu cầu hỗ trợ phòng trực tiếp lên Firebase (/serviceOrders)
  static Future<bool> createServiceOrder(ServiceOrderModel order) async {
    try {
      final url = Uri.parse('$_baseUrl/serviceOrders/${order.id}.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(order.toMap())),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi createServiceOrder lên Firebase: $e');
      return false;
    }
  }

  /// Xóa vĩnh viễn một đơn dịch vụ trên Firebase (/serviceOrders/{id})
  static Future<bool> deleteServiceOrder(String orderId) async {
    try {
      final url = Uri.parse('$_baseUrl/serviceOrders/$orderId.json');
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteServiceOrder trên Firebase: $e');
      return false;
    }
  }

  /// Tạo đơn đặt phòng mới và đẩy trực tiếp lên Firebase (mã hóa chuẩn UTF-8)
  static Future<bool> createBooking(BookingModel booking) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/${booking.id}.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(booking.toMap())),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errBody = utf8.decode(response.bodyBytes);
        debugPrint('PAYLOAD: ${json.encode(booking.toMap())}');
        debugPrint('Firebase trả về mã lỗi ${response.statusCode} (${response.reasonPhrase}): [$errBody] cho URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi createBooking lên Firebase: $e');
      return false;
    }
  }

  /// Xóa vĩnh viễn một đơn đặt phòng trên Firebase (/bookings/{id})
  static Future<bool> deleteBooking(String bookingId) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/$bookingId.json');
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteBooking trên Firebase: $e');
      return false;
    }
  }

  /// Cập nhật trạng thái đơn đặt phòng trên Firebase (ví dụ: hủy phòng)
  static Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/$bookingId.json');
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode({'status': status.name})),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi updateBookingStatus trên Firebase: $e');
      return false;
    }
  }

  /// Cập nhật trạng thái đơn dịch vụ F&B / yêu cầu hỗ trợ trên Firebase (/serviceOrders)
  static Future<bool> updateServiceOrderStatus(String orderId, String status) async {
    try {
      final url = Uri.parse('$_baseUrl/serviceOrders/$orderId.json');
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode({'status': status})),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi updateServiceOrderStatus trên Firebase: $e');
      return false;
    }
  }

  /// Đổi ngày/giờ chơi cho đơn đặt phòng trực tiếp trên Firebase
  static Future<bool> updateBookingSchedule(
    String bookingId,
    DateTime bookingDate,
    String timeSlot,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/$bookingId.json');
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(
              json.encode({
                'bookingDate': bookingDate.toIso8601String(),
                'timeSlot': timeSlot,
              }),
            ),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi updateBookingSchedule trên Firebase: $e');
      return false;
    }
  }

  /// Cập nhật trạng thái bảo trì phòng chơi lên Firebase
  static Future<bool> updateRoomMaintenance(String roomId, bool isUnderMaintenance) async {
    try {
      final url = Uri.parse('$_baseUrl/rooms/$roomId.json');
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode({'isUnderMaintenance': isUnderMaintenance})),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi updateRoomMaintenance trên Firebase: $e');
      return false;
    }
  }

  /// Khởi tạo danh mục dịch vụ F&B & Golf chuẩn lên Firebase (/serviceCatalog)
  static Future<void> seedServiceCatalog() async {
    try {
      final Map<String, dynamic> catalogPayload = {};
      for (final item in StorageService.initialServiceItems) {
        catalogPayload[item.id] = item.toMap();
      }
      final url = Uri.parse('$_baseUrl/serviceCatalog.json');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(catalogPayload)),
      );
    } catch (e) {
      debugPrint('Lỗi seedServiceCatalog: $e');
    }
  }

  /// Khởi tạo dữ liệu chuẩn Okamura Golfzon lên Firebase Realtime Database
  static Future<void> seedInitialData() async {
    try {
      final Map<String, dynamic> roomsPayload = {};
      for (final room in StorageService.initialRooms) {
        roomsPayload[room.id] = room.toMap();
      }

      final roomsUrl = Uri.parse('$_baseUrl/rooms.json');
      await http.put(
        roomsUrl,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(roomsPayload)),
      );

      await seedServiceCatalog();

      final branchUrl = Uri.parse('$_baseUrl/branchInfo.json');
      await http.put(
        branchUrl,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(
          json.encode({
            'name': AppConstants.appName,
            'hotline': AppConstants.hotline,
            'email': AppConstants.email,
            'address': AppConstants.address,
            'taxCode': AppConstants.taxCode,
          }),
        ),
      );

      final slotsUrl = Uri.parse('$_baseUrl/timeSlots.json');
      await http.put(
        slotsUrl,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(AppConstants.standardTimeSlots)),
      );

      // Nạp danh mục thể loại Golf lên Firebase
      final catUrl = Uri.parse('$_baseUrl/golfCategories.json');
      final Map<String, dynamic> catPayload = {};
      for (final cat in GolfCategoryModel.defaultCategories) {
        catPayload[cat.id] = cat.toMap();
      }
      await http.put(
        catUrl,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(catPayload)),
      );

      // Nạp tài khoản Admin duy nhất: OKAMURA ADMIN
      final adminUrl = Uri.parse('$_baseUrl/adminAccount.json');
      await http.put(
        adminUrl,
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(
          json.encode({
            'id': 'admin_okamura',
            'username': 'admin',
            'name': 'OKAMURA ADMIN',
            'role': 'admin',
            'email': 'admin@okamura-golf.vn',
            'phone': '0901234567',
            'branch': 'Okamura Golfzon Lounge',
            'status': 'active',
            'password': 'admin',
            'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          }),
        ),
      );

      // Nạp tài khoản Khách hàng thực tế duy nhất theo yêu cầu: NGUYỄN XUÂN HÀO
      await saveGolfer(GolferModel.customerHaoProfile);

      debugPrint('Đã hoàn thành nạp dữ liệu khởi tạo Okamura Golfzon lên Firebase.');
    } catch (e) {
      debugPrint('Lỗi seedInitialData lên Firebase: $e');
    }
  }

  /// Lưu/cập nhật món ăn hoặc dịch vụ vào Catalog trên Firebase (/serviceCatalog/{id})
  static Future<bool> saveServiceItem(ServiceItemModel item) async {
    try {
      final url = Uri.parse('$_baseUrl/serviceCatalog/${item.id}.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(item.toMap())),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi saveServiceItem lên Firebase: $e');
      return false;
    }
  }

  /// Xóa vĩnh viễn món ăn hoặc dịch vụ khỏi Catalog trên Firebase (/serviceCatalog/{id})
  static Future<bool> deleteServiceItem(String itemId) async {
    try {
      final url = Uri.parse('$_baseUrl/serviceCatalog/$itemId.json');
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteServiceItem trên Firebase: $e');
      return false;
    }
  }

  /// Lưu/cập nhật phòng Bay lên Firebase (/rooms/{id})
  static Future<bool> saveRoom(RoomModel room) async {
    try {
      final url = Uri.parse('$_baseUrl/rooms/${room.id}.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(room.toMap())),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi saveRoom lên Firebase: $e');
      return false;
    }
  }

  /// Xóa phòng Bay khỏi Firebase (/rooms/{id})
  static Future<bool> deleteRoom(String roomId) async {
    try {
      final url = Uri.parse('$_baseUrl/rooms/$roomId.json');
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteRoom trên Firebase: $e');
      return false;
    }
  }

  /// Lưu hồ sơ hội viên Golfer (Tier, HCP, Điểm tích lũy, Doanh số) lên Firebase (/golfers/{phone})
  static Future<bool> saveGolfer(GolferModel golfer) async {
    try {
      final safeKey = golfer.phone.replaceAll(RegExp(r'[^\d]'), '');
      final key = safeKey.isEmpty ? 'guest' : safeKey;
      final url = Uri.parse('$_baseUrl/golfers/$key.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(golfer.toMap())),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi saveGolfer lên Firebase: $e');
      return false;
    }
  }

  /// Xóa hồ sơ hội viên Golfer khỏi Firebase (/golfers/{phone}) khi đổi số điện thoại
  static Future<bool> deleteGolfer(String phone) async {
    try {
      final safeKey = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (safeKey.isEmpty) return false;
      final url = Uri.parse('$_baseUrl/golfers/$safeKey.json');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteGolfer trên Firebase: $e');
      return false;
    }
  }

  /// Lấy hồ sơ hội viên Golfer từ Firebase (/golfers/{phone})
  static Future<GolferModel?> fetchGolfer(String phone) async {
    try {
      final safeKey = phone.replaceAll(RegExp(r'[^\d]'), '');
      final key = safeKey.isEmpty ? 'guest' : safeKey;
      final url = Uri.parse('$_baseUrl/golfers/$key.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null' && response.body.trim().isNotEmpty) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return GolferModel.fromMap(decoded);
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchGolfer từ Firebase: $e');
    }
    return null;
  }

  /// Tra cứu tài khoản đăng nhập theo username, số điện thoại hoặc email
  static Future<GolferModel?> fetchGolferByIdentifier(String identifier) async {
    final cleanId = identifier.trim().toLowerCase();
    // 1. Kiểm tra tài khoản Quản trị viên
    if (cleanId == 'admin' || cleanId == '0901234567' || cleanId == 'admin@okamura-golf.vn') {
      return GolferModel.defaultAdminProfile;
    }
    // 2. Tra cứu trực tiếp theo số điện thoại
    final byPhone = await fetchGolfer(identifier);
    if (byPhone != null) return byPhone;

    // 3. Khách hàng thực tế: Nguyễn Xuân Hào
    if (cleanId == '0354378606' ||
        cleanId == 'haosimla365@gmail.com' ||
        cleanId == 'hao.nguyen' ||
        cleanId == 'hao') {
      return GolferModel.customerHaoProfile;
    }

    // 4. Quét trên Firebase tìm theo Email nếu nhập Email
    try {
      final url = Uri.parse('$_baseUrl/golfers.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null' && response.body.trim().isNotEmpty) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is Map<String, dynamic>) {
              final model = GolferModel.fromMap(Map<String, dynamic>.from(entry.value));
              if (model.phone == identifier ||
                  (model.email != null && model.email!.toLowerCase() == cleanId)) {
                return model;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchGolferByIdentifier: $e');
    }
    return null;
  }

  /// Lưu biên bản Chốt ca & Bàn giao thu ngân lên Firebase (/shiftHandovers/{id})
  static Future<bool> saveShiftHandover(Map<String, dynamic> handoverData) async {
    try {
      final id = handoverData['id'] ?? 'SHIFT-${DateTime.now().millisecondsSinceEpoch}';
      final url = Uri.parse('$_baseUrl/shiftHandovers/$id.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(handoverData)),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi saveShiftHandover lên Firebase: $e');
      return false;
    }
  }

  /// Lấy danh sách thể loại Golf từ Firebase (/golfCategories)
  static Future<List<GolfCategoryModel>> fetchGolfCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/golfCategories.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null' && response.body.trim().isNotEmpty) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final List<GolfCategoryModel> list = [];
          decoded.forEach((key, val) {
            if (val is Map<String, dynamic>) {
              final map = Map<String, dynamic>.from(val);
              map['id'] ??= key;
              list.add(GolfCategoryModel.fromMap(map));
            }
          });
          if (list.isNotEmpty) {
            await StorageService.saveGolfCategories(list);
            return list;
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchGolfCategories từ Firebase (sử dụng cache cục bộ): $e');
    }
    return await StorageService.loadGolfCategories();
  }

  /// Lưu/cập nhật thể loại Golf lên Firebase (/golfCategories/{id})
  static Future<bool> saveGolfCategory(GolfCategoryModel category) async {
    try {
      final url = Uri.parse('$_baseUrl/golfCategories/${category.id}.json');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode(category.toMap())),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi saveGolfCategory lên Firebase: $e');
      return false;
    }
  }

  /// Xóa thể loại Golf khỏi Firebase (/golfCategories/{id})
  static Future<bool> deleteGolfCategory(String categoryId) async {
    try {
      final url = Uri.parse('$_baseUrl/golfCategories/$categoryId.json');
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi deleteGolfCategory trên Firebase: $e');
      return false;
    }
  }
}
