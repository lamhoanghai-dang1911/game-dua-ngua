import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_dua_ngua/main.dart';
import 'package:game_dua_ngua/models/horse_model.dart';
import 'package:game_dua_ngua/models/bet_model.dart';
import 'package:game_dua_ngua/models/race_result_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'player_total_balance': 100,
    });
  });

  group('Module 2 & 3: Dart OOP & Settlement Logic Unit Tests', () {
    test('Bet model properties and immutability', () {
      const bet = Bet(horseId: 1, amount: 20);
      expect(bet.hasBet, isTrue);
      expect(bet.horseId, 1);
      expect(bet.amount, 20);

      final updated = bet.copyWith(amount: 50);
      expect(updated.amount, 50);
      expect(bet.amount, 20); // Immutability preserved
    });

    test('RaceResult calculations when player wins', () {
      final horses = Horse.defaultHorses;
      final bets = [
        const Bet(horseId: 1, amount: 30), // Bet on Horse 1
        const Bet(horseId: 2, amount: 10), // Bet on Horse 2
        const Bet(horseId: 3, amount: 0),
      ];

      // Giả sử Ngựa 1 (Xích Thố, tỷ lệ 2.0x) thắng
      final result = RaceResult(
        winnerHorse: horses[0],
        allHorses: horses,
        bets: bets,
        startingBalance: 100,
      );

      expect(result.totalBetAmount, 40); // 30 + 10
      expect(result.hasWonAnyBet, isTrue);
      expect(result.totalPayout, 60); // 30 * 2.0 = 60
      expect(result.netProfit, 20); // 60 - 40 = +20 xu
      expect(result.updatedBalance, 120); // 100 - 40 + 60 = 120 xu
    });

    test('RaceResult calculations when player loses', () {
      final horses = Horse.defaultHorses;
      final bets = [
        const Bet(horseId: 1, amount: 40),
        const Bet(horseId: 2, amount: 0),
        const Bet(horseId: 3, amount: 0),
      ];

      // Ngựa 2 thắng trong khi người chơi cược Ngựa 1
      final result = RaceResult(
        winnerHorse: horses[1],
        allHorses: horses,
        bets: bets,
        startingBalance: 100,
      );

      expect(result.totalBetAmount, 40);
      expect(result.hasWonAnyBet, isFalse);
      expect(result.totalPayout, 0);
      expect(result.netProfit, -40);
      expect(result.updatedBalance, 60); // 100 - 40 = 60 xu
    });
  });

  group('Module 4: UI & Betting Widget Tests', () {
    testWidgets('HomeBettingScreen displays balance, horses, and enables start on bet',
        (WidgetTester tester) async {
      // Đặt kích thước màn hình test mô phỏng điện thoại (1080x1920)
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MiniRacingGameApp());
      // Nạp số dư từ SharedPreferences
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Kiểm tra tiêu đề game
      expect(find.text('ĐẤU TRƯỜNG ĐUA NGỰA'), findsOneWidget);

      // Kiểm tra sự xuất hiện của cả 3 chiến mã
      expect(find.text('Xích Thố'), findsOneWidget);
      expect(find.text('Kim Mao'), findsOneWidget);
      expect(find.text('Bạch Long'), findsOneWidget);

      // Kiểm tra nút bắt đầu đua ban đầu chưa đặt cược sẽ bị disable
      final startButtonFinder = find.widgetWithText(ElevatedButton, 'BẮT ĐẦU ĐUA 🏁');
      expect(startButtonFinder, findsOneWidget);

      final ElevatedButton initialButton = tester.widget(startButtonFinder);
      expect(initialButton.onPressed, isNull);

      // Bấm chip "+5" của chiến mã đầu tiên
      final plus5Finder = find.text('+5');
      expect(plus5Finder, findsWidgets);
      await tester.tap(plus5Finder.first);
      await tester.pump();

      // Sau khi cược 5 xu, nút bắt đầu đua đã được kích hoạt
      final ElevatedButton activeAfterBetButton = tester.widget(startButtonFinder);
      expect(activeAfterBetButton.onPressed, isNotNull);
    });
  });
}
