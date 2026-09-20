import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BirdLog>> _load() {
    final userId = context.read<AuthSession>().currentUser!.id;
    return context.read<BirdLogService>().getForUser(userId);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FlowingTitle(l10n.diaryTitle, size: 28),
        actions: [
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
