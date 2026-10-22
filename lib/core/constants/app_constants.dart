/// Các hằng số ứng dụng Golf Booking
class AppConstants {
  static const String appName = 'OKAMURA GOLFZON';
  static const String hotline = '0868 819 198';
  static const String email = 'booking@fairway-co.com';
  static const String address =
      'Số 102 - 104, Lô DC28, Đường D16, KDC Việt Sing, P. An Phú, TP. Thuận An, Bình Dương';
  static const String taxCode = '3703243763';
  static const String firebaseDatabaseUrl =
      'https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Khung giờ hoạt động
  static const List<String> standardTimeSlots = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
    '20:00 - 22:00',
  ];

  // Khóa lưu trữ cục bộ
  static const String prefsKeyRooms = 'okamura_rooms_v1';
  static const String prefsKeyBookings = 'okamura_bookings_v1';
  static const String prefsKeyUserPhone = 'okamura_user_phone';
  static const String prefsKeyUserName = 'okamura_user_name';
}
