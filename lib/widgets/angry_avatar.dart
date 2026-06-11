import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AngryAvatar extends StatelessWidget {
  const AngryAvatar({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ToxicCoachPainter()),
    );
  }
}

class _ToxicCoachPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final paint = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = unit * 0.035
      ..color = AppColors.ink;

    void drawLimb(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, stroke);
    }

    paint.color = AppColors.lime;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.84),
        width: unit * 0.72,
        height: unit * 0.22,
      ),
      paint,
    );

    paint.color = AppColors.ink;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.54, size.height * 0.9),
        width: unit * 0.38,
        height: unit * 0.07,
      ),
      paint,
    );

    drawLimb([
      Offset(size.width * 0.36, size.height * 0.58),
      Offset(size.width * 0.18, size.height * 0.7),
      Offset(size.width * 0.12, size.height * 0.61),
    ]);
    drawLimb([
      Offset(size.width * 0.64, size.height * 0.58),
      Offset(size.width * 0.84, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.6),
    ]);

    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.11, size.height * 0.6),
      unit * 0.07,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.89, size.height * 0.59),
      unit * 0.07,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.11, size.height * 0.6),
      unit * 0.07,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.89, size.height * 0.59),
      unit * 0.07,
      stroke,
    );

    paint.color = AppColors.ink;
    final torso = Path()
      ..moveTo(size.width * 0.36, size.height * 0.56)
      ..lineTo(size.width * 0.64, size.height * 0.56)
      ..lineTo(size.width * 0.72, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.9,
        size.width * 0.28,
        size.height * 0.82,
      )
      ..close();
    canvas.drawPath(torso, paint);
    canvas.drawPath(torso, stroke);

    paint.color = Colors.white;
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.82),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.61, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.82),
      stroke,
    );

    drawLimb([
      Offset(size.width * 0.42, size.height * 0.82),
      Offset(size.width * 0.3, size.height * 0.96),
    ]);
    drawLimb([
      Offset(size.width * 0.58, size.height * 0.82),
      Offset(size.width * 0.72, size.height * 0.96),
    ]);

    paint.color = Colors.white;
    final leftShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.91,
        size.width * 0.2,
        size.height * 0.09,
      ),
      Radius.circular(unit * 0.04),
    );
    final rightShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.63,
        size.height * 0.91,
        size.width * 0.2,
        size.height * 0.09,
      ),
      Radius.circular(unit * 0.04),
    );
    canvas.drawRRect(leftShoe, paint);
    canvas.drawRRect(rightShoe, paint);
    canvas.drawRRect(leftShoe, stroke);
    canvas.drawRRect(rightShoe, stroke);

    paint.color = AppColors.orange;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.38),
      unit * 0.28,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.38),
      unit * 0.28,
      stroke,
    );

    paint.color = AppColors.lime;
    final band = Path()
      ..moveTo(size.width * 0.24, size.height * 0.29)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.19,
        size.width * 0.76,
        size.height * 0.29,
      )
      ..lineTo(size.width * 0.72, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.29,
        size.width * 0.28,
        size.height * 0.36,
      )
      ..close();
    canvas.drawPath(band, paint);
    canvas.drawPath(band, stroke);

    canvas.drawLine(
      Offset(size.width * 0.33, size.height * 0.4),
      Offset(size.width * 0.43, size.height * 0.36),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.67, size.height * 0.4),
      Offset(size.width * 0.57, size.height * 0.36),
      stroke,
    );

    paint.color = AppColors.ink;
    canvas.drawCircle(
      Offset(size.width * 0.39, size.height * 0.44),
      unit * 0.022,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.44),
      unit * 0.022,
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.54),
      Offset(size.width * 0.6, size.height * 0.54),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.46),
      Offset(size.width * 0.47, size.height * 0.51),
      stroke,
    );

    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.48),
      unit * 0.055,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.48),
      unit * 0.055,
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.53),
      Offset(size.width * 0.65, size.height * 0.62),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
