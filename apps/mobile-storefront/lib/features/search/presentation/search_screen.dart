import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/home_product.dart';
import '../../home/presentation/widgets/product_row.dart';
import '../data/search_repository.dart';

/// Real search — filters the live product catalog (see SearchRepository)
/// as you type, debounced so it doesn't refetch on every keystroke.
///
/// [repository] is injectable so widget tests can pass a fake instead of
/// hitting real Firestore (same pattern as HomeScreen).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = '', this.repository});

  final String initialQuery;
  final SearchRepository? repository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late final _repository = widget.repository ?? SearchRepository();

  List<HomeProduct>? _results;
  bool _loading = false;
  Object? _debounceToken;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _runSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    final token = Object();
    _debounceToken = token;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_debounceToken == token) _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    List<HomeProduct> results;
    try {
      results = await _repository.search(query);
    } catch (_) {
      results = const [];
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: TextField(
            controller: _controller,
            autofocus: widget.initialQuery.isEmpty,
            onChanged: _onChanged,
            onSubmitted: _runSearch,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search, color: AppColors.ink600),
            ),
          ),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_results == null) {
      return Center(
        child: Text(l10n.searchPrompt, style: AppTypography.bodyMuted),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 36, color: AppColors.ink400),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.searchNoResults(_controller.text), style: AppTypography.cardTitle),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _results!.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => ProductRow(product: _results![i]),
    );
  }
}
