import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/user_settings.dart';
import '../../services/user_service.dart';
import '../../state/auth_session.dart';
import '../../state/settings_controller.dart';
import '../../widgets/section_header.dart';

/// Language selection updates the Accept-Language header immediately (via
/// ApiClient.languageCode) and refreshes the cached profile so
/// server-resolved text (favoriteSpeciesName, species/badge names) catches
/// up right away, instead of waiting for the next unrelated fetch. Both
/// language and unit preference are also persisted together via
/// PUT /api/users/{id}/settings, since sending either field alone would
/// silently clear the other back to null server-side.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    _syncFromBackend();
  }

  Future<void> _syncFromBackend() async {
    try {
      final userId = context.read<AuthSession>().currentUser!.id;
      final remote = await context.read<UserService>().getSettings(userId);
      if (!mounted) return;
      await context
          .read<SettingsController>()
          .setUnitPreference(remote.unitPreference);
    } catch (_) {
      // Fall back to the locally cached preference on failure.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Persists both fields together on every change so updating one never
  /// silently clobbers the other back to null on the backend.
  Future<void> _syncToBackend(SettingsController controller) async {
    final userId = context.read<AuthSession>().currentUser!.id;
    final userService = context.read<UserService>();
    try {
      await userService.updateSettings(
        userId,
        UserSettings(
          unitPreference: controller.unitPreference,
          locale: controller.effectiveLanguageCode,
        ),
      );
    } catch (_) {
      // Local preference already applied; backend sync will retry next visit.
    }
  }

  Future<void> _updateLanguage(AppLanguage value) async {
    final controller = context.read<SettingsController>();
    await controller.setLanguage(value);
    if (!mounted) return;
    // Update the Accept-Language header immediately rather than waiting for
    // app.dart's next MaterialApp rebuild, so the very next request (the
    // profile refresh below) already uses it.
    context.read<ApiClient>().languageCode = controller.effectiveLanguageCode;
    await context.read<AuthSession>().refreshProfile();
    await _syncToBackend(controller);
  }

  Future<void> _updateUnitPreference(UnitPreference value) async {
    final controller = context.read<SettingsController>();
    await controller.setUnitPreference(value);
    await _syncToBackend(controller);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(l10n.language),
          RadioGroup<AppLanguage>(
            groupValue: settings.language,
            onChanged: (value) {
              if (value != null) _updateLanguage(value);
            },
            child: Column(
              children: [
                for (final lang in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(lang.label(l10n.code)),
                    value: lang,
                  ),
              ],
            ),
          ),
          Text(l10n.languageFooter,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          SectionHeader(l10n.units),
          if (_syncing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: AppTheme.accent),
            ),
          RadioGroup<UnitPreference>(
            groupValue: settings.unitPreference,
            onChanged: (value) {
              if (value != null) _updateUnitPreference(value);
            },
            child: Column(
              children: [
                for (final unit in UnitPreference.values)
                  RadioListTile<UnitPreference>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(unit.label(l10n.code)),
                    value: unit,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
