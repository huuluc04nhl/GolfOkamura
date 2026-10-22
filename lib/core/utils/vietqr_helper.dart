/// Tiện ích sinh mã thanh toán VietQR động chuẩn NAPAS 247
class VietQRHelper {
  // Cấu hình tài khoản thụ hưởng của Okamura Golfzon Lounge
  static const String defaultBankId = 'MB'; // Ngân hàng Quân Đội (MB Bank)
  static const String defaultAccountNo = '0901234567'; // STK trung tâm Lounge
  static const String defaultAccountName = 'OKAMURA GOLF LOUNGE';

  /// Tạo link ảnh mã VietQR động theo chuẩn NAPAS
  static String generateQrUrl({
    required double amount,
    required String memo,
    String bankId = defaultBankId,
    String accountNo = defaultAccountNo,
    String accountName = defaultAccountName,
  }) {
    final cleanAmount = amount.toInt();
    final encodedMemo = Uri.encodeComponent(memo);
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$cleanAmount&addInfo=$encodedMemo&accountName=$encodedName';
  }
}
