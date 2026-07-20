import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Circular 0-100 Land Health Score gauge (docs/architecture/MODULES.md §4).
class LandHealthGauge extends StatelessWidget {
  const LandHealthGauge({super.key, required this.score, this.size = 120});

  final double score; // 0-100
  final double size;

  Color get _color {
    if (score >= 70) return AppColors.confidenceHigh;
    if (score >= 45) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(progress: score / 100, color: _color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.round().toString(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: _color, height: 1),
              ),
              Text('/ 100', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
