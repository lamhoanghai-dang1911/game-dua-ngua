import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/horse_model.dart';
import '../models/bet_model.dart';
import '../models/race_result_model.dart';
import '../widgets/race_track_lane.dart';
import 'result_screen.dart';

/// ============================================================================
/// MODULE 4: MÀN HÌNH 2 - RACE SCREEN (MÔ PHỎNG ĐƯỜNG ĐUA)
/// - Tuân thủ tuyệt đối: KHÔNG sử dụng Slider mặc định.
/// - Áp dụng "slider giả": Container track + AnimatedPositioned racer + setState.
/// - Áp dụng Dart Async & Control Flow: Timer.periodic, Random, if/else.
/// - Đảm bảo dọn dẹp tài nguyên với dispose() để tránh rò rỉ bộ nhớ.
/// ============================================================================
class RaceScreen extends StatefulWidget {
  final List<Horse> horses;
  final List<Bet> bets;
  final int initialBalance;

  const RaceScreen({
    super.key,
    required this.horses,
    required this.bets,
    required this.initialBalance,
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  // Trạng thái tiến độ đua của từng ngựa (0.0 -> 1.0)
  late Map<int, double> _progressMap;

  // Trạng thái cuộc đua
  bool _isRacing = false;
  bool _isFinished = false;
  Horse? _winnerHorse;

  // Timer điều khiển vòng lặp mô phỏng
  Timer? _raceTimer;
  final Random _random = Random();
  int _stepTick = 0;

  // Trạng thái đếm ngược xuất phát (3, 2, 1, RUN!)
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _resetTrack();
  }

  /// Khởi tạo lại vị trí xuất phát cho cả 3 ngựa
  void _resetTrack() {
    _progressMap = {for (var horse in widget.horses) horse.id: 0.0};
    _isRacing = false;
    _isFinished = false;
    _winnerHorse = null;
    _stepTick = 0;
  }

  @override
  void dispose() {
    // HỦY TIMER BẮT BUỘC ĐỂ TRÁNH RÒ RỈ BỘ NHỚ
    _raceTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Bắt đầu đếm ngược rồi xuất phát
  void _startCountdown() {
    if (_isRacing || _isFinished) return;

    setState(() {
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
        _launchRace();
      }
    });
  }

  /// Kích hoạt Timer chạy đua cho các chiến mã
  void _launchRace() {
    setState(() {
      _isRacing = true;
    });

    // Mỗi chu kỳ tick 70ms, các ngựa sẽ di chuyển một bước ngẫu nhiên
    _raceTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) return;

      setState(() {
        _stepTick++;
        Horse? localWinner;

        for (var horse in widget.horses) {
          final currentProgress = _progressMap[horse.id] ?? 0.0;

          // Bước chạy ngẫu nhiên từ 0.006 đến 0.026
          double step = 0.006 + _random.nextDouble() * 0.020;

          // Hiệu ứng bứt tốc ngẫu nhiên (10% cơ hội tăng tốc mạnh mẽ)
          if (_random.nextDouble() < 0.10) {
            step += 0.015;
          }

          final newProgress = currentProgress + step;

          if (newProgress >= 1.0) {
            _progressMap[horse.id] = 1.0;
            // Xác định ngựa chạm đích ĐẦU TIÊN
            localWinner ??= horse;
          } else {
            _progressMap[horse.id] = newProgress;
          }
        }

        // Nếu đã có ngựa cán đích
        // Thay thế đoạn điều hướng Navigator.push cũ bằng cách gọi hàm Popup tại chỗ:
        if (localWinner != null && !_isFinished) {
          _isFinished = true;
          _isRacing = false;
          _winnerHorse = localWinner;
          _raceTimer?.cancel();

          // Chờ 1.2 giây để người chơi nhìn rõ khoảnh khắc cán đích rồi show Popup lên đè màn hình
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              // 1. Tính toán logic tiền thưởng nhận được
              final betOnWinner = _getBetForHorse(_winnerHorse!.id);
              final totalBet = widget.bets.fold<int>(
                0,
                (sum, b) => sum + b.amount,
              );
              final payout = betOnWinner * 2; // Ví dụ tỷ lệ x2
              final netProfit = payout - totalBet;
              final finalBalance = widget.initialBalance + netProfit;

              // 2. Gọi hàm popup UI
              _showVictoryPopup(
                context: context,
                winnerHorse: _winnerHorse,
                isUserWinner: payout > 0,
                netProfit: netProfit,
                finalBalance: finalBalance,
                onPlayAgain: () {
                  // Trả lại số tiền mới và quay về màn hình đặt cược chính
                  Navigator.pop(context, finalBalance);
                },
              );
            }
          });
        }
      });
    });
  }

  /// Lấy số tiền người chơi đã cược cho con ngựa cụ thể
  int _getBetForHorse(int horseId) {
    final bet = widget.bets.firstWhere(
      (b) => b.horseId == horseId,
      orElse: () => Bet(horseId: horseId, amount: 0),
    );
    return bet.amount;
  }

  /// Điều hướng sang Màn hình kết quả
  Future<void> _navigateToResultScreen() async {
    if (_winnerHorse == null) return;

    final result = RaceResult(
      winnerHorse: _winnerHorse!,
      allHorses: widget.horses,
      bets: widget.bets,
      startingBalance: widget.initialBalance,
    );

    // Chuyển sang ResultScreen
    final updatedBalance = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(raceResult: result)),
    );

    // Khi người chơi chọn "Chơi tiếp" hoặc "Về trang chủ", pop trả số dư mới về HomeBettingScreen
    if (mounted && updatedBalance != null) {
      Navigator.pop(context, updatedBalance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text(
          'ĐƯỜNG ĐUA TRỰC TIẾP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isRacing
              ? () {
                  _showExitConfirmDialog();
                }
              : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Khung trạng thái & Bảng tin cuộc đua
            _buildStatusHeader(),

            const SizedBox(height: 8),

            // 2. Khu vực 3 Làn đua "Slider giả" (Yêu cầu bắt buộc)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Mô phỏng 3 làn đua song song
                    for (var horse in widget.horses)
                      RaceTrackLane(
                        horse: horse,
                        betAmount: _getBetForHorse(horse.id),
                        progress: _progressMap[horse.id] ?? 0.0,
                        isWinner: _winnerHorse?.id == horse.id,
                        isRacing: _isRacing,
                        stepTick: _stepTick,
                      ),

                    const SizedBox(height: 16),

                    // Chú thích vạch xuất phát & vạch đích
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vạch xuất phát',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'Vạch đích 🏁',
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Thanh điều khiển bên dưới
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  /// Khung hiển thị trạng thái trận đua
  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tình trạng cuộc đua
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRacing
                      ? const Color(0xFF22C55E)
                      : (_isFinished
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isFinished
                    ? '🏆 CUỘC ĐUA KẾT THÚC!'
                    : (_isRacing
                          ? '🔥 ĐANG SO KÈ QUYẾT LIỆT!'
                          : (_countdown > 0
                                ? 'CHUẨN BỊ XUẤT PHÁT: $_countdown'
                                : 'SẴN SÀNG XUẤT PHÁT')),
                style: TextStyle(
                  color: _isFinished
                      ? const Color(0xFFFBBF24)
                      : (_isRacing ? const Color(0xFF4ADE80) : Colors.white),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Tổng tiền đang cược trong vòng này
          Row(
            children: [
              const Icon(
                Icons.monetization_on,
                color: Color(0xFFFBBF24),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Cược: ${widget.bets.fold<int>(0, (s, b) => s + b.amount)} xu',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Nút bấm điều khiển: Xuất phát, Xem kết quả
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isRacing && !_isFinished)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _countdown == 0 ? _startCountdown : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  _countdown > 0
                      ? 'XUẤT PHÁT TRONG $_countdown GIÂY...'
                      : 'PHÁT LỆNH XUẤT PHÁT! 🚀',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
              ),
            )
          else if (_isRacing)
            Container(
              height: 52,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'CÁC CHIẾN MÃ ĐANG LAO VỀ ĐÍCH...',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _navigateToResultScreen,
                icon: const Icon(Icons.assessment_rounded, size: 24),
                label: const Text(
                  'XEM BẢNG KẾT QUẢ & TIỀN THƯỞNG 🏆',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Hộp thoại xác nhận nếu muốn thoát khi đang đua dở
  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Hủy cuộc đua?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cuộc đua đang diễn ra. Nếu rời khỏi màn hình bây giờ, kết quả vòng này sẽ bị hủy bỏ.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Ở lại',
              style: TextStyle(color: Color(0xFF38BDF8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Rời đi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVictoryPopup({
    required BuildContext context,
    required dynamic winnerHorse,
    required bool isUserWinner,
    required int netProfit,
    required int finalBalance,
    required VoidCallback onPlayAgain,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc chọn nút bấm mới đóng được popup
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isUserWinner
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF475569),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Kích thước ôm sát nội dung kiểu popup
              children: [
                // 1. Icon Cúp vàng vinh danh
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUserWinner
                        ? const Color(0xFFFFD700).withAlpha(30)
                        : const Color(0xFF64748B).withAlpha(30),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: isUserWinner
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF94A3B8),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Trạng thái Thắng / Thua
                Text(
                  isUserWinner
                      ? '🎉 CHIẾN THẮNG RỰC RỠ! 🎉'
                      : 'KẾT QUẢ VÒNG ĐUA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isUserWinner
                        ? const Color(0xFFFBBF24)
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Thông tin chiến mã về nhất
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: winnerHorse.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${winnerHorse.name} về Nhất',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Biến động số dư xu của người chơi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Biến động',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUserWinner ? '+$netProfit xu' : '$netProfit xu',
                          style: TextStyle(
                            color: isUserWinner
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFF334155),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Số dư mới',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$finalBalance xu',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Nút bấm tương tác
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx); // Đóng popup kết quả trước
                      onPlayAgain(); // Kích hoạt callback để tiếp tục hoặc thoát về trang cược
                    },
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                    label: const Text(
                      'TIẾP TỤC TRẢI NGHIỆM 🏇',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
