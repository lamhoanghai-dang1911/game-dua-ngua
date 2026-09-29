import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// A decoded horse-and-jockey atlas owned by the State that loaded it.
///
/// Atlas frames are ordered left to right, then top to bottom. Drawing does
/// not allocate images, decode assets, or perform work outside the canvas.
/// The owner must dispose this object after its painters stop using it. If an
/// asynchronous load completes after the State unmounts, dispose that result
/// immediately instead of assigning it to the State.
class RaceHorseSprite {
  final ui.Image image;
  final int columns;
  final int rows;
  final int frameCount;
  final int idleFrame;
  final double sourceInset;
  final List<ui.Rect> _sourceRects;
  final List<double> _leftCropFractions;
  final ui.Paint _paint = ui.Paint()
    ..isAntiAlias = true
    ..filterQuality = ui.FilterQuality.medium;
  bool _disposed = false;

  RaceHorseSprite._(
    this._sourceRects,
    this._leftCropFractions, {
    required this.image,
    required this.columns,
    required this.rows,
    required this.frameCount,
    required this.idleFrame,
    required this.sourceInset,
  });

  /// Takes ownership of [image]. Useful for externally decoded atlases and
  /// tests. [sourceInset] is measured in source-image pixels and prevents a
  /// filtered edge from sampling a neighbouring cell.
  /// [frameLeftCrops] removes unwanted pixels at a frame's left edge, measured
  /// from that cell's boundary. Cropping preserves the remaining artwork's
  /// position and scale inside the nominal destination.
  factory RaceHorseSprite.fromImage(
    ui.Image image, {
    int columns = 3,
    int rows = 2,
    int frameCount = 6,
    int idleFrame = 0,
    double sourceInset = 0.5,
    Map<int, double> frameLeftCrops = const {},
  }) {
    _validateGrid(columns, rows, frameCount, idleFrame, sourceInset);
    final width = image.width / columns;
    final height = image.height / rows;
    if (sourceInset * 2 >= math.min(width, height)) {
      throw ArgumentError.value(
        sourceInset,
        'sourceInset',
        'Must leave a nonempty source rectangle inside every frame.',
      );
    }
    for (final crop in frameLeftCrops.entries) {
      RangeError.checkValueInInterval(crop.key, 0, frameCount - 1, 'frame');
      if (!crop.value.isFinite ||
          crop.value < 0 ||
          crop.value >= width - sourceInset) {
        throw ArgumentError.value(
          crop.value,
          'frameLeftCrops',
          'Must leave a nonempty source rectangle inside the frame.',
        );
      }
    }
    final leftInsets = List<double>.generate(
      frameCount,
      (index) => math.max(sourceInset, frameLeftCrops[index] ?? 0.0),
    );
    return RaceHorseSprite._(
      List<ui.Rect>.unmodifiable(
        List.generate(frameCount, (index) {
          final column = index % columns;
          final row = index ~/ columns;
          return ui.Rect.fromLTRB(
            column * width + leftInsets[index],
            row * height + sourceInset,
            (column + 1) * width - sourceInset,
            (row + 1) * height - sourceInset,
          );
        }),
      ),
      List<double>.unmodifiable(
        leftInsets.map(
          (left) => (left - sourceInset) / (width - 2 * sourceInset),
        ),
      ),
      image: image,
      columns: columns,
      rows: rows,
      frameCount: frameCount,
      idleFrame: idleFrame,
      sourceInset: sourceInset,
    );
  }

  /// Loads one PNG atlas with an independently owned decoded image handle.
  /// No shared global image can be invalidated by disposing another screen.
  static Future<RaceHorseSprite> load(
    String asset, {
    int columns = 3,
    int rows = 2,
    int frameCount = 6,
    int idleFrame = 0,
    double sourceInset = 0.5,
    Map<int, double> frameLeftCrops = const {},
    AssetBundle? bundle,
  }) async {
    _validateGrid(columns, rows, frameCount, idleFrame, sourceInset);
    final data = await (bundle ?? rootBundle).load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    ui.Image? decoded;
    try {
      decoded = (await codec.getNextFrame()).image;
      return RaceHorseSprite.fromImage(
        decoded,
        columns: columns,
        rows: rows,
        frameCount: frameCount,
        idleFrame: idleFrame,
        sourceInset: sourceInset,
        frameLeftCrops: frameLeftCrops,
      );
    } catch (_) {
      decoded?.dispose();
      rethrow;
    } finally {
      codec.dispose();
    }
  }

  bool get isDisposed => _disposed;

  /// Nominal dimensions including the transparent gutter around each horse.
  ui.Size get frameSize => ui.Size(image.width / columns, image.height / rows);

  /// Source rectangle excluding the sampling inset and any frame crop.
  ui.Rect sourceRectForFrame(int frame) {
    RangeError.checkValidIndex(frame, _sourceRects, 'frame');
    return _sourceRects[frame];
  }

  /// Converts a continuous angle to a looping discrete animation frame.
  /// Idle and reduced-motion callers keep [isRacing] false to hold one frame.
  int frameForPhase(double phase, {required bool isRacing}) {
    if (!isRacing || !phase.isFinite) return idleFrame;
    final cycle = (phase / (math.pi * 2)) % 1.0;
    return math.min(frameCount - 1, (cycle * frameCount).floor());
  }

  /// Draws one frame into [destination]. The destination should have the same
  /// aspect ratio as [frameSize] to preserve the animal's proportions.
  ///
  /// [horseId] introduces a small phase offset so three lanes do not step in
  /// lockstep. Positions, ground shadows and dust remain the track's concern.
  void draw(
    ui.Canvas canvas,
    ui.Rect destination, {
    required double phase,
    required bool isRacing,
    required int horseId,
    double opacity = 1,
  }) {
    if (_disposed || destination.isEmpty || !opacity.isFinite || opacity <= 0) {
      return;
    }
    final strideOffset = ((horseId - 1) % 3) * 0.19;
    final frame = frameForPhase(phase + strideOffset, isRacing: isRacing);
    final leftCrop = _leftCropFractions[frame];
    if (leftCrop > 0) {
      destination = ui.Rect.fromLTRB(
        destination.left + destination.width * leftCrop,
        destination.top,
        destination.right,
        destination.bottom,
      );
    }
    _paint.color = ui.Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    canvas.drawImageRect(image, _sourceRects[frame], destination, _paint);
  }

  /// Releases this object's image handle. Calling twice is harmless.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    image.dispose();
  }

  static void _validateGrid(
    int columns,
    int rows,
    int frameCount,
    int idleFrame,
    double sourceInset,
  ) {
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('Atlas columns and rows must be positive.');
    }
    if (frameCount <= 0 || frameCount > columns * rows) {
      throw ArgumentError.value(
        frameCount,
        'frameCount',
        'Must be between 1 and columns * rows.',
      );
    }
    if (idleFrame < 0 || idleFrame >= frameCount) {
      throw RangeError.range(idleFrame, 0, frameCount - 1, 'idleFrame');
    }
    if (!sourceInset.isFinite || sourceInset < 0) {
      throw ArgumentError.value(
        sourceInset,
        'sourceInset',
        'Must be a finite nonnegative pixel distance.',
      );
    }
  }
}

/// State-owned collection of the three racing atlases.
///
/// Typical lifecycle:
/// `final loaded = await RaceHorseSprites.loadDefault();`
/// then dispose [loaded] if unmounted, otherwise retain until State.dispose.
class RaceHorseSprites {
  static const assets = <int, String>{
    1: 'assets/racing/horse_red.png',
    2: 'assets/racing/horse_gold.png',
    3: 'assets/racing/horse_blue.png',
  };
  // Extended hooves from frame 0 intrude into frame 1's transparent gutter.
  static const _frameLeftCrops = <int, Map<int, double>>{
    1: {1: 10.5},
    2: {1: 4},
  };

  final Map<int, RaceHorseSprite> _sprites;
  bool _disposed = false;

  RaceHorseSprites._(Map<int, RaceHorseSprite> sprites)
    : _sprites = Map<int, RaceHorseSprite>.unmodifiable(sprites);

  RaceHorseSprite? operator [](int horseId) => _sprites[horseId];

  Map<int, RaceHorseSprite> get sprites => _sprites;

  bool get isDisposed => _disposed;

  static Future<RaceHorseSprites> loadDefault({
    AssetBundle? bundle,
    int columns = 3,
    int rows = 2,
    int frameCount = 6,
    int idleFrame = 0,
    double sourceInset = 0.5,
  }) async {
    final entries = assets.entries.toList(growable: false);
    final loaded = await Future.wait<RaceHorseSprite>(
      entries.map(
        (entry) => RaceHorseSprite.load(
          entry.value,
          bundle: bundle,
          columns: columns,
          rows: rows,
          frameCount: frameCount,
          idleFrame: idleFrame,
          sourceInset: sourceInset,
          frameLeftCrops: columns == 3 && rows == 2 && frameCount > 1
              ? _frameLeftCrops[entry.key] ?? const {}
              : const {},
        ),
      ),
      // A failed asset must not leak the other successfully decoded images.
      cleanUp: (sprite) => sprite.dispose(),
    );
    return RaceHorseSprites._({
      for (var index = 0; index < entries.length; index++)
        entries[index].key: loaded[index],
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final sprite in _sprites.values) {
      sprite.dispose();
    }
  }
}
