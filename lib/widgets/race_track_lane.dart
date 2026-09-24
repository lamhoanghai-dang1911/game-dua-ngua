import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/horse_model.dart';

/// ============================================================================
/// MODULE 4: FLUTTER UI - "SLIDER GIẢ" TRÊN ĐƯỜNG ĐUA (YÊU CẦU BẮT BUỘC)
/// - KHÔNG SỬ DỤNG widget Slider mặc định của Flutter.
/// - Đường đua (Track) = Container trang trí nền cỏ/đất, vạch mức, vạch đích.
/// - Đối tượng đua (Racer) = AnimatedPositioned + Widget Icon/Image ngựa đua.
/// - Di chuyển mô phỏng = Cập nhật giá trị progress thông qua setState và AnimatedPositioned.
/// ============================================================================
class RaceTrackLane extends StatelessWidget {
  final Horse horse;
  final int betAmount;
  final double progress; // 0.0 -> 1.0
  final bool isWinner;
  final bool isRacing;
  final int stepTick; // Dùng để tạo hiệu ứng nhún nhảy (galloping bobbing) khi chạy

  const RaceTrackLane({
    super.key,
    required this.horse,
    required this.betAmount,
    required this.progress,
    this.isWinner = false,
    this.isRacing = false,
    this.stepTick = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Kích thước các thành phần trên đường đua
    const double laneHeight = 86.0;
    const double racerWidth = 58.0;
    const double startOffset = 48.0; // Khoảng cách sau vạch số làn
    const double finishLineMargin = 40.0; // Vị trí vạch đích

    return Container(
      height: laneHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A2F), // Xanh thảm cỏ đua ngựa (Turf green)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD700) // Vàng kim nếu thắng
              : horse.primaryColor.withValues(alpha: 0.6),
          width: isWinner ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isWinner
                ? const Color(0xFFFFD700).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: isWinner ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalTrackWidth = constraints.maxWidth;
          // Khoảng cách tối đa ngựa có thể chạy từ vạch xuất phát tới vạch đích
          final maxRunDistance = totalTrackWidth - startOffset - racerWidth - finishLineMargin;
          final clampedProgress = progress.clamp(0.0, 1.0);
          final currentLeft = startOffset + (clampedProgress * maxRunDistance);

          // Hiệu ứng nhún nhảy phi nước đại khi đang chạy
          final double bobbingY = isRacing ? math.sin(stepTick * 0.8 + horse.id) * 3.5 : 0.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Nền đường cỏ & vạch kẻ đường đua đứt khúc
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrackLanePainter(
                    laneNumber: horse.id,
                    primaryColor: horse.primaryColor,
                  ),
                ),
              ),

              // 2. Vạch xuất phát (Start Gate) bên trái
              Positioned(
                left: startOffset - 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),

              // 3. Vạch đích (Checkered Finish Line) bên phải
              Positioned(
                right: finishLineMargin,
                top: 0,
                bottom: 0,
                child: _buildCheckeredFinishLine(),
              ),

              // 4. Bảng số làn đua cố định góc trái
              Positioned(
                left: 6,
                top: 14,
                bottom: 14,
                child: _buildLaneBadge(),
              ),

              // 5. "SLIDER GIẢ" - CON NGỰA DI CHUYỂN BẰNG ANIMATEDPOSITIONED
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutQuad,
                left: currentLeft,
                top: 10 + bobbingY,
                child: _buildRacerWidget(),
              ),

              // 6. Nhãn cược của người chơi gắn ở góc phải phía trên
              if (betAmount > 0)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFBBF24),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFFBBF24),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$betAmount xu',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 7. Huy hiệu Người chiến thắng (nếu đã cán đích)
              if (isWinner)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.black, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'VỀ NHẤT!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Badge số làn đua
  Widget _buildLaneBadge() {
    return Container(
      width: 32,
      decoration: BoxDecoration(
        color: horse.primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'LÀN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${horse.id}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget biểu diễn con ngựa đua đang chạy
  Widget _buildRacerWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ngựa đua với số hiệu và hiệu ứng đổ bóng
        Container(
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [horse.primaryColor, horse.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWinner ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.85),
              width: isWinner ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: horse.primaryColor.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icon ngựa / linh vật
              const Text(
                '🐎',
                style: TextStyle(fontSize: 26),
              ),
              // Số áo ngựa ở góc
              Positioned(
                right: 3,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${horse.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Tên vắn tắt của ngựa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            horse.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Vạch đích kẻ caro trắng đen (Checkered Flag)
  Widget _buildCheckeredFinishLine() {
    return Container(
      width: 16,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Column(
        children: List.generate(6, (index) {
          final isEven = index.isEven;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: isEven ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isEven ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// CustomPainter vẽ các vạch đứt nét trang trí trên đường cỏ
class _TrackLanePainter extends CustomPainter {
  final int laneNumber;
  final Color primaryColor;

  _TrackLanePainter({
    required this.laneNumber,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vẽ đường kẻ giữa làn
    const double dashWidth = 8.0;
    const double dashSpace = 8.0;
    double startX = 50.0;
    final double y = size.height / 2;

    while (startX < size.width - 50) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
