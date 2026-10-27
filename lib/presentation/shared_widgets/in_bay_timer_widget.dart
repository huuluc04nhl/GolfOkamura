import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Widget đồng hồ đếm ngược phiên chơi và tiến độ hố tại phòng Bay (Live In-Bay Timer)
class InBayTimerWidget extends StatefulWidget {
  final String roomName;
  final String timeSlot; // VD: '15:00 - 17:00'
  final DateTime bookingDate;
  final VoidCallback? onExtendSession;
  final bool isCompact;

  const InBayTimerWidget({
    super.key,
    required this.roomName,
    required this.timeSlot,
    required this.bookingDate,
    this.onExtendSession,
    this.isCompact = false,
  });

  @override
  State<InBayTimerWidget> createState() => _InBayTimerWidgetState();
}

class _InBayTimerWidgetState extends State<InBayTimerWidget> {
  late Timer _ticker;
  Duration _remaining = Duration.zero;
  double _progress = 0.0;
  bool _isOverdue = false;
  int _currentEstimatedHole = 1;

  @override
  void initState() {
    super.initState();
    _calculateSessionTime();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calculateSessionTime();
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _calculateSessionTime() {
    final now = DateTime.now();
    final parts = widget.timeSlot.split('-');
    if (parts.length != 2) return;

    try {
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      final startTime = DateTime(
        widget.bookingDate.year,
        widget.bookingDate.month,
        widget.bookingDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        widget.bookingDate.year,
        widget.bookingDate.month,
        widget.bookingDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      final totalDuration = endTime.difference(startTime).inSeconds;
      if (totalDuration <= 0) return;

      if (now.isBefore(startTime)) {
        // Chưa tới giờ chơi
        final untilStart = startTime.difference(now);
        setState(() {
          _remaining = untilStart;
          _progress = 0.0;
          _isOverdue = false;
          _currentEstimatedHole = 1;
        });
      } else if (now.isAfter(endTime)) {
        // Đã quá giờ
        final overdue = now.difference(endTime);
        setState(() {
          _remaining = overdue;
          _progress = 1.0;
          _isOverdue = true;
          _currentEstimatedHole = 18;
        });
      } else {
        // Đang trong phiên chơi
        final elapsed = now.difference(startTime).inSeconds;
        final left = endTime.difference(now);
        final progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        final estimatedHole = ((progress * 18).ceil()).clamp(1, 18);

        setState(() {
          _remaining = left;
          _progress = progress;
          _isOverdue = false;
          _currentEstimatedHole = estimatedHole;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final Color statusColor = _isOverdue
        ? Colors.redAccent
        : (minutes <= 15 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    if (widget.isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Text(
              _isOverdue ? 'Quá: $timeStr' : 'Còn: $timeStr',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PHIÊN CHƠI GOLFZON: ${widget.roomName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Hố $_currentEstimatedHole / 18',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Thanh tiến độ & Thời gian đếm ngược
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Khung: ${widget.timeSlot}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isOverdue
                                ? 'ĐÃ QUÁ GIỜ: $timeStr'
                                : 'CÒN LẠI: $timeStr',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onExtendSession != null) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onExtendSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF26354D)),
                    ),
                  ),
                  icon: const Icon(Icons.more_time_rounded, size: 14),
                  label: const Text('Gia Hạn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
