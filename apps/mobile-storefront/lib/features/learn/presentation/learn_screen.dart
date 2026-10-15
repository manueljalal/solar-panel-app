import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/learn_repository.dart';
import '../domain/learn_item.dart';
import 'learn_item_screen.dart';
import 'learn_poster.dart';

/// The Learn tab — admin-managed video lessons, newest first.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, LearnRepository? repository}) : _repository = repository;

  final LearnRepository? _repository;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final LearnRepository _repository = widget._repository ?? LearnRepository();
  late Future<List<LearnItem>> _items = _repository.fetchItems();

  Future<void> _reload() async {
    final next = _repository.fetchItems();
    setState(() => _items = next);
    await next.catchError((_) => <LearnItem>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.learnTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: FutureBuilder<List<LearnItem>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.homeLoadError, style: AppTypography.bodyMuted)),
                  TextButton(onPressed: _reload, child: Text(l10n.retry)),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(child: Text(l10n.learnEmpty, style: AppTypography.bodyMuted));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              // +1 for the intro header row.
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(l10n.learnTeaserSubtitle, style: AppTypography.bodyMuted),
                  );
                }
                final item = items[i - 1];
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LearnItemScreen(item: item)),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LearnPoster(item: item),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.titleFor(lang),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.25),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.descriptionFor(lang),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMuted.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
