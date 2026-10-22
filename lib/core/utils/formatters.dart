import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ và ngày giờ
class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');

  /// Định dạng số tiền VNĐ (VD: 450.000 đ)
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount).trim();
  }

  /// Tiện ích rút gọn định dạng số tiền
  static String currency(num amount) => formatCurrency(amount);

  /// Định dạng ngày (VD: 14/09/2026)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Định dạng ngày kèm thứ
  static String formatDayOfWeek(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final dayName = weekdays[date.weekday - 1];
    return '$dayName, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Định dạng ngày giờ
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
}
