import 'package:flutter/material.dart';
import '../models/horse_model.dart';

/// ============================================================================
/// MODULE 4: FLUTTER UI - WIDGET TÁI SỬ DỤNG
/// Huy hiệu vinh danh chiến mã vô địch trên màn hình kết quả hoặc khi kết thúc đua.
/// ============================================================================
class VictoryBadge extends StatelessWidget {
  final Horse winnerHorse;
  final bool isUserWinner;

  const VictoryBadge({
    super.key,
    required this.winnerHorse,
    required this.isUserWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUserWinner
              ? [
                  const Color(0xFF065F46), // Emerald dark
                  const Color(0xFF047857),
                  const Color(0xFF064E3B),
                ]
              : [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // Icon Cúp vàng hoặc Huy chương
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 48,
            ),
          ),
          const SizedBox(height: 12),

          // Lời chúc mừng
          Text(
            isUserWinner ? '🎉 CHÚC MỪNG BẠN THẮNG CƯỢC! 🎉' : 'NGỰA VÔ ĐỊCH CUỘC ĐUA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUserWinner ? const Color(0xFFFBBF24) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // Tên chiến mã vô địch
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: winnerHorse.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${winnerHorse.name} (Số ${winnerHorse.id})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            winnerHorse.nickname,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
