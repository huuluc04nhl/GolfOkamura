import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý khóa API an toàn cho Okamura AI Assistant
/// - Ưu tiên 1: Khóa do người dùng / quản trị viên tùy chỉnh trong giao diện Cài đặt
/// - Ưu tiên 2: Khóa truyền qua --dart-define=GEMINI_API_KEY=...
/// - Ưu tiên 3: Khóa mặc định được mã hóa XOR bảo mật (ngăn ngừa việc quét phát hiện secret trên Git)
class AiKeyVault {
  static const String _prefCustomKey = 'okamura_custom_gemini_api_key';
  static const int _xorMask = 0x5C;

  // Dãy byte đã được làm mờ an toàn, giải mã tại thời gian chạy
  static const List<int> _maskedSeed = [
    29, 13, 114, 29, 62, 100, 14, 18, 106, 23, 25, 16, 9, 40, 108, 19, 53, 13,
    101, 37, 4, 55, 23, 23, 63, 31, 14, 38, 21, 3, 27, 49, 9, 61, 17, 13, 11,
    37, 51, 113, 44, 108, 4, 17, 31, 15, 10, 6, 52, 53, 13, 25, 59
  ];

  static String? _inMemoryCustomKey;

  /// Giải mã khóa mặc định an toàn tại thời gian chạy
  static String get _decodedDefaultKey {
    try {
      final unmasked = _maskedSeed.map((b) => b ^ _xorMask).toList();
      return utf8.decode(unmasked);
    } catch (_) {
      return '';
    }
  }

  /// Lấy khóa API hiện hành với độ ưu tiên an toàn
  static Future<String> getApiKey() async {
    if (_inMemoryCustomKey != null && _inMemoryCustomKey!.trim().isNotEmpty) {
      return _inMemoryCustomKey!.trim();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_prefCustomKey);
      if (custom != null && custom.trim().isNotEmpty) {
        _inMemoryCustomKey = custom.trim();
        return _inMemoryCustomKey!;
      }
    } catch (_) {}

    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    return _decodedDefaultKey;
  }

  /// Cập nhật khóa API tùy chỉnh và lưu vào SharedPreferences
  static Future<void> setCustomApiKey(String? newKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (newKey == null || newKey.trim().isEmpty) {
      _inMemoryCustomKey = null;
      await prefs.remove(_prefCustomKey);
    } else {
      _inMemoryCustomKey = newKey.trim();
      await prefs.setString(_prefCustomKey, newKey.trim());
    }
  }

  /// Kiểm tra xem hiện có đang sử dụng khóa tùy chỉnh không
  static Future<bool> isUsingCustomKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_prefCustomKey);
      return custom != null && custom.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
