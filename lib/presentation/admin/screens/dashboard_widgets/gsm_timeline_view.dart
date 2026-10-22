import 'package:flutter/material.dart';
import 'package:golf_booking/core/utils/formatters.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/room_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';

/// Lịch Trình Đặt Chỗ GSM (Golfzon Simulator Management Timeline)
class GsmTimelineView extends StatefulWidget {
  final BookingProvider provider;
  final List<RoomModel> rooms;
  final bool isMobile;
  final void Function(RoomModel room) onQuickCheckin;

  const GsmTimelineView({
    super.key,
    required this.provider,
    required this.rooms,
    required this.isMobile,
    required this.onQuickCheckin,
  });

  @override
  State<GsmTimelineView> createState() => _GsmTimelineViewState();
}

class _GsmTimelineViewState extends State<GsmTimelineView> {
  DateTime _currentDate = DateTime.now();

  BookingModel? _getActiveBooking(String roomId) {
    for (final b in widget.provider.bookings) {
      if (b.status == BookingStatus.confirmed && b.roomId == roomId) {
        return b;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hours = [
      '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM',
      '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
      '09:00 PM', '10:00 PM'
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header Lịch Trình
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: widget.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFFB69568), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lịch Bay: ${Formatters.formatDate(_currentDate)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => setState(() => _currentDate = DateTime.now()),
                            child: const Text('Hôm nay', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.rooms.isNotEmpty) {
                              widget.onQuickCheckin(widget.rooms.first);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Đặt Bay Mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFFB69568), size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Lịch Đặt Phòng Golfzon: ${Formatters.formatDate(_currentDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _currentDate = DateTime.now()),
                        child: const Text('Hôm nay'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.rooms.isNotEmpty) {
                            widget.onQuickCheckin(widget.rooms.first);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Đặt Bay Mới', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),

          // Ma trận Timeline
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cột danh sách phòng
                  SizedBox(
                    width: widget.isMobile ? 140 : 200,
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          color: const Color(0xFFF8FAFC),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 12),
                          child: const Text('DANH SÁCH BAY GOLFZON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        ...widget.rooms.map((room) {
                          final booking = _getActiveBooking(room.id);
                          return Container(
                            height: 68,
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                right: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(room.posName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const Spacer(),
                                    Text(
                                      booking != null ? 'Đang chơi' : 'Trống',
                                      style: TextStyle(
                                        color: booking != null ? const Color(0xFF10B981) : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking != null ? 'Phiên 18 hố • Đang hoạt động' : 'Sẵn sàng đón khách',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Lưới giờ ngang
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 900,
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Container(
                                  height: 40,
                                  color: const Color(0xFFF8FAFC),
                                  child: Row(
                                    children: hours.map((h) {
                                      return SizedBox(
                                        width: 90,
                                        child: Text(
                                          h,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                ...widget.rooms.map((room) {
                                  return Container(
                                    height: 68,
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      children: hours.map((_) {
                                        return Container(
                                          width: 90,
                                          decoration: const BoxDecoration(
                                            border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }),
                              ],
                            ),

                            // Vạch đỏ thời gian thực
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: 180,
                              child: Container(
                                width: 2,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
