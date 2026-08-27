import 'dart:math';

import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';
import '../theme/app_colors.dart';

/// The coach mascot.
///
/// Two animations run independently:
/// - `_idle`: an infinite, gentle bob + breathe loop, so the coach is
///   never fully static — previously it only moved once on a reaction and
///   sat frozen the rest of the time.
/// - `_reaction`: a one-shot punch that replays from 0 whenever
///   [reaction] changes, with a per-reaction shape (pop for success/streak
///   with a confetti burst, a shake for fail, a spin-fade for reset).
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
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _reaction;
  late final List<_Particle> _particles;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _reaction = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AngryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction) {
      if (_reduceMotion) {
        _reaction.value = 1;
      } else {
        _reaction.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _reaction.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles() {
    final random = Random(7);
    return List.generate(10, (index) {
      final angle = (index / 10) * 2 * pi + random.nextDouble() * 0.3;
      return _Particle(
        angle: angle,
        distance: 0.55 + random.nextDouble() * 0.45,
        size: 3.0 + random.nextDouble() * 3.5,
        speckColor: index.isEven ? AppColors.accent : AppColors.success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _reaction]),
      builder: (context, _) {
        final idleT = _reduceMotion ? 0.0 : Curves.easeInOut.transform(_idle.value);
        final bob = (idleT - 0.5) * widget.size * 0.03;
        final breathe = 1 + (idleT * 0.018);

        final t = _reaction.value;
        final settle = Curves.easeOut.transform((t * 2.4).clamp(0.0, 1.0));
        final pop = Curves.elasticOut.transform(t);

        final shake = widget.reaction == CoachReaction.fail
            ? sin(t * pi * 7) * (1 - t) * widget.size * 0.05
            : 0.0;
        final spin = widget.reaction == CoachReaction.reset
            ? (1 - Curves.easeOut.transform(t)) * pi * 0.6
            : 0.0;
        final scale = breathe * (0.88 + (0.12 * pop));

        return SizedBox(
          width: widget.size,
          height: widget.size * 1.22,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: widget.size * 0.06,
                child: Opacity(
                  opacity: (0.16 + 0.1 * idleT) * (0.7 + 0.3 * settle),
                  child: Container(
                    width: widget.size * 0.72,
                    height: widget.size * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _reactionColor.withValues(alpha: 0.55),
                          _reactionColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (t < 1 &&
                  (widget.reaction == CoachReaction.success ||
                      widget.reaction == CoachReaction.streak))
                Positioned(
                  top: widget.size * 0.1,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        particles: _particles,
                        progress: t,
                        size: widget.size,
                        big: widget.reaction == CoachReaction.streak,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: widget.size * 0.02 + bob,
                child: Transform.translate(
                  offset: Offset(shake, 0),
                  child: Transform.rotate(
                    angle: spin,
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
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
                ),
              ),
              if (widget.size >= 82)
                Positioned(
                  bottom: 0,
                  child: Opacity(
                    opacity: settle,
                    child: _ReactionLabel(
                      icon: _reactionIcon,
                      label: _reactionLabel,
                      color: _reactionColor,
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
      CoachReaction.idle => AppColors.accent,
      CoachReaction.success => AppColors.success,
      CoachReaction.fail => AppColors.danger,
      CoachReaction.streak => AppColors.accent,
      CoachReaction.reset => AppColors.warning,
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
}

class _ReactionLabel extends StatelessWidget {
  const _ReactionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speckColor,
  });

  final double angle;
  final double distance;
  final double size;
  final Color speckColor;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.size,
    required this.big,
  });

  final List<_Particle> particles;
  final double progress;
  final double size;
  final bool big;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (progress >= 1) {
      return;
    }
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final travel = Curves.easeOut.transform(progress);
    final fade = 1 - Curves.easeIn.transform(progress);
    final reach = size * (big ? 0.62 : 0.46);

    for (final particle in particles) {
      final distance = travel * reach * particle.distance;
      final offset = Offset(
        center.dx + cos(particle.angle) * distance,
        center.dy + sin(particle.angle) * distance,
      );
      final paint = Paint()
        ..color = particle.speckColor.withValues(alpha: fade)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, particle.size * (big ? 1.2 : 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
