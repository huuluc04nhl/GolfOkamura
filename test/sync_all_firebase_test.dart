import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:golf_booking/core/constants/app_constants.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/golf_category_model.dart';
import 'package:golf_booking/shared/models/golfer_model.dart';
import 'package:golf_booking/shared/models/service_order_model.dart';
import 'package:golf_booking/shared/services/firebase_realtime_service.dart';
import 'package:golf_booking/shared/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl =
    'https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // Cho phép HTTP request thực tới Firebase

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Đồng bộ toàn bộ dữ liệu thực tế lên Firebase Realtime Database', () async {
    final client = http.Client();

    try {
      // 1. Đồng bộ 12 phòng chơi tiêu chuẩn GSM & POS365 (/rooms.json)
      final Map<String, dynamic> roomsPayload = {};
      for (final room in StorageService.initialRooms) {
        roomsPayload[room.id] = room.toMap();
      }
      final roomsRes = await client.put(
        Uri.parse('$baseUrl/rooms.json'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(roomsPayload)),
      );
      expect(roomsRes.statusCode, 200);

      // 2. Đồng bộ Thực đơn F&B & Dịch vụ chuẩn (/serviceCatalog.json)
      final Map<String, dynamic> catalogPayload = {};
      for (final item in StorageService.initialServiceItems) {
        catalogPayload[item.id] = item.toMap();
      }
      final catalogRes = await client.put(
        Uri.parse('$baseUrl/serviceCatalog.json'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(catalogPayload)),
      );
      expect(catalogRes.statusCode, 200);

      // 3. Đồng bộ Danh mục thể loại Golf (/golfCategories.json)
      final Map<String, dynamic> catPayload = {};
      for (final cat in GolfCategoryModel.defaultCategories) {
        catPayload[cat.id] = cat.toMap();
      }
      final catRes = await client.put(
        Uri.parse('$baseUrl/golfCategories.json'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(catPayload)),
      );
      expect(catRes.statusCode, 200);

      // 4. Đồng bộ Thông tin cơ sở Lounge (/branchInfo.json)
      final branchRes = await client.put(
        Uri.parse('$baseUrl/branchInfo.json'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(
          json.encode({
            'name': AppConstants.appName,
            'hotline': AppConstants.hotline,
            'email': AppConstants.email,
            'address': AppConstants.address,
            'taxCode': AppConstants.taxCode,
            'currency': 'VND',
            'openHour': '08:00',
            'closeHour': '23:30',
            'lastUpdated': DateTime.now().toIso8601String(),
          }),
        ),
      );
      expect(branchRes.statusCode, 200);

      // 5. Đồng bộ Khung giờ chơi chuẩn (/timeSlots.json)
      final slotsRes = await client.put(
        Uri.parse('$baseUrl/timeSlots.json'),
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode(json.encode(AppConstants.standardTimeSlots)),
      );
      expect(slotsRes.statusCode, 200);

      // 6. Đồng bộ Tài khoản Quản trị viên OKAMURA ADMIN (/adminAccount.json)
      final adminRes = await client.put(
        Uri.parse('$baseUrl/adminAccount.json'),
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
      expect(adminRes.statusCode, 200);

      // 7. Đồng bộ Hồ sơ Golfer VIP thực tế NGUYỄN XUÂN HÀO (/golfers/0909999999.json)
      final saveGolferOk = await FirebaseRealtimeService.saveGolfer(
        GolferModel.customerHaoProfile,
      );
      expect(saveGolferOk, true);

      // 8. Đảm bảo có lịch đặt phòng thực tế (/bookings.json)
      final existingBookings = await FirebaseRealtimeService.fetchBookings();
      if (existingBookings.isEmpty) {
        final now = DateTime.now();
        final b1 = BookingModel(
          id: 'OGZ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001',
          customerName: 'Nguyễn Xuân Hào',
          customerPhone: '0909999999',
          roomId: 'room_vip1',
          roomName: 'VIP 1 - President Suite',
          bookingDate: now,
          timeSlot: '14:00 - 16:00',
          totalPrice: 1500000,
          status: BookingStatus.confirmed,
          notes: 'Tiếp khách đối tác quan trọng, chuẩn bị sẵn gậy Honma 5 sao.',
          createdAt: now.subtract(const Duration(hours: 2)),
        );
        await FirebaseRealtimeService.createBooking(b1);
      }

      // 9. Đảm bảo có đơn dịch vụ F&B tận phòng (/serviceOrders.json)
      final existingOrders = await FirebaseRealtimeService.fetchServiceOrders();
      if (existingOrders.isEmpty) {
        final now = DateTime.now();
        final dateStr =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final o1 = ServiceOrderModel(
          id: 'FNB-$dateStr-1001',
          roomName: 'VIP 1 - President Suite',
          items: const [
            {
              'id': 'drink_sapporo_thap_vang',
              'name': 'Bia Sapporo Tháp Vàng 2.5L',
              'price': 400000.0,
              'qty': 1,
            },
            {
              'id': 'drink_americano',
              'name': 'Iced Americano Arabica',
              'price': 60000.0,
              'qty': 2,
            },
          ],
          totalPrice: 520000,
          status: 'preparing',
          orderType: 'fnb_order',
          note: 'Pha ít ngọt, mang thêm 4 ly đá và khăn lạnh',
          customerName: 'Nguyễn Xuân Hào',
          customerPhone: '0909999999',
          paymentMethod: 'pay_at_bay',
          createdAt: now.subtract(const Duration(minutes: 8)),
        );
        await FirebaseRealtimeService.createServiceOrder(o1);
      }

      // 10. Xác thực toàn bộ bằng đọc lại (Full Read Verification)
      final roomsVerify = await FirebaseRealtimeService.fetchRooms();
      final catalogVerify = await FirebaseRealtimeService.fetchServiceCatalog();
      final categoriesVerify = await FirebaseRealtimeService.fetchGolfCategories();
      final bookingsVerify = await FirebaseRealtimeService.fetchBookings();
      final ordersVerify = await FirebaseRealtimeService.fetchServiceOrders();
      final haoVerify = await FirebaseRealtimeService.fetchGolfer(
        GolferModel.customerHaoProfile.phone,
      );

      expect(roomsVerify.length, StorageService.initialRooms.length);
      expect(catalogVerify.isNotEmpty, true);
      expect(categoriesVerify.isNotEmpty, true);
      expect(bookingsVerify.isNotEmpty, true);
      expect(ordersVerify.isNotEmpty, true);
      expect(haoVerify != null, true);
      expect(haoVerify!.name, 'Nguyễn Xuân Hào');
    } finally {
      client.close();
    }
  });
}
