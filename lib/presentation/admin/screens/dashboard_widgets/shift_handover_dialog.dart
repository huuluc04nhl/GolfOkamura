import 'package:flutter/material.dart';
import 'package:golf_booking/core/utils/formatters.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';

/// Dialog Bàn Giao Ca / Chốt Ca Thu Ngân & Điều Hành Lounge (Shift Handover)
class ShiftHandoverDialog extends StatefulWidget {
  final BookingProvider provider;

  const ShiftHandoverDialog({super.key, required this.provider});

  @override
  State<ShiftHandoverDialog> createState() => _ShiftHandoverDialogState();
}

class _ShiftHandoverDialogState extends State<ShiftHandoverDialog> {
  final _cashInDrawerController = TextEditingController();
  final _noteController = TextEditingController();
  double _actualCash = 0;

  @override
  void dispose() {
    _cashInDrawerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayBookings = widget.provider.bookings.where((b) {
      return b.bookingDate.year == now.year &&
          b.bookingDate.month == now.month &&
          b.bookingDate.day == now.day;
    }).toList();

    double totalRoomRevenue = 0;
    for (final b in todayBookings) {
      if (b.status == BookingStatus.confirmed || b.status == BookingStatus.completed) {
        totalRoomRevenue += b.totalPrice;
      }
    }

    double totalFnbRevenue = 0;
    for (final o in widget.provider.serviceOrders) {
      if (o.status == 'served' || o.status == 'completed') {
        totalFnbRevenue += o.totalPrice;
      }
    }

    final totalRevenue = totalRoomRevenue + totalFnbRevenue;
    // Tỉ lệ thanh toán ca trực: 40% tiền mặt, 60% chuyển khoản VietQR / thẻ POS
    final expectedCash = totalRevenue * 0.40;
    final expectedTransfer = totalRevenue * 0.60;
    final difference = _actualCash - expectedCash;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF131C31),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Tiêu đề
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB69568).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFFB69568), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BIÊN BẢN CHỐT CA & BÀN GIAO THU NGÂN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ca làm việc: Ca 1 (07:00 - 15:00) • Ngày ${now.day}/${now.month}/${now.year}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Nội dung thống kê & nhập số tiền
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid thẻ tóm tắt doanh số ca
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Tổng Doanh Thu Ca',
                            Formatters.currency(totalRevenue),
                            Icons.monetization_on_rounded,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Tiền Phòng Bay (${todayBookings.length} lượt)',
                            Formatters.currency(totalRoomRevenue),
                            Icons.sports_golf_rounded,
                            const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Doanh Thu F&B & Bar',
                            Formatters.currency(totalFnbRevenue),
                            Icons.restaurant_rounded,
                            const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phân loại phương thức thanh toán
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CƠ CẤU THANH TOÁN THEO SỔ SÁCH',
                            style: TextStyle(
                              color: Color(0xFFB69568),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentTypeRow(
                                  'Tiền mặt sổ sách (40%)',
                                  Formatters.currency(expectedCash),
                                  Icons.payments_outlined,
                                  const Color(0xFF10B981),
                                ),
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFF1E293B)),
                              Expanded(
                                child: _buildPaymentTypeRow(
                                  'Chuyển khoản VietQR / Thẻ (60%)',
                                  Formatters.currency(expectedTransfer),
                                  Icons.qr_code_2_rounded,
                                  const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nhập số tiền mặt thực tế kiểm đếm trong két
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: difference == 0
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : (difference > 0 ? const Color(0xFF0284C7) : const Color(0xFFEF4444)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KIỂM ĐẾM TIỀN MẶT THỰC TẾ TRONG KÉT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cashInDrawerController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    hintText: 'Nhập số tiền mặt đếm được (VNĐ)...',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                    suffixText: 'VNĐ',
                                    suffixStyle: const TextStyle(color: Color(0xFFB69568)),
                                    prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFFB69568)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF334155)),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                                    setState(() {
                                      _actualCash = parsed;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _actualCash = expectedCash;
                                    _cashInDrawerController.text = expectedCash.toInt().toString();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB69568),
                                  side: const BorderSide(color: Color(0xFFB69568)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                ),
                                child: const Text('Khớp Sổ Sách'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tiền mặt cần bàn giao theo sổ sách: ${Formatters.currency(expectedCash)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Chênh lệch: ',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    Formatters.currency(difference),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: difference == 0
                                          ? const Color(0xFF10B981)
                                          : (difference > 0 ? const Color(0xFF0284C7) : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú bàn giao
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        hintText: 'Ghi chú bàn giao ca (thiết bị, công nợ, khách hẹn, tồn kho rượu/bia)...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút hành động
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.provider.submitShiftHandover(
                        totalRevenue: totalRevenue,
                        cashAmount: _actualCash > 0 ? _actualCash : expectedCash,
                        transferAmount: expectedTransfer,
                        cashierName: 'OKAMURA ADMIN',
                        notes: _noteController.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chốt ca trực thành công! Doanh thu: ${Formatters.currency(totalRevenue)} • Đã đồng bộ biên bản lên Firebase.',
                            ),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Chốt Ca & Bàn Giao'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeRow(String label, String amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 2),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
