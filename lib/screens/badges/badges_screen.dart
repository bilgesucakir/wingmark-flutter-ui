import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/badge.dart';
import '../../models/enums.dart';
import '../../models/user_badge.dart';
import '../../services/badge_service.dart';
import '../../state/auth_session.dart';
import '../../widgets/badge_icons.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/flowing_title.dart';

/// Backed by real backend progress (GET /api/badges/catalog +
/// /api/badges/user/{userId}) instead of the Swift app's local mock catalog.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => BadgesScreenState();
}

/// Public so RootTabView can auto-refresh this tab on reselect — see
/// DiaryScreenState for why that's needed with IndexedStack.
class BadgesScreenState extends State<BadgesScreen> {
  late Future<_BadgesData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BadgesData> _load() async {
    final service = context.read<BadgeService>();
    final userId = context.read<AuthSession>().currentUser!.id;
    final results = await Future.wait([
      service.getCatalog(),
      service.getForUser(userId),
    ]);
    final catalog = results[0] as List<BadgeDefinition>;
    final userBadges = results[1] as List<UserBadge>;
    final tierByBadgeId = {for (final b in catalog) b.id: b.tier};
    return _BadgesData(userBadges, tierByBadgeId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: FlowingTitle(l10n.badgesTitle, size: 28)),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: AppTheme.accent,
        child: FutureBuilder<_BadgesData>(
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
                ErrorRetry(message: l10n.somethingWentWrong, onRetry: _reload),
              ],
            );
          }
          final data = snapshot.data!;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: data.badges.length,
            itemBuilder: (context, index) {
              final badge = data.badges[index];
              final tier = data.tierByBadgeId[badge.badgeId];
              final color = badge.earned
                  ? (tier != null ? AppTheme.tierColor(tier.value) : AppTheme.accent)
                  : AppTheme.textSecondary.withValues(alpha: 0.5);
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: badge.earned ? 1 : 0.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconForBadge(badge.badgeIcon), size: 36, color: color),
                      const SizedBox(height: 8),
                      Text(
                        badge.badgeName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (tier != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          tier.label(l10n.code),
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                      if (!badge.earned) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${badge.progress}/${badge.targetValue}',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
          },
        ),
      ),
    );
  }
}

class _BadgesData {
  final List<UserBadge> badges;
  final Map<String, BadgeTier> tierByBadgeId;
  _BadgesData(this.badges, this.tierByBadgeId);
}
