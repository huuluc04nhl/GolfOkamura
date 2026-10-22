import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/room_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kiểm thử luồng dữ liệu thực tế đặt phòng Golfzon (User & Admin)', () {
    test('Khởi tạo provider và nạp danh sách phòng ban đầu', () async {
      final provider = BookingProvider();
      await provider.initFuture;

      expect(provider.rooms.isNotEmpty, true);
      expect(provider.rooms.any((r) => r.name.contains('A1 - Smoking')), true);
      expect(provider.rooms.any((r) => r.name.contains('A4 - No Smoking')), true);
    });

    test('Quy trình đặt phòng, kiểm tra trạng thái và hủy phòng thời gian thực', () async {
      final provider = BookingProvider();
      await provider.initFuture;

      final room = provider.rooms.first;
      final testDate = DateTime.now().add(Duration(days: 500 + (DateTime.now().microsecondsSinceEpoch % 1000)));
      const testTimeSlot = '10:00 - 12:00';

      // 1. Kiểm tra ban đầu phòng phải trống
      final initialStatus = provider.getRoomStatus(
        roomId: room.id,
        date: testDate,
        timeSlot: testTimeSlot,
      );
      expect(initialStatus, RoomBookingStatus.available);

      // 2. Thực hiện đặt phòng thực tế
      final success = await provider.createBooking(
        customerName: 'Nguyễn Văn Golf',
        customerPhone: '0987654321',
        room: room,
        bookingDate: testDate,
        timeSlot: testTimeSlot,
        notes: 'Gậy tay phải',
      );
      expect(success, true);
      expect(provider.bookings.any((b) => b.customerName == 'Nguyễn Văn Golf'), true);
      final createdBooking = provider.bookings.firstWhere((b) => b.customerName == 'Nguyễn Văn Golf');
      expect(createdBooking.status, BookingStatus.confirmed);

      // 3. Trạng thái phòng tại khung giờ đó phải chuyển sang Đã Đặt (Booked)
      final bookedStatus = provider.getRoomStatus(
        roomId: room.id,
        date: testDate,
        timeSlot: testTimeSlot,
      );
      expect(bookedStatus, RoomBookingStatus.booked);

      // 4. Nếu đặt trùng khung giờ đó thì phải từ chối
      final duplicateTry = await provider.createBooking(
        customerName: 'Khách Khác',
        customerPhone: '0123456789',
        room: room,
        bookingDate: testDate,
        timeSlot: testTimeSlot,
      );
      expect(duplicateTry, false);

      // 5. Hủy đơn đặt phòng và xác nhận phòng được giải phóng ngay lập tức
      final targetBooking = createdBooking;
      await provider.cancelBooking(targetBooking.id);

      final updatedBooking = provider.bookings.firstWhere((b) => b.id == targetBooking.id);
      expect(updatedBooking.status, BookingStatus.cancelled);
      final freedStatus = provider.getRoomStatus(
        roomId: room.id,
        date: testDate,
        timeSlot: testTimeSlot,
      );
      expect(freedStatus, RoomBookingStatus.available);
    });

    test('Chế độ bảo trì từ Admin vô hiệu hóa đặt phòng', () async {
      final provider = BookingProvider();
      await provider.initFuture;

      final room = provider.rooms.first;
      final testDate = DateTime.now().add(Duration(days: 700 + (DateTime.now().microsecondsSinceEpoch % 1000)));
      const testTimeSlot = '14:00 - 16:00';

      // Admin bật bảo trì phòng
      await provider.toggleRoomMaintenance(room.id);
      expect(provider.rooms.firstWhere((r) => r.id == room.id).isUnderMaintenance, true);

      // Trạng thái phòng phải là maintenance
      final status = provider.getRoomStatus(
        roomId: room.id,
        date: testDate,
        timeSlot: testTimeSlot,
      );
      expect(status, RoomBookingStatus.maintenance);

      // Admin tắt bảo trì
      await provider.toggleRoomMaintenance(room.id);
      expect(provider.rooms.firstWhere((r) => r.id == room.id).isUnderMaintenance, false);
    });

    test('Ngữ cảnh chọn phòng liên màn hình, đổi lịch chơi và quản lý trạng thái đơn F&B', () async {
      final provider = BookingProvider(autoSyncFirebase: false);
      await provider.initFuture;

      final vipRoom = provider.rooms.firstWhere((r) => r.isVip);
      provider.selectRoomForBooking(vipRoom, gameMode: 'Stroke & Match Play');
      expect(provider.preselectedRoom?.id, vipRoom.id);
      expect(provider.preselectedGameMode, 'Stroke & Match Play');

      final testDate = DateTime.now().add(const Duration(days: 30));
      final ok = await provider.createBooking(
        customerName: 'Lê Minh Tuấn',
        customerPhone: '0911223344',
        room: vipRoom,
        bookingDate: testDate,
        timeSlot: '16:00 - 18:00',
        durationHours: 3,
        playerCount: 4,
        notes: 'Ướp lạnh bia Asahi',
      );
      expect(ok, true);
      expect(provider.preselectedRoom, isNull);
      expect(provider.selectedServiceRoomName, vipRoom.name);

      final created = provider.bookings.firstWhere((b) => b.customerPhone == '0911223344');
      expect(created.totalPrice, vipRoom.pricePerHour * 3);
      expect(created.notes, contains('4 Golfer • 3h'));
      expect(created.notes, contains('Stroke & Match Play'));

      // Đổi sang khung giờ 18:00 - 20:00
      final rescheduled = await provider.rescheduleBooking(
        bookingId: created.id,
        newDate: testDate,
        newTimeSlot: '18:00 - 20:00',
      );
      expect(rescheduled, true);
      expect(
        provider.bookings.firstWhere((b) => b.id == created.id).timeSlot,
        '18:00 - 20:00',
      );

      // Tạo đơn F&B và đánh dấu Đã nhận món
      final order = await provider.submitServiceOrder(
        roomName: vipRoom.name,
        cartQuantities: {'drink_1': 2},
        note: 'Ít đá',
      );
      expect(order.status, 'preparing');
      await provider.updateServiceOrderStatus(order.id, 'served');
      expect(
        provider.serviceOrders.firstWhere((o) => o.id == order.id).status,
        'served',
      );

      // Chuyển phòng kiểu POS365 (transferBookingRoom) và Thanh toán trả phòng (completeBooking)
      final targetRoom = provider.rooms.firstWhere((r) => r.id != vipRoom.id);
      final transferred = await provider.transferBookingRoom(
        bookingId: created.id,
        targetRoom: targetRoom,
      );
      expect(transferred, true);
      expect(
        provider.bookings.firstWhere((b) => b.id == created.id).roomId,
        targetRoom.id,
      );

      await provider.completeBooking(created.id);
      expect(
        provider.bookings.firstWhere((b) => b.id == created.id).status,
        BookingStatus.completed,
      );
    });
  });
}
