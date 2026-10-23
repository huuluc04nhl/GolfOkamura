import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Các ngôn ngữ được hỗ trợ tại Okamura Golfzon
enum AppLanguage {
  vi('vi', 'Tiếng Việt', '🇻🇳', 'VN'),
  en('en', 'English', '🇬🇧', 'EN'),
  ko('ko', '한국어', '🇰🇷', 'KR'),
  ja('ja', '日本語', '🇯🇵', 'JP');

  final String code;
  final String label;
  final String flagEmoji;
  final String shortLabel;

  const AppLanguage(this.code, this.label, this.flagEmoji, this.shortLabel);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

/// Provider quản lý trạng thái ngôn ngữ toàn ứng dụng
class AppLanguageProvider extends ChangeNotifier {
  static const String _prefLanguageKey = 'okamura_selected_language';

  AppLanguage _currentLanguage = AppLanguage.vi;

  AppLanguage get currentLanguage => _currentLanguage;
  String get languageCode => _currentLanguage.code;
  String get flagEmoji => _currentLanguage.flagEmoji;
  String get shortLabel => _currentLanguage.shortLabel;

  AppLanguageProvider() {
    _loadLanguageFromPrefs();
  }

  Future<void> _loadLanguageFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefLanguageKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Thay đổi ngôn ngữ và lưu vào SharedPreferences
  Future<void> changeLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, language.code);
    } catch (_) {}
  }
}
