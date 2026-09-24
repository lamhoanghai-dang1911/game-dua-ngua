import 'package:flutter/material.dart';

/// ============================================================================
/// MODULE 4: FLUTTER UI - WIDGET TÁI SỬ DỤNG
/// Card hiển thị số dư tài khoản của người chơi và tổng tiền đang đặt cược.
/// Sử dụng Column, Row, Container, DecoratedBox và Typography hiện đại.
/// ============================================================================
class BalanceHeaderCard extends StatelessWidget {
  final int totalBalance;
  final int totalBetAmount;
  final VoidCallback? onResetMoney;
  final VoidCallback? onAddFreeChips;

  const BalanceHeaderCard({
    super.key,
    required this.totalBalance,
    required this.totalBetAmount,
    this.onResetMoney,
    this.onAddFreeChips,
  });

  int get remainingBalance => totalBalance - totalBetAmount;

  @override
  Widget build(BuildContext context) {
    final isNegative = remainingBalance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B), // Dark slate
            Color(0xFF0F172A), // Deep navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4), // Golden border
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tiêu đề & Icon VIP Derby
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFD4AF37),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VÍ NGƯỜI CHƠI',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Derby Club VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action buttons (Reset hoặc nhận xu cứu trợ nếu hết tiền)
              Row(
                children: [
                  if (totalBalance <= 0 && onAddFreeChips != null)
                    ElevatedButton.icon(
                      onPressed: onAddFreeChips,
                      icon: const Icon(Icons.add_circle, size: 16, color: Colors.white),
                      label: const Text(
                        'Cứu trợ +100',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (onResetMoney != null)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 20),
                      tooltip: 'Khôi phục 100 xu',
                      onPressed: onResetMoney,
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 14),

          // Hiển thị số liệu: Tổng số tiền | Đang cược | Khả dụng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tổng tiền hiện có
              _buildStatItem(
                label: 'TỔNG TIỀN (TOTAL)',
                value: '$totalBalance xu',
                valueColor: const Color(0xFFFBBF24), // Amber gold
                icon: Icons.monetization_on_rounded,
              ),

              Container(
                height: 36,
                width: 1,
                color: const Color(0xFF334155),
              ),

              // Tổng tiền đang cược
              _buildStatItem(
                label: 'ĐÃ CƯỢC',
                value: '$totalBetAmount xu',
                valueColor: totalBetAmount > 0 ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                icon: Icons.casino_rounded,
              ),

              Container(
                height: 36,
                width: 1,
                color: const Color(0xFF334155),
              ),

              // Tiền khả dụng
              _buildStatItem(
                label: 'CÒN LẠI',
                value: '$remainingBalance xu',
                valueColor: isNegative ? const Color(0xFFEF4444) : const Color(0xFF4ADE80),
                icon: isNegative ? Icons.warning_rounded : Icons.check_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: valueColor, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
