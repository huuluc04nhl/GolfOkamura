import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/golfer_model.dart';
import 'package:golf_booking/shared/models/service_order_model.dart';
import 'package:golf_booking/shared/services/firebase_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // Cho phép HTTP request thực tới Firebase

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Kiểm tra đồng bộ toàn diện với Firebase và tự động dọn sạch dữ liệu test sau khi chạy', () async {
    const testBookingId = 'OGZ-LIVE-TEST-001';
    const testOrderId = 'ORD-LIVE-TEST-001';

    addTearDown(() async {
      // Đảm bảo xóa vĩnh viễn mọi bản ghi test để không bao giờ để lại dữ liệu ảo trên Cloud
      await FirebaseRealtimeService.deleteBooking(testBookingId);
      await FirebaseRealtimeService.deleteServiceOrder(testOrderId);
      try {
        final url = Uri.parse('https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app/golfers/0999999999.json');
        final shiftUrl = Uri.parse('https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app/shiftHandovers/SHIFT-TEST-001.json');
        final client = HttpClient();
        final req1 = await client.deleteUrl(url);
        await req1.close();
        final req2 = await client.deleteUrl(shiftUrl);
        await req2.close();
      } catch (_) {}
    });

    // 1. Kiểm tra danh sách phòng & danh mục dịch vụ trên Firebase
    final rooms = await FirebaseRealtimeService.fetchRooms();
    expect(rooms.isNotEmpty, true);
    final catalog = await FirebaseRealtimeService.fetchServiceCatalog();
    expect(catalog.isNotEmpty, true);

    // 2. Tạo thử đơn đặt phòng, kiểm tra và xóa ngay
    final testBooking = BookingModel(
      id: testBookingId,
      customerName: 'Test System Verify',
      customerPhone: '0000000000',
      roomId: rooms.first.id,
      roomName: rooms.first.name,
      bookingDate: DateTime(2026, 12, 31),
      timeSlot: '18:00 - 20:00',
      totalPrice: rooms.first.pricePerHour * 2,
      notes: 'Auto verification',
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
    );

    final success = await FirebaseRealtimeService.createBooking(testBooking);
    expect(success, true);

    final deletedBooking = await FirebaseRealtimeService.deleteBooking(testBookingId);
    expect(deletedBooking, true);

    // 3. Tạo thử đơn F&B, kiểm tra và xóa ngay
    final testOrder = ServiceOrderModel(
      id: testOrderId,
      roomName: rooms.first.name,
      items: const [
        {
          'id': 'drink_1',
          'name': 'Iced Americano Arabica',
          'price': 55000.0,
          'qty': 1,
        },
      ],
      totalPrice: 55000,
      status: 'preparing',
      orderType: 'fnb_order',
      createdAt: DateTime.now(),
    );

    final orderSuccess = await FirebaseRealtimeService.createServiceOrder(testOrder);
    expect(orderSuccess, true);

    final deletedOrder = await FirebaseRealtimeService.deleteServiceOrder(testOrderId);
    expect(deletedOrder, true);

    // 4. Kiểm tra đồng bộ hồ sơ Golfer & Hạng hội viên lên Firebase
    final testGolfer = GolferModel(
      id: 'test_golfer_verify',
      name: 'Golfer Test Live',
      phone: '0999999999',
      handicap: 12.5,
      tier: GolferTier.gold,
      loyaltyPoints: 1200,
      totalSpend: 15000000,
      memberSince: DateTime.now(),
    );
    final saveGolferOk = await FirebaseRealtimeService.saveGolfer(testGolfer);
    expect(saveGolferOk, true);

    final fetchedGolfer = await FirebaseRealtimeService.fetchGolfer('0999999999');
    expect(fetchedGolfer != null, true);
    expect(fetchedGolfer?.tier, GolferTier.gold);

    // 5. Kiểm tra đồng bộ biên bản Chốt ca trực thu ngân lên Firebase
    final shiftOk = await FirebaseRealtimeService.saveShiftHandover({
      'id': 'SHIFT-TEST-001',
      'shiftName': 'Ca Test Live',
      'totalRevenue': 500000.0,
      'cashAmount': 200000.0,
      'transferAmount': 300000.0,
      'cashierName': 'Test Cashier',
      'notes': 'Test auto sync',
    });
    expect(shiftOk, true);
  });
}
