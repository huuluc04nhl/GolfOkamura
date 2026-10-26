import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_bottom_sheet.dart';

/// Nút nổi (Floating Action Button) hình tròn biểu tượng chữ "C" kích hoạt Trợ lý ảo AI Caddie
/// Hỗ trợ KÉO THẢ TỰ DO (Draggable) đến mọi vị trí trên màn hình, không che khuất nội dung
class AiFloatingButton extends StatefulWidget {
  final double bottomOffset;
  final double rightOffset;

  const AiFloatingButton({
    super.key,
    this.bottomOffset = 14,
    this.rightOffset = 16,
  });

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton> {
  Offset? _position;
  Offset? _pointerDownPosition;
  Offset? _initialButtonPosition;
  DateTime? _pointerDownTime;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    // Vị trí mặc định ở góc dưới bên phải (ngay sát trên thanh bottom bar)
    final defaultX = screenSize.width - 50 - widget.rightOffset;
    final defaultY = screenSize.height - 70 - safePadding.bottom - 50 - widget.bottomOffset;

    // Giới hạn vùng an toàn không bị trôi ra ngoài màn hình
    final minX = 8.0;
    final maxX = (screenSize.width - 50 - 8.0).clamp(minX, screenSize.width);
    final minY = safePadding.top + 8.0;
    final maxY = (screenSize.height - safePadding.bottom - 50 - 8.0).clamp(minY, screenSize.height);

    final currentPos = _position ?? Offset(defaultX, defaultY);
    final safeX = currentPos.dx.clamp(minX, maxX);
    final safeY = currentPos.dy.clamp(minY, maxY);

    return Positioned(
      left: safeX,
      top: safeY,
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
          if (!_isDragging && delta.distance > 3.0) {
            _isDragging = true;
          }
          if (_isDragging) {
            final nextX = (_initialButtonPosition!.dx + delta.dx).clamp(minX, maxX);
            final nextY = (_initialButtonPosition!.dy + delta.dy).clamp(minY, maxY);
            setState(() {
              _position = Offset(nextX, nextY);
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

          setState(() {
            _isDragging = false;
          });

          // Nếu chỉ chạm nhanh (không kéo), lập tức mở chatbox
          if (!wasDragging && distance < 6.0 && durationMs < 450) {
            AiChatBottomSheet.show(context);
          }
          _pointerDownPosition = null;
          _initialButtonPosition = null;
        },
        onPointerCancel: (_) {
          setState(() {
            _isDragging = false;
          });
          _pointerDownPosition = null;
          _initialButtonPosition = null;
        },
        child: Tooltip(
          message: 'AI Caddie - Chạm để chat, kéo để đổi vị trí',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF242A38),
                    Color(0xFF111723),
                    Color(0xFF090D15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isDragging ? const Color(0xFFFFDF7A) : AppColors.primaryGold,
                  width: _isDragging ? 2.2 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(
                      alpha: _isDragging ? 0.65 : 0.38,
                    ),
                    blurRadius: _isDragging ? 20 : 12,
                    offset: Offset(0, _isDragging ? 6 : 4),
                    spreadRadius: _isDragging ? 2 : 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng hào quang vàng nhẹ bên trong
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

                  // Biểu tượng chữ "C" đại diện cho Caddie / Concierge
                  const Text(
                    'C',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFFD4AF37),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),

                  // Ngôi sao lấp lánh AI ở góc trên bên phải chữ "C"
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF090D15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFDF7A),
                        size: 11,
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
