import 'dart:convert';

/// Trạng thái phòng golf
enum RoomBookingStatus {
  available, // Còn trống
  booked,    // Đã có khách đặt trong khung giờ này
  maintenance, // Đang bảo trì thiết bị
}

/// Model phòng chơi Golfzon thực tế (mô phỏng theo phòng A1..A5 của Okamura Golfzon)
class RoomModel {
  final String id;
  final String name;
  final bool isSmoking;
  final double pricePerHour;
  final int capacity;
  final String sensorModel;
  final bool isUnderMaintenance;
  final String description;
  final String category; // 'standard', 'vip', 'dual', 'connecting', 'range', 'studio'

  const RoomModel({
    required this.id,
    required this.name,
    required this.isSmoking,
    required this.pricePerHour,
    this.capacity = 4,
    this.sensorModel = 'Golfzon TwoVision Plus 3D',
    this.isUnderMaintenance = false,
    this.description = 'Phòng mô phỏng chuẩn quốc tế, cảm biến đa hướng tốc độ cao.',
    this.category = 'standard',
  });

  bool get isVip => category == 'vip' || id.contains('vip');
  bool get isDualTee => category == 'dual' || id.contains('dual');
  bool get isConnecting => category == 'connecting' || id.contains('b1_b2');
  bool get isDrivingRange => category == 'range' || id.contains('dr');
  bool get isStudio => category == 'studio' || id.contains('studio');

  String get categoryLabel {
    if (isVip) return 'VIP Suite';
    if (isDualTee) return 'Dual Tee';
    if (isConnecting) return 'Phòng Đôi';
    if (isDrivingRange) return 'Làn GDR Plus';
    if (isStudio) return 'PGA Studio';
    return isSmoking ? 'Tiêu Chuẩn (Hút thuốc)' : 'Tiêu Chuẩn';
  }

  String get posName {
    if (name.contains('A1') || id == 'room_a1') return 'PHÒNG 1';
    if (name.contains('A2') || id == 'room_a2') return 'PHÒNG 2';
    if (name.contains('A3') || id == 'room_a3') return 'PHÒNG 3';
    if (name.contains('A4') || id == 'room_a4') return 'PHÒNG 4';
    if (name.contains('A5') || id == 'room_a5') return 'PHÒNG 5';
    if (name.contains('A6') || id == 'room_a6_dual') return 'PHÒNG 6';
    if (name.contains('VIP 1')) return 'VIP 1';
    if (name.contains('VIP 2')) return 'VIP 2';
    if (name.contains('B1+B2') || name.contains('b1_b2')) return 'PHÒNG ĐÔI';
    if (name.contains('01') || id == 'room_dr1') return 'GDR 1';
    if (name.contains('02') || id == 'room_dr2') return 'GDR 2';
    if (name.contains('Studio') || id == 'room_studio1') return 'STUDIO';
    return name;
  }

  RoomModel copyWith({
    String? id,
    String? name,
    bool? isSmoking,
    double? pricePerHour,
    int? capacity,
    String? sensorModel,
    bool? isUnderMaintenance,
    String? description,
    String? category,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isSmoking: isSmoking ?? this.isSmoking,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      capacity: capacity ?? this.capacity,
      sensorModel: sensorModel ?? this.sensorModel,
      isUnderMaintenance: isUnderMaintenance ?? this.isUnderMaintenance,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isSmoking': isSmoking,
      'pricePerHour': pricePerHour,
      'capacity': capacity,
      'sensorModel': sensorModel,
      'isUnderMaintenance': isUnderMaintenance,
      'description': description,
      'category': category,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isSmoking: map['isSmoking'] as bool? ?? false,
      pricePerHour: (map['pricePerHour'] as num).toDouble(),
      capacity: map['capacity'] as int? ?? 4,
      sensorModel: map['sensorModel'] as String? ?? 'Golfzon TwoVision Plus 3D',
      isUnderMaintenance: map['isUnderMaintenance'] as bool? ?? false,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'standard',
    );
  }

  String toJson() => json.encode(toMap());
  factory RoomModel.fromJson(String source) =>
      RoomModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
