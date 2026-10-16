import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DualRotatingDial extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final Color accentColor;
  final bool isRunning;

  const DualRotatingDial({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.accentColor,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    // Dial rotation angles (in turns: 0.0 to 1.0)
    // Left dial: completes 1 turn per 60 minutes
    final minuteFraction = (minutes % 60) / 60.0;
    // Right dial: completes 1 turn per 60 seconds
    final secondFraction = seconds / 60.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Dial: Minutes
        _SingleDial(
          value: minutes,
          label: 'MIN',
          fraction: minuteFraction,
          accentColor: accentColor,
          totalTicks: 60,
          majorTickInterval: 5,
          isRunning: isRunning,
        ),

        const SizedBox(width: 16),

        // Elegant separator colon
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? accentColor : const Color(0x667A7F8D),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? accentColor : const Color(0x667A7F8D),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right Dial: Seconds
        _SingleDial(
          value: seconds,
          label: 'SEC',
          fraction: secondFraction,
          accentColor: accentColor,
          totalTicks: 60,
          majorTickInterval: 5,
          isRunning: isRunning,
        ),
      ],
    );
  }
}

class _SingleDial extends StatelessWidget {
  final int value;
  final String label;
  final double fraction;
  final Color accentColor;
  final int totalTicks;
  final int majorTickInterval;
  final bool isRunning;

  static const double dialSize = 145.0;

  const _SingleDial({
    required this.value,
    required this.label,
    required this.fraction,
    required this.accentColor,
    required this.totalTicks,
    required this.majorTickInterval,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueString = value.toString().padLeft(2, '0');

    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle boundary
          Container(
            width: dialSize,
            height: dialSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(
                color: const Color(0x332E323D),
                width: 1.5,
              ),
            ),
          ),

          // Rotating Tick Marks Bezel
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: fraction, end: fraction),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, animatedFraction, child) {
              return Transform.rotate(
                angle: animatedFraction * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _DialTicksPainter(
                    totalTicks: totalTicks,
                    majorTickInterval: majorTickInterval,
                    accentColor: accentColor,
                    fraction: animatedFraction,
                  ),
                ),
              );
            },
          ),

          // Static Top Indicator Notch (12 o'clock needle)
          Positioned(
            top: 6,
            child: Container(
              width: 3,
              height: 7,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // Center Digital Value & Label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valueString,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 9,
                  letterSpacing: 2.0,
                  color: isRunning ? accentColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialTicksPainter extends CustomPainter {
  final int totalTicks;
  final int majorTickInterval;
  final Color accentColor;
  final double fraction;

  _DialTicksPainter({
    required this.totalTicks,
    required this.majorTickInterval,
    required this.accentColor,
    required this.fraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < totalTicks; i++) {
      final isMajor = i % majorTickInterval == 0;
      final tickAngle = (i * (2 * math.pi / totalTicks)) - (math.pi / 2);
      final tickLength = isMajor ? 9.0 : 4.5;
      final strokeWidth = isMajor ? 1.5 : 0.75;

      final innerRadius = radius - 8 - tickLength;
      final outerRadius = radius - 8;

      final start = Offset(
        center.dx + innerRadius * math.cos(tickAngle),
        center.dy + innerRadius * math.sin(tickAngle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(tickAngle),
        center.dy + outerRadius * math.sin(tickAngle),
      );

      final paint = Paint()
        ..color = isMajor
            ? (i == 0 ? accentColor : const Color(0x997A7F8D))
            : const Color(0x337A7F8D)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialTicksPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.accentColor != accentColor;
  }
}
