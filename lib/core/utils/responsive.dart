import 'package:flutter/material.dart';

/// Tiện ích hỗ trợ hiển thị Responsive chuẩn xác cho toàn bộ thiết bị di động:
/// - Màn hình điện thoại nhỏ / đời cũ (iPhone SE 1-3, iPhone mini, Android màn nhỏ < 360dp)
/// - Màn hình tiêu chuẩn (iPhone 12/13/14/15/16, Samsung Galaxy S21-S24: 375dp - 414dp)
/// - Màn hình lớn (iPhone Pro Max, Galaxy Ultra: 415dp - 500dp)
/// - Màn hình gập dọc siêu dài (Galaxy Z Flip 3/4/5/6, Motorola Razr: tỉ lệ 21:9 - 22:9)
/// - Màn hình gập mở rộng vuông (Galaxy Z Fold, Pixel Fold, iPad mini: 600dp - 900dp)
/// - Màn hình Tablet / Web Preview Desktop (>= 900dp)
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? foldableOrTablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.foldableOrTablet,
    this.desktop,
  });

  /// Kiểm tra màn hình nhỏ (iPhone SE, dòng máy mini, bề ngang < 360dp)
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Kiểm tra điện thoại thông thường (bề ngang < 600dp)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  /// Màn hình gập dọc siêu dài (Samsung Galaxy Z Flip, Razr, Xperia: tỉ lệ > 2.15)
  static bool isUltraTall(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return isMobile(context) && (size.height / size.width > 2.15);
  }

  /// Màn hình vuông gập mở (Galaxy Z Fold khi mở ra, Pixel Fold: tỉ lệ vuông vắn)
  static bool isSquarishFoldable(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = size.height / size.width;
    return size.width >= 560 && ratio >= 0.8 && ratio <= 1.45;
  }

  /// Màn hình gập mở rộng hoặc Tablet (600dp - 1024dp)
  static bool isFoldableOrTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  /// Màn hình lớn / Web Desktop (>= 1024dp)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// Padding ngang thích ứng theo từng loại thiết bị
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12.0; // Máy nhỏ
    if (width < 430) return 16.0; // Máy tiêu chuẩn
    if (width < 600) return 20.0; // Máy Pro Max
    return 24.0; // Màn hình gập / Tablet
  }

  /// Khoảng cách đáy an toàn (tránh Home Indicator trên iPhone và thanh cử chỉ Android)
  static double safeBottomPadding(BuildContext context, {double extra = 12.0}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return (bottomInset > 0 ? bottomInset : 10.0) + extra;
  }

  /// Khoảng cách đỉnh an toàn (tránh Dynamic Island, Camera đục lỗ, Notch)
  static double safeTopPadding(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return topInset > 0 ? topInset : 24.0;
  }

  /// Tự động giới hạn cỡ chữ khi người dùng chỉnh font scale quá to trong cài đặt máy
  static double safeFontScale(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(10) / 10;
    return scale.clamp(0.85, 1.2);
  }

  /// Số cột hiển thị linh hoạt
  static int getGridColumnCount(BuildContext context, {int baseColumns = 2}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 1;
    if (width < 600) return baseColumns;
    if (width < 900) return baseColumns + 1;
    return baseColumns + 2;
  }

  /// Khung chiều rộng chuẩn để tối ưu hiển thị trên các màn hình gập hoặc xem trước web
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 600) return 560; // Chuẩn tỷ lệ Smartphone cao cấp
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 1024 && desktop != null) {
      return desktop!;
    }

    if (width >= 600 && foldableOrTablet != null) {
      return foldableOrTablet!;
    }

    return mobile;
  }
}
