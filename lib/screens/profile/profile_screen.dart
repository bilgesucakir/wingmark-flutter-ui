import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/bird_log.dart';
import '../../services/bird_log_service.dart';
import '../../state/auth_session.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/flowing_title.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundElevated,
        title: Text(l10n.logOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logOut,
                style: const TextStyle(color: Color(0xFFE58C8C))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthSession>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthSession>().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: FlowingTitle(l10n.profileTitle, size: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.account_circle, size: 96, color: AppTheme.accent),
          const SizedBox(height: 12),
          Center(
            child: Text(user.fullName,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Center(
            child: Text('@${user.username}',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          Center(
            child: Text(user.email,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              l10n.joined(DateFormat.yMMMM(l10n.code).format(user.createdAt)),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<BirdLog>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: AppTheme.accent)),
                );
              }
              if (snapshot.hasError) {
                return ErrorRetry(
                  message: l10n.somethingWentWrong,
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                );
              }
              final logs = snapshot.data ?? [];
              final speciesCount =
                  logs.map((l) => l.speciesId).whereType<String>().toSet().length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(value: logs.length, label: l10n.sightingsCount),
                  _StatColumn(value: speciesCount, label: l10n.speciesCount),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE58C8C),
              side: const BorderSide(color: Color(0xFFE58C8C)),
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }
}
