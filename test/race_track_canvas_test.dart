import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_dua_ngua/models/bet_model.dart';
import 'package:game_dua_ngua/models/horse_model.dart';
import 'package:game_dua_ngua/screens/race_screen.dart';
import 'package:game_dua_ngua/widgets/race_track_canvas.dart';

Widget _track({
  double progress = 0,
  bool isRacing = false,
  bool reduceMotion = false,
  Size size = const Size(780, 420),
  int? winnerHorseId,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: SizedBox.fromSize(
          size: size,
          child: RaceTrackCanvas(
            horses: [Horse.defaultHorses.first],
            progressMap: {1: progress},
            winnerHorseId: winnerHorseId,
            isRacing: isRacing,
            // Deliberately constant: the display must animate between ticks.
            stepTick: 7,
            countdown: 0,
          ),
        ),
      ),
    ),
  );
}

Future<Uint8List> _racerPixels(WidgetTester tester) async {
  // Image codecs complete outside the test clock. Compare fully loaded frames,
  // not a temporary vector fallback against the subsequently decoded sprite.
  for (
    var attempt = 0;
    attempt < 200 && find.text('ĐANG TẢI SÂN ĐUA…').evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(find.text('ĐANG TẢI SÂN ĐUA…'), findsNothing);
  final paints = find.descendant(
    of: find.byType(RaceTrackCanvas),
    matching: find.byType(CustomPaint),
  );
  // The front paint layer contains only racers, shadows and dust. Capturing
  // that layer avoids unrelated framework or background redraws.
  final boundaryFinder = find
      .ancestor(of: paints.last, matching: find.byType(RepaintBoundary))
      .first;
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return Uint8List.fromList(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}

double _horizontalCenter(Uint8List pixels, int width) {
  var mass = 0.0;
  var weightedX = 0.0;
  for (var i = 0; i < pixels.length; i += 4) {
    final alpha = pixels[i + 3];
    mass += alpha;
    weightedX += ((i ~/ 4) % width) * alpha;
  }
  expect(mass, greaterThan(0), reason: 'A visible horse must be painted.');
  return weightedX / mass;
}

void main() {
  testWidgets('gallop repaints between unchanged simulation ticks', (
    tester,
  ) async {
    await tester.pumpWidget(_track(isRacing: true, progress: 0.25));
    await tester.pump(const Duration(milliseconds: 16));
    final firstFrame = await _racerPixels(tester);

    await tester.pump(const Duration(milliseconds: 32));
    final nextFrame = await _racerPixels(tester);

    expect(
      listEquals(firstFrame, nextFrame),
      isFalse,
      reason: 'The horse should gallop even before the next race update.',
    );
    expect(
      tester.widget<RaceTrackCanvas>(find.byType(RaceTrackCanvas)).stepTick,
      7,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('stopping a race settles travel and leaves no active animation', (
    tester,
  ) async {
    await tester.pumpWidget(_track(isRacing: true));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(_track(isRacing: true, progress: 0.8));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(_track(progress: 0.8));
    final stopped = await _racerPixels(tester);

    await tester.pump(const Duration(seconds: 1));
    expect(listEquals(stopped, await _racerPixels(tester)), isTrue);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // A stopped tween must land at the same position as an initially parked
    // horse at the requested destination, rather than freeze halfway there.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_track(progress: 0.8));
    expect(listEquals(stopped, await _racerPixels(tester)), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish and reset visibly move the horse to exact destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_track());
    final start = await _racerPixels(tester);
    await tester.pumpWidget(_track(progress: 1));
    final finish = await _racerPixels(tester);

    expect(
      _horizontalCenter(finish, 780) - _horizontalCenter(start, 780),
      greaterThan(200),
      reason: 'A completed horse must move across the track toward the finish.',
    );
    await tester.pumpWidget(_track());
    expect(listEquals(start, await _racerPixels(tester)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion holds the pose and updates positions immediately',
    (tester) async {
      await tester.pumpWidget(_track(isRacing: true, reduceMotion: true));
      final initial = await _racerPixels(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(listEquals(initial, await _racerPixels(tester)), isTrue);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(
        _track(isRacing: true, reduceMotion: true, progress: 0.75),
      );
      final moved = await _racerPixels(tester);
      expect(listEquals(initial, moved), isFalse);
      await tester.pump(const Duration(milliseconds: 300));
      expect(listEquals(moved, await _racerPixels(tester)), isTrue);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a narrow track tolerates out of range progress and winner state',
    (tester) async {
      await tester.pumpWidget(
        _track(size: const Size(220, 120), progress: -0.2),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _track(size: const Size(220, 120), progress: 1.2, winnerHorseId: 1),
      );
      expect(tester.takeException(), isNull);
      expect(await _racerPixels(tester), isNotEmpty);
    },
  );

  for (final size in [
    const Size(844, 390),
    const Size(667, 375),
    const Size(390, 844),
  ]) {
    testWidgets('race screen fits $size before and during the race', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: RaceScreen(
            horses: Horse.defaultHorses,
            bets: const [Bet(horseId: 1, amount: 20)],
            initialBalance: 100,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final trackRect = tester.getRect(find.byType(RaceTrackCanvas));
      expect(trackRect.left, greaterThanOrEqualTo(0));
      expect(trackRect.right, lessThanOrEqualTo(size.width));
      expect(trackRect.top, greaterThanOrEqualTo(0));
      expect(trackRect.bottom, lessThanOrEqualTo(size.height));
      expect(trackRect.height, greaterThan(150));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (var second = 0; second < 3; second++) {
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }
      expect(
        tester.widget<RaceTrackCanvas>(find.byType(RaceTrackCanvas)).isRacing,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 140));
      expect(tester.takeException(), isNull);

      // Dispose while racing so both simulation and display timers are checked.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }
}
