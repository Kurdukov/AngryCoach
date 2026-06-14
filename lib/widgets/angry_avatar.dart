import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';

class AngryAvatar extends StatelessWidget {
  const AngryAvatar({
    super.key,
    this.size = 120,
    this.intensity = CoachIntensity.toxic,
  });

  final double size;
  final CoachIntensity intensity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetName,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.sports_martial_arts_rounded, size: size * 0.72);
        },
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
}
