import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';
import '../theme/app_colors.dart';

class AngryAvatar extends StatelessWidget {
  const AngryAvatar({
    super.key,
    this.size = 120,
    this.intensity = CoachIntensity.toxic,
    this.reaction = CoachReaction.idle,
  });

  final double size;
  final CoachIntensity intensity;
  final CoachReaction reaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _reactionColor.withValues(alpha: 0.28),
                    _reactionColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: _reactionOffset,
            child: Transform.rotate(
              angle: _reactionAngle,
              child: Image.asset(
                _assetName,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_martial_arts_rounded,
                    size: size * 0.72,
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: size * 0.04,
            top: size * 0.06,
            child: _ReactionBadge(
              icon: _reactionIcon,
              color: _reactionColor,
              size: size * 0.26,
            ),
          ),
        ],
      ),
    );
  }

  String get _assetName {
    return switch (intensity) {
      CoachIntensity.sarcastic => 'assets/images/coach_3d_soft.png',
      CoachIntensity.toxic => 'assets/images/coach_3d.png',
      CoachIntensity.ruthless => 'assets/images/coach_3d_hard.png',
    };
  }

  Color get _reactionColor {
    return switch (reaction) {
      CoachReaction.idle => AppColors.primary,
      CoachReaction.success => AppColors.green,
      CoachReaction.fail => AppColors.pink,
      CoachReaction.streak => AppColors.primarySoft,
      CoachReaction.reset => AppColors.yellow,
    };
  }

  IconData get _reactionIcon {
    return switch (reaction) {
      CoachReaction.idle => Icons.visibility_rounded,
      CoachReaction.success => Icons.check_rounded,
      CoachReaction.fail => Icons.close_rounded,
      CoachReaction.streak => Icons.local_fire_department_rounded,
      CoachReaction.reset => Icons.restart_alt_rounded,
    };
  }

  Offset get _reactionOffset {
    return switch (reaction) {
      CoachReaction.success => Offset(0, -size * 0.03),
      CoachReaction.fail => Offset(size * 0.03, size * 0.02),
      CoachReaction.streak => Offset(0, -size * 0.05),
      CoachReaction.reset => Offset(0, size * 0.02),
      CoachReaction.idle => Offset.zero,
    };
  }

  double get _reactionAngle {
    return switch (reaction) {
      CoachReaction.success => -0.04,
      CoachReaction.fail => 0.06,
      CoachReaction.streak => -0.08,
      CoachReaction.reset => 0.0,
      CoachReaction.idle => 0.0,
    };
  }
}

class _ReactionBadge extends StatelessWidget {
  const _ReactionBadge({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size.clamp(24.0, 42.0).toDouble();
    final iconSize = size.clamp(14.0, 22.0).toDouble();

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
