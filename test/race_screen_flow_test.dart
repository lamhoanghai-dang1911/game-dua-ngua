import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_dua_ngua/models/bet_model.dart';
import 'package:game_dua_ngua/models/horse_model.dart';
import 'package:game_dua_ngua/screens/race_screen.dart';
import 'package:game_dua_ngua/screens/result_screen.dart';
import 'package:game_dua_ngua/widgets/race_track_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

RaceTrackCanvas _track(WidgetTester tester) =>
    tester.widget<RaceTrackCanvas>(find.byType(RaceTrackCanvas));

Future<void> _openRace(WidgetTester tester) async {
  // Orientation changes are platform calls; resolve them before route pushes.
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<int>(
              MaterialPageRoute<int>(
                builder: (_) => RaceScreen(
                  horses: Horse.defaultHorses,
                  bets: const [Bet(horseId: 1, amount: 20)],
                  initialBalance: 100,
                ),
              ),
            ),
            child: const Text('Mở đường đua'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở đường đua'));
  await tester.pumpAndSettle();
}

Future<void> _startRace(WidgetTester tester) async {
  await tester.tap(find.text('BẮT ĐẦU ĐUA'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  expect(_track(tester).isRacing, isTrue);
}

Future<void> _finishRace(WidgetTester tester) async {
  await _startRace(tester);
  // Each step stays below the result delay so the finish button remains visible.
  for (var step = 0; step < 60; step++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (_track(tester).winnerHorseId != null) return;
  }
  fail('The race should finish within 30 seconds of simulation time.');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'player_total_balance': 100});
  });

  testWidgets('rapid start taps create only one countdown', (tester) async {
    await _openRace(tester);
    // No intervening frame: both taps can reach the same enabled callback.
    await tester.tap(find.text('BẮT ĐẦU ĐUA'));
    await tester.tap(find.text('BẮT ĐẦU ĐUA'));
    await tester.pump(const Duration(seconds: 1));
    expect(_track(tester).countdown, 2);
    expect(_track(tester).isRacing, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('system back pauses countdown and stay resumes it', (
    tester,
  ) async {
    await _openRace(tester);
    await tester.tap(find.text('BẮT ĐẦU ĐUA'));
    await tester.pump(const Duration(seconds: 1));
    expect(_track(tester).countdown, 2);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Hủy cuộc đua?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(_track(tester).countdown, 2);
    expect(find.byType(ResultScreen), findsNothing);

    await tester.tap(find.text('Ở lại'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_track(tester).isRacing, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('exit confirmation pauses racing and leaving cancels the race', (
    tester,
  ) async {
    await _openRace(tester);
    await _startRace(tester);
    await tester.pump(const Duration(seconds: 1));
    final progressBefore = Map<int, double>.from(_track(tester).progressMap);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Hủy cuộc đua?'), findsOneWidget);
    expect(_track(tester).progressMap, progressBefore);
    expect(_track(tester).isRacing, isFalse);
    expect(find.byType(ResultScreen), findsNothing);

    await tester.tap(find.text('Rời đi'));
    await tester.pumpAndSettle();
    expect(find.text('Mở đường đua'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(ResultScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual results and auto delay push a single result screen', (
    tester,
  ) async {
    await _openRace(tester);
    await _finishRace(tester);
    // Reproduce two callbacks before the platform orientation request completes.
    final showResults = tester
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'XEM KẾT QUẢ'),
        )
        .onPressed!;
    showResults();
    showResults();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ResultScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Về Trang Chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Mở đường đua'), findsOneWidget);
    expect(find.byType(RaceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a finished race cancels pending automatic results', (
    tester,
  ) async {
    await _openRace(tester);
    await _finishRace(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Mở đường đua'), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
