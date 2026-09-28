import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/horse_model.dart';

/// Original, resolution-independent racehorse illustration.
///
/// Paints facing right inside a 600 x 360 design space. The standing ground is
/// y=335. [phase] is a continuous gallop angle in radians, independent of race
/// progress. Every limb has its own shoulder/hip, elbow/stifle, knee/hock and
/// fetlock; the two pairs follow the asymmetric sequence of a running gallop.
class RaceHorseArtist {
  RaceHorseArtist._();

  static const Size designSize = Size(600, 360);
  static const double groundY = 335;
  static const _ink = Color(0xFF271B1B);
  static const _leather = Color(0xFF302227);
  static const _cream = Color(0xFFFFF2CE);
  static final Map<int, TextPainter> _numbers = {};

  static void paint(
    Canvas canvas, {
    required Horse horse,
    required double phase,
    required bool isRacing,
  }) {
    final coat = _Coat.forHorse(horse.id);
    final cycle = isRacing ? phase : 0.0;
    final lift = isRacing ? -9.6 - 3.2 * math.sin(cycle * 2) : 0.0;

    canvas.save();
    canvas.translate(300, 170 + lift);
    canvas.rotate(isRacing ? math.sin(cycle) * 0.012 : 0);
    canvas.translate(-300, -170);

    _tail(canvas, coat, cycle, isRacing);
    _leg(
      canvas,
      coat,
      _hindPose(cycle + 0.68, isRacing, far: true),
      far: true,
      rear: true,
    );
    _leg(
      canvas,
      coat,
      _frontPose(cycle + 0.58, isRacing, far: true),
      far: true,
      rear: false,
    );
    _mane(canvas, coat, cycle, isRacing);
    _leg(
      canvas,
      coat,
      _hindPose(cycle, isRacing, far: false),
      far: false,
      rear: true,
    );
    _leg(
      canvas,
      coat,
      _frontPose(cycle, isRacing, far: false),
      far: false,
      rear: false,
      sock: horse.id != 2,
    );
    _body(canvas, coat);
    _face(canvas, coat, horse);
    _tack(canvas, horse);
    _jockey(canvas, horse, cycle, isRacing);
    canvas.restore();
  }

  static void _shape(
    Canvas canvas,
    Path path,
    Color color, {
    double outline = 0,
    Color? edge,
  }) {
    canvas.drawPath(path, Paint()..color = color);
    if (outline > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = edge ?? _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = outline
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static void _line(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _tail(Canvas canvas, _Coat coat, double phase, bool racing) {
    final sweep = racing ? math.sin(phase + 0.4) * 10 : 18.0;
    final tail = Path()
      ..moveTo(155, 145)
      ..cubicTo(126, 139, 107, 170, 82, 180 + sweep)
      ..cubicTo(53, 191 + sweep, 34, 186 + sweep, 20, 217 + sweep)
      ..cubicTo(39, 204 + sweep, 49, 208 + sweep, 62, 201 + sweep)
      ..cubicTo(40, 218 + sweep, 31, 229 + sweep, 29, 244 + sweep)
      ..cubicTo(47, 227 + sweep, 66, 220 + sweep, 80, 207 + sweep)
      ..cubicTo(69, 225 + sweep, 54, 232 + sweep, 48, 247 + sweep)
      ..cubicTo(84, 229 + sweep, 88, 211 + sweep, 105, 201 + sweep)
      ..cubicTo(126, 187, 138, 167, 159, 162)
      ..close();
    _shape(canvas, tail, coat.hair, outline: 1.5);
    _line(
      canvas,
      Path()
        ..moveTo(144, 150)
        ..cubicTo(107, 156, 102, 195 + sweep, 49, 209 + sweep),
      coat.hairLight,
      4,
    );
    _line(
      canvas,
      Path()
        ..moveTo(127, 166)
        ..cubicTo(104, 185, 107, 210 + sweep, 66, 231 + sweep),
      coat.hairLight.withValues(alpha: 0.5),
      2,
    );
  }

  static void _mane(Canvas canvas, _Coat coat, double phase, bool racing) {
    final wind = racing ? math.sin(phase + 0.7) * 3.5 : 0.0;
    final mane = Path()
      ..moveTo(489, 72)
      ..cubicTo(468, 47, 438, 54, 418, 63)
      ..lineTo(438, 63)
      ..cubicTo(412, 66, 402, 72, 386, 75 + wind)
      ..lineTo(409, 76)
      ..lineTo(371, 89 + wind)
      ..lineTo(390, 88)
      ..lineTo(352, 107 + wind)
      ..lineTo(376, 101)
      ..lineTo(350, 120 + wind)
      ..cubicTo(389, 106, 414, 82, 449, 75)
      ..lineTo(479, 83)
      ..close();
    _shape(canvas, mane, coat.hair);
    for (var i = 0; i < 4; i++) {
      _line(
        canvas,
        Path()
          ..moveTo(477 - i * 7, 65 + i * 2)
          ..quadraticBezierTo(
            444 - i * 10,
            54 + i * 7,
            421 - i * 15,
            66 + i * 10 + wind,
          ),
        coat.hairLight,
        i == 0 ? 2.8 : 1.8,
      );
    }
  }

  static void _body(Canvas canvas, _Coat coat) {
    final silhouette = Path()
      ..moveTo(147, 144)
      ..cubicTo(162, 125, 188, 120, 219, 124)
      ..cubicTo(251, 125, 267, 133, 298, 134)
      ..cubicTo(333, 137, 355, 126, 382, 105)
      ..cubicTo(413, 80, 442, 59, 465, 62)
      ..cubicTo(484, 60, 497, 77, 510, 90)
      ..cubicTo(527, 101, 547, 109, 562, 119)
      ..cubicTo(573, 122, 579, 134, 572, 143)
      ..cubicTo(566, 151, 554, 148, 543, 141)
      ..lineTo(514, 124)
      ..cubicTo(502, 136, 487, 130, 477, 121)
      ..cubicTo(469, 148, 449, 171, 439, 190)
      ..cubicTo(433, 214, 417, 226, 395, 225)
      ..cubicTo(363, 224, 348, 219, 322, 223)
      ..cubicTo(282, 236, 257, 234, 235, 224)
      ..cubicTo(218, 218, 203, 213, 192, 207)
      ..cubicTo(174, 220, 151, 218, 141, 203)
      ..cubicTo(130, 184, 132, 161, 147, 144)
      ..close();
    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [coat.light, coat.base, coat.base, coat.shadow],
          stops: const [0, 0.35, 0.68, 1],
        ).createShader(const Rect.fromLTWH(133, 61, 443, 175)),
    );
    _line(canvas, silhouette, coat.outline, 2.6);

    // The croup, ribcage, scapula and throat are large connected planes.
    _shape(
      canvas,
      Path()
        ..moveTo(146, 177)
        ..cubicTo(145, 144, 182, 127, 215, 133)
        ..cubicTo(241, 136, 247, 142, 266, 143)
        ..cubicTo(221, 140, 203, 144, 185, 156)
        ..cubicTo(166, 169, 163, 192, 157, 202)
        ..cubicTo(149, 197, 145, 186, 146, 177)
        ..close(),
      coat.light,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(172, 155)
        ..cubicTo(201, 140, 223, 146, 240, 157)
        ..cubicTo(216, 159, 202, 178, 199, 198)
        ..cubicTo(183, 206, 170, 207, 159, 202)
        ..cubicTo(171, 188, 162, 172, 172, 155)
        ..close(),
      coat.base,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(157, 208)
        ..cubicTo(185, 216, 199, 189, 219, 185)
        ..cubicTo(207, 199, 211, 207, 240, 217)
        ..cubicTo(277, 228, 306, 211, 332, 211)
        ..cubicTo(359, 211, 389, 219, 406, 217)
        ..cubicTo(389, 230, 354, 216, 322, 224)
        ..cubicTo(285, 236, 257, 233, 234, 224)
        ..lineTo(190, 207)
        ..cubicTo(178, 216, 166, 219, 157, 208)
        ..close(),
      coat.shadow,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(341, 154)
        ..cubicTo(371, 139, 399, 117, 433, 92)
        ..cubicTo(448, 79, 460, 73, 471, 75)
        ..cubicTo(440, 97, 424, 133, 408, 154)
        ..cubicTo(390, 179, 367, 184, 351, 181)
        ..close(),
      coat.light,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(438, 105)
        ..cubicTo(451, 97, 466, 83, 478, 84)
        ..cubicTo(471, 104, 475, 119, 463, 140)
        ..cubicTo(452, 158, 431, 177, 428, 190)
        ..cubicTo(430, 175, 433, 161, 446, 142)
        ..cubicTo(456, 126, 456, 114, 438, 105)
        ..close(),
      coat.shadow.withValues(alpha: 0.73),
    );
    _shape(
      canvas,
      Path()
        ..moveTo(386, 169)
        ..cubicTo(406, 154, 424, 158, 430, 174)
        ..cubicTo(434, 194, 422, 211, 407, 216)
        ..cubicTo(412, 200, 411, 187, 401, 182)
        ..lineTo(377, 182)
        ..close(),
      coat.shadow,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(382, 168)
        ..cubicTo(399, 154, 414, 161, 419, 175)
        ..cubicTo(407, 171, 395, 173, 387, 180)
        ..lineTo(374, 181)
        ..close(),
      coat.light,
    );
    _line(
      canvas,
      Path()
        ..moveTo(158, 195)
        ..cubicTo(176, 196, 175, 168, 193, 159)
        ..cubicTo(209, 150, 218, 151, 227, 153),
      coat.outline.withValues(alpha: 0.65),
      2.1,
    );
    _line(
      canvas,
      Path()
        ..moveTo(360, 155)
        ..cubicTo(375, 144, 385, 127, 404, 114),
      coat.highlight.withValues(alpha: 0.75),
      3.2,
    );
    _line(
      canvas,
      Path()
        ..moveTo(418, 154)
        ..quadraticBezierTo(435, 141, 441, 122),
      coat.outline.withValues(alpha: 0.6),
      2.2,
    );
    // A thin reflected rim keeps the chest and haunch legible on dark tracks.
    _line(
      canvas,
      Path()
        ..moveTo(152, 142)
        ..cubicTo(173, 124, 193, 126, 219, 128),
      coat.highlight,
      2.3,
    );
  }

  static void _face(Canvas canvas, _Coat coat, Horse horse) {
    final farEar = Path()
      ..moveTo(470, 69)
      ..quadraticBezierTo(464, 51, 471, 40)
      ..quadraticBezierTo(482, 46, 483, 66)
      ..close();
    _shape(canvas, farEar, coat.shadow, outline: 1.5);
    final ear = Path()
      ..moveTo(482, 69)
      ..quadraticBezierTo(481, 50, 491, 39)
      ..quadraticBezierTo(498, 53, 492, 74)
      ..close();
    _shape(canvas, ear, coat.base, outline: 1.8);
    _shape(
      canvas,
      Path()
        ..moveTo(487, 63)
        ..lineTo(491, 48)
        ..quadraticBezierTo(494, 56, 490, 65)
        ..close(),
      coat.shadow,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(478, 75)
        ..quadraticBezierTo(489, 62, 500, 80)
        ..lineTo(486, 81)
        ..lineTo(494, 90)
        ..quadraticBezierTo(480, 85, 478, 75)
        ..close(),
      coat.hair,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(502, 94)
        ..cubicTo(524, 104, 540, 117, 553, 123)
        ..lineTo(545, 126)
        ..cubicTo(529, 118, 515, 110, 502, 101)
        ..close(),
      horse.id == 3 ? const Color(0xFFFFFBEE) : coat.highlight,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(489, 100)
        ..cubicTo(496, 107, 499, 119, 510, 123)
        ..cubicTo(499, 132, 487, 124, 484, 116)
        ..close(),
      coat.shadow,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(552, 120)
        ..cubicTo(564, 122, 575, 129, 572, 139)
        ..cubicTo(569, 148, 558, 146, 547, 138)
        ..quadraticBezierTo(544, 127, 552, 120)
        ..close(),
      coat.muzzle,
    );
    // Small almond eye, brow ridge and a recessed nostril.
    _shape(
      canvas,
      Path()
        ..moveTo(494, 91)
        ..quadraticBezierTo(502, 86, 506, 94)
        ..quadraticBezierTo(501, 99, 496, 96)
        ..close(),
      _ink,
    );
    canvas.drawCircle(
      const Offset(502, 92),
      1.45,
      Paint()..color = const Color(0xFFFFE9C5),
    );
    _line(
      canvas,
      Path()
        ..moveTo(492, 86)
        ..quadraticBezierTo(500, 83, 506, 89),
      coat.highlight,
      2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(556, 126)
        ..cubicTo(562, 123, 567, 129, 565, 134)
        ..cubicTo(562, 136, 561, 129, 556, 130)
        ..close(),
      _ink,
    );
    _line(
      canvas,
      Path()
        ..moveTo(554, 140)
        ..quadraticBezierTo(563, 143, 569, 139),
      _ink,
      2.0,
    );
    _line(
      canvas,
      Path()
        ..moveTo(548, 120)
        ..quadraticBezierTo(558, 117, 564, 124),
      coat.light,
      2,
    );
  }

  static void _tack(Canvas canvas, Horse horse) {
    final cloth = Path()
      ..moveTo(252, 127)
      ..cubicTo(281, 129, 306, 135, 327, 129)
      ..lineTo(344, 179)
      ..cubicTo(320, 190, 280, 187, 246, 175)
      ..close();
    canvas.drawPath(
      cloth,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [horse.secondaryColor, horse.primaryColor],
        ).createShader(const Rect.fromLTWH(246, 127, 98, 60)),
    );
    _line(canvas, cloth, _cream, 2.6);
    _line(
      canvas,
      Path()
        ..moveTo(250, 170)
        ..quadraticBezierTo(303, 188, 339, 176),
      horse.primaryColor.withValues(alpha: 0.8),
      3,
    );
    final number = _numbers.putIfAbsent(
      horse.id,
      () => TextPainter(
        text: TextSpan(
          text: '${horse.id}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 37,
            height: 1,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x55302020), offset: Offset(1.5, 2))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    number.paint(canvas, Offset(282 - number.width / 2, 142));

    _shape(
      canvas,
      Path()
        ..moveTo(326, 136)
        ..lineTo(337, 138)
        ..quadraticBezierTo(342, 180, 353, 223)
        ..lineTo(339, 224)
        ..quadraticBezierTo(334, 180, 326, 136)
        ..close(),
      _leather,
      outline: 1.5,
    );
    _line(
      canvas,
      Path()
        ..moveTo(329, 145)
        ..lineTo(343, 216),
      const Color(0xFF835C49),
      2.4,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(257, 121)
        ..quadraticBezierTo(278, 126, 302, 123)
        ..quadraticBezierTo(323, 117, 334, 130)
        ..lineTo(327, 140)
        ..quadraticBezierTo(295, 130, 265, 138)
        ..close(),
      _leather,
      outline: 1.6,
    );
    _line(
      canvas,
      Path()
        ..moveTo(264, 126)
        ..quadraticBezierTo(296, 132, 320, 126),
      const Color(0xFF997B63),
      2.1,
    );

    final bridle = horse.id == 1
        ? const Color(0xFFCA3E29)
        : Color.lerp(horse.primaryColor, _ink, 0.33)!;
    _line(
      canvas,
      Path()
        ..moveTo(481, 74)
        ..lineTo(503, 111)
        ..lineTo(544, 137),
      _ink,
      8,
    );
    _line(
      canvas,
      Path()
        ..moveTo(481, 74)
        ..lineTo(503, 111)
        ..lineTo(544, 137),
      bridle,
      5.2,
    );
    _line(
      canvas,
      Path()
        ..moveTo(483, 79)
        ..quadraticBezierTo(480, 110, 491, 125)
        ..lineTo(503, 111),
      _leather,
      4,
    );
    _line(
      canvas,
      Path()
        ..moveTo(551, 112)
        ..quadraticBezierTo(536, 122, 539, 136),
      bridle,
      7,
    );
    _line(
      canvas,
      Path()
        ..moveTo(553, 114)
        ..quadraticBezierTo(543, 120, 542, 128),
      horse.secondaryColor,
      1.8,
    );
    canvas.drawCircle(
      const Offset(545, 137),
      5.8,
      Paint()
        ..color = const Color(0xFFF6EACB)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final point in [const Offset(485, 81), const Offset(503, 111)]) {
      canvas.drawCircle(point, 2.2, Paint()..color = _cream);
    }
  }

  static void _jockey(Canvas canvas, Horse horse, double phase, bool racing) {
    final rise = racing ? math.sin(phase * 2 + 0.6) * 2.5 : 0.0;
    final silk = switch (horse.id) {
      1 => const Color(0xFFFFCC38),
      2 => const Color(0xFF2EB894),
      _ => const Color(0xFFF4F7F5),
    };
    final silkShadow = Color.lerp(silk, const Color(0xFF6B4227), 0.27)!;
    final accent = horse.id == 2 ? const Color(0xFFFFCE50) : horse.primaryColor;
    final hand = Offset(411, 106 + rise);

    // Both reins run all the way from the bit into the gloved hands.
    final reins = Path()
      ..moveTo(542, 136)
      ..quadraticBezierTo(469, 139, hand.dx, hand.dy)
      ..moveTo(541, 140)
      ..quadraticBezierTo(469, 153, hand.dx - 5, hand.dy + 3);
    _line(canvas, reins, _ink, 3.6);
    _line(canvas, reins, const Color(0xFFBDA084), 1.1);

    canvas.save();
    canvas.translate(0, rise);
    // Far boot and calf appear on the opposite side of the saddle.
    _shape(
      canvas,
      Path()
        ..moveTo(313, 114)
        ..lineTo(338, 137)
        ..lineTo(326, 164)
        ..lineTo(317, 161)
        ..lineTo(321, 139)
        ..lineTo(300, 128)
        ..close(),
      const Color(0xFF35262A),
      outline: 1.7,
    );

    // Folded breeches: raised hips, thigh forward, lower leg tucked back.
    _shape(
      canvas,
      Path()
        ..moveTo(279, 95)
        ..cubicTo(295, 92, 316, 108, 337, 120)
        ..cubicTo(345, 126, 343, 135, 333, 140)
        ..lineTo(306, 166)
        ..lineTo(292, 158)
        ..lineTo(317, 129)
        ..cubicTo(300, 126, 282, 126, 274, 117)
        ..close(),
      _cream,
      outline: 2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(282, 113)
        ..quadraticBezierTo(309, 115, 330, 127)
        ..lineTo(301, 159)
        ..lineTo(293, 156)
        ..lineTo(317, 130)
        ..quadraticBezierTo(295, 127, 281, 119)
        ..close(),
      const Color(0xFFCDBB9E),
    );
    _shape(
      canvas,
      Path()
        ..moveTo(299, 147)
        ..lineTo(314, 153)
        ..lineTo(301, 176)
        ..lineTo(308, 178)
        ..quadraticBezierTo(315, 184, 309, 187)
        ..lineTo(285, 184)
        ..lineTo(286, 174)
        ..close(),
      _leather,
      outline: 2,
    );
    _line(
      canvas,
      Path()
        ..moveTo(302, 153)
        ..lineTo(293, 175)
        ..lineTo(290, 178),
      const Color(0xFFA17A61),
      3,
    );
    _line(
      canvas,
      Path()
        ..moveTo(321, 133)
        ..lineTo(308, 179)
        ..quadraticBezierTo(307, 194, 287, 187)
        ..lineTo(288, 177),
      const Color(0xFFDFD9C8),
      2.2,
    );

    // Aerodynamic racing crouch with curved shoulders and a fitted silk.
    final jersey = Path()
      ..moveTo(275, 109)
      ..cubicTo(263, 97, 274, 72, 293, 55)
      ..cubicTo(305, 43, 326, 39, 341, 45)
      ..lineTo(353, 62)
      ..cubicTo(338, 75, 323, 88, 316, 105)
      ..cubicTo(304, 116, 286, 117, 275, 109)
      ..close();
    _shape(canvas, jersey, silk, outline: 2.2);
    _shape(
      canvas,
      Path()
        ..moveTo(277, 88)
        ..cubicTo(282, 103, 297, 108, 319, 97)
        ..lineTo(316, 106)
        ..cubicTo(302, 119, 279, 114, 275, 106)
        ..close(),
      silkShadow,
    );
    canvas.save();
    canvas.clipPath(jersey);
    for (var i = 0; i < 3; i++) {
      final x = 279.0 + i * 21;
      _shape(
        canvas,
        Path()
          ..moveTo(x, 43)
          ..lineTo(x + 10, 39)
          ..cubicTo(x + 10, 60, x + 13, 73, x + 25, 86)
          ..lineTo(x + 14, 93)
          ..cubicTo(x + 2, 76, x, 61, x, 43)
          ..close(),
        accent,
      );
    }
    canvas.restore();
    _line(
      canvas,
      Path()
        ..moveTo(286, 64)
        ..quadraticBezierTo(304, 45, 325, 46),
      Colors.white.withValues(alpha: 0.65),
      2.2,
    );

    // Neck, profile, jaw and helmet: much smaller than the horse's head.
    _shape(
      canvas,
      Path()
        ..moveTo(340, 51)
        ..lineTo(350, 42)
        ..lineTo(366, 55)
        ..lineTo(351, 68)
        ..close(),
      const Color(0xFFB9764C),
      outline: 1.5,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(348, 33)
        ..cubicTo(358, 24, 376, 28, 381, 41)
        ..lineTo(380, 49)
        ..lineTo(385, 53)
        ..lineTo(379, 57)
        ..lineTo(376, 66)
        ..quadraticBezierTo(365, 69, 352, 53)
        ..close(),
      const Color(0xFFE8AF75),
      outline: 1.8,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(349, 38)
        ..lineTo(357, 42)
        ..lineTo(359, 54)
        ..lineTo(373, 66)
        ..quadraticBezierTo(361, 63, 352, 52)
        ..close(),
      const Color(0xFF9D593E),
    );
    // Helmet shell, seam, visor and chin strap.
    _shape(
      canvas,
      Path()
        ..moveTo(344, 37)
        ..cubicTo(341, 18, 355, 13, 366, 17)
        ..cubicTo(380, 20, 385, 29, 382, 43)
        ..quadraticBezierTo(362, 34, 344, 37)
        ..close(),
      accent,
      outline: 2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(349, 35)
        ..quadraticBezierTo(346, 19, 359, 17)
        ..lineTo(366, 17)
        ..quadraticBezierTo(357, 25, 359, 36)
        ..close(),
      _leather,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(348, 35)
        ..quadraticBezierTo(367, 33, 387, 43)
        ..lineTo(389, 47)
        ..quadraticBezierTo(369, 40, 348, 40)
        ..close(),
      _ink,
    );
    _line(
      canvas,
      Path()
        ..moveTo(355, 40)
        ..lineTo(360, 56)
        ..lineTo(371, 61),
      _leather,
      2.6,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(368, 42)
        ..lineTo(381, 46)
        ..lineTo(378, 53)
        ..lineTo(368, 49)
        ..close(),
      const Color(0xFF263946),
      outline: 1.6,
    );
    _line(
      canvas,
      Path()
        ..moveTo(370, 44)
        ..lineTo(377, 47),
      const Color(0xFFB6E5E9),
      1.5,
    );

    // Bent arm and a compact gloved hand follow the upper-body suspension.
    _shape(
      canvas,
      Path()
        ..moveTo(335, 59)
        ..cubicTo(344, 54, 351, 60, 351, 69)
        ..lineTo(356, 91)
        ..quadraticBezierTo(381, 98, 403, 99)
        ..lineTo(406, 112)
        ..cubicTo(383, 115, 357, 107, 346, 105)
        ..quadraticBezierTo(337, 99, 336, 90)
        ..lineTo(331, 72)
        ..quadraticBezierTo(330, 64, 335, 59)
        ..close(),
      silk,
      outline: 2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(338, 81)
        ..quadraticBezierTo(342, 102, 355, 101)
        ..lineTo(402, 108)
        ..lineTo(405, 113)
        ..quadraticBezierTo(373, 114, 346, 105)
        ..quadraticBezierTo(338, 99, 338, 81)
        ..close(),
      silkShadow,
    );
    _line(
      canvas,
      Path()
        ..moveTo(336, 67)
        ..quadraticBezierTo(340, 60, 345, 66)
        ..lineTo(350, 87),
      Colors.white.withValues(alpha: 0.6),
      2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(400, 99)
        ..lineTo(411, 99)
        ..lineTo(418, 103)
        ..quadraticBezierTo(423, 111, 417, 114)
        ..lineTo(405, 112)
        ..close(),
      _leather,
      outline: 1.7,
    );
    _line(
      canvas,
      Path()
        ..moveTo(405, 102)
        ..lineTo(413, 102)
        ..lineTo(416, 106),
      const Color(0xFFB49D79),
      1.6,
    );
    canvas.restore();
  }

  static _LegPose _frontPose(double phase, bool racing, {required bool far}) {
    final shift = far ? const Offset(-17, -3) : Offset.zero;
    if (!racing) {
      return _LegPose(
        const Offset(402, 172) + shift,
        const Offset(409, 223) + shift,
        Offset(far ? 397 : 411, 270),
        Offset(far ? 384 : 410, 322),
      );
    }
    const poses = [
      _LegPose(
        Offset(402, 172),
        Offset(421, 216),
        Offset(475, 245),
        Offset(550, 274),
      ),
      _LegPose(
        Offset(402, 172),
        Offset(430, 217),
        Offset(471, 266),
        Offset(477, 321),
      ),
      _LegPose(
        Offset(402, 172),
        Offset(403, 230),
        Offset(397, 280),
        Offset(365, 321),
      ),
      _LegPose(
        Offset(402, 172),
        Offset(378, 228),
        Offset(350, 261),
        Offset(321, 275),
      ),
      _LegPose(
        Offset(402, 172),
        Offset(399, 213),
        Offset(420, 235),
        Offset(377, 248),
      ),
      _LegPose(
        Offset(402, 172),
        Offset(427, 209),
        Offset(462, 210),
        Offset(438, 237),
      ),
    ];
    return _LegPose.sample(poses, phase).shift(shift);
  }

  static _LegPose _hindPose(double phase, bool racing, {required bool far}) {
    final shift = far ? const Offset(15, -4) : Offset.zero;
    if (!racing) {
      return _LegPose(
        const Offset(186, 171) + shift,
        const Offset(196, 225) + shift,
        Offset(far ? 175 : 160, 267),
        Offset(far ? 180 : 148, 322),
      );
    }
    const poses = [
      _LegPose(
        Offset(186, 171),
        Offset(174, 217),
        Offset(116, 252),
        Offset(52, 292),
      ),
      _LegPose(
        Offset(186, 171),
        Offset(194, 225),
        Offset(151, 256),
        Offset(114, 267),
      ),
      _LegPose(
        Offset(186, 171),
        Offset(229, 213),
        Offset(217, 259),
        Offset(258, 278),
      ),
      _LegPose(
        Offset(186, 171),
        Offset(239, 216),
        Offset(252, 272),
        Offset(278, 320),
      ),
      _LegPose(
        Offset(186, 171),
        Offset(204, 228),
        Offset(174, 275),
        Offset(173, 322),
      ),
      _LegPose(
        Offset(186, 171),
        Offset(170, 221),
        Offset(114, 262),
        Offset(102, 316),
      ),
    ];
    return _LegPose.sample(poses, phase).shift(shift);
  }

  static void _leg(
    Canvas canvas,
    _Coat coat,
    _LegPose pose, {
    required bool far,
    required bool rear,
    bool sock = false,
  }) {
    final nodes = [pose.root, pose.upper, pose.knee, pose.ankle];
    final widths = rear ? [25.0, 16.5, 7.2, 5.2] : [24.0, 14.0, 7.2, 5.1];
    final leg = _taperedLimb(nodes, widths);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: far
            ? [coat.shadow, coat.outline]
            : [coat.base, coat.base, coat.shadow],
      ).createShader(leg.getBounds());
    canvas.drawPath(leg, paint);
    _line(canvas, leg, coat.outline, 2.1);

    if (!far) {
      final tendon = Path()
        ..moveTo(pose.upper.dx - 4, pose.upper.dy)
        ..quadraticBezierTo(
          pose.knee.dx - 3,
          pose.knee.dy - 8,
          pose.knee.dx,
          pose.knee.dy,
        )
        ..lineTo(pose.ankle.dx - 1.5, pose.ankle.dy - 3);
      _line(canvas, tendon, coat.light, 3.4);
      if (sock) {
        final start = Offset.lerp(pose.knee, pose.ankle, 0.64)!;
        _shape(
          canvas,
          _taperedLimb([start, pose.ankle], [5.6, 5.1]),
          const Color(0xFFEEE1C8),
        );
      }
    }

    final direction = pose.ankle - pose.knee;
    final hoofTilt = (direction.dx / math.max(direction.distance, 1)) * -0.65;
    canvas.save();
    canvas.translate(pose.ankle.dx, pose.ankle.dy);
    canvas.rotate(hoofTilt);
    final hoof = Path()
      ..moveTo(-5.8, -2.5)
      ..lineTo(5.7, -2)
      ..quadraticBezierTo(7.5, 5.5, 13.5, 8)
      ..lineTo(13, 12)
      ..lineTo(-8.5, 12)
      ..quadraticBezierTo(-9.5, 6, -5.8, -2.5)
      ..close();
    _shape(canvas, hoof, far ? _ink : const Color(0xFF352C2D), outline: 1.5);
    _line(
      canvas,
      Path()
        ..moveTo(-4, 2)
        ..lineTo(5, 2)
        ..lineTo(8, 5),
      far ? coat.shadow : const Color(0xFF9D8771),
      1.7,
    );
    canvas.restore();
  }

  /// Tapered curved contour around a chain of actual joints, with rounded
  /// transitions at knees and hocks instead of thick lines or separate ovals.
  static Path _taperedLimb(List<Offset> nodes, List<double> radii) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < nodes.length; i++) {
      final before = nodes[math.max(0, i - 1)];
      final after = nodes[math.min(nodes.length - 1, i + 1)];
      final tangent = after - before;
      final length = math.max(tangent.distance, 0.001);
      final normal = Offset(-tangent.dy / length, tangent.dx / length);
      left.add(nodes[i] + normal * radii[i]);
      right.add(nodes[i] - normal * radii[i]);
    }
    final outline = [...left, ...right.reversed];
    final first = Offset.lerp(outline.last, outline.first, 0.78)!;
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 0; i < outline.length; i++) {
      final previous = outline[(i - 1 + outline.length) % outline.length];
      final point = outline[i];
      final next = outline[(i + 1) % outline.length];
      final entry = Offset.lerp(previous, point, 0.78)!;
      final exit = Offset.lerp(point, next, 0.22)!;
      path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(point.dx, point.dy, exit.dx, exit.dy);
    }
    return path..close();
  }
}

class _LegPose {
  final Offset root;
  final Offset upper;
  final Offset knee;
  final Offset ankle;

  const _LegPose(this.root, this.upper, this.knee, this.ankle);

  _LegPose shift(Offset offset) =>
      _LegPose(root + offset, upper + offset, knee + offset, ankle + offset);

  static _LegPose sample(List<_LegPose> poses, double phase) {
    final position = (phase / (math.pi * 2) % 1) * poses.length;
    final index = position.floor();
    final t = position - index;
    final count = poses.length;
    final p0 = poses[(index - 1 + count) % count];
    final p1 = poses[index % count];
    final p2 = poses[(index + 1) % count];
    final p3 = poses[(index + 2) % count];
    // Cyclic Catmull-Rom preserves velocity through every stride keyframe.
    Offset interpolate(Offset a, Offset b, Offset c, Offset d) {
      return (b * 2 +
              (c - a) * t +
              (a * 2 - b * 5 + c * 4 - d) * t * t +
              (b * 3 - a - c * 3 + d) * t * t * t) *
          0.5;
    }

    return _LegPose(
      interpolate(p0.root, p1.root, p2.root, p3.root),
      interpolate(p0.upper, p1.upper, p2.upper, p3.upper),
      interpolate(p0.knee, p1.knee, p2.knee, p3.knee),
      interpolate(p0.ankle, p1.ankle, p2.ankle, p3.ankle),
    );
  }
}

class _Coat {
  final Color base;
  final Color light;
  final Color highlight;
  final Color shadow;
  final Color outline;
  final Color hair;
  final Color hairLight;
  final Color muzzle;

  const _Coat({
    required this.base,
    required this.light,
    required this.highlight,
    required this.shadow,
    required this.outline,
    required this.hair,
    required this.hairLight,
    required this.muzzle,
  });

  static _Coat forHorse(int id) => switch (id) {
    2 => const _Coat(
      base: Color(0xFFB57A32),
      light: Color(0xFFDEAC57),
      highlight: Color(0xFFFFD68E),
      shadow: Color(0xFF784623),
      outline: Color(0xFF452D20),
      hair: Color(0xFF31231E),
      hairLight: Color(0xFF765239),
      muzzle: Color(0xFF604638),
    ),
    3 => const _Coat(
      base: Color(0xFFCFD6D8),
      light: Color(0xFFF3F0E8),
      highlight: Color(0xFFFFFFFF),
      shadow: Color(0xFF81949E),
      outline: Color(0xFF405561),
      hair: Color(0xFF71848E),
      hairLight: Color(0xFFCFDBDD),
      muzzle: Color(0xFF88929B),
    ),
    _ => const _Coat(
      base: Color(0xFFA84F28),
      light: Color(0xFFD17B42),
      highlight: Color(0xFFF0AC66),
      shadow: Color(0xFF71331F),
      outline: Color(0xFF3B241F),
      hair: Color(0xFF301B1C),
      hairLight: Color(0xFF74412B),
      muzzle: Color(0xFF663721),
    ),
  };
}
