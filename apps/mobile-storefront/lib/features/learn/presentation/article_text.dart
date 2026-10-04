import '../../../l10n/app_localizations.dart';
import '../domain/learn_article.dart';

class ArticleText {
  const ArticleText({required this.title, required this.body});
  final String title;
  final String body;
}

ArticleText articleTextFor(LearnArticleId id, AppLocalizations l10n) {
  switch (id) {
    case LearnArticleId.wattage:
      return ArticleText(title: l10n.learnArticleWattageTitle, body: l10n.learnArticleWattageBody);
    case LearnArticleId.installation:
      return ArticleText(title: l10n.learnArticleInstallationTitle, body: l10n.learnArticleInstallationBody);
    case LearnArticleId.financing:
      return ArticleText(title: l10n.learnArticleFinancingTitle, body: l10n.learnArticleFinancingBody);
    case LearnArticleId.maintenance:
      return ArticleText(title: l10n.learnArticleMaintenanceTitle, body: l10n.learnArticleMaintenanceBody);
    case LearnArticleId.netMetering:
      return ArticleText(title: l10n.learnArticleNetMeteringTitle, body: l10n.learnArticleNetMeteringBody);
  }
}
