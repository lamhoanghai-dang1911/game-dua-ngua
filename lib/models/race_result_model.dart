import 'horse_model.dart';
import 'bet_model.dart';

/// ============================================================================
/// MODULE 2 & 3: DART ESSENTIALS & ADVANCED OOP
/// Lớp RaceResult tổng hợp kết quả của cuộc đua:
/// - Áp dụng các phương thức xử lý Collection trong Dart: `fold`, `firstWhere`, `map`.
/// - Tính toán tiền thưởng/phạt chính xác theo logic bài tập.
/// ============================================================================
class RaceResult {
  final Horse winnerHorse;
  final List<Horse> allHorses;
  final List<Bet> bets;
  final int startingBalance; // Số dư tài khoản TRƯỚC khi đặt cược vòng này

  const RaceResult({
    required this.winnerHorse,
    required this.allHorses,
    required this.bets,
    required this.startingBalance,
  });

  /// Tổng số tiền người chơi đã đặt cược ở vòng này
  int get totalBetAmount {
    return bets.fold<int>(0, (sum, bet) => sum + bet.amount);
  }

  /// Phiếu cược dành cho ngựa chiến thắng
  Bet get winnerBet {
    return bets.firstWhere(
      (b) => b.horseId == winnerHorse.id,
      orElse: () => Bet(horseId: winnerHorse.id, amount: 0),
    );
  }

  /// Kiểm tra xem người chơi có thắng cược không (có đặt tiền vào ngựa về nhất)
  bool get hasWonAnyBet => winnerBet.amount > 0;

  /// Tổng số tiền nhận lại từ nhà cái:
  /// Nếu đoán trúng: Nhận lại tiền cược + tiền thưởng (ví dụ cược 20 xu với tỷ lệ 2.0x => nhận 40 xu)
  /// Nếu đoán sai: 0 xu
  int get totalPayout {
    if (winnerBet.amount > 0) {
      return (winnerBet.amount * winnerHorse.oddsMultiplier).round();
    }
    return 0;
  }

  /// Lãi/Lỗ ròng của vòng đua:
  /// = Tổng tiền nhận lại - Tổng tiền đã bỏ ra cược
  int get netProfit => totalPayout - totalBetAmount;

  /// Số dư mới của người chơi sau khi thanh toán cược
  int get updatedBalance => startingBalance - totalBetAmount + totalPayout;

  /// Lấy phiếu cược cho một con ngựa cụ thể
  Bet getBetForHorse(int horseId) {
    return bets.firstWhere(
      (b) => b.horseId == horseId,
      orElse: () => Bet(horseId: horseId, amount: 0),
    );
  }

  /// Kiểm tra một con ngựa cụ thể người chơi có thắng cược không
  bool isHorseBetWon(int horseId) {
    return horseId == winnerHorse.id && getBetForHorse(horseId).amount > 0;
  }
}
