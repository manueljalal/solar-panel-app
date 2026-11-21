import 'package:flutter/material.dart';

/// The Solary horizontal lock-up: the leaf mark followed by the "Solary"
/// wordmark, in the brand's proportions. It is a logo, so it reads
/// mark-then-word in every language, RTL included.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: height,
            child: CustomPaint(painter: SolaryMarkPainter()),
          ),
          SizedBox(width: height * SolaryWordmark.gap),
          Padding(
            padding: EdgeInsets.only(top: height * SolaryWordmark.drop),
            child: SolaryWordmark(width: height * SolaryWordmark.widthToMark),
          ),
        ],
      ),
    );
  }
}

/// The "Solary" lettering from the brand pack (transparent PNG, so it sits
/// cleanly on any background).
class SolaryWordmark extends StatelessWidget {
  const SolaryWordmark({super.key, required this.width});

  final double width;

  // Placement next to a mark of height 1, from the brand's horizontal logo.
  static const widthToMark = 3.19;
  static const gap = 0.17;
  static const drop = 0.027;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/wordmark.png', width: width);
  }
}

/// The Solary mark, drawn as vectors (unit square) so it stays sharp at any
/// size: eight leaves in two rising strands. [progress] sweeps each leaf in
/// from below-left, top leaf first (used by the launch splash); the default
/// of 1 paints the finished mark.
class SolaryMarkPainter extends CustomPainter {
  SolaryMarkPainter({this.progress = 1});

  final double progress;

  static const deepGreen = Color(0xFF032622);

  // Traced from the brand pack's symbol SVG, ordered top to bottom.
  static final _leaves = <Path>[
  Path()
    ..moveTo(0.8086, 0.0065)
    ..lineTo(0.6911, 0.0049)
    ..cubicTo(0.6911, 0.0049, 0.6902, 0.0049, 0.6897, 0.0049)
    ..cubicTo(0.6758, 0.0077, 0.6556, 0.0133, 0.6367, 0.0277)
    ..cubicTo(0.5946, 0.0594, 0.5992, 0.1024, 0.5709, 0.1380)
    ..cubicTo(0.5592, 0.1527, 0.5402, 0.1682, 0.5070, 0.1787)
    ..cubicTo(0.4994, 0.1811, 0.5020, 0.1921, 0.5099, 0.1914)
    ..cubicTo(0.5303, 0.1898, 0.5476, 0.1866, 0.5609, 0.1835)
    ..cubicTo(0.5912, 0.1763, 0.7079, 0.1531, 0.7755, 0.0733)
    ..cubicTo(0.7931, 0.0524, 0.8059, 0.0326, 0.8146, 0.0166)
    ..cubicTo(0.8170, 0.0122, 0.8138, 0.0069, 0.8086, 0.0067)
    ..close(),
  Path()
    ..moveTo(0.0742, 0.4433)
    ..lineTo(0.2433, 0.4457)
    ..cubicTo(0.2433, 0.4457, 0.2447, 0.4457, 0.2454, 0.4457)
    ..cubicTo(0.2654, 0.4418, 0.2945, 0.4336, 0.3216, 0.4130)
    ..cubicTo(0.3795, 0.3694, 0.3693, 0.3090, 0.4162, 0.2545)
    ..cubicTo(0.4369, 0.2307, 0.4734, 0.2020, 0.5429, 0.1871)
    ..cubicTo(0.5418, 0.1806, 0.5408, 0.1743, 0.5397, 0.1679)
    ..cubicTo(0.5276, 0.1716, 0.5091, 0.1767, 0.4863, 0.1811)
    ..cubicTo(0.4572, 0.1868, 0.4354, 0.1887, 0.4306, 0.1890)
    ..cubicTo(0.3612, 0.1957, 0.2085, 0.2456, 0.1219, 0.3477)
    ..cubicTo(0.0965, 0.3776, 0.0782, 0.4064, 0.0655, 0.4294)
    ..cubicTo(0.0619, 0.4357, 0.0668, 0.4433, 0.0742, 0.4434)
    ..close(),
  Path()
    ..moveTo(0.7427, 0.2534)
    ..lineTo(0.5736, 0.2509)
    ..cubicTo(0.5736, 0.2509, 0.5722, 0.2509, 0.5715, 0.2509)
    ..cubicTo(0.5515, 0.2548, 0.5224, 0.2631, 0.4952, 0.2836)
    ..cubicTo(0.4374, 0.3272, 0.4476, 0.3877, 0.4007, 0.4421)
    ..cubicTo(0.3800, 0.4659, 0.3435, 0.4947, 0.2740, 0.5095)
    ..cubicTo(0.2751, 0.5160, 0.2761, 0.5223, 0.2772, 0.5288)
    ..cubicTo(0.2893, 0.5251, 0.3077, 0.5199, 0.3305, 0.5155)
    ..cubicTo(0.3596, 0.5099, 0.3814, 0.5079, 0.3863, 0.5076)
    ..cubicTo(0.4558, 0.5010, 0.6084, 0.4510, 0.6950, 0.3489)
    ..cubicTo(0.7204, 0.3190, 0.7386, 0.2902, 0.7514, 0.2673)
    ..cubicTo(0.7550, 0.2610, 0.7501, 0.2534, 0.7427, 0.2532)
    ..close(),
  Path()
    ..moveTo(0.9916, 0.3098)
    ..lineTo(0.8741, 0.3081)
    ..cubicTo(0.8741, 0.3081, 0.8731, 0.3081, 0.8726, 0.3081)
    ..cubicTo(0.8587, 0.3109, 0.8385, 0.3166, 0.8196, 0.3309)
    ..cubicTo(0.7776, 0.3626, 0.7821, 0.4054, 0.7538, 0.4412)
    ..cubicTo(0.7422, 0.4559, 0.7231, 0.4714, 0.6900, 0.4819)
    ..cubicTo(0.6824, 0.4843, 0.6850, 0.4953, 0.6929, 0.4947)
    ..cubicTo(0.7133, 0.4930, 0.7306, 0.4898, 0.7438, 0.4867)
    ..cubicTo(0.7742, 0.4795, 0.8909, 0.4564, 0.9585, 0.3765)
    ..cubicTo(0.9761, 0.3557, 0.9888, 0.3358, 0.9976, 0.3198)
    ..cubicTo(1.0000, 0.3154, 0.9968, 0.3101, 0.9916, 0.3099)
    ..close(),
  Path()
    ..moveTo(0.2573, 0.7465)
    ..lineTo(0.4264, 0.7489)
    ..cubicTo(0.4264, 0.7489, 0.4278, 0.7489, 0.4285, 0.7489)
    ..cubicTo(0.4485, 0.7450, 0.4776, 0.7368, 0.5048, 0.7163)
    ..cubicTo(0.5626, 0.6726, 0.5524, 0.6122, 0.5993, 0.5577)
    ..cubicTo(0.6200, 0.5339, 0.6565, 0.5052, 0.7260, 0.4903)
    ..cubicTo(0.7249, 0.4838, 0.7239, 0.4775, 0.7228, 0.4711)
    ..cubicTo(0.7107, 0.4748, 0.6923, 0.4798, 0.6695, 0.4843)
    ..cubicTo(0.6404, 0.4900, 0.6186, 0.4919, 0.6137, 0.4922)
    ..cubicTo(0.5442, 0.4989, 0.3916, 0.5488, 0.3050, 0.6510)
    ..cubicTo(0.2796, 0.6809, 0.2614, 0.7096, 0.2486, 0.7326)
    ..cubicTo(0.2450, 0.7389, 0.2499, 0.7465, 0.2573, 0.7466)
    ..close(),
  Path()
    ..moveTo(0.0084, 0.6901)
    ..lineTo(0.1259, 0.6917)
    ..cubicTo(0.1259, 0.6917, 0.1269, 0.6917, 0.1274, 0.6917)
    ..cubicTo(0.1413, 0.6889, 0.1615, 0.6833, 0.1804, 0.6689)
    ..cubicTo(0.2224, 0.6372, 0.2179, 0.5942, 0.2462, 0.5587)
    ..cubicTo(0.2578, 0.5440, 0.2769, 0.5284, 0.3100, 0.5179)
    ..cubicTo(0.3176, 0.5155, 0.3150, 0.5045, 0.3071, 0.5052)
    ..cubicTo(0.2867, 0.5068, 0.2694, 0.5100, 0.2562, 0.5131)
    ..cubicTo(0.2258, 0.5204, 0.1091, 0.5435, 0.0415, 0.6233)
    ..cubicTo(0.0239, 0.6442, 0.0112, 0.6641, 0.0024, 0.6801)
    ..cubicTo(0.0000, 0.6844, 0.0032, 0.6898, 0.0084, 0.6899)
    ..close(),
  Path()
    ..moveTo(0.9258, 0.5567)
    ..lineTo(0.7567, 0.5543)
    ..cubicTo(0.7567, 0.5543, 0.7553, 0.5543, 0.7546, 0.5543)
    ..cubicTo(0.7346, 0.5582, 0.7055, 0.5664, 0.6784, 0.5870)
    ..cubicTo(0.6205, 0.6306, 0.6307, 0.6910, 0.5838, 0.7455)
    ..cubicTo(0.5631, 0.7693, 0.5266, 0.7980, 0.4571, 0.8129)
    ..cubicTo(0.4582, 0.8194, 0.4592, 0.8257, 0.4603, 0.8321)
    ..cubicTo(0.4724, 0.8284, 0.4909, 0.8233, 0.5137, 0.8189)
    ..cubicTo(0.5428, 0.8132, 0.5646, 0.8113, 0.5694, 0.8110)
    ..cubicTo(0.6389, 0.8043, 0.7917, 0.7544, 0.8781, 0.6523)
    ..cubicTo(0.9035, 0.6224, 0.9218, 0.5936, 0.9345, 0.5706)
    ..cubicTo(0.9381, 0.5643, 0.9332, 0.5567, 0.9258, 0.5566)
    ..close(),
  Path()
    ..moveTo(0.1914, 0.9935)
    ..lineTo(0.3089, 0.9951)
    ..cubicTo(0.3089, 0.9951, 0.3098, 0.9951, 0.3103, 0.9951)
    ..cubicTo(0.3242, 0.9923, 0.3444, 0.9867, 0.3633, 0.9723)
    ..cubicTo(0.4054, 0.9406, 0.4008, 0.8976, 0.4291, 0.8620)
    ..cubicTo(0.4408, 0.8473, 0.4598, 0.8318, 0.4930, 0.8213)
    ..cubicTo(0.5006, 0.8189, 0.4980, 0.8079, 0.4901, 0.8086)
    ..cubicTo(0.4697, 0.8102, 0.4524, 0.8134, 0.4391, 0.8165)
    ..cubicTo(0.4088, 0.8237, 0.2921, 0.8469, 0.2245, 0.9267)
    ..cubicTo(0.2069, 0.9476, 0.1941, 0.9674, 0.1854, 0.9834)
    ..cubicTo(0.1830, 0.9878, 0.1862, 0.9931, 0.1914, 0.9933)
    ..close(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    for (var i = 0; i < _leaves.length; i++) {
      final start = 0.04 + i * 0.035;
      final raw = progress >= 1 ? 1.0 : ((progress - start) / 0.22).clamp(0.0, 1.0);
      if (raw == 0) continue;
      final p = Curves.easeOutCubic.transform(raw);

      canvas.save();
      canvas.translate(-0.2 * (1 - p), 0.2 * (1 - p));
      canvas.drawPath(_leaves[i], Paint()..color = deepGreen.withValues(alpha: p));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SolaryMarkPainter old) => old.progress != progress;
}
