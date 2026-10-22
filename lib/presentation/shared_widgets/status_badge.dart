import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/room_model.dart';

/// Huy hiệu hiển thị trạng thái phòng
class RoomStatusBadge extends StatelessWidget {
  final RoomBookingStatus status;

  const RoomStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    String label;
    IconData icon;

    switch (status) {
      case RoomBookingStatus.available:
        textColor = AppColors.primaryGold;
        bgColor = AppColors.statusAvailableBg;
        label = 'Phòng trống';
        icon = Icons.check_circle_outline;
        break;
      case RoomBookingStatus.booked:
        textColor = AppColors.statusBooked;
        bgColor = AppColors.statusBookedBg;
        label = 'Đã đặt';
        icon = Icons.lock_clock;
        break;
      case RoomBookingStatus.maintenance:
        textColor = AppColors.statusMaintenance;
        bgColor = AppColors.statusMaintenanceBg;
        label = 'Bảo trì';
        icon = Icons.build_circle_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu hiển thị trạng thái đơn đặt
class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BookingStatus.confirmed:
        color = const Color(0xFF2E7D32);
        break;
      case BookingStatus.completed:
        color = const Color(0xFF1976D2);
        break;
      case BookingStatus.cancelled:
        color = AppColors.statusBooked;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
