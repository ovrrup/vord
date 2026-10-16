import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PomodoroTomatoTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final String statusLabel;

  const PomodoroTomatoTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.statusLabel,
  });

  String _formatTime(int totalSecs) {
    final minutes = totalSecs ~/ 60;
    final seconds = totalSecs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = remainingSeconds / 60.0;
    // Rotation angle: 0 aligns with 12 o'clock when 0 mins remaining.
    // Negative rotation so it turns counter-clockwise as time is set, then rotates clockwise back to 0 as it counts down.
    final targetTurn = -(minutes / 60.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Realistic Mechanical Pomodoro Tomato
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom hemisphere & surface shadow
              const CustomPaint(
                size: Size(250, 250),
                painter: _TomatoBasePainter(),
              ),

              // Rotating Top Hemisphere with stamped mechanical numbers & stem
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: targetTurn, end: targetTurn),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, animatedTurn, child) {
                  return Transform.rotate(
                    angle: animatedTurn * 2 * math.pi,
                    child: const CustomPaint(
                      size: Size(250, 250),
                      painter: _TomatoRotatingDialPainter(),
                    ),
                  );
                },
              ),

              // Stationary Center Reference Indicator & Stem Overlay
              const CustomPaint(
                size: Size(250, 250),
                painter: _TomatoStaticOverlayPainter(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Digital Readout
        Text(
          _formatTime(remainingSeconds),
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 54,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.0,
            color: const Color(0xFFFFF0F3),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        const SizedBox(height: 8),

        // Status Label with subtle pulse
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            statusLabel,
            key: ValueKey<String>('$statusLabel-$remainingSeconds'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isRunning
                  ? const Color(0xFFFF758F) // Soft glazed coral-pink
                  : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the base tomato body, bottom hemisphere, and surface shadow
class _TomatoBasePainter extends CustomPainter {
  const _TomatoBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Soft grounded ambient drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.88),
        width: radius * 1.6,
        height: radius * 0.35,
      ),
      shadowPaint,
    );

    // 2. Tomato base sphere background gradient
    final baseRect = Rect.fromCircle(center: center, radius: radius);
    final baseGradient = RadialGradient(
      center: const Alignment(-0.25, -0.2),
      radius: 0.85,
      colors: const [
        Color(0xFFFF2A4D), // Glaze crimson highlight
        Color(0xFFBA181B), // Rich cherry red
        Color(0xFF660708), // Deep shadow edge
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final bodyPaint = Paint()..shader = baseGradient.createShader(baseRect);
    canvas.drawCircle(center, radius, bodyPaint);

    // 3. Realistic lower hemisphere gloss sheen
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x55FFFFFF),
          Color(0x00FFFFFF),
          Color(0x22FFFFFF),
        ],
      ).createShader(baseRect);
    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the rotating top dome of the tomato with mechanical stamped numbers
class _TomatoRotatingDialPainter extends CustomPainter {
  const _TomatoRotatingDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Dial split-seam track (the metallic/engraved band where numbers sit)
    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..color = const Color(0x40000000);
    canvas.drawCircle(center, radius - 14, bandPaint);

    // 2. Stamped minute graduations & numbers (0 to 55)
    for (var m = 0; m < 60; m++) {
      final isMajor = m % 5 == 0;
      final angle = (m * (2 * math.pi / 60)) - (math.pi / 2);

      final outerR = radius - 4;
      final innerR = isMajor ? radius - 14 : radius - 9;

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = isMajor ? const Color(0xFFFFF0F3) : const Color(0x88FFFFFF)
        ..strokeWidth = isMajor ? 1.5 : 0.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);

      // Draw minute numbers for major graduations (0, 5, 10, 15...)
      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$m',
            style: const TextStyle(
              color: Color(0xFFFFF0F3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final textRadius = radius - 22;
        final textCenter = Offset(
          center.dx + textRadius * math.cos(angle),
          center.dy + textRadius * math.sin(angle),
        );

        canvas.save();
        canvas.translate(textCenter.dx, textCenter.dy);
        canvas.rotate(angle + math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }

    // 3. Tomato Stem Crown (5 natural star leaves attached to rotating dome)
    _paintLeafCrown(canvas, center);
  }

  void _paintLeafCrown(Canvas canvas, Offset center) {
    const leafCount = 5;
    const leafLength = 32.0;

    for (var i = 0; i < leafCount; i++) {
      final leafAngle = (i * (2 * math.pi / leafCount)) - (math.pi / 2);

      final path = Path();
      path.moveTo(center.dx, center.dy);

      final tip = Offset(
        center.dx + leafLength * math.cos(leafAngle),
        center.dy + leafLength * math.sin(leafAngle),
      );

      final ctrl1 = Offset(
        center.dx + (leafLength * 0.5) * math.cos(leafAngle - 0.35),
        center.dy + (leafLength * 0.5) * math.sin(leafAngle - 0.35),
      );
      final ctrl2 = Offset(
        center.dx + (leafLength * 0.5) * math.cos(leafAngle + 0.35),
        center.dy + (leafLength * 0.5) * math.sin(leafAngle + 0.35),
      );

      path.quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy);
      path.quadraticBezierTo(ctrl2.dx, ctrl2.dy, center.dx, center.dy);
      path.close();

      final leafPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2D6A4F), // Deep forest leaf green
            Color(0xFF40916C), // Vibrant organic foliage
          ],
        ).createShader(Rect.fromCircle(center: center, radius: leafLength));

      canvas.drawPath(path, leafPaint);
    }

    // Center stem core
    final stemCorePaint = Paint()..color = const Color(0xFF1B4332);
    canvas.drawCircle(center, 7, stemCorePaint);

    final stemTopPaint = Paint()..color = const Color(0xFF52B788);
    canvas.drawCircle(Offset(center.dx - 1, center.dy - 1), 3.5, stemTopPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the fixed reference alignment indicator and glazed surface specular reflection
class _TomatoStaticOverlayPainter extends CustomPainter {
  const _TomatoStaticOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Crisp white reference indicator at 12 o'clock (fixed alignment needle)
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final markerPath = Path();
    markerPath.moveTo(center.dx, center.dy - radius - 2);
    markerPath.lineTo(center.dx - 4, center.dy - radius - 9);
    markerPath.lineTo(center.dx + 4, center.dy - radius - 9);
    markerPath.close();
    canvas.drawPath(markerPath, markerPaint);

    // 2. Glazed specular light reflection (curved glossy highlight on upper left)
    final highlightPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final highlightRect = Rect.fromCircle(
      center: Offset(center.dx - radius * 0.15, center.dy - radius * 0.15),
      radius: radius * 0.65,
    );

    // Arc from 140 to 180 degrees (top left shoulder)
    canvas.drawArc(
      highlightRect,
      math.pi * 0.85,
      math.pi * 0.45,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
