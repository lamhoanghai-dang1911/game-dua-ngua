import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_dua_ngua/models/horse_model.dart';
import 'package:game_dua_ngua/widgets/race_rider_canvas.dart';

const _frameKey = ValueKey('rider-frame');

Widget _rider({
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
        child: RepaintBoundary(
          key: _frameKey,
          child: SizedBox.fromSize(
            size: size,
            child: RaceRiderCanvas(
              horses: Horse.defaultHorses,
              progressMap: {1: progress, 2: progress, 3: progress},
              winnerHorseId: winnerHorseId,
              isRacing: isRacing,
              // Camera motion must continue between simulation updates.
              stepTick: 7,
              countdown: 0,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  // Codecs finish on the real clock. Never compare a loading placeholder
  // against the finished scene when checking for animated frame changes.
  for (
    var attempt = 0;
    attempt < 200 && find.text('ĐANG TẢI GÓC NHÌN…').evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(find.text('ĐANG TẢI GÓC NHÌN…'), findsNothing);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frameKey),
  );
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

// Isolate the world between the top telemetry and foreground horse. A change
// here verifies the perspective scene responds, beyond updating distance text.
Uint8List _worldPixels(Uint8List pixels) {
  const width = 780;
  final bytes = BytesBuilder(copy: false);
  for (var y = 130; y < 210; y++) {
    bytes.add(pixels.sublist((y * width + 50) * 4, (y * width + 210) * 4));
  }
  return bytes.takeBytes();
}

void main() {
  testWidgets('rider camera animates between unchanged simulation ticks', (
    tester,
  ) async {
    await tester.pumpWidget(_rider(isRacing: true, progress: 0.25));
    await tester.pump(const Duration(milliseconds: 16));
    final firstFrame = await _pixels(tester);

    await tester.pump(const Duration(milliseconds: 48));
    expect(listEquals(firstFrame, await _pixels(tester)), isFalse);
    expect(
      tester.widget<RaceRiderCanvas>(find.byType(RaceRiderCanvas)).stepTick,
      7,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('stopping rider view settles motion and cancels its ticker', (
    tester,
  ) async {
    await tester.pumpWidget(_rider(isRacing: true, progress: 0.2));
    await _pixels(tester);
    await tester.pumpWidget(_rider(isRacing: true, progress: 0.8));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(_rider(progress: 0.8));
    final stopped = await _pixels(tester);

    await tester.pump(const Duration(seconds: 1));
    expect(listEquals(stopped, await _pixels(tester)), isTrue);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress changes the perspective world and reset restores it', (
    tester,
  ) async {
    await tester.pumpWidget(_rider(progress: 0.1));
    final start = await _pixels(tester);
    await tester.pumpWidget(_rider(progress: 0.95));
    final approach = await _pixels(tester);
    expect(
      listEquals(_worldPixels(start), _worldPixels(approach)),
      isFalse,
      reason: 'The finish approach must change the scene, not only the HUD.',
    );

    await tester.pumpWidget(_rider(progress: 0.1));
    expect(listEquals(start, await _pixels(tester)), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion freezes the camera while progress still updates',
    (tester) async {
      await tester.pumpWidget(_rider(isRacing: true, reduceMotion: true));
      final initial = await _pixels(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(listEquals(initial, await _pixels(tester)), isTrue);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(
        _rider(isRacing: true, reduceMotion: true, progress: 0.75),
      );
      final moved = await _pixels(tester);
      expect(listEquals(initial, moved), isFalse);
      await tester.pump(const Duration(milliseconds: 300));
      expect(listEquals(moved, await _pixels(tester)), isTrue);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small rider canvas clamps progress and renders winner state', (
    tester,
  ) async {
    await tester.pumpWidget(_rider(size: const Size(220, 120), progress: -0.2));
    expect(await _pixels(tester), isNotEmpty);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _rider(size: const Size(220, 120), progress: 1.2, winnerHorseId: 1),
    );
    expect(await _pixels(tester), isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
