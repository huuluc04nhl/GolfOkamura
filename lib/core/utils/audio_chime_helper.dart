import 'package:flutter/services.dart';

/// Tiện ích phát âm thanh thông báo chuông quầy Lounge (Audio Chime)
class AudioChimeHelper {
  /// Phát âm thanh chuông khi có đơn gọi món hoặc yêu cầu mới từ khách
  static Future<void> playNewOrderChime() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Phát âm thanh khi hoàn tất thanh toán / check-in
  static Future<void> playSuccessChime() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
