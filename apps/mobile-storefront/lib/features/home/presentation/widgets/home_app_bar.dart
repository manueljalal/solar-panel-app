import 'package:flutter/material.dart';
import '../../../../shared/widgets/solary_logo.dart';

/// The Solary logo at the top of the home screen (not a real AppBar — this
/// scrolls away with the rest of the sliver list). The shopper's city is
/// chosen where it matters instead: the Companies filter and Account →
/// Location.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: AlignmentDirectional.centerStart,
      child: SolaryLogo(height: 30),
    );
  }
}
