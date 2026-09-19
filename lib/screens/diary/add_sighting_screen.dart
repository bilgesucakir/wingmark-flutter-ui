import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
import '../../models/enums.dart';
import '../../models/species.dart';
import '../../services/bird_log_service.dart';
import '../../services/species_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/section_header.dart';

/// New-sighting form. Extends the Swift app's AddSightingView with what it
/// was missing entirely: photo capture, gender, latitude/longitude (required
/// by the backend), pet/custom-name/visibility — all modeled already but
/// absent from the original screen.
class AddSightingScreen extends StatefulWidget {
  const AddSightingScreen({super.key});

  @override
  State<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends State<AddSightingScreen> {
  DateTime _date = DateTime.now();
  final _locationNameController = TextEditingController();
  final _speciesSearchController = TextEditingController();
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();

  ll.LatLng? _point;
  bool _locating = true;

  Species? _selectedSpecies;
  SpeciesStatus _speciesStatus = SpeciesStatus.confident;
  bool _doesNotKnowSpecies = false;
  List<Species> _searchResults = [];
  Timer? _debounce;

  LifeStage _lifeStage = LifeStage.adult;
  Gender _gender = Gender.unknown;
  bool _isPet = false;

  XFile? _photo;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationNameController.dispose();
    _speciesSearchController.dispose();
    _customNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locating = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _point = ll.LatLng(position.latitude, position.longitude);
        _locating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onSpeciesQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results =
            await context.read<SpeciesService>().search(value.trim());
        if (mounted) setState(() => _searchResults = results);
      } catch (_) {
        // Ignore transient search errors; user can keep typing/retry.
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_point == null) {
      setState(() => _error = l10n.locationRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    // Read providers before the first await — using `context` for anything
    // context-dependent after an await needs a `mounted` guard instead.
    final uploadService = context.read<UploadService>();
    final birdLogService = context.read<BirdLogService>();

    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await uploadService.uploadPhoto(_photo!.path);
      }

      final request = BirdLogRequest(
        speciesId: _doesNotKnowSpecies ? null : _selectedSpecies?.id,
        speciesStatus:
            (_doesNotKnowSpecies || _selectedSpecies == null) ? null : _speciesStatus,
        pet: _isPet,
        customName: _customNameController.text.trim().isEmpty
            ? null
            : _customNameController.text.trim(),
        lifeStage: _lifeStage,
        gender: _gender,
        photoUrl: photoUrl,
        note: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        latitude: _point!.latitude,
        longitude: _point!.longitude,
        locationName: _locationNameController.text.trim().isEmpty
            ? null
            : _locationNameController.text.trim(),
      );

      await birdLogService.create(request);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = l10n.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        leadingWidth: 80,
        title: Text(l10n.addSightingTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SectionHeader(l10n.sectionWhenWhere),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.date),
            subtitle: Text(DateFormat.yMMMd(l10n.code).add_Hm().format(_date)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _locationNameController,
            decoration: InputDecoration(labelText: l10n.locationName),
          ),
          const SizedBox(height: 12),
          Text(l10n.tapMapToAdjust,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _locating
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: _point ?? const ll.LatLng(20, 0),
                        initialZoom: _point != null ? 12 : 2,
                        onTap: (tapPosition, point) {
                          setState(() => _point = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.wingmark.app',
                        ),
                        if (_point != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: _point!,
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
          TextButton.icon(
            onPressed: () {
              setState(() => _locating = true);
              _resolveCurrentLocation();
            },
            icon: const Icon(Icons.my_location, size: 18),
            label: Text(l10n.useCurrentLocation),
          ),
          SectionHeader(l10n.sectionSpecies),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.doNotKnowSpecies),
            value: _doesNotKnowSpecies,
            onChanged: (value) => setState(() {
              _doesNotKnowSpecies = value;
              if (value) {
                _selectedSpecies = null;
                _searchResults = [];
                _speciesSearchController.clear();
              }
            }),
          ),
          if (!_doesNotKnowSpecies) ...[
            if (_selectedSpecies != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedSpecies!.name(l10n.code)),
                subtitle: Text(_selectedSpecies!.scientificName,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedSpecies = null),
                ),
              )
            else ...[
              TextField(
                controller: _speciesSearchController,
                onChanged: _onSpeciesQueryChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchSpecies,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              for (final species in _searchResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(species.name(l10n.code)),
                  subtitle: Text(species.scientificName,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  onTap: () => setState(() {
                    _selectedSpecies = species;
                    _searchResults = [];
                    _speciesSearchController.clear();
                  }),
                ),
            ],
            if (_selectedSpecies != null) ...[
              const SizedBox(height: 8),
              SectionHeader(l10n.sectionStatus),
              SegmentedButton<SpeciesStatus>(
                segments: [
                  ButtonSegment(
                    value: SpeciesStatus.confident,
                    label: Text(SpeciesStatus.confident.label(l10n.code)),
                  ),
                  ButtonSegment(
                    value: SpeciesStatus.guess,
                    label: Text(SpeciesStatus.guess.label(l10n.code)),
                  ),
                ],
                selected: {_speciesStatus},
                onSelectionChanged: (s) =>
                    setState(() => _speciesStatus = s.first),
              ),
            ],
          ],
          SectionHeader(l10n.sectionLifeStage),
          SegmentedButton<LifeStage>(
            segments: [
              for (final stage in LifeStage.values)
                ButtonSegment(value: stage, label: Text(stage.label(l10n.code))),
            ],
            selected: {_lifeStage},
            onSelectionChanged: (s) => setState(() => _lifeStage = s.first),
          ),
          SectionHeader(l10n.sectionGender),
          SegmentedButton<Gender>(
            segments: [
              for (final gender in Gender.values)
                ButtonSegment(value: gender, label: Text(gender.label(l10n.code))),
            ],
            selected: {_gender},
            onSelectionChanged: (s) => setState(() => _gender = s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.sectionPet),
            value: _isPet,
            onChanged: (value) => setState(() => _isPet = value),
          ),
          TextField(
            controller: _customNameController,
            decoration: InputDecoration(labelText: l10n.sectionCustomName),
          ),
          SectionHeader(l10n.sectionPhoto),
          if (_photo != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photo!.path),
                      height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black45),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _photo = null),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.addPhoto),
            ),
          SectionHeader(l10n.sectionNotes),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFE58C8C))),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
