import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_bottom_sheet.dart';

/// Nút nổi (Floating Action Button) kích hoạt Trợ lý ảo AI Caddie
/// Thiết kế Quiet Luxury chuẩn mực:
/// - Mặc định thu gọn thành Tab bo viền sang trọng bám sát mép phải màn hình (Edge-docked)
/// - Giới hạn an toàn tuyệt đối: Không bao giờ bị kéo lọt ra sau hoặc rớt xuống thanh bottom bar
/// - Hỗ trợ kéo thả tức thì (Zero-latency raw pointer tracking) để tùy chỉnh độ cao theo tầm tay
/// - Tự động hít (magnetic snap) về mép phải khi buông tay
class AiFloatingButton extends StatefulWidget {
  final double bottomBarHeight;
  final double initialBottomOffset;

  const AiFloatingButton({
    super.key,
    this.bottomBarHeight = 70.0,
    this.initialBottomOffset = 18.0,
  });

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton> {
  // Trạng thái vị trí
  double? _x;
  double? _y;
  bool _isDocked = true;
  bool _isDragging = false;

  // Tracking pointer cho gesture tức thì 120Hz
  Offset? _pointerDownPosition;
  Offset? _initialButtonPosition;
  DateTime? _pointerDownTime;

  static const double _dockedWidth = 34.0;
  static const double _dockedHeight = 48.0;
  static const double _expandedSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    // Xác định chiều rộng khả dụng (hỗ trợ responsive cả màn hình rộng 600dp và mobile)
    final isWide = screenSize.width > 600;
    final leftEdge = isWide ? (screenSize.width - 600) / 2 : 0.0;
    final rightEdge = isWide ? (screenSize.width + 600) / 2 : screenSize.width;

    // Chiều cao khả dụng trong Scaffold.body:
    // Tuyệt đối không tính thanh bottom navigation bar và safe padding đáy
    final totalBottomHeight = widget.bottomBarHeight + safePadding.bottom;
    final availableHeight = screenSize.height - totalBottomHeight;

    // Kích thước nút theo trạng thái
    final currentWidth = _isDocked && !_isDragging ? _dockedWidth : _expandedSize;
    final currentHeight = _isDocked && !_isDragging ? _dockedHeight : _expandedSize;

    // Giới hạn an toàn không bị trôi ra khỏi màn hình hoặc chui ra sau thanh bottom bar
    final minX = leftEdge + 4.0;
    final maxX = rightEdge - currentWidth;
    final minY = safePadding.top + 8.0;
    final maxY = (availableHeight - currentHeight - 8.0).clamp(minY, availableHeight);

    // Vị trí mặc định ban đầu: Thu gọn bám sát mép phải, ngay sát trên thanh bottom bar
    final defaultX = rightEdge - _dockedWidth;
    final defaultY = (availableHeight - _dockedHeight - widget.initialBottomOffset).clamp(minY, maxY);

    final safeX = (_x ?? defaultX).clamp(minX, maxX);
    final safeY = (_y ?? defaultY).clamp(minY, maxY);

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: safeX,
      top: safeY,
      width: currentWidth,
      height: currentHeight,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _pointerDownPosition = event.position;
          _initialButtonPosition = Offset(safeX, safeY);
          _pointerDownTime = DateTime.now();
          _isDragging = false;
        },
        onPointerMove: (event) {
          if (_pointerDownPosition == null || _initialButtonPosition == null) return;
          final delta = event.position - _pointerDownPosition!;

          // Khi di chuyển vượt ngưỡng nhẹ 3px, lập tức chuyển sang chế độ kéo mở rộng
          if (!_isDragging && delta.distance > 3.0) {
            _isDragging = true;
            _isDocked = false;
          }

          if (_isDragging) {
            final nextX = (_initialButtonPosition!.dx + delta.dx).clamp(minX, maxX);
            final nextY = (_initialButtonPosition!.dy + delta.dy).clamp(minY, maxY);
            setState(() {
              _x = nextX;
              _y = nextY;
            });
          }
        },
        onPointerUp: (event) {
          if (_pointerDownPosition == null) return;
          final distance = (event.position - _pointerDownPosition!).distance;
          final durationMs = _pointerDownTime != null
              ? DateTime.now().difference(_pointerDownTime!).inMilliseconds
              : 999;
          final wasDragging = _isDragging;

          if (!wasDragging && distance < 6.0 && durationMs < 450) {
            // Chạm click nhanh -> Mở ngay AI Caddie Chatbot
            setState(() {
              _isDragging = false;
              _isDocked = true;
            });
            AiChatBottomSheet.show(context);
          } else {
            // Vừa kéo xong -> Tự động hít nhẹ nhàng về mép phải và thu gọn lại thành Tab bám viền
            setState(() {
              _isDragging = false;
              _isDocked = true;
              _x = rightEdge - _dockedWidth;
              // Giữ nguyên độ cao Y người dùng vừa chọn, đảm bảo an toàn tuyệt đối
              _y = safeY.clamp(minY, (availableHeight - _dockedHeight - 8.0).clamp(minY, availableHeight));
            });
          }

          _pointerDownPosition = null;
          _initialButtonPosition = null;
        },
        onPointerCancel: (_) {
          setState(() {
            _isDragging = false;
            _isDocked = true;
            _x = rightEdge - _dockedWidth;
          });
          _pointerDownPosition = null;
          _initialButtonPosition = null;
        },
        child: Tooltip(
          message: 'AI Caddie - Chạm để trò chuyện, kéo để đổi độ cao',
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: currentWidth,
              height: currentHeight,
              decoration: BoxDecoration(
                borderRadius: _isDocked && !_isDragging
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      )
                    : BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF242A38),
                    Color(0xFF111723),
                    Color(0xFF090D15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: _isDocked && !_isDragging
                    ? const Border(
                        left: BorderSide(color: AppColors.primaryGold, width: 1.8),
                        top: BorderSide(color: AppColors.primaryGold, width: 1.8),
                        bottom: BorderSide(color: AppColors.primaryGold, width: 1.8),
                      )
                    : Border.all(
                        color: _isDragging ? const Color(0xFFFFDF7A) : AppColors.primaryGold,
                        width: _isDragging ? 2.2 : 1.8,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(
                      alpha: _isDragging ? 0.65 : (_isDocked ? 0.35 : 0.4),
                    ),
                    blurRadius: _isDragging ? 20 : 12,
                    offset: _isDocked && !_isDragging ? const Offset(-2, 2) : Offset(0, _isDragging ? 6 : 4),
                    spreadRadius: _isDragging ? 2 : 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: _isDocked && !_isDragging ? const Offset(-2, 0) : const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng hào quang vàng nhẹ khi mở rộng tròn
                  if (!_isDocked || _isDragging)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryGold.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                  // Mũi tên nhỏ bên trái khi ở dạng Tab thu gọn để báo hiệu kéo / chạm
                  if (_isDocked && !_isDragging)
                    Positioned(
                      left: 2,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.primaryGold.withValues(alpha: 0.7),
                        size: 13,
                      ),
                    ),

                  // Biểu tượng chữ "C" đại diện cho Caddie / Concierge
                  Padding(
                    padding: EdgeInsets.only(left: (_isDocked && !_isDragging) ? 6.0 : 0.0),
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: (_isDocked && !_isDragging) ? 17 : 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'serif',
                        letterSpacing: -0.5,
                        shadows: const [
                          Shadow(
                            color: Color(0xFFD4AF37),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ngôi sao lấp lánh AI ở góc trên bên phải
                  Positioned(
                    top: (_isDocked && !_isDragging) ? 6 : 8,
                    right: (_isDocked && !_isDragging) ? 4 : 8,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF090D15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: const Color(0xFFFFDF7A),
                        size: (_isDocked && !_isDragging) ? 8.5 : 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
