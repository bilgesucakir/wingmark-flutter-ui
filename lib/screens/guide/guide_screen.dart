import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/species.dart';
import '../../services/species_service.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/flowing_title.dart';
import 'species_detail_screen.dart';

/// Species catalog browser backed by GET /api/species?search=&page=&size=
/// (the backend paginates this endpoint — see SpeciesController.java) — the
/// Swift app's GuideView listed a small hardcoded local seed instead.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => GuideScreenState();
}

enum _SpeciesSort {
  commonNameAsc,
  commonNameDesc,
  scientificNameAsc,
  scientificNameDesc,
}

/// Public so RootTabView can auto-refresh this tab on reselect — see
/// DiaryScreenState for why that's needed with IndexedStack.
class GuideScreenState extends State<GuideScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<Species> _items = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Object? _error;
  _SpeciesSort _sortOption = _SpeciesSort.commonNameAsc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  String get _sort {
    final locale = AppLocalizations.of(context).code;
    switch (_sortOption) {
      case _SpeciesSort.commonNameAsc:
        return 'commonName.$locale,asc';
      case _SpeciesSort.commonNameDesc:
        return 'commonName.$locale,desc';
      case _SpeciesSort.scientificNameAsc:
        return 'scientificName,asc';
      case _SpeciesSort.scientificNameDesc:
        return 'scientificName,desc';
    }
  }

  void _changeSort(_SpeciesSort option) {
    setState(() => _sortOption = option);
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<SpeciesService>()
          .search(query: _searchController.text.trim(), sort: _sort);
      if (!mounted) return;
      setState(() {
        _items = page.content;
        _nextPage = page.number + 1;
        _hasMore = !page.isLastPage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await context.read<SpeciesService>().search(
            query: _searchController.text.trim(),
            page: _nextPage,
            sort: _sort,
          );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.content];
        _nextPage = page.number + 1;
        _hasMore = !page.isLastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      // Leave _hasMore as-is so scrolling near the bottom again retries.
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// Public — called by RootTabView on tab reselect and by pull-to-refresh.
  Future<void> refresh() => _loadFirstPage();

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadFirstPage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FlowingTitle(l10n.guideTitle, size: 28),
        actions: [
          PopupMenuButton<_SpeciesSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortTooltip,
            onSelected: _changeSort,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: _SpeciesSort.commonNameAsc,
                checked: _sortOption == _SpeciesSort.commonNameAsc,
                child: Text(l10n.sortCommonNameAsc),
              ),
              CheckedPopupMenuItem(
                value: _SpeciesSort.commonNameDesc,
                checked: _sortOption == _SpeciesSort.commonNameDesc,
                child: Text(l10n.sortCommonNameDesc),
              ),
              CheckedPopupMenuItem(
                value: _SpeciesSort.scientificNameAsc,
                checked: _sortOption == _SpeciesSort.scientificNameAsc,
                child: Text(l10n.sortScientificNameAsc),
              ),
              CheckedPopupMenuItem(
                value: _SpeciesSort.scientificNameDesc,
                checked: _sortOption == _SpeciesSort.scientificNameDesc,
                child: Text(l10n.sortScientificNameDesc),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.searchSpecies,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              color: AppTheme.accent,
              child: _buildBody(l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          ErrorRetry(
              message: l10n.somethingWentWrong, onRetry: _loadFirstPage),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          Center(
            child: Text(l10n.noSpeciesFound,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              ),
            ),
          );
        }
        final s = _items[index];
        return ListTile(
          title: Text(s.name(l10n.code)),
          subtitle: Text(
            s.scientificName,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          leading: s.images.isNotEmpty
              ? CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(s.images.first.imageUrl),
                )
              : const CircleAvatar(child: Icon(Icons.pets)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SpeciesDetailScreen(speciesId: s.id),
            ),
          ),
        );
      },
    );
  }
}
