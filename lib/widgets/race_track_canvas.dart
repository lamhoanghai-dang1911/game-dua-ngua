import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/horse_model.dart';
import 'race_horse_artist.dart';
import 'race_horse_sprites.dart';

/// The display runs at the screen's refresh rate, independently of the 70 ms
/// simulation ticks. Positions remain controlled by the race screen.
class RaceTrackCanvas extends StatefulWidget {
  final List<Horse> horses;
  final Map<int, double> progressMap;
  final int? winnerHorseId;
  final bool isRacing;
  final int stepTick;
  final int countdown;

  const RaceTrackCanvas({
    super.key,
    required this.horses,
    required this.progressMap,
    required this.winnerHorseId,
    required this.isRacing,
    required this.stepTick,
    required this.countdown,
  });

  @override
  State<RaceTrackCanvas> createState() => _RaceTrackCanvasState();
}

class _RaceTrackCanvasState extends State<RaceTrackCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _gallop;
  late final AnimationController _travel;
  late final Listenable _frames;
  late Map<int, double> _from;
  late Map<int, double> _to;
  bool _reduceMotion = false;
  bool _loadingArtwork = true;
  RaceHorseSprites? _sprites;
  ui.Image? _stadium;

  @override
  void initState() {
    super.initState();
    _from = Map.of(widget.progressMap);
    _to = Map.of(widget.progressMap);
    _gallop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _travel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      value: 1,
    );
    _frames = Listenable.merge([_gallop, _travel]);
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    await Future.wait([_loadHorses(), _loadStadium()]);
    if (mounted) setState(() => _loadingArtwork = false);
  }

  Future<void> _loadHorses() async {
    try {
      final sprites = await RaceHorseSprites.loadDefault();
      if (!mounted) {
        sprites.dispose();
        return;
      }
      setState(() => _sprites = sprites);
    } catch (error) {
      // Keep the illustrated horses playable when an asset cannot be decoded.
      debugPrint('Unable to load racehorse artwork: $error');
    }
  }

  Future<void> _loadStadium() async {
    try {
      final data = await rootBundle.load('assets/racing/stadium.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      late final ui.Image stadium;
      try {
        stadium = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        stadium.dispose();
        return;
      }
      setState(() => _stadium = stadium);
    } catch (error) {
      debugPrint('Unable to load stadium artwork: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _travel.value = 1;
    _syncGallop();
  }

  void _syncGallop() {
    if (widget.isRacing && !_reduceMotion) {
      if (!_gallop.isAnimating) _gallop.repeat();
    } else {
      _gallop.stop();
    }
  }

  @override
  void didUpdateWidget(covariant RaceTrackCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(_to, widget.progressMap)) {
      // Preserve the displayed position when a new tick interrupts a tween.
      _from = {
        for (final horse in widget.horses)
          horse.id: lerpDouble(
            _from[horse.id] ?? 0,
            _to[horse.id] ?? 0,
            _travel.value,
          )!,
      };
      _to = Map.of(widget.progressMap);
      if (widget.isRacing && !_reduceMotion) {
        _travel.forward(from: 0);
      } else {
        // Results and resets land at their exact simulation positions.
        _travel.value = 1;
      }
    } else if (!widget.isRacing) {
      _travel.value = 1;
    }
    _syncGallop();
  }

  @override
  void dispose() {
    _gallop.dispose();
    _travel.dispose();
    _sprites?.dispose();
    _stadium?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.winnerHorseId != null
          ? 'Ngựa số ${widget.winnerHorseId} về nhất'
          : 'Đường đua ${widget.horses.length} làn',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF71634A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _TrackSurfacePainter(widget.horses, _stadium),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: _RacersPainter(
                    horses: widget.horses,
                    from: _from,
                    to: _to,
                    travel: _travel,
                    gallop: _gallop,
                    frames: _frames,
                    isRacing: widget.isRacing,
                    animate: !_reduceMotion,
                    winnerHorseId: widget.winnerHorseId,
                    sprites: _sprites,
                  ),
                ),
              ),
              if (_loadingArtwork)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xCC192228)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'ĐANG TẢI SÂN ĐUA…',
                        style: TextStyle(color: Color(0xFFF3D39A), fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared geometry aligns the nose with the finish plane at progress == 1.
class _TrackGeometry {
  final Size size;
  final int laneCount;

  const _TrackGeometry(this.size, this.laneCount);

  double get verge => math.min(10, size.height * 0.025);
  double get stadiumHeight => math.min(110, size.height * 0.24);
  double get trackTop => stadiumHeight + verge;
  double get laneHeight =>
      (size.height - trackTop - verge) / math.max(1, laneCount);
  double get labelWidth =>
      math.min(size.width * 0.22, size.width < 500 ? 68 : 96);
  double get scale => math.max(
    0,
    math.min(
      (laneHeight - 8) / 380,
      math.min(0.58, (size.width - labelWidth - 44) * 0.46 / 600),
    ),
  );
  double get startNose => labelWidth + 8 + 580 * scale;
  double get finishNose => math.max(startNose, size.width - 26);
  double top(int lane) => trackTop + lane * laneHeight;
  double ground(int lane) =>
      top(lane) + math.min(laneHeight - 5, (laneHeight + 360 * scale) / 2);
  double nose(double progress) =>
      lerpDouble(startNose, finishNose, progress.clamp(0, 1))!;
  Offset origin(int lane, double progress) =>
      Offset(nose(progress) - 580 * scale, ground(lane) - 410 * scale);
}

class _TrackSurfacePainter extends CustomPainter {
  final List<Horse> horses;
  final ui.Image? stadium;
  _TrackSurfacePainter(this.horses, this.stadium);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || horses.isEmpty) return;
    final geometry = _TrackGeometry(size, horses.length);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF324334),
    );
    final background = stadium;
    if (background != null) {
      _drawPhotoRegion(
        canvas,
        background,
        Rect.fromLTWH(
          0,
          0,
          background.width.toDouble(),
          background.height * 0.40,
        ),
        Rect.fromLTWH(0, 0, size.width, geometry.trackTop),
        alignment: Alignment.bottomCenter,
      );
    }
    final panorama = Rect.fromLTWH(0, 0, size.width, geometry.trackTop);
    canvas.drawRect(
      panorama,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x440A1318), Color(0x000A1318), Color(0x770A1318)],
        ).createShader(panorama),
    );
    for (var lane = 0; lane < horses.length; lane++) {
      final horse = horses[lane];
      final top = geometry.top(lane);
      final laneHeight = geometry.laneHeight;
      final rect = Rect.fromLTWH(
        geometry.labelWidth,
        top,
        size.width - geometry.labelWidth,
        laneHeight,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: lane.isEven
                ? const [
                    Color(0xFFAE875F),
                    Color(0xFFD3AF7E),
                    Color(0xFFBE9667),
                  ]
                : const [
                    Color(0xFFA58059),
                    Color(0xFFC7A375),
                    Color(0xFFB68D61),
                  ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );

      if (background != null) {
        // Use the three dirt bands between the photograph's painted lines.
        // Mapping them to the same lane geometry keeps feet and rails aligned.
        const bands = [(0.405, 0.520), (0.530, 0.682), (0.692, 1.0)];
        final band = bands[lane % bands.length];
        _drawPhotoRegion(
          canvas,
          background,
          Rect.fromLTRB(
            0,
            background.height * band.$1,
            background.width.toDouble(),
            background.height * band.$2,
          ),
          rect,
        );
        canvas.drawRect(rect, Paint()..color = const Color(0x0D3B2618));
      }

      // Deterministic dirt grains are on a separate, static paint layer.
      final grain = Paint()..strokeCap = StrokeCap.round;
      for (var i = 0; background == null && i < rect.width / 3; i++) {
        final x = rect.left + (i * 43.7 + lane * 19) % rect.width;
        final y =
            rect.top +
            5 +
            (i * 17.3 + lane * 13) % math.max(1, laneHeight - 10);
        grain
          ..color = i.isEven ? const Color(0x1C5E422B) : const Color(0x28FFF1C9)
          ..strokeWidth = i % 3 == 0 ? 1.5 : 0.8;
        canvas.drawLine(Offset(x, y), Offset(x + 2.5 + i % 4, y), grain);
      }
      for (double x = geometry.startNose; x < geometry.finishNose; x += 38) {
        canvas.drawLine(
          Offset(x, top + laneHeight - 4),
          Offset(math.min(x + 18, geometry.finishNose), top + laneHeight - 4),
          Paint()
            ..color = const Color(0x60FAE9C9)
            ..strokeWidth = 1,
        );
      }

      final label = Rect.fromLTWH(0, top, geometry.labelWidth, laneHeight);
      canvas.drawRect(
        label,
        Paint()
          ..color = lane.isEven
              ? const Color(0xFF1A2427)
              : const Color(0xFF202A2C),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, top + 10, 3, math.max(1, laneHeight - 20)),
        Paint()..color = horse.primaryColor,
      );
      final center = Offset(geometry.labelWidth / 2, top + laneHeight / 2);
      final badgeRadius = math.min(14.0, laneHeight * 0.19);
      final badgeCenter = center - Offset(0, laneHeight > 45 ? 9 : 0);
      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()..color = horse.primaryColor,
      );
      _text(
        canvas,
        '${horse.id}'.padLeft(2, '0'),
        badgeCenter,
        size: badgeRadius,
        color: Colors.white,
        weight: FontWeight.w800,
      );
      if (laneHeight > 45) {
        _text(
          canvas,
          horse.name,
          center + const Offset(0, 15),
          size: size.width < 500 ? 10 : 11,
          color: const Color(0xFFF4EDDE),
          weight: FontWeight.w600,
          maxWidth: math.max(1, geometry.labelWidth - 8),
        );
      }

      if (lane > 0) {
        canvas.drawLine(
          Offset(0, top),
          Offset(size.width, top),
          Paint()
            ..color = const Color(0x55584832)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(geometry.labelWidth, top - 1),
          Offset(size.width, top - 1),
          Paint()
            ..color = const Color(0xCCE8DDC3)
            ..strokeWidth = 1,
        );
      }
    }

    // Finish markings sit under the racers instead of cutting across them.
    canvas.drawLine(
      Offset(geometry.startNose, geometry.trackTop),
      Offset(geometry.startNose, size.height - geometry.verge),
      Paint()
        ..color = const Color(0x85F7EEDB)
        ..strokeWidth = 1.5,
    );
    const cell = 5.0;
    for (
      var row = 0;
      row < (size.height - geometry.trackTop - geometry.verge) / cell;
      row++
    ) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            geometry.finishNose + col * cell,
            geometry.trackTop + row * cell,
            cell,
            cell,
          ),
          Paint()
            ..color = (row + col).isEven
                ? const Color(0xFFF7EEDB)
                : const Color(0xFF26332C),
        );
      }
    }
    for (final y in [geometry.trackTop - 2, size.height - geometry.verge + 2]) {
      canvas.drawLine(
        Offset(0, y + 2),
        Offset(size.width, y + 2),
        Paint()
          ..color = const Color(0x50051112)
          ..strokeWidth = 3,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFFE2DDC9)
          ..strokeWidth = 2,
      );
    }
    for (final marker in [
      ('START', geometry.startNose),
      ('FINISH', geometry.finishNose - 4),
    ]) {
      final badge = Rect.fromCenter(
        center: Offset(marker.$2, geometry.trackTop - 11),
        width: 44,
        height: 16,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badge, const Radius.circular(3)),
        Paint()..color = const Color(0xDD192228),
      );
      _text(
        canvas,
        marker.$1,
        badge.center,
        size: 8,
        color: const Color(0xFFF3D39A),
        weight: FontWeight.w800,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackSurfacePainter oldDelegate) =>
      !listEquals(horses, oldDelegate.horses) || stadium != oldDelegate.stadium;

  void _drawPhotoRegion(
    Canvas canvas,
    ui.Image image,
    Rect source,
    Rect destination, {
    Alignment alignment = Alignment.center,
  }) {
    // Crop each photographic region to fit; stretching a wide strip makes
    // dirt grains and spectators unnaturally tall in portrait layouts.
    final fitted = applyBoxFit(BoxFit.cover, source.size, destination.size);
    canvas.drawImageRect(
      image,
      alignment.inscribe(fitted.source, source),
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}

class _RacersPainter extends CustomPainter {
  final List<Horse> horses;
  final Map<int, double> from;
  final Map<int, double> to;
  final Animation<double> travel;
  final Animation<double> gallop;
  final bool isRacing;
  final bool animate;
  final int? winnerHorseId;
  final RaceHorseSprites? sprites;

  _RacersPainter({
    required this.horses,
    required this.from,
    required this.to,
    required this.travel,
    required this.gallop,
    required Listenable frames,
    required this.isRacing,
    required this.animate,
    required this.winnerHorseId,
    required this.sprites,
  }) : super(repaint: frames);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || horses.isEmpty) return;
    final geometry = _TrackGeometry(size, horses.length);
    for (var lane = 0; lane < horses.length; lane++) {
      final horse = horses[lane];
      final progress = lerpDouble(
        from[horse.id] ?? 0,
        to[horse.id] ?? 0,
        travel.value,
      )!;
      final origin = geometry.origin(lane, progress);
      final scale = geometry.scale;
      if (scale <= 0) continue;
      final phase = gallop.value * math.pi * 2 + horse.id * 1.7;
      final moving = isRacing && animate;
      final ground = geometry.ground(lane);

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          geometry.labelWidth,
          geometry.top(lane),
          size.width - geometry.labelWidth,
          geometry.laneHeight,
        ),
      );
      if (horse.id == winnerHorseId) {
        final glow = Rect.fromCenter(
          center: Offset(origin.dx + 310 * scale, ground - 120 * scale),
          width: 560 * scale,
          height: 310 * scale,
        );
        canvas.drawOval(
          glow,
          Paint()
            ..shader = const RadialGradient(
              colors: [Color(0x90FFE0A0), Color(0x00FFE0A0)],
            ).createShader(glow),
        );
      }

      final shadowWidth = (moving ? 285 + 30 * math.sin(phase) : 290) * scale;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(origin.dx + 310 * scale, ground + 1),
          width: shadowWidth,
          height: 17 * scale,
        ),
        Paint()
          ..color = const Color(0x3D342419)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(0.5, 5 * scale),
          ),
      );
      if (moving) _dust(canvas, origin, ground, scale, phase);

      final sprite = sprites?[horse.id];
      if (sprite != null) {
        // The atlas is 4:3, unlike the vector fallback's 5:3 design space.
        // Never squeeze a sprite into the fallback rectangle.
        sprite.draw(
          canvas,
          Rect.fromLTWH(
            origin.dx,
            origin.dy,
            600 * scale,
            600 * scale * sprite.frameSize.height / sprite.frameSize.width,
          ),
          phase: phase,
          isRacing: moving,
          horseId: horse.id,
        );
      } else {
        canvas.translate(origin.dx + 5 * scale, origin.dy + 75 * scale);
        canvas.scale(scale);
        RaceHorseArtist.paint(
          canvas,
          horse: horse,
          phase: phase,
          isRacing: moving,
        );
      }
      canvas.restore();

      if (horse.id == winnerHorseId && geometry.laneHeight > 45) {
        final badge = Rect.fromLTWH(
          4,
          geometry.top(lane) + geometry.laneHeight / 2 + 8,
          geometry.labelWidth - 8,
          18,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badge, const Radius.circular(9)),
          Paint()..color = const Color(0xFF192F2A),
        );
        _text(
          canvas,
          'VỀ NHẤT',
          badge.center,
          size: 9,
          color: const Color(0xFFFFD784),
          weight: FontWeight.w800,
        );
      }
    }
  }

  void _dust(
    Canvas canvas,
    Offset origin,
    double ground,
    double scale,
    double phase,
  ) {
    for (var i = 0; i < 7; i++) {
      final age = (phase / (2 * math.pi) + i / 7) % 1;
      final x = origin.dx + (170 - age * 155) * scale;
      final y = ground - (6 + age * 28 + math.sin(i * 2.3) * 7) * scale;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: (12 + age * 35) * scale,
          height: (7 + age * 16) * scale,
        ),
        Paint()
          ..color = const Color(0xFFF9DDA9).withValues(alpha: (1 - age) * 0.27),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RacersPainter oldDelegate) =>
      !listEquals(horses, oldDelegate.horses) ||
      !mapEquals(from, oldDelegate.from) ||
      !mapEquals(to, oldDelegate.to) ||
      isRacing != oldDelegate.isRacing ||
      animate != oldDelegate.animate ||
      winnerHorseId != oldDelegate.winnerHorseId ||
      sprites != oldDelegate.sprites;
}

void _text(
  Canvas canvas,
  String text,
  Offset center, {
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w500,
  double maxWidth = double.infinity,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}
