import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Launch animation shown over the app on cold start. The native launch
/// screen is plain white, so this picks up seamlessly: the four pieces of
/// the Solary mark fly in from their corners, the wordmark slides out from
/// behind the mark, then the whole splash fades away to reveal the app,
/// which has been building (and loading Home) underneath the whole time.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _frame(_c.value),
            ),
          ),
      ],
    );
  }

  /// Progress of [t] within [start, end] of the timeline, eased.
  static double _phase(double t, double start, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - start) / (end - start)).clamp(0.0, 1.0));

  Widget _frame(double t) {
    const markSize = 64.0;
    const gap = 16.0;
    const wordWidth = 150.0;

    // Timeline (fractions of 2.3s).
    final shift = _phase(t, 0.36, 0.60); // mark slides left, word emerges
    final exit = _phase(t, 0.84, 1.0, Curves.easeInCubic);

    // Centred lock-up: mark alone at first, then mark + wordmark together.
    final mark = SizedBox.square(
      dimension: markSize,
      child: CustomPaint(painter: _MarkPainter(t)),
    );
    final word = ClipRect(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: shift,
        child: Opacity(
          opacity: shift,
          child: Transform.translate(
            offset: Offset(-24 * (1 - shift), 0),
            child: Image.asset('assets/images/wordmark.png', width: wordWidth),
          ),
        ),
      ),
    );

    return IgnorePointer(
      ignoring: exit > 0.5,
      child: Opacity(
        opacity: 1 - exit,
        child: ColoredBox(
          color: Colors.white,
          child: Center(
            child: Transform.scale(
              scale: 1 + 0.06 * exit,
              child: Directionality(
                // The lock-up is a logo: always mark-then-word, even in RTL.
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mark,
                    SizedBox(width: gap * shift),
                    word,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Solary mark, drawn as vectors (unit square) so it stays sharp at
/// any size: four pieces around a centre cross, each animated in from its
/// own corner with a small stagger.
class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);

  final double t;

  static const _navy = Color(0xFF01308C);
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
      final raw = ((t - start) / 0.26).clamp(0.0, 1.0);
      if (raw == 0) continue;
      final p = Curves.easeOutBack.transform(raw);
      final fade = Curves.easeOut.transform(raw);

      // Each piece travels in from 60% of the mark's size away, turning
      // a quarter-turn into place.
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
      canvas.drawPath(path, Paint()..color = _navy.withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}
