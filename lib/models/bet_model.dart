/// ============================================================================
/// MODULE 2 & 3: DART ESSENTIALS & OOP
/// Lớp Bet đại diện cho một phiếu cược của người chơi trên một ngựa cụ thể.
/// ============================================================================
class Bet {
  final int horseId;
  final int amount;

  const Bet({
    required this.horseId,
    this.amount = 0,
  });

  /// Kiểm tra xem người chơi có đặt tiền vào cửa này không
  bool get hasBet => amount > 0;

  /// Tạo bản sao phiếu cược với số tiền mới
  Bet copyWith({
    int? amount,
  }) {
    return Bet(
      horseId: horseId,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() => 'Bet(horseId: $horseId, amount: $amount)';
}
