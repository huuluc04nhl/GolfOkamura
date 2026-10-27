import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/vietqr_helper.dart';

/// Modal Quét Mã Thanh Toán VietQR Chuẩn NAPAS 24/7 Dành Cho Golfer & Khách Hàng
class VietQrPaymentDialog extends StatelessWidget {
  final String bookingId;
  final String roomName;
  final double amount;
  final String? customerName;
  final VoidCallback? onPaymentConfirmed;

  const VietQrPaymentDialog({
    super.key,
    required this.bookingId,
    required this.roomName,
    required this.amount,
    this.customerName,
    this.onPaymentConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final memo = 'OKAMURA $bookingId';
    final qrUrl = VietQRHelper.generateQrUrl(
      amount: amount,
      memo: memo,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isCompactScreen = screenHeight < 720;
    final qrSize = isCompactScreen ? 175.0 : 205.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF16151D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiêu đề
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C27),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryGold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primaryGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'THANH TOÁN VIETQR 24/7',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Liên ngân hàng NAPAS • Tự động xác nhận',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Thân mã QR và thông tin chuyển khoản (cuộn an toàn tuyệt đối)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    // Khung QR Code
                    Container(
                      width: qrSize,
                      height: qrSize,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.network(
                        qrUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 64,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Số tiền cần thanh toán
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Formatters.formatCurrency(amount),
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vé: $bookingId • $roomName',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    // Chi tiết tài khoản nhận (Layout chống tràn 100%)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1C27),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSimpleRow('Ngân hàng thụ hưởng:', 'MB Bank (Quân Đội)'),
                          const Divider(color: Colors.white12, height: 12),
                          _buildCopyRow(
                            context,
                            label: 'Số tài khoản:',
                            value: VietQRHelper.defaultAccountNo,
                          ),
                          const Divider(color: Colors.white12, height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chủ tài khoản: ',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  VietQRHelper.defaultAccountName,
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 12),
                          // Khung sao chép nội dung chuyển khoản
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nội dung chuyển khoản (*):',
                                style: TextStyle(color: Colors.white60, fontSize: 10.5),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        memo,
                                        style: const TextStyle(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 0.4,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: memo));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã sao chép nội dung: "$memo"'),
                                            duration: const Duration(seconds: 1),
                                            backgroundColor: const Color(0xFF1E1C27),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.copy_rounded, size: 11, color: AppColors.primaryGold),
                                            SizedBox(width: 3),
                                            Text(
                                              'Sao chép',
                                              style: TextStyle(
                                                color: AppColors.primaryGold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Ghi chú an toàn
                    Row(
                      children: const [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Quý khách mở App Ngân hàng bất kỳ để quét mã QR và thanh toán.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Nút Xác nhận dưới chân
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1C27),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Thanh toán sau',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onPaymentConfirmed != null) {
                          onPaymentConfirmed!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tôi đã chuyển khoản xong',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildSimpleRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép "$value" vào bộ nhớ tạm!'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF1E1C27),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
