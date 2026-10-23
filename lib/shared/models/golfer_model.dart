import 'package:flutter/material.dart';

/// Hạng hội viên Golfer tại Okamura Golfzon Lounge
enum GolferTier {
  standard, // Tiêu chuẩn
  silver,   // Bạc (Tích lũy > 5 triệu)
  gold,     // Vàng (Tích lũy > 15 triệu)
  diamond,  // Kim Cương (Tích lũy > 35 triệu)
}

extension GolferTierX on GolferTier {
  static GolferTier fromSpend(double spend) {
    if (spend >= 35000000) return GolferTier.diamond;
    if (spend >= 15000000) return GolferTier.gold;
    if (spend >= 5000000) return GolferTier.silver;
    return GolferTier.standard;
  }

  String get label {
    switch (this) {
      case GolferTier.standard:
        return 'Standard Member';
      case GolferTier.silver:
        return 'Silver VIP';
      case GolferTier.gold:
        return 'Gold VIP';
      case GolferTier.diamond:
        return 'Diamond Elite';
    }
  }

  double get discountPercent {
    switch (this) {
      case GolferTier.standard:
        return 0.0;
      case GolferTier.silver:
        return 0.05; // Giảm 5%
      case GolferTier.gold:
        return 0.10; // Giảm 10%
      case GolferTier.diamond:
        return 0.15; // Giảm 15%
    }
  }

  Color get color {
    switch (this) {
      case GolferTier.standard:
        return const Color(0xFF94A3B8);
      case GolferTier.silver:
        return const Color(0xFFCBD5E1);
      case GolferTier.gold:
        return const Color(0xFFF59E0B);
      case GolferTier.diamond:
        return const Color(0xFF38BDF8);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case GolferTier.standard:
        return const [Color(0xFF334155), Color(0xFF1E293B)];
      case GolferTier.silver:
        return const [Color(0xFF94A3B8), Color(0xFF475569)];
      case GolferTier.gold:
        return const [Color(0xFFB69568), Color(0xFF785B28)];
      case GolferTier.diamond:
        return const [Color(0xFF0284C7), Color(0xFF0F172A)];
    }
  }
}

/// Thông tin hồ sơ hội viên Golfer
class GolferModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final double handicap;
  final GolferTier tier;
  final int loyaltyPoints;
  final double totalSpend;
  final DateTime memberSince;
  final String role; // 'admin' | 'customer'
  final String password;

  const GolferModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.handicap = 18.0,
    this.tier = GolferTier.standard,
    this.loyaltyPoints = 0,
    this.totalSpend = 0.0,
    required this.memberSince,
    this.role = 'customer',
    this.password = '123456',
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';
  bool get isGuest => role == 'guest' || id == 'golfer_guest';

  GolferModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    double? handicap,
    GolferTier? tier,
    int? loyaltyPoints,
    double? totalSpend,
    DateTime? memberSince,
    String? role,
    String? password,
  }) {
    return GolferModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      handicap: handicap ?? this.handicap,
      tier: tier ?? this.tier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpend: totalSpend ?? this.totalSpend,
      memberSince: memberSince ?? this.memberSince,
      role: role ?? this.role,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'handicap': handicap,
      'tier': tier.name,
      'loyaltyPoints': loyaltyPoints,
      'totalSpend': totalSpend,
      'memberSince': memberSince.toIso8601String(),
      'role': role,
      'password': password,
    };
  }

  factory GolferModel.fromMap(Map<String, dynamic> map) {
    GolferTier parseTier(String? val) {
      switch (val) {
        case 'silver':
          return GolferTier.silver;
        case 'gold':
          return GolferTier.gold;
        case 'diamond':
          return GolferTier.diamond;
        default:
          return GolferTier.standard;
      }
    }

    return GolferModel(
      id: (map['id'] ?? 'golfer_default').toString(),
      name: (map['name'] ?? 'Golfer VIP').toString(),
      phone: (map['phone'] ?? '0901234567').toString(),
      email: map['email'] as String?,
      handicap: (map['handicap'] is num)
          ? (map['handicap'] as num).toDouble()
          : double.tryParse(map['handicap']?.toString() ?? '18.0') ?? 18.0,
      tier: parseTier(map['tier']?.toString()),
      loyaltyPoints: (map['loyaltyPoints'] is int)
          ? map['loyaltyPoints'] as int
          : int.tryParse(map['loyaltyPoints']?.toString() ?? '0') ?? 0,
      totalSpend: (map['totalSpend'] is num)
          ? (map['totalSpend'] as num).toDouble()
          : double.tryParse(map['totalSpend']?.toString() ?? '0') ?? 0.0,
      memberSince: DateTime.tryParse(map['memberSince']?.toString() ?? '') ?? DateTime.now(),
      role: (map['role'] ?? 'customer').toString(),
      password: (map['password'] ?? '123456').toString(),
    );
  }

  /// Tài khoản mẫu chuẩn Okamura Admin
  static GolferModel get defaultAdminProfile => GolferModel(
    id: 'admin_okamura',
    name: 'OKAMURA ADMIN',
    phone: '0901234567',
    email: 'admin@okamura-golf.vn',
    handicap: 14.2,
    tier: GolferTier.diamond,
    loyaltyPoints: 5000,
    totalSpend: 35000000,
    memberSince: DateTime(2025, 1, 1),
    role: 'admin',
    password: 'admin',
  );

  /// Tài khoản khách hàng thực tế duy nhất theo yêu cầu: NGUYỄN XUÂN HÀO
  static GolferModel get customerHaoProfile => GolferModel(
    id: 'golfer_nguyenxuanhao',
    name: 'Nguyễn Xuân Hào',
    phone: '0354378606',
    email: 'haosimla365@gmail.com',
    handicap: 15.6,
    tier: GolferTier.gold,
    loyaltyPoints: 1250,
    totalSpend: 16500000,
    memberSince: DateTime(2025, 6, 15),
    role: 'customer',
    password: '123456',
  );

  /// Tài khoản Khách vãng lai (không đăng nhập)
  static GolferModel get guestProfile => GolferModel(
    id: 'golfer_guest',
    name: 'Khách vãng lai',
    phone: '',
    email: null,
    handicap: 18.0,
    tier: GolferTier.standard,
    loyaltyPoints: 0,
    totalSpend: 0.0,
    memberSince: DateTime(2026, 1, 1),
    role: 'guest',
    password: '',
  );

  /// Mặc định hệ thống
  static GolferModel get defaultProfile => defaultAdminProfile;
}
