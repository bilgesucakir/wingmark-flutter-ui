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

/// Species catalog browser backed by GET /api/species?search= — the Swift
/// app's GuideView listed a small hardcoded local seed instead of the
/// backend's real catalog.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<Species>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SpeciesService>().search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _future = context.read<SpeciesService>().search(value.trim());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: FlowingTitle(l10n.guideTitle, size: 28)),
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
            child: FutureBuilder<List<Species>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent));
                }
                if (snapshot.hasError) {
                  return ErrorRetry(
                    message: l10n.somethingWentWrong,
                    onRetry: () => setState(() {
                      _future = context
                          .read<SpeciesService>()
                          .search(_searchController.text.trim());
                    }),
                  );
                }
                final species = snapshot.data ?? [];
                if (species.isEmpty) {
                  return Center(
                    child: Text(l10n.noSpeciesFound,
                        style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: species.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = species[index];
                    return ListTile(
                      title: Text(s.name(l10n.code)),
                      subtitle: Text(
                        s.scientificName,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      leading: s.images.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  s.images.first.imageUrl),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
