import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_dua_ngua/models/bet_model.dart';
import 'package:game_dua_ngua/models/horse_model.dart';
import 'package:game_dua_ngua/screens/race_screen.dart';
import 'package:game_dua_ngua/screens/result_screen.dart';
import 'package:game_dua_ngua/widgets/race_rider_canvas.dart';
import 'package:game_dua_ngua/widgets/race_track_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

RaceTrackCanvas _track(WidgetTester tester) =>
    tester.widget<RaceTrackCanvas>(find.byType(RaceTrackCanvas));

RaceRiderCanvas _rider(WidgetTester tester) =>
    tester.widget<RaceRiderCanvas>(find.byType(RaceRiderCanvas));

String _clockText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .singleWhere((text) => RegExp(r'^\d{2}:\d{2}\.\d{2}$').hasMatch(text));

Future<void> _switchTo(WidgetTester tester, String view) async {
  await tester.tap(find.byKey(ValueKey('race-view-$view')));
  // No simulation time elapses during a camera change.
  await tester.pump();
}

Future<void> _openRace(WidgetTester tester) async {
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

Future<void> _disposeRace(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(tester.takeException(), isNull);
  expect(tester.binding.transientCallbackCount, 0);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'player_total_balance': 100});
  });

  testWidgets(
    'switching cameras preserves countdown, progress and race clock',
    (tester) async {
      await _openRace(tester);
      expect(find.byType(RaceTrackCanvas), findsOneWidget);
      await tester.tap(find.text('BẮT ĐẦU ĐUA'));
      await tester.pump(const Duration(seconds: 1));
      expect(_track(tester).countdown, 2);
      final beforeStart = Map<int, double>.from(_track(tester).progressMap);
      final startClock = _clockText(tester);

      await _switchTo(tester, 'rider');
      expect(_rider(tester).countdown, 2);
      expect(_rider(tester).progressMap, beforeStart);
      expect(_clockText(tester), startClock);
      await _switchTo(tester, 'side');
      expect(_track(tester).countdown, 2);
      await _switchTo(tester, 'rider');
      await tester.pump(const Duration(seconds: 2));
      expect(_rider(tester).isRacing, isTrue);
      expect(_rider(tester).stepTick, 0);

      await tester.pump(const Duration(milliseconds: 700));
      expect(_rider(tester).stepTick, 10);
      final progress = Map<int, double>.from(_rider(tester).progressMap);
      final runningClock = _clockText(tester);
      for (var switchCount = 0; switchCount < 3; switchCount++) {
        await _switchTo(tester, 'side');
        expect(_track(tester).progressMap, progress);
        expect(_track(tester).stepTick, 10);
        expect(_track(tester).isRacing, isTrue);
        expect(_clockText(tester), runningClock);
        await _switchTo(tester, 'rider');
        expect(_rider(tester).progressMap, progress);
        expect(_rider(tester).stepTick, 10);
        expect(_clockText(tester), runningClock);
      }

      await tester.pump(const Duration(milliseconds: 70));
      expect(_rider(tester).stepTick, 11);
      expect(_rider(tester).progressMap, isNot(progress));
      expect(find.byType(RaceScreen, skipOffstage: false), findsOneWidget);
      await _disposeRace(tester);
    },
  );

  testWidgets('switching at the finish still opens only one result route', (
    tester,
  ) async {
    await _openRace(tester);
    await _switchTo(tester, 'rider');
    await tester.tap(find.text('BẮT ĐẦU ĐUA'));
    await tester.pump(const Duration(seconds: 3));
    for (var step = 0; step < 60; step++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (_rider(tester).winnerHorseId != null) break;
    }
    final winner = _rider(tester).winnerHorseId;
    expect(winner, isNotNull);
    final finishProgress = Map<int, double>.from(_rider(tester).progressMap);
    final finishClock = _clockText(tester);
    await _switchTo(tester, 'side');
    expect(_track(tester).winnerHorseId, winner);
    expect(_track(tester).progressMap, finishProgress);
    expect(_clockText(tester), finishClock);
    await _switchTo(tester, 'rider');
    expect(_rider(tester).winnerHorseId, winner);

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

  for (final size in [
    const Size(844, 390),
    const Size(667, 375),
    const Size(390, 844),
  ]) {
    testWidgets('rider view fits $size before and during racing', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _openRace(tester);
      await _switchTo(tester, 'rider');
      expect(tester.takeException(), isNull);

      final rect = tester.getRect(find.byType(RaceRiderCanvas));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      expect(rect.height, greaterThan(150));

      await tester.tap(find.text('BẮT ĐẦU ĐUA'));
      await tester.pump(const Duration(seconds: 3));
      expect(_rider(tester).isRacing, isTrue);
      await tester.pump(const Duration(milliseconds: 140));
      expect(tester.takeException(), isNull);

      // Cover live layout changes without restarting the race.
      await _switchTo(tester, 'side');
      expect(_track(tester).isRacing, isTrue);
      await _switchTo(tester, 'rider');
      expect(_rider(tester).isRacing, isTrue);
      await _disposeRace(tester);
    });
  }
}
