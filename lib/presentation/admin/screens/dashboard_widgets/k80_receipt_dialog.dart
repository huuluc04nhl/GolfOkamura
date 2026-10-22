import 'package:flutter/material.dart';
import 'package:golf_booking/core/utils/formatters.dart';
import 'package:golf_booking/core/utils/vietqr_helper.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/room_model.dart';
import 'package:golf_booking/shared/models/service_order_model.dart';

/// Dialog mô phỏng In Bill Nhiệt Khổ 80mm (K80 Thermal Receipt)
/// Chuẩn hóa quầy Bar & Lounge với mã VietQR động NAPAS ở chân bill
class K80ReceiptDialog extends StatelessWidget {
  final RoomModel room;
  final BookingModel? booking;
  final List<ServiceOrderModel> orders;
  final double roomTotal;
  final double serviceTotal;
  final double grandTotal;
  final bool applyVat;

  const K80ReceiptDialog({
    super.key,
    required this.room,
    required this.booking,
    required this.orders,
    required this.roomTotal,
    required this.serviceTotal,
    required this.grandTotal,
    this.applyVat = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final billNo = 'HD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${room.id.replaceAll('room_', '').toUpperCase()}';
    final qrUrl = VietQRHelper.generateQrUrl(
      amount: grandTotal,
      memo: 'TT $billNo',
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Thanh công cụ trên cùng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.print_rounded, color: Color(0xFFB69568), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Xem Trước Phiếu In K80 (80mm)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Thân hóa đơn K80 cuộn được
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Đầu bill
                    const Text(
                      'OKAMURA GOLFZON LOUNGE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Tầng 3, TTTM Golfzon Diamond Club\nHotline: 0901 234 567',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '------------------------------------------------',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
                    ),
                    const Text(
                      'PHIẾU TẠM TÍNH PHIÊN CHƠI',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      '------------------------------------------------',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
                    ),

                    // Thông tin ca & phòng
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildK80Row('Mã hóa đơn:', billNo),
                          _buildK80Row('Thời gian in:', dateStr),
                          _buildK80Row('Khu vực / Bay:', room.posName),
                          if (booking != null) ...[
                            _buildK80Row('Khách hàng:', booking!.customerName),
                            _buildK80Row('Khung giờ chơi:', booking!.timeSlot),
                          ],
                          _buildK80Row('Thu ngân trực:', 'Admin Lounge - Ca 1'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '================================================',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black87),
                    ),

                    // Bảng chi tiết món / giờ chơi
                    Row(
                      children: const [
                        Expanded(flex: 5, child: Text('TÊN MÓN / DV', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 3, child: Text('T.TIỀN', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    const Text(
                      '------------------------------------------------',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
                    ),

                    // 1. Dòng giờ chơi phòng Bay
                    if (booking != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Giờ chơi ${room.posName}\n(${booking!.timeSlot})',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              '1',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              Formatters.currency(roomTotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // 2. Các món F&B và dịch vụ
                    ...orders.expand((order) => order.items.map((item) {
                          final name = item['name'] ?? 'Món F&B';
                          final qty = (item['qty'] as num?)?.toInt() ?? 1;
                          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                          final total = price * qty;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    Formatters.currency(total),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),

                    const Text(
                      '================================================',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black87),
                    ),

                    // Tổng hợp thanh toán
                    _buildSummaryLine('Cộng tiền phòng:', Formatters.currency(roomTotal)),
                    _buildSummaryLine('Cộng F&B & Dịch vụ:', Formatters.currency(serviceTotal)),
                    if (applyVat)
                      _buildSummaryLine('Thuế GTGT (VAT 8%):', Formatters.currency((roomTotal + serviceTotal) * 0.08)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG CỘNG:',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text(
                          Formatters.currency(grandTotal),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                    const Text(
                      '================================================',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.black87),
                    ),
                    const SizedBox(height: 8),

                    // Mã VietQR động ở chân hóa đơn
                    const Text(
                      'QUÉT MÃ VIETQR THANH TOÁN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        qrUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.black45),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'STK: ${VietQRHelper.defaultAccountNo} - ${VietQRHelper.defaultBankId}\n${VietQRHelper.defaultAccountName}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '*** CẢM ƠN QUÝ KHÁCH & HẸN GẶP LẠI ***',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            // Nút Thao tác In
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Đóng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã gửi lệnh in Bill K80 tới máy in nhiệt quầy bar!'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('In Phiếu K80 (80mm)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildK80Row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          Text(amount, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
        ],
      ),
    );
  }
}
