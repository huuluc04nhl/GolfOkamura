import 'package:flutter/material.dart';

/// Model Thể Loại Golf / Phân Hạng Bay Simulator
class GolfCategoryModel {
  final String id; // 'standard', 'vip', 'dual', 'connecting', 'range', 'studio' hoặc mã tùy chỉnh
  final String name; // Tên hiển thị: 'Tiêu Chuẩn', 'VIP Suite Luxury', ...
  final String description; // Mô tả trải nghiệm
  final double basePricePerHour; // Đơn giá giờ tham chiếu (VNĐ)
  final String defaultSensor; // Cảm biến mặc định (TwoVision NX, GDR Plus...)
  final int maxCapacity; // Sức chứa tối đa (người)
  final String iconKey; // 'golf', 'vip', 'dual', 'connecting', 'range', 'studio', 'cup', 'star'
  final String badgeColorHex; // Mã màu hex: 'B69568', '10B981', '38BDF8', 'EC4899', 'F59E0B', '8B5CF6'

  const GolfCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.basePricePerHour,
    required this.defaultSensor,
    this.maxCapacity = 4,
    this.iconKey = 'golf',
    this.badgeColorHex = 'B69568',
  });

  Color get badgeColor {
    final hex = badgeColorHex.replaceAll('#', '');
    return Color(int.tryParse('0xFF$hex') ?? 0xFFB69568);
  }

  IconData get iconData {
    switch (iconKey) {
      case 'vip':
        return Icons.workspace_premium_rounded;
      case 'dual':
        return Icons.swap_horiz_rounded;
      case 'connecting':
        return Icons.meeting_room_rounded;
      case 'range':
        return Icons.track_changes_rounded;
      case 'studio':
        return Icons.psychology_rounded;
      case 'cup':
        return Icons.emoji_events_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'golf':
      default:
        return Icons.sports_golf_rounded;
    }
  }

  GolfCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    double? basePricePerHour,
    String? defaultSensor,
    int? maxCapacity,
    String? iconKey,
    String? badgeColorHex,
  }) {
    return GolfCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
      defaultSensor: defaultSensor ?? this.defaultSensor,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      iconKey: iconKey ?? this.iconKey,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'basePricePerHour': basePricePerHour,
      'defaultSensor': defaultSensor,
      'maxCapacity': maxCapacity,
      'iconKey': iconKey,
      'badgeColorHex': badgeColorHex,
    };
  }

  factory GolfCategoryModel.fromMap(Map<String, dynamic> map) {
    return GolfCategoryModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      basePricePerHour: (map['basePricePerHour'] is num)
          ? (map['basePricePerHour'] as num).toDouble()
          : double.tryParse(map['basePricePerHour']?.toString() ?? '350000') ?? 350000,
      defaultSensor: (map['defaultSensor'] ?? 'Golfzon TwoVision NX 3D').toString(),
      maxCapacity: (map['maxCapacity'] is int)
          ? map['maxCapacity'] as int
          : int.tryParse(map['maxCapacity']?.toString() ?? '4') ?? 4,
      iconKey: (map['iconKey'] ?? 'golf').toString(),
      badgeColorHex: (map['badgeColorHex'] ?? 'B69568').toString(),
    );
  }

  static List<GolfCategoryModel> get defaultCategories => const [
    GolfCategoryModel(
      id: 'standard',
      name: 'Tiêu Chuẩn',
      description: 'Phòng golf mô phỏng tiêu chuẩn quốc tế, chơi 18 hố với cảm biến TwoVision tốc độ cao.',
      basePricePerHour: 350000,
      defaultSensor: 'Golfzon TwoVision Plus 3D',
      maxCapacity: 4,
      iconKey: 'golf',
      badgeColorHex: '10B981',
    ),
    GolfCategoryModel(
      id: 'vip',
      name: 'VIP Suite Luxury',
      description: 'Phòng Suite cách âm cao cấp, màn hình cong siêu nét, hệ thống cảm biến NX 3D tân tiến.',
      basePricePerHour: 550000,
      defaultSensor: 'Golfzon TwoVision NX 3D Suite',
      maxCapacity: 6,
      iconKey: 'vip',
      badgeColorHex: 'B69568',
    ),
    GolfCategoryModel(
      id: 'dual',
      name: 'Dual Tee (Tay trái & phải)',
      description: 'Trang bị 2 bệ nâng bóng tự động riêng biệt, hỗ trợ tối đa cho golfer thuận tay trái và tay phải.',
      basePricePerHour: 400000,
      defaultSensor: 'Golfzon TwoVision Dual Plate',
      maxCapacity: 4,
      iconKey: 'dual',
      badgeColorHex: '38BDF8',
    ),
    GolfCategoryModel(
      id: 'connecting',
      name: 'Phòng Đôi Thông Nhau',
      description: 'Vách ngăn di động liên thông 2 phòng B1+B2, lý tưởng cho tiệc nhóm đông hoặc giải đấu đối kháng.',
      basePricePerHour: 700000,
      defaultSensor: 'Dual TwoVision NX Link',
      maxCapacity: 10,
      iconKey: 'connecting',
      badgeColorHex: 'EC4899',
    ),
    GolfCategoryModel(
      id: 'range',
      name: 'Làn Tập GDR Plus',
      description: 'Phân tích cú đánh chi tiết, camera quay chậm tốc độ cao, đo thông số smash factor, góc phóng bóng.',
      basePricePerHour: 250000,
      defaultSensor: 'Golfzon GDR Plus Driving Range',
      maxCapacity: 2,
      iconKey: 'range',
      badgeColorHex: 'F59E0B',
    ),
    GolfCategoryModel(
      id: 'studio',
      name: 'PGA Studio Chuyên Nghiệp',
      description: 'Phòng chuyên gia phân tích swing 3D, fitting gậy và huấn luyện cùng huấn luyện viên PGA.',
      basePricePerHour: 600000,
      defaultSensor: 'Golfzon Wave Studio & 3D Plate',
      maxCapacity: 3,
      iconKey: 'studio',
      badgeColorHex: '8B5CF6',
    ),
  ];
}
