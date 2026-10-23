import 'dart:convert';

/// Trạng thái đơn đặt phòng
enum BookingStatus {
  confirmed, // Đã xác nhận
  completed, // Đã hoàn thành (sau khi chơi)
  cancelled, // Đã hủy
}

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.completed:
        return 'Đã hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Đơn đặt phòng thực tế của khách hàng
class BookingModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String roomId;
  final String roomName;
  final DateTime bookingDate;
  final String timeSlot;
  final double totalPrice;
  final String? notes;
  final BookingStatus status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.roomId,
    required this.roomName,
    required this.bookingDate,
    required this.timeSlot,
    required this.totalPrice,
    this.notes,
    this.status = BookingStatus.confirmed,
    required this.createdAt,
  });

  BookingModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? roomId,
    String? roomName,
    DateTime? bookingDate,
    String? timeSlot,
    double? totalPrice,
    String? notes,
    BookingStatus? status,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'roomId': roomId,
      'roomName': roomName,
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot,
      'totalPrice': totalPrice,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      customerEmail: map['customerEmail'] as String?,
      roomId: map['roomId'] as String,
      roomName: map['roomName'] as String,
      bookingDate: DateTime.parse(map['bookingDate'] as String),
      timeSlot: map['timeSlot'] as String,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      notes: map['notes'] as String?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());
  factory BookingModel.fromJson(String source) =>
      BookingModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
