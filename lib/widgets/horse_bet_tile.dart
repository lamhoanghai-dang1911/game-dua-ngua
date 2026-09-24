import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/horse_model.dart';

/// ============================================================================
/// MODULE 4: FLUTTER UI - WIDGET TÁI SỬ DỤNG
/// Card đặt cược cho từng chiến mã (Horse 1, Horse 2, Horse 3).
/// Kết hợp cả:
/// - TextField nhập trực tiếp số tiền.
/// - Các nút bấm tăng giảm (+ / -).
/// - Chip cược nhanh (+5, +10, All-in, Xóa).
/// ============================================================================
class HorseBetTile extends StatefulWidget {
  final Horse horse;
  final int currentBet;
  final int maxAvailable;
  final ValueChanged<int> onBetChanged;

  const HorseBetTile({
    super.key,
    required this.horse,
    required this.currentBet,
    required this.maxAvailable,
    required this.onBetChanged,
  });

  @override
  State<HorseBetTile> createState() => _HorseBetTileState();
}

class _HorseBetTileState extends State<HorseBetTile> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.currentBet == 0 ? '' : widget.currentBet.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant HorseBetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đồng bộ giá trị trong TextField nếu bên ngoài thay đổi
    final currentTextValue = int.tryParse(_textController.text) ?? 0;
    if (widget.currentBet != currentTextValue) {
      _textController.text = widget.currentBet == 0 ? '' : widget.currentBet.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateAmount(int newAmount) {
    final clamped = newAmount < 0 ? 0 : newAmount;
    widget.onBetChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final horse = widget.horse;
    final hasBet = widget.currentBet > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBet ? horse.primaryColor : const Color(0xFF334155),
          width: hasBet ? 2 : 1,
        ),
        boxShadow: hasBet
            ? [
                BoxShadow(
                  color: horse.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Dòng thông tin ngựa: Avatar, Tên, Số hiệu, Tỷ lệ cược
            Row(
              children: [
                // Avatar số hiệu
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [horse.primaryColor, horse.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: horse.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      horse.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tên ngựa & nickname
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            horse.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: horse.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Số ${horse.id}',
                              style: TextStyle(
                                color: horse.secondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        horse.nickname,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tỷ lệ ăn cược (Odds)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TỶ LỆ',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'x${horse.oddsMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bộ điều khiển cược: [-] [ Ô nhập TextField ] [+]
            Row(
              children: [
                // Nút giảm (-)
                IconButton.filledTonal(
                  onPressed: widget.currentBet > 0
                      ? () => _updateAmount(widget.currentBet - 5)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),

                // Ô nhập tiền cược (TextField)
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasBet ? horse.primaryColor : const Color(0xFF334155),
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0 xu',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: 'xu ',
                        suffixStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val) ?? 0;
                        _updateAmount(parsed);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút tăng (+)
                IconButton.filledTonal(
                  onPressed: () => _updateAmount(widget.currentBet + 5),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: horse.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Các nút cược nhanh: +5, +10, +25, Tất tay (All-in), Xóa (Clear)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(
                    label: '+5',
                    onTap: () => _updateAmount(widget.currentBet + 5),
                  ),
                  _buildQuickChip(
                    label: '+10',
                    onTap: () => _updateAmount(widget.currentBet + 10),
                  ),
                  _buildQuickChip(
                    label: '+25',
                    onTap: () => _updateAmount(widget.currentBet + 25),
                  ),
                  _buildQuickChip(
                    label: 'Tất tay',
                    color: const Color(0xFFD97706),
                    onTap: () {
                      final available = widget.maxAvailable + widget.currentBet;
                      if (available > 0) {
                        _updateAmount(available);
                      }
                    },
                  ),
                  if (hasBet)
                    _buildQuickChip(
                      label: 'Xóa cược',
                      color: const Color(0xFFEF4444),
                      onTap: () => _updateAmount(0),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: chipColor.withValues(alpha: 0.6), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color ?? const Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
