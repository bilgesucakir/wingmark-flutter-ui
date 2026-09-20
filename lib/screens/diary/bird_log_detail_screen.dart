import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
import '../../widgets/section_header.dart';
import 'add_sighting_screen.dart';

/// Full detail view for a single sighting, with an Edit action that reopens
/// AddSightingScreen pre-filled (see its `existing` parameter).
class BirdLogDetailScreen extends StatefulWidget {
  const BirdLogDetailScreen({super.key, required this.log});

  final BirdLog log;

  @override
  State<BirdLogDetailScreen> createState() => _BirdLogDetailScreenState();
}

class _BirdLogDetailScreenState extends State<BirdLogDetailScreen> {
  late BirdLog _log;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<BirdLog>(
      MaterialPageRoute(
        builder: (_) => AddSightingScreen(existing: _log),
      ),
    );
    if (result != null) {
      setState(() {
        _log = result;
        _changed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final log = _log;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
          ],
        ),
        body: ListView(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: log.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: resolveMediaUrl(log.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(48),
                      child: Image.asset(kBirdPlaceholderAsset),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.displayName(l10n.code),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  if (log.speciesStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        log.speciesStatus!.label(l10n.code),
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SectionHeader(l10n.date),
                  Text(DateFormat.yMMMd(l10n.code)
                      .add_Hm()
                      .format(log.observedAt.toLocal())),
                  if (log.locationName != null) ...[
                    SectionHeader(l10n.locationName),
                    Text(log.locationName!),
                  ],
                  if (log.latitude != null && log.longitude != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 160,
                        child: IgnorePointer(
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter:
                                  ll.LatLng(log.latitude!, log.longitude!),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.wingmark.app',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point:
                                      ll.LatLng(log.latitude!, log.longitude!),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.location_pin,
                                      color: AppTheme.accent, size: 32),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  SectionHeader(l10n.sectionLifeStage),
                  Text(log.lifeStage.label(l10n.code)),
                  SectionHeader(l10n.sectionGender),
                  Text(log.gender.label(l10n.code)),
                  if (log.pet) ...[
                    SectionHeader(l10n.sectionPet),
                    const Icon(Icons.pets, color: AppTheme.accent),
                  ],
                  if (log.note != null && log.note!.trim().isNotEmpty) ...[
                    SectionHeader(l10n.sectionNotes),
                    Text(log.note!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
