import 'package:flutter/material.dart';

import '../../shared/widgets/solary_logo.dart';

/// Launch animation shown over the app on cold start. The native launch
/// screen is plain white, so this picks up seamlessly: the eight leaves of
/// the Solary mark sweep in one after another, the wordmark slides out from
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
    const gap = markSize * SolaryWordmark.gap;
    const wordWidth = markSize * SolaryWordmark.widthToMark;

    // Timeline (fractions of 2.3s).
    final shift = _phase(t, 0.36, 0.60); // mark slides left, word emerges
    final exit = _phase(t, 0.84, 1.0, Curves.easeInCubic);

    // Centred lock-up: mark alone at first, then mark + wordmark together.
    final mark = SizedBox.square(
      dimension: markSize,
      child: CustomPaint(painter: SolaryMarkPainter(progress: t)),
    );
    final word = ClipRect(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: shift,
        heightFactor: 1,
        child: Opacity(
          opacity: shift,
          child: Transform.translate(
            offset: Offset(-24 * (1 - shift), 0),
            child: const Padding(
              padding: EdgeInsets.only(top: markSize * SolaryWordmark.drop),
              child: SolaryWordmark(width: wordWidth),
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
