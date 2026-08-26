import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';

class AngryAvatar extends StatefulWidget {
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
  State<AngryAvatar> createState() => _AngryAvatarState();
}

class _AngryAvatarState extends State<AngryAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Starts "settled" (value = 1) so an idle avatar renders at rest
    // instead of stuck mid-animation. A reaction change replays the
    // bounce from 0.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AngryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ??
          false;
      if (reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bounce = Curves.elasticOut.transform(_controller.value);
        final scale = 0.86 + (0.14 * bounce);
        final settle = Curves.easeOut.transform(
          (_controller.value * 2.4).clamp(0.0, 1.0),
        );

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: settle,
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
              ),
              Transform.scale(
                scale: scale,
                child: Transform.translate(
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
                          size: widget.size * 0.72,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: widget.size * 0.04,
                right: widget.size * 0.04,
                bottom: widget.size * 0.02,
                child: Transform.scale(
                  scale: 0.85 + (0.15 * settle),
                  child: Opacity(
                    opacity: settle,
                    child: _ReactionBadge(
                      icon: _reactionIcon,
                      label: _reactionLabel,
                      color: _reactionColor,
                      avatarSize: widget.size,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _assetName {
    return switch (widget.intensity) {
      CoachIntensity.sarcastic => 'assets/images/coach_3d_soft.png',
      CoachIntensity.toxic => 'assets/images/coach_3d.png',
      CoachIntensity.ruthless => 'assets/images/coach_3d_hard.png',
    };
  }

  Color get _reactionColor {
    return switch (widget.reaction) {
      CoachReaction.idle => const Color(0xFF0B1220),
      CoachReaction.success => const Color(0xFF0B6B3A),
      CoachReaction.fail => const Color(0xFF8A1235),
      CoachReaction.streak => const Color(0xFF0057D9),
      CoachReaction.reset => const Color(0xFF7A4D00),
    };
  }

  IconData get _reactionIcon {
    return switch (widget.reaction) {
      CoachReaction.idle => Icons.visibility_rounded,
      CoachReaction.success => Icons.emoji_events_rounded,
      CoachReaction.fail => Icons.warning_amber_rounded,
      CoachReaction.streak => Icons.bolt_rounded,
      CoachReaction.reset => Icons.restart_alt_rounded,
    };
  }

  String get _reactionLabel {
    return switch (widget.reaction) {
      CoachReaction.idle => 'ЖДУ ОТЧЁТ',
      CoachReaction.success => 'ЗАЧЁТ',
      CoachReaction.fail => 'ПРОВАЛ',
      CoachReaction.streak => 'СЕРИЯ',
      CoachReaction.reset => 'СБРОС',
    };
  }

  Offset get _reactionOffset {
    return switch (widget.reaction) {
      CoachReaction.success => Offset(0, -widget.size * 0.03),
      CoachReaction.fail => Offset(widget.size * 0.03, widget.size * 0.02),
      CoachReaction.streak => Offset(0, -widget.size * 0.05),
      CoachReaction.reset => Offset(0, widget.size * 0.02),
      CoachReaction.idle => Offset.zero,
    };
  }

  double get _reactionAngle {
    return switch (widget.reaction) {
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
    required this.label,
    required this.color,
    required this.avatarSize,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final compact = avatarSize < 82;
    final height = compact ? 26.0 : 34.0;
    final iconSize = compact ? 14.0 : 17.0;
    final fontSize = compact ? 9.0 : 11.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: iconSize),
          if (!compact) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
