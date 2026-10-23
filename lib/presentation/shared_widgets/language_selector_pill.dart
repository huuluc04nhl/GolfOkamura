import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/theme/app_colors.dart';

/// Nút chuyển đổi ngôn ngữ thu gọn dạng Pill chuẩn phong cách Okamura Golfzon
class LanguageSelectorPill extends StatelessWidget {
  final bool isDark;
  final bool compact;

  const LanguageSelectorPill({
    super.key,
    this.isDark = true,
    this.compact = false,
  });

  void _showLanguageSelectionSheet(BuildContext context) {
    final languageProvider = Provider.of<AppLanguageProvider?>(context, listen: false);
    final currentLang = languageProvider?.currentLanguage ?? AppLanguage.vi;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: AppColors.primaryGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHỌN NGÔN NGỮ / LANGUAGE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Okamura Golfzon International Lounge',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Danh sách 4 ngôn ngữ
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      languageProvider?.changeLanguage(lang);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGold.withValues(alpha: 0.15)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGold
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang.flagEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryGold
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getLanguageSubtitle(lang),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageSubtitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.vi:
        return 'Tiếng Việt (Mặc định)';
      case AppLanguage.en:
        return 'English (International)';
      case AppLanguage.ko:
        return '한국어 (골프존 표준)';
      case AppLanguage.ja:
        return '日本語 (オカムラ公式)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<AppLanguageProvider?>(context, listen: true);
    final currentLang = languageProvider?.currentLanguage ?? AppLanguage.vi;

    return InkWell(
      onTap: () => _showLanguageSelectionSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang.flagEmoji,
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),
            const SizedBox(width: 4),
            Text(
              currentLang.shortLabel,
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primaryGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
