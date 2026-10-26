import 'package:flutter/material.dart';

/// Danh mục món F&B / Dịch vụ thuê gậy / HLV được lưu trữ & đồng bộ từ Firebase
class ServiceItemModel {
  final String id;
  final int category; // 0: Đồ uống, 1: Ẩm thực, 2: Thuê gậy, 3: HLV & Caddie
  final String name;
  final String subtitle;
  final double price;
  final String tag;
  final String iconKey;
  final String accentHex;
  final String? imageUrl;

  const ServiceItemModel({
    required this.id,
    required this.category,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.tag,
    required this.iconKey,
    this.accentHex = 'B69568',
    this.imageUrl,
  });

  IconData get iconData {
    switch (iconKey) {
      case 'coffee':
        return Icons.coffee_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      case 'beer':
        return Icons.sports_bar_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'ramen':
        return Icons.ramen_dining_rounded;
      case 'fruit':
        return Icons.icecream_rounded;
      case 'golf':
        return Icons.sports_golf_rounded;
      case 'vip':
        return Icons.workspace_premium_rounded;
      case 'shoe':
        return Icons.roller_skating_rounded;
      case 'glove':
        return Icons.front_hand_rounded;
      case 'caddie':
        return Icons.support_agent_rounded;
      case 'coach':
        return Icons.school_rounded;
      case 'video':
        return Icons.videocam_rounded;
      default:
        return Icons.room_service_rounded;
    }
  }

  Color get accentColor {
    try {
      return Color(int.parse('0xFF$accentHex'));
    } catch (_) {
      return const Color(0xFFB69568);
    }
  }

  String get unit {
    if (name.contains('Tháp')) {
      return 'tháp';
    }
    if (name.contains('Bia Ly')) {
      return 'ly';
    }
    if (name.contains('Bia') ||
        name.contains('Tiger') ||
        name.contains('Coca') ||
        name.contains('Sprite') ||
        name.contains('Monster') ||
        name.contains('Soda') ||
        name.contains('Aquarius')) {
      return 'lon';
    }
    if (name.contains('Dasani') ||
        name.contains('Nước') ||
        name.contains('Teddy')) {
      return 'chai';
    }
    if (name.contains('Cà phê') ||
        name.contains('Americano') ||
        name.contains('Espresso') ||
        name.contains('Latte') ||
        name.contains('Lungo') ||
        name.contains('Cappuchino') ||
        name.contains('Flat White') ||
        name.contains('Au Lait')) {
      return 'ly';
    }
    if (name.contains('18 LỖ') ||
        name.contains('9 LỖ') ||
        name.contains('Giờ') ||
        name.contains('1 Giờ') ||
        name.contains('60 Phút')) {
      return 'h';
    }
    if (name.contains('Fullset')) {
      return 'bộ';
    }
    if (name.contains('Đĩa') ||
        name.contains('Gà') ||
        name.contains('Xúc Xích') ||
        name.contains('Mì')) {
      return 'đĩa';
    }
    if (name.contains('Găng') || name.contains('Giày')) {
      return 'đôi';
    }
    return 'phần';
  }

  String get resolvedImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    // Ánh xạ ảnh món thực tế sắc nét theo tên & phân loại
    final n = name.toLowerCase();
    if (n.contains('americano') || n.contains('cà phê') || n.contains('espresso') || n.contains('lungo')) {
      return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('latte') || n.contains('cappuchino') || n.contains('flat white')) {
      return 'https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('tháp') || n.contains('tower')) {
      return 'https://images.unsplash.com/photo-1538488881522-4328ca75ab60?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('sapporo') || n.contains('tiger') || n.contains('bia') || n.contains('asahi') || n.contains('heineken')) {
      return 'https://images.unsplash.com/photo-1608270586620-248524c67de9?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('coca') || n.contains('sprite') || n.contains('monster') || n.contains('pepsi') || n.contains('energy')) {
      return 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('dasani') || n.contains('nước khoáng') || n.contains('aquarius') || n.contains('soda')) {
      return 'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('gà') || n.contains('chicken') || n.contains('bò') || n.contains('xúc xích') || n.contains('steak')) {
      return 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('mì') || n.contains('ramen') || n.contains('udon') || n.contains('phở')) {
      return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('quả') || n.contains('trái cây') || n.contains('fruit') || n.contains('salad')) {
      return 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('taylormade') || n.contains('fullset') || n.contains('gậy') || n.contains('driver') || n.contains('iron')) {
      return 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('giày') || n.contains('shoes')) {
      return 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('găng') || n.contains('glove')) {
      return 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('hlv') || n.contains('caddie') || n.contains('coach') || n.contains('pro')) {
      return 'https://images.unsplash.com/photo-1592919505780-303950717480?auto=format&fit=crop&w=400&q=80';
    }
    if (n.contains('lỗ') || n.contains('golfzon') || n.contains('giờ')) {
      return 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?auto=format&fit=crop&w=400&q=80';
    }
    // Fallback theo Category
    switch (category) {
      case 0:
        return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80';
      case 1:
        return 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=400&q=80';
      case 2:
        return 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=400&q=80';
      case 3:
        return 'https://images.unsplash.com/photo-1592919505780-303950717480?auto=format&fit=crop&w=400&q=80';
      default:
        return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'name': name,
        'subtitle': subtitle,
        'price': price,
        'tag': tag,
        'iconKey': iconKey,
        'accentHex': accentHex,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  factory ServiceItemModel.fromMap(Map<String, dynamic> map) {
    return ServiceItemModel(
      id: (map['id'] ?? '').toString(),
      category: (map['category'] is int)
          ? map['category'] as int
          : int.tryParse(map['category']?.toString() ?? '0') ?? 0,
      name: (map['name'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0,
      tag: (map['tag'] ?? '').toString(),
      iconKey: (map['iconKey'] ?? 'service').toString(),
      accentHex: (map['accentHex'] ?? 'B69568').toString(),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  ServiceItemModel copyWith({
    String? id,
    int? category,
    String? name,
    String? subtitle,
    double? price,
    String? tag,
    String? iconKey,
    String? accentHex,
    String? imageUrl,
  }) {
    return ServiceItemModel(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      tag: tag ?? this.tag,
      iconKey: iconKey ?? this.iconKey,
      accentHex: accentHex ?? this.accentHex,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Đơn gọi món / yêu cầu hỗ trợ tại phòng đồng bộ trực tiếp lên Firebase (/serviceOrders)
class ServiceOrderModel {
  final String id;
  final String roomName;
  final List<Map<String, dynamic>> items; // [{'id', 'name', 'qty', 'price'}]
  final double totalPrice;
  final String status; // 'preparing', 'served', 'cancelled'
  final String orderType; // 'fnb_order' hoặc 'quick_request'
  final String? note;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod; // 'pay_at_bay' (Gộp hóa đơn Bay) hoặc 'vietqr' (Quét QR ngay)
  final String paymentStatus; // 'pending' (chưa thanh toán / gộp phòng) hoặc 'paid' (đã trả)
  final DateTime createdAt;

  const ServiceOrderModel({
    required this.id,
    required this.roomName,
    required this.items,
    required this.totalPrice,
    this.status = 'preparing',
    this.orderType = 'fnb_order',
    this.note,
    this.customerName,
    this.customerPhone,
    this.paymentMethod = 'pay_at_bay',
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  ServiceOrderModel copyWith({
    String? id,
    String? roomName,
    List<Map<String, dynamic>>? items,
    double? totalPrice,
    String? status,
    String? orderType,
    String? note,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return ServiceOrderModel(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'served':
        return 'Đã phục vụ';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Đang chuẩn bị';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'vietqr':
        return 'VietQR chuyển khoản';
      default:
        return 'Gộp hóa đơn Bay';
    }
  }

  String get summaryText {
    if (items.isEmpty) return note ?? 'Yêu cầu hỗ trợ phòng';
    final first = items.first;
    final firstName = (first['name'] ?? '').toString();
    if (items.length == 1) return firstName;
    return '$firstName +${items.length - 1} món';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'roomName': roomName,
        'items': items,
        'totalPrice': totalPrice,
        'status': status,
        'orderType': orderType,
        'note': note,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServiceOrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final List<Map<String, dynamic>> parsedItems = [];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          parsedItems.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return ServiceOrderModel(
      id: (map['id'] ?? '').toString(),
      roomName: (map['roomName'] ?? 'Room 1').toString(),
      items: parsedItems,
      totalPrice: (map['totalPrice'] is num)
          ? (map['totalPrice'] as num).toDouble()
          : double.tryParse(map['totalPrice']?.toString() ?? '0') ?? 0,
      status: (map['status'] ?? 'preparing').toString(),
      orderType: (map['orderType'] ?? 'fnb_order').toString(),
      note: map['note']?.toString(),
      customerName: map['customerName']?.toString(),
      customerPhone: map['customerPhone']?.toString(),
      paymentMethod: (map['paymentMethod'] ?? 'pay_at_bay').toString(),
      paymentStatus: (map['paymentStatus'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
