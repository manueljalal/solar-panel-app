import 'package:flutter/material.dart';

/// Which article an id refers to — title/body text is resolved from
/// AppLocalizations at render time (see learn_screen.dart / article_screen.dart),
/// the same pattern used for home banners, since a top-level `const` list
/// can't hold locale-aware text directly.
enum LearnArticleId { wattage, installation, financing, maintenance, netMetering }

class LearnArticle {
  const LearnArticle({required this.icon, required this.id, required this.minutes});

  final IconData icon;
  final LearnArticleId id;
  final int minutes;
}

// Real (if short) written content — not lorem ipsum. Matches the reference
// PDF's Learn article list. Actual title/body strings live in the ARB files.
const learnArticles = [
  LearnArticle(icon: Icons.wb_sunny_outlined, id: LearnArticleId.wattage, minutes: 4),
  LearnArticle(icon: Icons.home_outlined, id: LearnArticleId.installation, minutes: 6),
  LearnArticle(icon: Icons.credit_card_outlined, id: LearnArticleId.financing, minutes: 5),
  LearnArticle(icon: Icons.build_outlined, id: LearnArticleId.maintenance, minutes: 3),
  LearnArticle(icon: Icons.bolt_outlined, id: LearnArticleId.netMetering, minutes: 5),
];
