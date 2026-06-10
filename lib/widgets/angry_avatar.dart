import 'package:flutter/material.dart';

class AngryAvatar extends StatelessWidget {
  const AngryAvatar({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC107), width: 2),
      ),
      child: Text('😒', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
