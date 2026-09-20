import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_localizations.dart';
import '../../models/species.dart';
import '../../models/user.dart';
import '../../services/species_service.dart';
import '../../services/user_service.dart';
import '../../widgets/section_header.dart';

/// Edit first/last name and favorite species (PUT /api/users/{id}).
/// Pops with the updated UserProfile on success, or null if cancelled.
///
/// favoriteSpeciesName comes back already locale-resolved by the backend
/// (via the Accept-Language header — see ApiClient.languageCode), so this
/// screen never needs to fetch the full Species just to show its name.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _firstNameController =
      TextEditingController(text: widget.user.firstName);
  late final _lastNameController =
      TextEditingController(text: widget.user.lastName);
  final _speciesSearchController = TextEditingController();
  Timer? _debounce;

  late String? _favoriteSpeciesId = widget.user.favoriteSpeciesId;
  late String? _favoriteSpeciesName = widget.user.favoriteSpeciesName;
  bool _pickingFavorite = false;
  List<Species> _searchResults = [];

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _speciesSearchController.dispose();
    super.dispose();
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
            await context.read<SpeciesService>().search(query: value.trim());
        if (mounted) setState(() => _searchResults = results.content);
      } catch (_) {
        // Ignore transient search errors; user can keep typing/retry.
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await context.read<UserService>().updateProfile(
            widget.user.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            favoriteSpeciesId: _favoriteSpeciesId,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppLocalizations.of(context).somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        leadingWidth: 80,
        title: Text(l10n.editProfileTitle),
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
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: l10n.firstName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: l10n.lastName),
          ),
          SectionHeader(l10n.favoriteSpecies),
          if (_pickingFavorite) ...[
            TextField(
              controller: _speciesSearchController,
              autofocus: true,
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
                  _favoriteSpeciesName = species.name(l10n.code);
                  _favoriteSpeciesId = species.id;
                  _pickingFavorite = false;
                  _searchResults = [];
                  _speciesSearchController.clear();
                }),
              ),
          ] else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_favoriteSpeciesName ?? l10n.noFavoriteSpecies),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (_favoriteSpeciesName != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _favoriteSpeciesName = null;
                        _favoriteSpeciesId = null;
                      }),
                    ),
                  TextButton(
                    onPressed: () => setState(() => _pickingFavorite = true),
                    child: Text(l10n.chooseFavoriteSpecies),
                  ),
                ],
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFE58C8C))),
          ],
        ],
      ),
    );
  }
}
