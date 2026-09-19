import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/species.dart';
import '../../models/species_recording.dart';
import '../../services/species_service.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/section_header.dart';

class SpeciesDetailScreen extends StatefulWidget {
  const SpeciesDetailScreen({super.key, required this.speciesId});

  final String speciesId;

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  late Future<_SpeciesDetailData> _future;
  final _player = AudioPlayer();
  String? _playingRecordingId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SpeciesDetailData> _load() async {
    final service = context.read<SpeciesService>();
    final species = await service.getById(widget.speciesId);
    List<SpeciesRecording> sounds = [];
    try {
      sounds = await service.getSounds(widget.speciesId);
    } catch (_) {
      // Sound guide feature is optional (needs XENO_CANTO_API_KEY server-side).
    }
    return _SpeciesDetailData(species, sounds);
  }

  Future<void> _toggle(SpeciesRecording recording) async {
    if (_playingRecordingId == recording.id) {
      await _player.stop();
      setState(() => _playingRecordingId = null);
      return;
    }
    try {
      await _player.setUrl(recording.recordingUrl);
      setState(() => _playingRecordingId = recording.id);
      await _player.play();
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingRecordingId = null);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _playingRecordingId = null);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget _localizedSection(String label, Map<String, String>? map, String locale) {
    final text = localizedText(map, locale);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(label),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: FutureBuilder<_SpeciesDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: ErrorRetry(
                message: l10n.somethingWentWrong,
                onRetry: () => setState(() {
                  _future = _load();
                }),
              ),
            );
          }
          final species = snapshot.data!.species;
          final sounds = snapshot.data!.sounds;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: species.images.isNotEmpty ? 220 : 0,
                flexibleSpace: species.images.isNotEmpty
                    ? FlexibleSpaceBar(
                        background: PageView(
                          children: [
                            for (final image in species.images)
                              CachedNetworkImage(
                                  imageUrl: image.imageUrl, fit: BoxFit.cover),
                          ],
                        ),
                      )
                    : null,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(species.name(l10n.code),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    Text(species.scientificName,
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary)),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Açıklama' : 'Description',
                        species.description,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Habitat' : 'Habitat',
                        species.habitat,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Beslenme' : 'Diet',
                        species.diet,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Boyut' : 'Size',
                        species.sizeDescription,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Yaşam süresi' : 'Lifespan',
                        species.lifespan,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Korunma durumu' : 'Conservation status',
                        species.conservationStatus,
                        l10n.code),
                    _localizedSection(
                        l10n.code == 'tr' ? 'Doğal yayılış alanı' : 'Native range',
                        species.nativeRange,
                        l10n.code),
                    SectionHeader(l10n.soundsTitle),
                    if (sounds.isEmpty)
                      Text(l10n.noSounds,
                          style: TextStyle(color: AppTheme.textSecondary))
                    else
                      ...sounds.map((r) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _playingRecordingId == r.id
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: AppTheme.accent,
                              size: 32,
                            ),
                            title: Text(r.recordist ?? 'Xeno-canto'),
                            subtitle: Text([
                              if (r.type != null) r.type!,
                              if (r.quality != null) 'Q${r.quality}',
                            ].join(' · ')),
                            trailing: r.licenseUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        size: 18),
                                    tooltip: l10n.code == 'tr'
                                        ? 'Lisans'
                                        : 'License',
                                    onPressed: () => launchUrl(
                                        Uri.parse(r.licenseUrl!),
                                        mode: LaunchMode.externalApplication),
                                  )
                                : null,
                            onTap: () => _toggle(r),
                          )),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpeciesDetailData {
  final Species species;
  final List<SpeciesRecording> sounds;
  _SpeciesDetailData(this.species, this.sounds);
}
