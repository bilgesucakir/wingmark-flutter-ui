import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
import '../../models/enums.dart';
import '../../services/bird_log_service.dart';
import '../../state/auth_session.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/flowing_title.dart';
import 'add_sighting_screen.dart';
import 'bird_log_detail_screen.dart';

/// The "Diary" tab — mirrors Swift's ContentView, but reads/writes the real
/// backend (GET/POST/DELETE /api/bird-logs) instead of local SwiftData.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

/// Public so RootTabView can hold a GlobalKey and call [refresh] when this
/// tab is reselected — IndexedStack keeps this screen's state alive across
/// tab switches, so without this it would never refetch after the first load
/// unless the user went through the "+" add-sighting flow.
class DiaryScreenState extends State<DiaryScreen> {
  late Future<List<BirdLog>> _future;

  SortDirection _sortDirection = SortDirection.descending;
  bool? _hasSpecies;
  Gender? _gender;
  LifeStage? _lifeStage;

  bool get _hasActiveFilters =>
      _hasSpecies != null || _gender != null || _lifeStage != null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BirdLog>> _load() {
    final userId = context.read<AuthSession>().currentUser!.id;
    return context.read<BirdLogService>().getForUser(
          userId,
          sortDirection: _sortDirection,
          hasSpecies: _hasSpecies,
          gender: _gender,
          lifeStage: _lifeStage,
        );
  }

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _delete(BirdLog log) async {
    try {
      await context.read<BirdLogService>().delete(log.id);
    } catch (_) {
      // Swallow — reload below will restore the row if the delete failed.
    }
    _reload();
  }

  Future<void> _openAddSighting() async {
    final created = await Navigator.of(context).push<BirdLog>(
      MaterialPageRoute(builder: (_) => const AddSightingScreen()),
    );
    if (created != null) _reload();
  }

  Future<void> _openDetail(BirdLog log) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BirdLogDetailScreen(log: log)),
    );
    if (changed == true) _reload();
  }

  void _showFilterSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundElevated,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void apply(void Function() mutate) {
              setSheetState(mutate);
              setState(mutate);
              _reload();
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.diaryFilterTitle,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () => apply(() {
                              _hasSpecies = null;
                              _gender = null;
                              _lifeStage = null;
                            }),
                            child: Text(l10n.clearFilters),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<SortDirection>(
                      segments: [
                        ButtonSegment(
                          value: SortDirection.descending,
                          label: Text(l10n.sortNewestFirst),
                        ),
                        ButtonSegment(
                          value: SortDirection.ascending,
                          label: Text(l10n.sortOldestFirst),
                        ),
                      ],
                      selected: {_sortDirection},
                      onSelectionChanged: (s) =>
                          apply(() => _sortDirection = s.first),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.filterSpeciesIdentified,
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      ChoiceChip(
                        label: Text(l10n.filterAny),
                        selected: _hasSpecies == null,
                        onSelected: (_) => apply(() => _hasSpecies = null),
                      ),
                      ChoiceChip(
                        label: Text(l10n.filterIdentified),
                        selected: _hasSpecies == true,
                        onSelected: (_) => apply(() => _hasSpecies = true),
                      ),
                      ChoiceChip(
                        label: Text(l10n.filterUnidentified),
                        selected: _hasSpecies == false,
                        onSelected: (_) => apply(() => _hasSpecies = false),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(l10n.sectionGender,
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      ChoiceChip(
                        label: Text(l10n.filterAny),
                        selected: _gender == null,
                        onSelected: (_) => apply(() => _gender = null),
                      ),
                      for (final gender in Gender.values)
                        ChoiceChip(
                          label: Text(gender.label(l10n.code)),
                          selected: _gender == gender,
                          onSelected: (_) => apply(() => _gender = gender),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Text(l10n.sectionLifeStage,
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      ChoiceChip(
                        label: Text(l10n.filterAny),
                        selected: _lifeStage == null,
                        onSelected: (_) => apply(() => _lifeStage = null),
                      ),
                      for (final stage in LifeStage.values)
                        ChoiceChip(
                          label: Text(stage.label(l10n.code)),
                          selected: _lifeStage == stage,
                          onSelected: (_) => apply(() => _lifeStage = stage),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.done),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FlowingTitle(l10n.diaryTitle, size: 28),
        actions: [
          IconButton(
            icon: Icon(
              _hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _hasActiveFilters ? AppTheme.accent : null,
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddSighting,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: AppTheme.accent,
        child: FutureBuilder<List<BirdLog>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  ErrorRetry(
                      message: l10n.somethingWentWrong, onRetry: _reload),
                ],
              );
            }
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Center(
                    child: Text(l10n.diaryEmpty,
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(log),
                  child: ListTile(
                    onTap: () => _openDetail(log),
                    leading: log.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: resolveMediaUrl(log.photoUrl!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const CircleAvatar(
                            backgroundColor: AppTheme.backgroundElevated,
                            child: Icon(Icons.pets, color: AppTheme.accent),
                          ),
                    title: Text(log.displayName(l10n.code)),
                    subtitle: Text(_formatDate(log.observedAt)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
