import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_dua_ngua/widgets/race_horse_sprites.dart';

Future<Uint8List> _render(RaceHorseSprite sprite, double phase) async {
  final recorder = ui.PictureRecorder();
  sprite.draw(
    ui.Canvas(recorder),
    const ui.Rect.fromLTWH(0, 0, 80, 80),
    phase: phase,
    isRacing: true,
    horseId: 1,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(80, 80);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return Uint8List.fromList(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  testWidgets('frame crop removes debris without shifting or stretching art', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(10, 10, 20, 20),
        ui.Paint()..color = const ui.Color(0xFF00FF00),
      );
      // Frame 1 has a red fragment in its gutter and a blue main subject.
      canvas.drawRect(
        const ui.Rect.fromLTWH(41, 20, 2, 4),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(55, 10, 10, 20),
        ui.Paint()..color = const ui.Color(0xFF0000FF),
      );
      final picture = recorder.endRecording();
      final atlas = await picture.toImage(80, 40);
      picture.dispose();
      final original = RaceHorseSprite.fromImage(
        atlas.clone(),
        columns: 2,
        rows: 1,
        frameCount: 2,
        sourceInset: 0,
      );
      final cropped = RaceHorseSprite.fromImage(
        atlas,
        columns: 2,
        rows: 1,
        frameCount: 2,
        sourceInset: 0,
        frameLeftCrops: const {1: 4},
      );
      try {
        final before = await _render(original, math.pi + 0.1);
        final after = await _render(cropped, math.pi + 0.1);
        expect(before[(42 * 80 + 4) * 4 + 3], 255);
        expect(after[(42 * 80 + 4) * 4 + 3], 0);
        // Every pixel around the main subject keeps its original position.
        for (var y = 0; y < 80; y++) {
          final start = (y * 80 + 16) * 4;
          final end = (y * 80 + 80) * 4;
          expect(after.sublist(start, end), before.sublist(start, end));
        }
        expect(await _render(cropped, 0), await _render(original, 0));
      } finally {
        original.dispose();
        cropped.dispose();
      }
    });
  });
}
