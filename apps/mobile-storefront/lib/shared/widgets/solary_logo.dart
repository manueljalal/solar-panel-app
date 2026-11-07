import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Solary lock-up: the mark followed by the "solary" wordmark. It is a
/// logo, so it reads mark-then-word in every language, RTL included.
class SolaryLogo extends StatelessWidget {
  const SolaryLogo({super.key, this.height = 28});

  /// Height of the mark; the wordmark and spacing scale with it.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: height,
            child: CustomPaint(painter: SolaryMarkPainter()),
          ),
          SizedBox(width: height * 0.25),
          SolaryWordmark(width: height * 2.35),
        ],
      ),
    );
  }
}

/// The "solary" lettering, cut from the brand artwork (transparent PNG, so
/// it sits cleanly on any background).
class SolaryWordmark extends StatelessWidget {
  const SolaryWordmark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/wordmark.png', width: width);
  }
}

/// The Solary mark, drawn as vectors (unit square) so it stays sharp at any
/// size: four pieces around a centre cross. [progress] animates each piece
/// in from its own corner with a small stagger (used by the launch splash);
/// the default of 1 paints the finished mark.
class SolaryMarkPainter extends CustomPainter {
  SolaryMarkPainter({this.progress = 1});

  final double progress;

  static const navy = Color(0xFF01308C);
  static const _a = 0.494; // inner edge before the gap
  static const _b = 0.506; // inner edge after the gap

  static const _pieces = <(List<Offset>, Offset)>[
    // Top-left: square with its lower-left corner cut on a 45° line.
    ([Offset(0, 0), Offset(_a, 0), Offset(_a, 0.5), Offset(0.26, 0.5), Offset(0, 0.24)], Offset(-1, -1)),
    // Top-right: triangle.
    ([Offset(_b, 0), Offset(1, 0), Offset(1, _a)], Offset(1, -1)),
    // Bottom-left: triangle.
    ([Offset(0, _b), Offset(0, 1), Offset(_a, 1)], Offset(-1, 1)),
    // Bottom-right: square with its upper-right corner cut.
    ([Offset(_b, 0.5), Offset(0.74, 0.5), Offset(1, 0.76), Offset(1, 1), Offset(_b, 1)], Offset(1, 1)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pieces.length; i++) {
      final (points, dir) = _pieces[i];
      final start = 0.04 + i * 0.06;
      final raw = progress >= 1 ? 1.0 : ((progress - start) / 0.26).clamp(0.0, 1.0);
      if (raw == 0) continue;
      final p = Curves.easeOutBack.transform(raw);
      final fade = Curves.easeOut.transform(raw);

      // Each piece travels in from 60% of the mark's size away, turning
      // an eighth of a turn into place.
      final offset = dir * (size.width * 0.6 * (1 - p));
      final angle = (1 - p) * math.pi / 4 * (dir.dx * dir.dy);
      final centre = Offset(size.width / 2, size.height / 2);

      canvas.save();
      canvas.translate(centre.dx + offset.dx, centre.dy + offset.dy);
      canvas.rotate(angle);
      canvas.translate(-centre.dx, -centre.dy);
      final path = Path()
        ..addPolygon(
          [for (final o in points) Offset(o.dx * size.width, o.dy * size.height)],
          true,
        );
      canvas.drawPath(path, Paint()..color = navy.withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SolaryMarkPainter old) => old.progress != progress;
}
