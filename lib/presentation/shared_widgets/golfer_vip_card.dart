import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/golfer_model.dart';
import '../../shared/providers/booking_provider.dart';

/// Thẻ Hội Viên Golfer Sang Trọng (Golfer VIP Loyalty Card)
class GolferVipCard extends StatelessWidget {
  final GolferModel golfer;
  final VoidCallback? onEditProfile;

  const GolferVipCard({
    super.key,
    required this.golfer,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final tier = golfer.tier;
    final gradient = tier.gradientColors;

    // Tính mốc thăng hạng tiếp theo
    double nextTierTarget = 5000000;
    String nextTierName = 'Silver VIP';
    if (golfer.totalSpend >= 35000000) {
      nextTierTarget = 35000000;
      nextTierName = 'Tối Đa (Diamond)';
    } else if (golfer.totalSpend >= 15000000) {
      nextTierTarget = 35000000;
      nextTierName = 'Diamond Elite';
    } else if (golfer.totalSpend >= 5000000) {
      nextTierTarget = 15000000;
      nextTierName = 'Gold VIP';
    }

    final progress = nextTierTarget > 0
        ? (golfer.totalSpend / nextTierTarget).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Logo Okamura & Badge Hạng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFE2C99D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'OKAMURA GOLFZON',
                            style: TextStyle(
                              color: Color(0xFFE2C99D),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'DIAMOND CLUB MEMBERSHIP',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tier.color.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 13, color: tier.color),
                    const SizedBox(width: 4),
                    Text(
                      tier.label,
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dòng 2: Tên Golfer & Handicap
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      golfer.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SĐT: ${golfer.phone}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HCP: ${golfer.handicap.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFE2C99D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dòng 3: Điểm tích lũy & Ưu đãi chiết khấu
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Điểm thưởng', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    Text(
                      '${golfer.loyaltyPoints} PTS',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Ưu đãi giờ chơi', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    Text(
                      tier.discountPercent > 0 ? 'Giảm ${(tier.discountPercent * 100).toInt()}%' : 'Tiêu chuẩn',
                      style: TextStyle(
                        color: tier.discountPercent > 0 ? const Color(0xFF10B981) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onEditProfile != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onEditProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_outlined, size: 12, color: Colors.white70),
                        SizedBox(width: 4),
                        Text('Cập nhật', style: TextStyle(color: Colors.white, fontSize: 10.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Thanh tiến trình lên hạng
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Tích lũy: ${Formatters.formatCurrency(golfer.totalSpend)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Lên $nextTierName: ${Formatters.formatCurrency(nextTierTarget)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE2C99D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dialog chỉnh sửa hồ sơ Golfer / Hội viên
  static void showEditGolferDialog(BuildContext context, BookingProvider provider) {
    final current = provider.currentGolfer;
    final nameCtrl = TextEditingController(text: current.name);
    final phoneCtrl = TextEditingController(text: current.phone);
    final emailCtrl = TextEditingController(text: current.email ?? '');
    final hcpCtrl = TextEditingController(text: current.handicap.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16151D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: const [
            Icon(Icons.badge_outlined, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text(
              'Hồ Sơ Định Danh Hội Viên',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Họ và tên Golfer:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF232028),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Số điện thoại đăng ký:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF232028),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Handicap chính thức (HCP):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: hcpCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF232028),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Email nhận hóa đơn:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF232028),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              if (newName.isEmpty || newPhone.isEmpty) return;

              final parsedHcp = double.tryParse(hcpCtrl.text.trim()) ?? current.handicap;
              final updated = current.copyWith(
                name: newName,
                phone: newPhone,
                handicap: parsedHcp,
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
              );

              await provider.updateGolferProfile(updated);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật hồ sơ hội viên thành công!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
