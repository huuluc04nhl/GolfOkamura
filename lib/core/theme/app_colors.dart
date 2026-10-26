import 'package:flutter/material.dart';

/// Bảng màu nhận diện thương hiệu Okamura Golfzon & Admin Web
class AppColors {
  // Brand Colors - Okamura Golfzon (Trích xuất từ okamuragolfzon.com)
  static const Color primaryGold = Color(0xFFB69568);
  static const Color darkGold = Color(0xFF917349);
  static const Color lightGold = Color(0xFFDFC7A3);
  static const Color softGold = Color(0xFFF7F2EA);

  // User Theme Colors (Glassmorphism & Obsidian Carbon chuẩn AuthScreen)
  static const Color userBgDark = Color(0xFF070B14);
  static const Color userCardDark = Color(0xFF0F172A);
  static const Color userSurfaceDark = Color(0xFF141E33);
  static const Color userBorder = Color(0x3DB69568); // Viền kính ánh vàng kim mờ 24%

  // Glassmorphism System Colors (Đồng bộ tuyệt đối chuẩn 2 Tab Đăng nhập / Đăng ký)
  static const Color glassBg = Color(0xFF090D18);
  static const Color glassSurface = Color(0xFF0F172A);
  static const Color glassBorder = Color(0x4DB69568); // 30% primary gold
  static const Color glassBorderActive = Color(0xFFB69568);

  // Gradient Vàng Kim Hoàng Gia (Dành cho Active Tab, Nút bấm & Điểm nhấn ánh kim)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFE5C887),
      Color(0xFFB69568),
      Color(0xFFB58728),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Mode Colors (khi cần nền sáng)
  static const Color userBgLight = Color(0xFFFAF8F5);
  static const Color userCardLight = Color(0xFFFFFFFF);

  // Typography Colors
  static const Color textLight = Color(0xFFF5F5F7);
  static const Color textMuted = Color(0xFF9E9EA7);
  static const Color textDark = Color(0xFF1E2024);

  // Status Colors (Phòng trống & Đã đặt theo chuẩn Okamura)
  static const Color statusAvailable = Color(0xFFB69568); // Vàng kim nhận diện
  static const Color statusAvailableBg = Color(0x20B69568);
  static const Color statusBooked = Color(0xFFDC3545);    // Đỏ đã đặt
  static const Color statusBookedBg = Color(0x20DC3545);
  static const Color statusMaintenance = Color(0xFFE65100); // Cam bảo trì
  static const Color statusMaintenanceBg = Color(0x20E65100);

  // Admin Dashboard Colors
  static const Color adminBg = Color(0xFFF4F6F9);
  static const Color adminSidebar = Color(0xFF0F172A);
  static const Color adminSidebarActive = Color(0xFF1E293B);
  static const Color adminCard = Color(0xFFFFFFFF);
  static const Color adminBorder = Color(0xFFE2E8F0);
  static const Color adminText = Color(0xFF0F172A);
  static const Color adminMuted = Color(0xFF64748B);
}
