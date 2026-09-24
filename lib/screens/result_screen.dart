import 'package:flutter/material.dart';
import '../models/race_result_model.dart';
import '../services/storage_service.dart';
import '../widgets/victory_badge.dart';

/// ============================================================================
/// MODULE 4: MÀN HÌNH 3 - RESULT SCREEN (KẾT QUẢ CUỘC ĐUA)
/// - Hiển thị tên chiến mã thắng cuộc và vinh danh.
/// - Bảng thống kê cược: Đối tượng, Tiền cược, Kết quả (Win / Lose), Biến động xu.
/// - Hiển thị Tổng tiền sau cuộc đua (Total Money updated).
/// - Nút Play Again & Back to Home để quay về màn hình chính với số dư mới.
/// ============================================================================
class ResultScreen extends StatefulWidget {
  final RaceResult raceResult;

  const ResultScreen({
    super.key,
    required this.raceResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int _finalBalance;

  @override
  void initState() {
    super.initState();
    _finalBalance = widget.raceResult.updatedBalance;
    // Tự động lưu số dư mới vào SharedPreferences / Local storage
    _saveBalance();
  }

  Future<void> _saveBalance() async {
    await StorageService.saveBalance(_finalBalance);
  }

  /// Trợ cấp 100 xu nếu người chơi cháy túi
  Future<void> _claimRelief() async {
    final newBalance = _finalBalance + 100;
    await StorageService.saveBalance(newBalance);
    setState(() {
      _finalBalance = newBalance;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Đã cấp 100 xu cứu trợ thành công!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.raceResult;
    final winner = result.winnerHorse;
    final isPlayerWin = result.hasWonAnyBet;
    final net = result.netProfit;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _finalBalance);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        appBar: AppBar(
          title: const Text(
            'KẾT QUẢ CUỘC ĐUA',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          automaticallyImplyLeading: false, // Ngăn bấm back mặc định để điều hướng chuẩn
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // 1. Huy hiệu vinh danh người chiến thắng
                      VictoryBadge(
                        winnerHorse: winner,
                        isUserWinner: isPlayerWin,
                      ),

                      // 2. Card Tổng kết biến động số dư
                      _buildBalanceSummaryCard(result, net),

                      const SizedBox(height: 12),

                      // 3. Tiêu đề Bảng Thống kê Cược
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'BẢNG THỐNG KÊ CHI TIẾT CƯỢC',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),

                      // 4. Bảng danh sách các ngựa & kết quả cược
                      _buildBetsTable(result),

                      // Cứu trợ nếu tài khoản còn 0 xu
                      if (_finalBalance <= 0)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sentiment_very_dissatisfied, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Bạn đã hết sạch xu! Đừng lo, nhận ngay 100 xu để tiếp tục.',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _claimRelief,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Nhận +100'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Thanh nút bấm điều hướng (Play Again / Back to Home)
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Card tóm tắt tổng tiền trước/sau cuộc đua
  Widget _buildBalanceSummaryCard(RaceResult result, int net) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniCol('Số dư ban đầu', '${result.startingBalance} xu', Colors.white70),
              _buildMiniCol('Tổng cược', '-${result.totalBetAmount} xu', const Color(0xFFEF4444)),
              _buildMiniCol('Tiền thưởng', '+${result.totalPayout} xu', const Color(0xFF4ADE80)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG TIỀN HIỆN TẠI',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_finalBalance xu',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (net >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: net >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
                child: Text(
                  net >= 0 ? 'LỜI: +$net XU' : 'LỖ: $net XU',
                  style: TextStyle(
                    color: net >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCol(String title, String val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Bảng thống kê cược từng đối tượng đua
  Widget _buildBetsTable(RaceResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          // Tiêu đề cột
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ĐỐI TƯỢNG', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TIỀN CƯỢC', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('KẾT QUẢ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('NHẬN VỀ', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Từng hàng ngựa đua
          for (var horse in result.allHorses) ...[
            _buildBetRow(result, horse),
            if (horse.id != result.allHorses.last.id)
              const Divider(color: Color(0xFF334155), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildBetRow(RaceResult result, dynamic horse) {
    final bet = result.getBetForHorse(horse.id);
    final isWinner = horse.id == result.winnerHorse.id;
    final isBetPlaced = bet.amount > 0;
    final payout = isWinner && isBetPlaced ? (bet.amount * horse.oddsMultiplier).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Cột 1: Tên & số hiệu ngựa
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: horse.primaryColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horse.name,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Số ${horse.id}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Tiền đặt cược
          Expanded(
            flex: 2,
            child: Text(
              isBetPlaced ? '${bet.amount} xu' : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isBetPlaced ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isBetPlaced ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Cột 3: Kết quả (Win / Lose)
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isWinner
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWinner ? 'WIN 🏆' : 'LOSE ❌',
                  style: TextStyle(
                    color: isWinner ? const Color(0xFFFFD700) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Cột 4: Tiền nhận về
          Expanded(
            flex: 2,
            child: Text(
              payout > 0 ? '+$payout xu' : (isBetPlaced ? '0 xu' : '-'),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: payout > 0 ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: payout > 0 ? FontWeight.w900 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2 Nút bấm: "Chơi lại" (Play Again) và "Về trang chủ" (Back to Home)
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          // Nút Về Trang Chủ (Back to Home)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, _finalBalance);
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Về Trang Chủ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nút Chơi Tiếp (Play Again)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, _finalBalance);
              },
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text('Chơi Tiếp 🏇', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
