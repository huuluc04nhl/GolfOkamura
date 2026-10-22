import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_booking/core/utils/formatters.dart';
import 'package:golf_booking/shared/models/booking_model.dart';
import 'package:golf_booking/shared/models/room_model.dart';
import 'package:golf_booking/shared/models/service_order_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';
import 'package:golf_booking/presentation/shared_widgets/in_bay_timer_widget.dart';
import 'k80_receipt_dialog.dart';

/// Bảng Hóa Đơn & Điều Hành Vận Hành Bay (Bay Invoice & Operations Panel)
/// Mô-đun hóa độc lập cho màn hình Admin Operations Lounge
class BayInvoicePanel extends StatefulWidget {
  final RoomModel room;
  final BookingModel? booking;
  final List<ServiceOrderModel> orders;
  final VoidCallback onTransferRoom;
  final VoidCallback onGoToFnb;
  final VoidCallback onGoToServices;
  final VoidCallback onReleaseBay;
  final bool isTablet;

  const BayInvoicePanel({
    super.key,
    required this.room,
    required this.booking,
    required this.orders,
    required this.onTransferRoom,
    required this.onGoToFnb,
    required this.onGoToServices,
    required this.onReleaseBay,
    this.isTablet = false,
  });

  @override
  State<BayInvoicePanel> createState() => _BayInvoicePanelState();
}

class _BayInvoicePanelState extends State<BayInvoicePanel> {
  bool _applyVat = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final roomTotal = widget.booking?.totalPrice ?? 0.0;

    double serviceTotal = 0.0;
    for (final order in widget.orders) {
      if (order.status != 'cancelled') {
        serviceTotal += order.totalPrice;
      }
    }

    final subtotal = roomTotal + serviceTotal;
    final vatAmount = _applyVat ? (subtotal * 0.08) : 0.0;
    final grandTotal = subtotal + vatAmount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header hóa đơn phòng
          _buildHeader(context, roomTotal, serviceTotal, grandTotal),

          // Banner thông báo đơn khách từ app nếu có
          _buildGuestOrdersNotificationBanner(context, provider),

          // Widget đồng hồ đếm ngược phiên chơi (Live In-Bay Timer)
          if (widget.booking != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: InBayTimerWidget(
                roomName: widget.room.posName,
                timeSlot: widget.booking!.timeSlot,
                bookingDate: widget.booking!.bookingDate,
                isCompact: true,
              ),
            ),

          // Bảng tính chi tiết các mục dịch vụ & giờ chơi
          Expanded(
            child: _buildItemizedTable(provider),
          ),

          // Chân hóa đơn & Tóm tắt tổng tiền + 4 Nút nghiệp vụ
          _buildFooter(context, subtotal, vatAmount, grandTotal),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double roomTotal,
    double serviceTotal,
    double grandTotal,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.room.posName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: widget.booking != null
                ? Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Golfer: ${widget.booking!.customerName} • ${widget.booking!.timeSlot}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Bay đang trống • Sẵn sàng đón khách mới',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
          ),
          const SizedBox(width: 8),

          // Nút Xem & In Phiếu K80
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => K80ReceiptDialog(
                  room: widget.room,
                  booking: widget.booking,
                  orders: widget.orders,
                  roomTotal: roomTotal,
                  serviceTotal: serviceTotal,
                  grandTotal: grandTotal,
                  applyVat: _applyVat,
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.print_outlined, size: 14, color: Color(0xFFB69568)),
                  SizedBox(width: 5),
                  Text(
                    'In Bill K80',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildGuestOrdersNotificationBanner(BuildContext context, BookingProvider provider) {
    final pendingOrders = widget.orders.where((o) => o.status == 'preparing').toList();
    if (pendingOrders.isEmpty) return const SizedBox.shrink();

    final totalItemsCount = pendingOrders.fold<int>(0, (sum, o) => sum + o.items.length);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Có ${pendingOrders.length} đơn ($totalItemsCount món) khách vừa gọi từ App!',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              for (final o in pendingOrders) {
                await provider.updateServiceOrderStatus(o.id, 'served');
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xác nhận phục vụ tất cả các đơn khách gọi!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Xác nhận xong',
                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemizedTable(BookingProvider provider) {
    final bool isEmpty = widget.booking == null && widget.orders.isEmpty;
    final fnbOrders = widget.orders.where((o) => o.orderType != 'quick_request').toList();
    final quickRequests = widget.orders.where((o) => o.orderType == 'quick_request').toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: const Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              Expanded(flex: 4, child: Text('Tên dịch vụ / Món gọi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              SizedBox(width: 36, child: Text('ĐVT', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              SizedBox(width: 76, child: Text('Số lượng', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              SizedBox(width: 76, child: Text('Đơn giá', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              SizedBox(width: 86, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              SizedBox(width: 30),
            ],
          ),
        ),
        Expanded(
          child: isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_golf_outlined, size: 44, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa phát sinh chi phí tại ${widget.room.posName}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chạm vào thực đơn bên phải để thêm món hoặc khách gọi từ app',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    if (widget.booking != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: const Color(0xFFF8FAFC),
                        child: const Row(
                          children: [
                            Icon(Icons.sports_golf_rounded, size: 14, color: Color(0xFFB69568)),
                            SizedBox(width: 6),
                            Text(
                              '1. TIỀN PHÒNG & PHIÊN CHƠI GOLFZON',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 28, child: Text('1', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phiên chơi Golfzon 18 Hố (${widget.booking!.timeSlot})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    'Golfer: ${widget.booking!.customerName} • ${widget.room.sensorModel}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 36, child: Text('h', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                            const SizedBox(width: 76, child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            SizedBox(
                              width: 76,
                              child: Text(
                                Formatters.formatCurrency(widget.booking!.totalPrice),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                            SizedBox(
                              width: 86,
                              child: Text(
                                Formatters.formatCurrency(widget.booking!.totalPrice),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 30),
                          ],
                        ),
                      ),
                    ],

                    if (fnbOrders.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded, size: 14, color: Color(0xFF0275D8)),
                            const SizedBox(width: 6),
                            Text(
                              '2. DỊCH VỤ F&B & THUÊ ĐỒ (${fnbOrders.fold<int>(0, (sum, o) => sum + o.items.length)} món)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._buildOrderItems(provider, fnbOrders, widget.booking != null ? 2 : 1),
                    ],

                    if (quickRequests.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: const Color(0xFFF8FAFC),
                        child: const Row(
                          children: [
                            Icon(Icons.room_service_rounded, size: 14, color: Color(0xFF10B981)),
                            SizedBox(width: 6),
                            Text(
                              '3. YÊU CẦU PHỤC VỤ TẠI PHÒNG (Miễn phí)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...quickRequests.map((req) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 28, child: Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981))),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  req.note ?? 'Yêu cầu phục vụ phòng',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF047857)),
                                ),
                              ),
                              const SizedBox(width: 36, child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                              const SizedBox(width: 76, child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                              const SizedBox(width: 76, child: Text('Miễn phí', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Color(0xFF10B981)))),
                              const SizedBox(width: 86, child: Text('0 đ', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                              SizedBox(
                                width: 30,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF10B981)),
                                  tooltip: 'Đã hoàn tất hỗ trợ',
                                  onPressed: () => provider.deleteServiceOrder(req.id),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _buildOrderItems(
    BookingProvider provider,
    List<ServiceOrderModel> orders,
    int startIndex,
  ) {
    int index = startIndex;
    final List<Widget> rows = [];

    for (final order in orders) {
      for (final item in order.items) {
        final rowIdx = index++;
        final itemId = (item['id'] ?? '').toString();
        final name = (item['name'] ?? '').toString();
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final total = price * qty;

        rows.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text('$rowIdx', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      if (order.orderType == 'fnb_order') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('App', style: TextStyle(color: Color(0xFF059669), fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    name.contains('Tháp') ? 'tháp' : (name.contains('Bia') || name.contains('Tiger') || name.contains('Coca') ? 'lon' : (name.contains('Dasani') ? 'chai' : 'ly')),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => provider.updateServiceItemQuantity(
                          orderId: order.id,
                          itemId: itemId,
                          delta: -1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$qty',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      InkWell(
                        onTap: () => provider.updateServiceItemQuantity(
                          orderId: order.id,
                          itemId: itemId,
                          delta: 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Text(
                    Formatters.formatCurrency(price),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Text(
                    Formatters.formatCurrency(total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    onPressed: () => provider.removeServiceItem(orderId: order.id, itemId: itemId),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return rows;
  }

  Widget _buildFooter(
    BuildContext context,
    double subtotal,
    double vatAmount,
    double grandTotal,
  ) {
    final hasActiveSession = widget.booking != null || widget.orders.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border(top: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      child: Column(
        children: [
          // Tiền tạm tính & Checkbox VAT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _applyVat,
                      activeColor: const Color(0xFF0F172A),
                      onChanged: (val) {
                        setState(() {
                          _applyVat = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('VAT (8%)', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
              Row(
                children: [
                  const Text('Tổng thanh toán: ', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  Text(
                    Formatters.currency(grandTotal),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4 nút nghiệp vụ vận hành Bay cân đối 1:1:1:1
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Đổi Bay',
                  Icons.swap_horiz_rounded,
                  const Color(0xFF334155),
                  widget.onTransferRoom,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Gọi Món',
                  Icons.restaurant_rounded,
                  const Color(0xFFD97706),
                  widget.onGoToFnb,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Dịch Vụ',
                  Icons.sports_golf_rounded,
                  const Color(0xFF0284C7),
                  widget.onGoToServices,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Trả Bay',
                  Icons.check_circle_outline_rounded,
                  hasActiveSession ? const Color(0xFF059669) : Colors.grey,
                  widget.onReleaseBay,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color bg,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: isPrimary ? 2 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
