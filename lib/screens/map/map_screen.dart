import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
import '../../services/bird_log_service.dart';
import '../../state/auth_session.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/flowing_title.dart';
import '../diary/bird_log_detail_screen.dart';

/// Real map view backed by GET /api/bird-logs/user/{userId} — the Swift
/// app's MapView was still a placeholder icon, this pins actual sightings
/// with each log's own photo (or a placeholder silhouette).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

/// Public so RootTabView can auto-refresh this tab on reselect — see
/// DiaryScreenState for why that's needed with IndexedStack.
class MapScreenState extends State<MapScreen> {
  late Future<List<BirdLog>> _future;
  final _mapController = MapController();

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

  void _onMarkerTap(BirdLog log, AppLocalizations l10n) {
    final point = ll.LatLng(log.latitude!, log.longitude!);
    // Focus the map on this sighting first, then bring up its details.
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(point, currentZoom < 14 ? 15 : currentZoom);
    _showSightingSheet(log, l10n);
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
        title: FlowingTitle(l10n.mapTitle, size: 28),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<List<BirdLog>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snapshot.hasError) {
            return ErrorRetry(
                message: l10n.somethingWentWrong, onRetry: _reload);
          }
          final logs = (snapshot.data ?? [])
              .where((l) => l.latitude != null && l.longitude != null)
              .toList();
          final center = logs.isNotEmpty
              ? ll.LatLng(logs.first.latitude!, logs.first.longitude!)
              : const ll.LatLng(20, 0);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: logs.isNotEmpty ? 10 : 2,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.wingmark.app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final log in logs)
                        Marker(
                          point: ll.LatLng(log.latitude!, log.longitude!),
                          width: 46,
                          height: 56,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _onMarkerTap(log, l10n),
                            child: _PhotoPin(log: log),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (logs.isEmpty)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.mapEmpty,
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSightingSheet(BirdLog log, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundElevated,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openDetail(log);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: log.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: resolveMediaUrl(log.photoUrl!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(40),
                          child: Image.asset(kBirdPlaceholderAsset),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(log.displayName(l10n.code),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${log.observedAt.toLocal()}'.split('.').first,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              if (log.locationName != null) ...[
                const SizedBox(height: 4),
                Text(log.locationName!,
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A circular thumbnail (the log's photo, or the bird silhouette fallback)
/// with a small pin pointer beneath it.
class _PhotoPin extends StatelessWidget {
  const _PhotoPin({required this.log});

  final BirdLog log;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: log.photoUrl != null
                ? AppTheme.backgroundElevated
                : Colors.white,
            border: Border.all(color: AppTheme.accent, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: log.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: resolveMediaUrl(log.photoUrl!),
                  fit: BoxFit.cover,
                )
              : Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(kBirdPlaceholderAsset),
                ),
        ),
        const Icon(Icons.arrow_drop_down, color: AppTheme.accent, size: 20),
      ],
    );
  }
}
