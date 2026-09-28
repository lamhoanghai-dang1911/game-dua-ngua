import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/horse_model.dart';

const _trackAssets = <String>[
  'assets/racing/pov/tracks/track_0.png',
  'assets/racing/pov/tracks/track_1.png',
  'assets/racing/pov/tracks/track_2.png',
  'assets/racing/pov/tracks/track_3.png',
  'assets/racing/pov/tracks/track_4.png',
  'assets/racing/pov/tracks/track_5.png',
  'assets/racing/pov/tracks/track_6.png',
];

const _horseSheetAssets = <int, List<String>>{
  1: [
    'assets/racing/pov/horse_red/frames_32_a.png',
    'assets/racing/pov/horse_red/frames_32_b.png',
  ],
  2: [
    'assets/racing/pov/horse_gold/frames_32_a.png',
    'assets/racing/pov/horse_gold/frames_32_b.png',
  ],
  3: [
    'assets/racing/pov/horse_blue/frames_32_a.png',
    'assets/racing/pov/horse_blue/frames_32_b.png',
  ],
};

const _horseSheetColumns = 4;
const _horseSheetRows = 4;
const _horseFramesPerSheet = _horseSheetColumns * _horseSheetRows;
const _horseFrameCount = _horseFramesPerSheet * 2;
const _horseAnimationDuration = Duration(seconds: 8);

class RaceRiderCanvas extends StatefulWidget {
  final List<Horse> horses;
  final Map<int, double> progressMap;
  final Map<int, double> speedMap;
  final double raceDistanceMeters;
  final int? winnerHorseId;
  final bool isRacing;
  final int stepTick;
  final int countdown;

  const RaceRiderCanvas({
    super.key,
    required this.horses,
    required this.progressMap,
    this.speedMap = const {},
    this.raceDistanceMeters = 250,
    this.winnerHorseId,
    required this.isRacing,
    required this.stepTick,
    required this.countdown,
  });

  @override
  State<RaceRiderCanvas> createState() => _RaceRiderCanvasState();
}

class _RaceRiderCanvasState extends State<RaceRiderCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _cameraController;
  late final AnimationController _horseController;
  late final AnimationController _travelController;
  late final Listenable _frames;
  late Map<int, double> _fromProgress;
  late Map<int, double> _toProgress;
  _RiderArtwork? _artwork;
  bool _loadingArtwork = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _fromProgress = Map.of(widget.progressMap);
    _toProgress = Map.of(widget.progressMap);
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    // Keep the close-up horse animation deliberately slower than the camera.
    // 32 frames over 8 seconds gives every pose 250 ms on screen.
    _horseController = AnimationController(
      vsync: this,
      duration: _horseAnimationDuration,
    );
    _travelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      value: 1,
    );
    _frames = Listenable.merge([
      _cameraController,
      _horseController,
      _travelController,
    ]);
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    try {
      final artwork = await _RiderArtwork.load();
      if (!mounted) {
        artwork.dispose();
        return;
      }
      setState(() {
        _artwork = artwork;
        _loadingArtwork = false;
      });
      _syncCamera();
    } catch (error) {
      debugPrint('Không thể tải ảnh góc nhìn kỵ sĩ: $error');
      if (mounted) setState(() => _loadingArtwork = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _travelController.value = 1;
    _syncCamera();
  }

  @override
  void didUpdateWidget(covariant RaceRiderCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(_toProgress, widget.progressMap)) {
      // Continue from the exact position currently visible on screen. This
      // avoids a small jump every time the 70 ms race simulation updates.
      _fromProgress = {
        for (final horse in widget.horses)
          horse.id: ui.lerpDouble(
            _fromProgress[horse.id] ?? 0,
            _toProgress[horse.id] ?? 0,
            _travelController.value,
          )!,
      };
      _toProgress = Map.of(widget.progressMap);
      if (widget.isRacing && !_reduceMotion) {
        _travelController.forward(from: 0);
      } else {
        _travelController.value = 1;
      }
    } else if (!widget.isRacing) {
      _travelController.value = 1;
    }
    _syncCamera();
  }

  void _syncCamera() {
    final shouldAnimate =
        widget.isRacing &&
        widget.countdown == 0 &&
        !_reduceMotion &&
        _artwork != null;
    if (shouldAnimate) {
      if (!_cameraController.isAnimating) _cameraController.repeat();
      if (!_horseController.isAnimating) _horseController.repeat();
    } else {
      _cameraController.stop();
      _horseController.stop();
      if (_cameraController.value != 0) _cameraController.value = 0;
      if (_horseController.value != 0) _horseController.value = 0;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _horseController.dispose();
    _travelController.dispose();
    _artwork?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.winnerHorseId == null
          ? 'Góc nhìn kỵ sĩ gồm ${widget.horses.length} đường đua'
          : 'Ngựa số ${widget.winnerHorseId} về nhất ở góc nhìn kỵ sĩ',
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF10151B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF71634A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _loadingArtwork
                ? const _RiderLoadingView()
                : AnimatedBuilder(
                    animation: _frames,
                    builder: (context, _) => CustomPaint(
                      painter: _RaceRiderPainter(
                        horses: widget.horses,
                        progressMap: {
                          for (final horse in widget.horses)
                            horse.id: ui.lerpDouble(
                              _fromProgress[horse.id] ?? 0,
                              _toProgress[horse.id] ?? 0,
                              _travelController.value,
                            )!,
                        },
                        speedMap: widget.speedMap,
                        raceDistanceMeters: widget.raceDistanceMeters,
                        winnerHorseId: widget.winnerHorseId,
                        isRacing: widget.isRacing,
                        stepTick: widget.stepTick,
                        countdown: widget.countdown,
                        cameraPhase: _cameraController.value,
                        horsePhase: _horseController.value,
                        reduceMotion: _reduceMotion,
                        artwork: _artwork,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RiderLoadingView extends StatelessWidget {
  const _RiderLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF141B24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE2BC70),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'ĐANG TẢI GÓC NHÌN…',
              style: TextStyle(
                color: Color(0xFFD7C28F),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderArtwork {
  final List<ui.Image> tracks;
  final Map<int, List<ui.Image>> horseSheets;
  bool _disposed = false;

  _RiderArtwork({required this.tracks, required this.horseSheets});

  static Future<_RiderArtwork> load() async {
    final decoded = <ui.Image>[];
    try {
      final tracks = <ui.Image>[];
      for (final asset in _trackAssets) {
        final image = await _decodeAsset(asset, targetWidth: 512);
        decoded.add(image);
        tracks.add(image);
      }

      final horses = <int, List<ui.Image>>{};
      for (final entry in _horseSheetAssets.entries) {
        final sheets = <ui.Image>[];
        for (final asset in entry.value) {
          final sheet = await _decodeAsset(asset, targetWidth: 1254);
          decoded.add(sheet);
          sheets.add(sheet);
        }
        horses[entry.key] = sheets;
      }
      return _RiderArtwork(tracks: tracks, horseSheets: horses);
    } catch (_) {
      for (final image in decoded) {
        image.dispose();
      }
      rethrow;
    }
  }

  static Future<ui.Image> _decodeAsset(
    String asset, {
    required int targetWidth,
  }) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: targetWidth,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final image in tracks) {
      image.dispose();
    }
    for (final sheets in horseSheets.values) {
      for (final sheet in sheets) {
        sheet.dispose();
      }
    }
  }
}

class _RaceRiderPainter extends CustomPainter {
  final List<Horse> horses;
  final Map<int, double> progressMap;
  final Map<int, double> speedMap;
  final double raceDistanceMeters;
  final int? winnerHorseId;
  final bool isRacing;
  final int stepTick;
  final int countdown;
  final double cameraPhase;
  final double horsePhase;
  final bool reduceMotion;
  final _RiderArtwork? artwork;

  _RaceRiderPainter({
    required this.horses,
    required this.progressMap,
    required this.speedMap,
    required this.raceDistanceMeters,
    required this.winnerHorseId,
    required this.isRacing,
    required this.stepTick,
    required this.countdown,
    required this.cameraPhase,
    required this.horsePhase,
    required this.reduceMotion,
    required this.artwork,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || horses.isEmpty) return;

    final visibleHorses = horses.take(3).toList(growable: false);
    final laneWidth = size.width / visibleHorses.length;
    for (var index = 0; index < visibleHorses.length; index++) {
      final horse = visibleHorses[index];
      final lane = Rect.fromLTWH(index * laneWidth, 0, laneWidth, size.height);
      canvas.save();
      canvas.clipRect(lane);
      _paintLane(canvas, lane, horse, index);
      canvas.restore();
    }

    for (var index = 1; index < visibleHorses.length; index++) {
      final x = laneWidth * index;
      final color = visibleHorses[index].primaryColor;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.32)
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..strokeWidth = 2,
      );
    }
  }

  void _paintLane(Canvas canvas, Rect lane, Horse horse, int laneIndex) {
    final progress = (progressMap[horse.id] ?? 0).clamp(0.0, 1.0).toDouble();
    final speed = (speedMap[horse.id] ?? 0).clamp(0.0, 99.0).toDouble();
    final running = isRacing && countdown == 0;
    final phase = reduceMotion ? 0.0 : cameraPhase * math.pi * 2;
    final gallopOffset = running
        ? math.sin(phase + laneIndex * 0.72) * lane.height * 0.0045
        : 0.0;
    final sway = running
        ? math.sin(phase * 0.5 + laneIndex * 1.1) * lane.width * 0.007
        : 0.0;

    final tracks = artwork?.tracks;
    if (tracks != null && tracks.isNotEmpty) {
      final trackIndex = (progress * (tracks.length - 1)).round().clamp(
        0,
        tracks.length - 1,
      );
      final backgroundRect = lane
          .inflate(lane.width * 0.018)
          .translate(sway * 0.22, gallopOffset * 0.45);
      paintImage(
        canvas: canvas,
        rect: backgroundRect,
        image: tracks[trackIndex],
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
      );
    } else {
      _paintFallbackTrack(canvas, lane, horse);
    }

    _paintAtmosphere(canvas, lane, progress, phase, running);
    _paintHorse(canvas, lane, horse, gallopOffset, sway, running);
    _paintTopHud(canvas, lane, horse, speed);
    _paintBottomHud(canvas, lane, horse, progress);

    if (winnerHorseId == horse.id) {
      _paintWinner(canvas, lane, horse);
    }
  }

  void _paintAtmosphere(
    Canvas canvas,
    Rect lane,
    double progress,
    double phase,
    bool running,
  ) {
    canvas.drawRect(
      lane,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x10000000),
            Color(0x00000000),
            Color(0x23000000),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(lane),
    );

    if (!running) return;
    final dustPaint = Paint()..color = Colors.white.withValues(alpha: 0.2);
    for (var particle = 0; particle < 10; particle++) {
      final seed = particle * 0.618 + progress * 9 + lane.left * 0.01;
      final x = lane.left + ((seed + cameraPhase * 0.33) % 1) * lane.width;
      final y =
          lane.top +
          lane.height * (0.52 + ((seed * 1.91 + cameraPhase) % 1) * 0.35);
      final radius = 0.6 + ((particle * 7) % 4) * 0.45;
      canvas.drawCircle(
        Offset(x, y + math.sin(phase + seed) * 3),
        radius,
        dustPaint,
      );
    }
  }

  void _paintHorse(
    Canvas canvas,
    Rect lane,
    Horse horse,
    double gallopOffset,
    double sway,
    bool running,
  ) {
    final sheets = artwork?.horseSheets[horse.id];
    if (sheets == null || sheets.length < 2) return;

    final framePosition = running
        ? (horsePhase * _horseFrameCount + horse.id * 0.67) % _horseFrameCount
        : 0.0;
    final frameIndex = framePosition.floor();
    final nextFrameIndex = (frameIndex + 1) % _horseFrameCount;
    final frameProgress = framePosition - frameIndex;
    // Hold each pose for most of its 250 ms slot. Cross-fade only near the end
    // so the mane and ears remain readable instead of constantly ghosting.
    final transitionProgress = ((frameProgress - 0.6) / 0.4)
        .clamp(0.0, 1.0)
        .toDouble();
    final frameBlend =
        transitionProgress * transitionProgress * (3 - 2 * transitionProgress);
    final horseWidth = lane.width * (lane.height < 170 ? 1.02 : 1.18);
    final horseHeight = horseWidth;
    final horseTop = lane.bottom - horseHeight * 0.79 + gallopOffset;
    final horseRect = Rect.fromLTWH(
      lane.center.dx - horseWidth / 2 + sway,
      horseTop,
      horseWidth,
      horseHeight,
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(lane.center.dx, lane.bottom - horseHeight * 0.08),
      width: horseWidth * 0.72,
      height: horseHeight * 0.12,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    _paintHorseFrame(
      canvas,
      sheets,
      frameIndex,
      horseRect,
      opacity: running ? 1 - frameBlend : 1,
    );
    if (running && frameBlend > 0) {
      _paintHorseFrame(
        canvas,
        sheets,
        nextFrameIndex,
        horseRect,
        opacity: frameBlend,
      );
    }
  }

  void _paintHorseFrame(
    Canvas canvas,
    List<ui.Image> sheets,
    int frame,
    Rect destination, {
    double opacity = 1,
  }) {
    final sheetIndex = frame ~/ _horseFramesPerSheet;
    final localFrame = frame % _horseFramesPerSheet;
    final sheet = sheets[sheetIndex];
    final cellWidth = sheet.width / _horseSheetColumns;
    final cellHeight = sheet.height / _horseSheetRows;
    final column = localFrame % _horseSheetColumns;
    final row = localFrame ~/ _horseSheetColumns;
    const sourceInset = 0.75;
    final source = Rect.fromLTRB(
      column * cellWidth + sourceInset,
      row * cellHeight + sourceInset,
      (column + 1) * cellWidth - sourceInset,
      (row + 1) * cellHeight - sourceInset,
    );
    canvas.drawImageRect(
      sheet,
      source,
      destination,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  void _paintTopHud(Canvas canvas, Rect lane, Horse horse, double speed) {
    final compact = lane.width < 150 || lane.height < 180;
    final hudHeight = math.min(lane.height * 0.29, compact ? 47.0 : 74.0);
    canvas.drawRect(
      Rect.fromLTWH(lane.left, lane.top, lane.width, hudHeight),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xE80A0F15),
                Color(0x9C0A0F15),
                Color(0x000A0F15),
              ],
            ).createShader(
              Rect.fromLTWH(lane.left, lane.top, lane.width, hudHeight),
            ),
    );

    final badgeSize = compact ? 28.0 : math.min(48.0, lane.width * 0.2);
    final badge = RRect.fromRectAndRadius(
      Rect.fromLTWH(lane.left + 8, lane.top + 7, badgeSize, badgeSize),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      badge,
      Paint()..color = horse.primaryColor.withValues(alpha: 0.93),
    );
    canvas.drawRRect(
      badge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = horse.secondaryColor,
    );
    _drawText(
      canvas,
      '${horse.id}',
      badge.center,
      size: compact ? 16 : 25,
      color: Colors.white,
      weight: FontWeight.w900,
    );

    final textLeft = badge.right + (compact ? 5 : 8);
    final available = math.max(1.0, lane.right - textLeft - 5);
    if (!compact) {
      _drawTextAt(
        canvas,
        'ĐƯỜNG ĐUA ${horse.id}',
        Offset(textLeft, lane.top + 10),
        maxWidth: available,
        size: math.min(13, lane.width * 0.055),
        color: Colors.white,
        weight: FontWeight.w900,
      );
    }
    _drawTextAt(
      canvas,
      speed > 0 ? '${speed.round()} km/h' : 'SẴN SÀNG',
      Offset(textLeft, lane.top + (compact ? 13 : 36)),
      maxWidth: available,
      size: compact ? 8.5 : math.min(16, lane.width * 0.068),
      color: speed > 0 ? Colors.white : const Color(0xFFD8D6D0),
      weight: FontWeight.w800,
    );

    canvas.drawRect(
      Rect.fromLTWH(lane.left, lane.top + hudHeight - 2, lane.width, 2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            horse.primaryColor,
            horse.secondaryColor,
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(lane.left, lane.top, lane.width, 2)),
    );
  }

  void _paintBottomHud(Canvas canvas, Rect lane, Horse horse, double progress) {
    final compact = lane.width < 150 || lane.height < 180;
    final hudHeight = compact ? 30.0 : math.min(62.0, lane.height * 0.22);
    final rect = Rect.fromLTWH(
      lane.left + (compact ? 3 : 8),
      lane.bottom - hudHeight - (compact ? 3 : 7),
      lane.width - (compact ? 6 : 16),
      hudHeight,
    );
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(panel, Paint()..color = const Color(0xD7161A1E));
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = horse.primaryColor.withValues(alpha: 0.95),
    );

    final remaining = ((1 - progress) * raceDistanceMeters).ceil();
    if (!compact) {
      _drawTextAt(
        canvas,
        'CÒN LẠI',
        Offset(rect.left + 9, rect.top + 5),
        maxWidth: rect.width * 0.42,
        size: 8,
        color: const Color(0xFFD5D5CF),
        weight: FontWeight.w800,
      );
    }
    _drawTextAt(
      canvas,
      '$remaining m',
      Offset(rect.left + (compact ? 5 : 9), rect.top + (compact ? 5 : 20)),
      maxWidth: rect.width * 0.48,
      size: compact ? 8 : math.min(18, lane.width * 0.075),
      color: Colors.white,
      weight: FontWeight.w900,
    );

    final rail = Rect.fromLTWH(
      rect.left + rect.width * (compact ? 0.5 : 0.54),
      rect.bottom - (compact ? 11 : 17),
      rect.width * (compact ? 0.43 : 0.4),
      compact ? 5 : 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, const Radius.circular(4)),
      Paint()..color = const Color(0xFF44484B),
    );
    if (progress > 0) {
      final fill = Rect.fromLTWH(
        rail.left,
        rail.top,
        rail.width * progress,
        rail.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(4)),
        Paint()
          ..shader = LinearGradient(
            colors: [horse.primaryColor, horse.secondaryColor],
          ).createShader(fill),
      );
    }
    _drawText(
      canvas,
      '⚑',
      Offset(rail.right, rail.top - (compact ? 5 : 8)),
      size: compact ? 9 : 14,
      color: Colors.white,
      weight: FontWeight.w900,
    );
  }

  void _paintWinner(Canvas canvas, Rect lane, Horse horse) {
    final banner = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lane.center.dx, lane.top + lane.height * 0.35),
        width: lane.width * 0.72,
        height: math.min(39, lane.height * 0.14),
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      banner,
      Paint()
        ..color = const Color(0xEB111418)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(
      banner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = horse.secondaryColor,
    );
    _drawText(
      canvas,
      'VỀ NHẤT',
      banner.center,
      size: math.min(15, lane.width * 0.07),
      color: const Color(0xFFFFE8A7),
      weight: FontWeight.w900,
    );
  }

  void _paintFallbackTrack(Canvas canvas, Rect lane, Horse horse) {
    canvas.drawRect(
      lane,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF345A7C), Color(0xFFF2A459), Color(0xFF815037)],
        ).createShader(lane),
    );
    final horizon = lane.top + lane.height * 0.43;
    final road = Path()
      ..moveTo(lane.center.dx - lane.width * 0.09, horizon)
      ..lineTo(lane.center.dx + lane.width * 0.09, horizon)
      ..lineTo(lane.right, lane.bottom)
      ..lineTo(lane.left, lane.bottom)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF9E6038));
    canvas.drawLine(
      Offset(lane.left, lane.bottom),
      Offset(lane.center.dx, horizon),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(lane.right, lane.bottom),
      Offset(lane.center.dx, horizon),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(lane.center.dx, horizon),
      3,
      Paint()..color = horse.secondaryColor,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1,
          shadows: const [Shadow(blurRadius: 5, color: Colors.black87)],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  void _drawTextAt(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required double size,
    required Color color,
    required FontWeight weight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _RaceRiderPainter oldDelegate) {
    return horses != oldDelegate.horses ||
        !mapEquals(progressMap, oldDelegate.progressMap) ||
        !mapEquals(speedMap, oldDelegate.speedMap) ||
        raceDistanceMeters != oldDelegate.raceDistanceMeters ||
        winnerHorseId != oldDelegate.winnerHorseId ||
        isRacing != oldDelegate.isRacing ||
        stepTick != oldDelegate.stepTick ||
        countdown != oldDelegate.countdown ||
        cameraPhase != oldDelegate.cameraPhase ||
        horsePhase != oldDelegate.horsePhase ||
        reduceMotion != oldDelegate.reduceMotion ||
        artwork != oldDelegate.artwork;
  }
}
