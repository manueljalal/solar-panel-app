import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/category_tabs.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_category.dart';
import '../data/bulk_repository.dart';
import '../domain/bulk_models.dart';
import 'bulk_listing_form_screen.dart';
import 'bulk_request_form_screen.dart';
import 'widgets/bulk_company_row.dart';
import 'widgets/bulk_post_card.dart';
import 'widgets/country_flag.dart';

enum _Sort { newest, byValue }

/// The vendor-only bulk marketplace: wholesale offers with tier prices,
/// buyer requests, and the caller's own posts. Reached from the Home
/// "Own a solar business?" tile once the signed-in account is an approved
/// vendor. Feed data comes from the vendor-gated `bulk-*` functions.
///
/// Mirrors Home's browsing model: country chips, the admin-managed category
/// row, a Companies row (tap to filter to one company) and a sort control.
/// Country is applied server-side (it changes what is fetched); category,
/// company and sort are applied locally to the loaded feed so they are
/// instant.
class BulkMarketScreen extends StatefulWidget {
  const BulkMarketScreen({
    super.key,
    BulkRepository? repository,
    HomeRepository? homeRepository,
  }) : _repository = repository,
       _homeRepository = homeRepository;

  final BulkRepository? _repository;
  final HomeRepository? _homeRepository;

  @override
  State<BulkMarketScreen> createState() => _BulkMarketScreenState();
}

class _BulkMarketScreenState extends State<BulkMarketScreen> {
  late final BulkRepository _repo = widget._repository ?? BulkRepository();
  late final HomeRepository _home = widget._homeRepository ?? HomeRepository();

  BulkCountry? _country; // null = all
  String? _categoryId; // null = all
  String? _companyId; // null = all
  _Sort _sort = _Sort.newest;
  List<HomeCategory> _categories = const [];

  /// vendorId -> logo URL, from the vendor records (same source as Home's
  /// Companies row). Covers posts made before logos were saved on posts.
  Map<String, String> _logos = const {};

  late Future<List<BulkListing>> _listings;
  late Future<List<BulkRequest>> _requests;
  late Future<List<BulkPost>> _mine;

  @override
  void initState() {
    super.initState();
    _load();
    // Categories are a nicety — if they fail to load the row just hides.
    _home.fetchCategories().then((value) {
      if (mounted) setState(() => _categories = value);
    }, onError: (_) {});
    _home.fetchCompanies().then((value) {
      if (mounted) setState(() => _logos = {for (final c in value) c.id: c.logoUrl});
    }, onError: (_) {});
  }

  void _load() {
    setState(() {
      _listings = _repo.listListings(country: _country);
      _requests = _repo.listRequests(country: _country);
      _mine = _loadMine();
    });
  }

  Future<List<BulkPost>> _loadMine() async {
    final results = await Future.wait([
      _repo.listListings(mine: true),
      _repo.listRequests(mine: true),
    ]);
    return [...results[0].cast<BulkPost>(), ...results[1].cast<BulkPost>()];
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(l10n.bulkPostListing),
              subtitle: Text(l10n.bulkPostListingHint),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(l10n.bulkPostRequest),
              subtitle: Text(l10n.bulkPostRequestHint),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => choice
            ? BulkListingFormScreen(repository: _repo, categories: _categories)
            : BulkRequestFormScreen(repository: _repo, categories: _categories),
      ),
    );
    if (posted == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bulkPosted)));
      _load();
    }
  }

  Future<void> _close(BulkPost post) async {
    await _repo.closePost(isListing: post is BulkListing, id: post.id);
    if (mounted) _load();
  }

  /// Category + company filter, then sort. [byValue] is price for wholesale
  /// offers and quantity for requests.
  List<T> _apply<T extends BulkPost>(List<T> all) {
    final out = all.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (_companyId != null && p.vendorId != _companyId) return false;
      return true;
    }).toList();
    out.sort((a, b) {
      if (_sort == _Sort.byValue) {
        if (a is BulkListing && b is BulkListing) {
          return a.bestPriceUsd.compareTo(b.bestPriceUsd);
        }
        if (a is BulkRequest && b is BulkRequest) {
          return b.quantity.compareTo(a.quantity);
        }
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            l10n.bulkMarketTitle,
            style: AppTypography.h1.copyWith(fontSize: 19),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.ink600,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: l10n.bulkTabWholesale),
              Tab(text: l10n.bulkTabRequests),
              Tab(text: l10n.bulkTabMine),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _post,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            l10n.bulkPostFab,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _Feed<BulkListing>(
              future: _listings,
              empty: l10n.bulkEmptyListings,
              noResults: l10n.bulkNoResults,
              onRefresh: _load,
              apply: _apply,
              header: (all) => _filters<BulkListing>(
                l10n,
                all,
                valueSortLabel: l10n.bulkSortPriceLow,
              ),
              itemBuilder: (post) => BulkPostCard(
                post: post,
                onTap: () => showBulkPostSheet(context, post),
              ),
            ),
            _Feed<BulkRequest>(
              future: _requests,
              empty: l10n.bulkEmptyRequests,
              noResults: l10n.bulkNoResults,
              onRefresh: _load,
              apply: _apply,
              header: (all) => _filters<BulkRequest>(
                l10n,
                all,
                valueSortLabel: l10n.bulkSortQtyHigh,
              ),
              itemBuilder: (post) => BulkPostCard(
                post: post,
                onTap: () => showBulkPostSheet(context, post),
              ),
            ),
            _Feed<BulkPost>(
              future: _mine,
              empty: l10n.bulkEmptyMine,
              noResults: l10n.bulkNoResults,
              onRefresh: _load,
              itemBuilder: (post) => BulkPostCard(
                post: post,
                onTap: () => showBulkPostSheet(context, post),
                onClose: post.isOpen ? () => _close(post) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Country chips + sort, category row, companies row — same sections and
  /// order as Home.
  Widget _filters<T extends BulkPost>(
    AppLocalizations l10n,
    List<T> all, {
    required String valueSortLabel,
  }) {
    Widget chip(String label, BulkCountry? value) {
      final selected = _country == value;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: ChoiceChip(
          avatar: value == null ? null : CountryFlag(country: value, width: 20),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.ink900,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) {
            if (_country == value) return;
            _country = value;
            _load();
          },
        ),
      );
    }

    final companies = companiesOf(all, logos: _logos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chip(l10n.bulkCountryAll, null),
                    chip(l10n.bulkCountryIraq, BulkCountry.iraq),
                    chip(l10n.bulkCountryChina, BulkCountry.china),
                  ],
                ),
              ),
            ),
            PopupMenuButton<_Sort>(
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _Sort.newest,
                  child: Text(l10n.bulkSortNewest),
                ),
                PopupMenuItem(
                  value: _Sort.byValue,
                  child: Text(valueSortLabel),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16, color: AppColors.ink600),
                  const SizedBox(width: 4),
                  Text(
                    _sort == _Sort.newest
                        ? l10n.bulkSortNewest
                        : valueSortLabel,
                    style: AppTypography.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CategoryTabs(
            categories: _categories,
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
        ],
        if (companies.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          BulkCompanyRow(
            companies: companies,
            selectedId: _companyId,
            onSelected: (id) => setState(() => _companyId = id),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _Feed<T extends BulkPost> extends StatelessWidget {
  const _Feed({
    required this.future,
    required this.empty,
    required this.noResults,
    required this.onRefresh,
    required this.itemBuilder,
    this.apply,
    this.header,
  });

  final Future<List<T>> future;
  final String empty;
  final String noResults;
  final VoidCallback onRefresh;
  final Widget Function(T post) itemBuilder;
  final List<T> Function(List<T> all)? apply;
  final Widget Function(List<T> all)? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final all = snapshot.data ?? <T>[];
        final shown = apply?.call(all) ?? all;

        final children = <Widget>[
          if (header != null) header!(all),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot.hasError)
            Column(
              children: [
                Text(l10n.bulkLoadError, style: AppTypography.bodyMuted),
                TextButton(onPressed: onRefresh, child: Text(l10n.retry)),
              ],
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  all.isEmpty ? empty : noResults,
                  style: AppTypography.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ];

        // Square photo (full tile width) + a fixed text block.
        final tileWidth =
            (MediaQuery.of(context).size.width -
                AppSpacing.lg * 2 -
                AppSpacing.md) /
            2;
        final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: BulkPostCard.extentFor(tileWidth),
        );

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList(delegate: SliverChildListDelegate(children)),
              ),
              if (!loading && !snapshot.hasError && shown.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    96,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => itemBuilder(shown[i]),
                      childCount: shown.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
