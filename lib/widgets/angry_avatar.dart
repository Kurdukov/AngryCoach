import 'package:flutter/material.dart';

class AngryAvatar extends StatelessWidget {
  const AngryAvatar({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/coach_3d.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.sports_martial_arts_rounded, size: size * 0.72);
        },
      ),
    );
  }
}
