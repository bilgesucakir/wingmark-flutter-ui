import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/user_settings.dart';
import '../../services/user_service.dart';
import '../../state/auth_session.dart';
import '../../state/settings_controller.dart';
import '../../widgets/section_header.dart';

/// Language is app-local (AppStorage-equivalent, matching Swift). Unit
/// preference additionally syncs with GET/PUT /api/users/{id}/settings —
/// the Swift app only ever kept this local.
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

  Future<void> _updateUnitPreference(UnitPreference value) async {
    final controller = context.read<SettingsController>();
    final userId = context.read<AuthSession>().currentUser!.id;
    final userService = context.read<UserService>();
    await controller.setUnitPreference(value);
    try {
      await userService.updateSettings(
        userId,
        UserSettings(unitPreference: value),
      );
    } catch (_) {
      // Local preference already applied; backend sync will retry next visit.
    }
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
              if (value != null) settings.setLanguage(value);
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
