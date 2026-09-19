/// Mirrors backend UserBadgeResponseDto — per-user progress against a badge,
/// with badgeName already locale-resolved server-side.
class UserBadge {
  final String badgeId;
  final String badgeName;
  final String badgeIcon;
  final bool earned;
  final DateTime? earnedAt;
  final int progress;
  final int targetValue;

  UserBadge({
    required this.badgeId,
    required this.badgeName,
    required this.badgeIcon,
    required this.earned,
    this.earnedAt,
    required this.progress,
    required this.targetValue,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId: json['badgeId'] as String,
      badgeName: json['badgeName'] as String? ?? '',
      badgeIcon: json['badgeIcon'] as String? ?? 'emoji_events',
      earned: json['earned'] as bool? ?? false,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
    );
  }
}
