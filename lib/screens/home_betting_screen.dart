import 'package:flutter/material.dart';
import '../models/horse_model.dart';
import '../models/bet_model.dart';
import '../services/storage_service.dart';
import '../widgets/balance_header_card.dart';
import '../widgets/horse_bet_tile.dart';
import 'race_screen.dart';

/// ============================================================================
/// MODULE 4: MÀN HÌNH 1 - HOME / BETTING SCREEN
/// Quản lý trạng thái bằng StatefulWidget & setState:
/// - Hiển thị số tiền hiện có.
/// - 3 dòng cược tương ứng với 3 chiến mã.
/// - Validation logic: Tổng cược > 0 và <= Tổng số tiền.
/// - Điều hướng Navigator.push sang RaceScreen.
/// ============================================================================
class HomeBettingScreen extends StatefulWidget {
  const HomeBettingScreen({super.key});

  @override
  State<HomeBettingScreen> createState() => _HomeBettingScreenState();
}

class _HomeBettingScreenState extends State<HomeBettingScreen> {
  // Trạng thái (State) của màn hình
  int _totalBalance = 100;
  bool _isLoading = true;

  // Danh sách 3 chiến mã
  late List<Horse> _horses;

  // Map lưu số tiền cược theo horseId
  final Map<int, int> _betsMap = {};

  @override
  void initState() {
    super.initState();
    _horses = Horse.defaultHorses;
    // Khởi tạo tiền cược ban đầu = 0 cho cả 3 ngựa
    for (var horse in _horses) {
      _betsMap[horse.id] = 0;
    }
    _loadBalance();
  }

  /// Đọc số dư từ StorageService
  Future<void> _loadBalance() async {
    final balance = await StorageService.getBalance();
    setState(() {
      _totalBalance = balance;
      _isLoading = false;
    });
  }

  /// Tính tổng số tiền đã đặt cược trên cả 3 ngựa
  int get _totalBetAmount {
    return _betsMap.values.fold<int>(0, (sum, val) => sum + val);
  }

  /// Số tiền khả dụng còn lại để cược
  int get _remainingBalance => _totalBalance - _totalBetAmount;

  /// Điều kiện hợp lệ để bắt đầu cuộc đua:
  /// 1. Phải có ít nhất 1 cửa được đặt cược (> 0)
  /// 2. Tổng cược không vượt quá số dư hiện có
  bool get _canStartRace => _totalBetAmount > 0 && _totalBetAmount <= _totalBalance;

  /// Cập nhật số tiền cược cho 1 ngựa cụ thể
  void _updateBet(int horseId, int newAmount) {
    setState(() {
      _betsMap[horseId] = newAmount;
    });
  }

  /// Reset toàn bộ cược về 0
  void _clearAllBets() {
    setState(() {
      for (var horse in _horses) {
        _betsMap[horse.id] = 0;
      }
    });
  }

  /// Đặt lại số dư về mặc định 100 xu
  Future<void> _resetBalance() async {
    final resetVal = await StorageService.resetBalance();
    setState(() {
      _totalBalance = resetVal;
      _clearAllBets();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã khôi phục số dư về 100 xu!'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Nhận cứu trợ 100 xu khi tài khoản về 0
  Future<void> _addFreeChips() async {
    final newBalance = _totalBalance + 100;
    await StorageService.saveBalance(newBalance);
    setState(() {
      _totalBalance = newBalance;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Bạn đã nhận gói cứu trợ 100 xu khởi nghiệp!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Bắt đầu cuộc đua - Kiểm tra logic & Điều hướng sang RaceScreen
  Future<void> _handleStartRace() async {
    if (_totalBetAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng đặt cược ít nhất một chiến mã trước khi bắt đầu!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    if (_totalBetAmount > _totalBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Tổng tiền cược ($_totalBetAmount xu) vượt quá số dư hiện có ($_totalBalance xu)!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    // Chuyển đổi _betsMap sang List<Bet>
    final activeBets = _horses.map((horse) {
      return Bet(
        horseId: horse.id,
        amount: _betsMap[horse.id] ?? 0,
      );
    }).toList();

    // Điều hướng sang RaceScreen và chờ nhận lại số dư mới sau khi đua xong
    final updatedBalance = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => RaceScreen(
          horses: _horses,
          bets: activeBets,
          initialBalance: _totalBalance,
        ),
      ),
    );

    // Cập nhật lại số dư mới sau khi màn hình ResultScreen pop về
    if (updatedBalance != null) {
      setState(() {
        _totalBalance = updatedBalance;
        _clearAllBets(); // Reset các ô cược cho vòng đua tiếp theo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏇 ', style: TextStyle(fontSize: 22)),
            Text(
              'ĐẤU TRƯỜNG ĐUA NGỰA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Luật chơi & Tỷ lệ',
            onPressed: _showRulesDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Thẻ hiển thị số dư tài khoản
            BalanceHeaderCard(
              totalBalance: _totalBalance,
              totalBetAmount: _totalBetAmount,
              onResetMoney: _resetBalance,
              onAddFreeChips: _totalBalance <= 0 ? _addFreeChips : null,
            ),

            // Tiêu đề phần đặt cược & nút xóa nhanh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CHỌN CHIẾN MÃ ĐẶT CƯỢC',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (_totalBetAmount > 0)
                    TextButton.icon(
                      onPressed: _clearAllBets,
                      icon: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Xóa tất cả cược',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),

            // 2. Danh sách 3 chiến mã đặt cược (Expanded ListView)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _horses.length,
                itemBuilder: (context, index) {
                  final horse = _horses[index];
                  return HorseBetTile(
                    horse: horse,
                    currentBet: _betsMap[horse.id] ?? 0,
                    maxAvailable: _remainingBalance,
                    onBetChanged: (newAmount) => _updateBet(horse.id, newAmount),
                  );
                },
              ),
            ),

            // 3. Thông báo lỗi hoặc cảnh báo cược
            if (_totalBetAmount > _totalBalance)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tổng cược ($_totalBetAmount xu) vượt quá số dư ($_totalBalance xu). Hãy giảm tiền cược!',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Thanh nút bấm "Bắt đầu cuộc đua" cố định bên dưới
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  // Tóm tắt cược vắn tắt
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TỔNG TIỀN CƯỢC',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$_totalBetAmount xu',
                          style: TextStyle(
                            color: _totalBetAmount > _totalBalance
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFFBBF24),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút START RACE
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _canStartRace ? _handleStartRace : null,
                      icon: const Icon(Icons.sports_score_rounded, size: 22),
                      label: const Text(
                        'BẮT ĐẦU ĐUA 🏁',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A), // Turf green
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF334155),
                        disabledForegroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: _canStartRace ? 6 : 0,
                        shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
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

  /// Hộp thoại hướng dẫn luật chơi & tỷ lệ
  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFFFBBF24)),
            SizedBox(width: 8),
            Text('Luật Chơi & Thưởng', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Cuộc đua gồm 3 chiến mã chạy song song với tốc độ ngẫu nhiên.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '2. Bạn có thể cược cho 1, 2 hoặc cả 3 ngựa, miễn là tổng cược ≤ số tiền hiện có.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '3. Tỷ lệ thưởng: Nếu ngựa bạn chọn về nhất, bạn nhận lại Tiền cược x 2.0 (lời 100%). Nếu thua, mất tiền đã cược.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '4. Nếu không may cháy túi (0 xu), hãy bấm "Cứu trợ +100 xu" để tiếp tục trải nghiệm!',
              style: TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
