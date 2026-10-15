import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../domain/bulk_models.dart';

/// A small drawn national flag (not an emoji, so it renders identically on
/// every device). Only the countries the marketplace trades between.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.width = 20});

  final BulkCountry country;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 2 / 3;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(color: const Color(0x1F000000), width: 0.5),
      ),
      child: CustomPaint(
        painter: country == BulkCountry.china
            ? const _ChinaPainter()
            : const _IraqPainter(),
      ),
    );
  }
}

/// Red / white / black horizontal bands with the green takbir script in the
/// white band.
class _IraqPainter extends CustomPainter {
  const _IraqPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.height / 3;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, band),
      Paint()..color = const Color(0xFFCE1126),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, band, size.width, band),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, band * 2, size.width, band),
      Paint()..color = const Color(0xFF000000),
    );

    // Stylised script: a short wavy stroke centred in the white band.
    final path = Path();
    final y = band * 1.5;
    final x0 = size.width * 0.28;
    final x1 = size.width * 0.72;
    final amp = band * 0.22;
    path.moveTo(x0, y);
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(x0 + (x1 - x0) * t, y + (i.isEven ? -amp : amp));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF007A3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, band * 0.2)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Red field, large yellow star at the hoist and four small ones in an arc.
class _ChinaPainter extends CustomPainter {
  const _ChinaPainter();

  static const _yellow = Color(0xFFFFDE00);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDE2910),
    );
    final unit = size.width / 30; // the official flag is drawn on a 30x20 grid
    final paint = Paint()..color = _yellow;

    void star(Offset center, double radius, double rotation) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? radius : radius * 0.382;
        final a = rotation + math.pi * i / 5;
        final p = Offset(
          center.dx + r * math.sin(a),
          center.dy - r * math.cos(a),
        );
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    const bigCenter = Offset(5, 5);
    star(bigCenter * unit, 3 * unit, 0);
    for (final c in const [
      Offset(10, 2),
      Offset(12, 4),
      Offset(12, 7),
      Offset(10, 9),
    ]) {
      // each small star points one tip at the big star
      final angle = math.atan2(c.dx - bigCenter.dx, -(c.dy - bigCenter.dy));
      star(c * unit, unit, angle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
