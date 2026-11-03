// Renders the flat wardrobe illustrations in assets/wardrobe/.
// Run with: flutter test tool/generate_wardrobe_art.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/features/wardrobe/data/seed_wardrobe.dart';
import 'package:wardrobe_app/shared/widgets/attribute_labels.dart';

const _size = Size(600, 800);

enum _Shape {
  knit,
  shirt,
  trousers,
  skirt,
  dress,
  coat,
  jacket,
  shoe,
  heel,
  boot,
  sneaker,
  tote,
  hat,
}

const _shapes = {
  'itm_cashmere_crew': _Shape.knit,
  'itm_poplin_shirt': _Shape.shirt,
  'itm_silk_blouse': _Shape.shirt,
  'itm_wool_trousers': _Shape.trousers,
  'itm_midi_skirt': _Shape.skirt,
  'itm_evening_dress': _Shape.dress,
  'itm_camel_coat': _Shape.coat,
  'itm_navy_blazer': _Shape.jacket,
  'itm_leather_loafers': _Shape.shoe,
  'itm_court_heels': _Shape.heel,
  'itm_leather_tote': _Shape.tote,
  'itm_linen_shirt': _Shape.shirt,
  'itm_linen_trousers': _Shape.trousers,
  'itm_sundress': _Shape.dress,
  'itm_canvas_sneakers': _Shape.sneaker,
  'itm_straw_hat': _Shape.hat,
  'itm_fisherman_knit': _Shape.knit,
  'itm_dark_jeans': _Shape.trousers,
  'itm_field_jacket': _Shape.jacket,
  'itm_chelsea_boots': _Shape.boot,
};

void main() {
  testWidgets('generate wardrobe art', (tester) async {
    await tester.runAsync(() async {
      for (final item in seedWardrobe) {
        final recorder = ui.PictureRecorder();
        _paint(Canvas(recorder), _shapes[item.id]!, item.color.swatch);
        final image = await recorder.endRecording().toImage(
          _size.width.toInt(),
          _size.height.toInt(),
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(item.imageAsset).writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}

Path _poly(List<Offset> points) => Path()..addPolygon(points, true);

Offset _o(double x, double y) => Offset(x, y);

void _paint(Canvas canvas, _Shape shape, Color color) {
  final background = Color.lerp(color, const Color(0xFFF2EEE8), 0.82)!;
  final outline = Color.lerp(color, Colors.black, 0.35)!;
  final detail = Color.lerp(color, Colors.black, 0.18)!;
  canvas.drawRect(Offset.zero & _size, Paint()..color = background);
  canvas.drawOval(
    Rect.fromCenter(center: _o(300, 720), width: 380, height: 36),
    Paint()..color = Colors.black.withValues(alpha: 0.07),
  );

  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeJoin = StrokeJoin.round;
  final line = Paint()
    ..color = detail
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;

  void draw(Path path) {
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);
  }

  final top = _poly([
    _o(245, 200),
    _o(355, 200),
    _o(450, 240),
    _o(505, 580),
    _o(445, 596),
    _o(410, 330),
    _o(410, 640),
    _o(190, 640),
    _o(190, 330),
    _o(155, 596),
    _o(95, 580),
    _o(150, 240),
  ]);

  const footwear = {_Shape.shoe, _Shape.heel, _Shape.boot, _Shape.sneaker};
  if (footwear.contains(shape)) {
    // Rest footwear on the floor shadow.
    canvas.translate(0, shape == _Shape.heel ? 65 : 120);
  }

  switch (shape) {
    case _Shape.knit:
      draw(top);
      canvas
        ..drawArc(
          Rect.fromCenter(center: _o(300, 200), width: 110, height: 70),
          0,
          3.14,
          false,
          line,
        )
        ..drawLine(_o(200, 615), _o(400, 615), line)
        ..drawLine(_o(110, 560), _o(160, 572), line)
        ..drawLine(_o(440, 572), _o(490, 560), line);
    case _Shape.shirt:
      draw(top);
      draw(_poly([_o(245, 200), _o(300, 260), _o(270, 285)]));
      draw(_poly([_o(355, 200), _o(300, 260), _o(330, 285)]));
      canvas.drawLine(_o(300, 260), _o(300, 630), line);
      for (var y = 320.0; y < 630; y += 70) {
        canvas.drawCircle(_o(312, y), 5, Paint()..color = outline);
      }
    case _Shape.trousers:
      draw(
        _poly([
          _o(200, 170),
          _o(400, 170),
          _o(425, 670),
          _o(330, 670),
          _o(300, 330),
          _o(270, 670),
          _o(175, 670),
        ]),
      );
      canvas
        ..drawLine(_o(200, 210), _o(400, 210), line)
        ..drawLine(_o(300, 210), _o(300, 300), line);
    case _Shape.skirt:
      draw(_poly([_o(220, 200), _o(380, 200), _o(460, 640), _o(140, 640)]));
      canvas.drawLine(_o(220, 240), _o(380, 240), line);
      for (var i = 1; i < 6; i++) {
        final t = i / 6;
        canvas.drawLine(_o(220 + 160 * t, 245), _o(140 + 320 * t, 635), line);
      }
    case _Shape.dress:
      draw(
        _poly([
          _o(245, 140),
          _o(270, 140),
          _o(300, 200),
          _o(330, 140),
          _o(355, 140),
          _o(365, 210),
          _o(345, 340),
          _o(460, 690),
          _o(140, 690),
          _o(255, 340),
          _o(235, 210),
        ]),
      );
      canvas.drawLine(_o(255, 340), _o(345, 340), line);
    case _Shape.coat:
      draw(
        _poly([
          _o(245, 160),
          _o(355, 160),
          _o(450, 200),
          _o(505, 600),
          _o(445, 616),
          _o(410, 310),
          _o(420, 700),
          _o(180, 700),
          _o(190, 310),
          _o(155, 616),
          _o(95, 600),
          _o(150, 200),
        ]),
      );
      draw(_poly([_o(245, 160), _o(300, 330), _o(250, 300), _o(215, 200)]));
      draw(_poly([_o(355, 160), _o(300, 330), _o(350, 300), _o(385, 200)]));
      canvas.drawLine(_o(300, 330), _o(300, 700), line);
      for (final y in [400.0, 480.0, 560.0]) {
        canvas.drawCircle(_o(320, y), 7, Paint()..color = outline);
      }
    case _Shape.jacket:
      draw(top);
      draw(_poly([_o(245, 200), _o(300, 380), _o(250, 340), _o(220, 240)]));
      draw(_poly([_o(355, 200), _o(300, 380), _o(350, 340), _o(380, 240)]));
      canvas
        ..drawLine(_o(300, 380), _o(300, 640), line)
        ..drawLine(_o(210, 520), _o(270, 520), line)
        ..drawLine(_o(330, 520), _o(390, 520), line);
    case _Shape.shoe:
      draw(
        Path()
          ..moveTo(130, 560)
          ..lineTo(150, 470)
          ..quadraticBezierTo(250, 445, 310, 495)
          ..quadraticBezierTo(440, 500, 480, 560)
          ..close(),
      );
      draw(_poly([_o(115, 560), _o(490, 560), _o(490, 590), _o(115, 590)]));
      canvas.drawLine(_o(270, 490), _o(350, 505), line);
    case _Shape.heel:
      draw(
        Path()
          ..moveTo(150, 470)
          ..quadraticBezierTo(230, 450, 300, 520)
          ..quadraticBezierTo(400, 560, 480, 575)
          ..lineTo(480, 595)
          ..lineTo(300, 590)
          ..quadraticBezierTo(230, 560, 175, 540)
          ..close(),
      );
      draw(_poly([_o(150, 470), _o(175, 540), _o(170, 650), _o(150, 650)]));
    case _Shape.boot:
      draw(
        Path()
          ..moveTo(150, 560)
          ..lineTo(165, 290)
          ..lineTo(295, 290)
          ..lineTo(305, 465)
          ..quadraticBezierTo(440, 480, 480, 560)
          ..close(),
      );
      draw(_poly([_o(140, 560), _o(490, 560), _o(490, 595), _o(140, 595)]));
      draw(_poly([_o(210, 330), _o(280, 330), _o(285, 450), _o(215, 450)]));
    case _Shape.sneaker:
      draw(
        Path()
          ..moveTo(130, 555)
          ..lineTo(150, 450)
          ..quadraticBezierTo(250, 430, 300, 470)
          ..quadraticBezierTo(440, 480, 480, 555)
          ..close(),
      );
      draw(_poly([_o(115, 555), _o(490, 555), _o(490, 595), _o(115, 595)]));
      for (var x = 235.0; x < 330; x += 28) {
        canvas.drawLine(_o(x, 462), _o(x + 22, 478), line);
      }
    case _Shape.tote:
      canvas.drawArc(
        const Rect.fromLTWH(220, 260, 160, 200),
        3.14,
        3.14,
        false,
        line..strokeWidth = 12,
      );
      draw(_poly([_o(160, 360), _o(440, 360), _o(470, 650), _o(130, 650)]));
    case _Shape.hat:
      draw(
        Path()..addOval(
          Rect.fromCenter(center: _o(300, 500), width: 440, height: 120),
        ),
      );
      draw(
        Path()..addRRect(
          RRect.fromRectAndCorners(
            const Rect.fromLTRB(210, 340, 390, 500),
            topLeft: const Radius.circular(70),
            topRight: const Radius.circular(70),
          ),
        ),
      );
      canvas.drawRect(
        const Rect.fromLTRB(212, 455, 388, 480),
        Paint()..color = detail,
      );
  }
}
