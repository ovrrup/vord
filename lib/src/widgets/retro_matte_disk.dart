import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Component 2: A matte-styled physical disk that rotates while running and spreads
/// progressive colors from the center outward naturally as time passes.
class RetroMatteDisk extends StatefulWidget {
  final int elapsedSeconds;
  final bool isRunning;
  final bool isFocusMode;
  final bool animate;
  final String formattedTime;

  const RetroMatteDisk({
    super.key,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.isFocusMode,
    this.animate = true,
    required this.formattedTime,
  });

  @override
  State<RetroMatteDisk> createState() => _RetroMatteDiskState();
}

class _RetroMatteDiskState extends State<RetroMatteDisk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    if (widget.isRunning && widget.animate) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RetroMatteDisk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning && widget.animate) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(constraints.maxWidth * 0.88, 300.0);

        return SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating Matte Disk with Dynamic Center-Spreading Colors
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, _) {
                  final rotationAngle = widget.animate && widget.isRunning
                      ? _rotationController.value * 2 * math.pi
                      : 0.0;

                  return CustomPaint(
                    size: Size(diameter, diameter),
                    painter: _MatteDiskPainter(
                      elapsedSeconds: widget.elapsedSeconds,
                      rotationAngle: rotationAngle,
                      isDark: isDark,
                      isFocusMode: widget.isFocusMode,
                    ),
                  );
                },
              ),

              // Upright Stopwatch Display in Center
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.formattedTime,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: diameter * 0.19,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x33000000)
                          : const Color(0x1F000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x33FFFFFF)
                            : const Color(0x22000000),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.isFocusMode ? 'FOCUSING' : 'RESTING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatteDiskPainter extends CustomPainter {
  final int elapsedSeconds;
  final double rotationAngle;
  final bool isDark;
  final bool isFocusMode;

  _MatteDiskPainter({
    required this.elapsedSeconds,
    required this.rotationAngle,
    required this.isDark,
    required this.isFocusMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Calculate color progression from center outward
    final shader = _buildRadialDiffusionShader(center, radius);

    // 2. Draw physical matte disk background with spreading colors
    final diskPaint = Paint()..shader = shader;
    canvas.drawCircle(center, radius - 2, diskPaint);

    // 3. Draw rotating physical markings (notches, ticks, fine matte lines)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Subtle concentric matte groove rings
    final groovePaint = Paint()
      ..color = isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.40, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.65, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.85, groovePaint);

    // Physical tick graduations around the rim
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0x80FFFFFF) : const Color(0x60000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const tickCount = 60;
    for (int i = 0; i < tickCount; i++) {
      final isMajor = i % 5 == 0;
      final tickAngle = (i * 2 * math.pi) / tickCount;
      final outerR = radius - 6;
      final innerR = isMajor ? radius - 16 : radius - 11;

      final p1 = Offset(innerR * math.cos(tickAngle), innerR * math.sin(tickAngle));
      final p2 = Offset(outerR * math.cos(tickAngle), outerR * math.sin(tickAngle));

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    canvas.restore();

    // 4. Draw outer physical matte bezel / rim (static outer casing)
    final outerBezelPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3136) : const Color(0xFFD0D7DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerBezelPaint);

    // Inner subtle matte shadow/bevel for physical recessed depth
    final innerBezelPaint = Paint()
      ..color = isDark ? const Color(0x22000000) : const Color(0x11000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 5, innerBezelPaint);
  }

  Shader _buildRadialDiffusionShader(Offset center, double radius) {
    // Exact requested color progression stages:
    // Black theme: #121212 -> #1B2E24 -> #28593D -> #3FA36C
    // White mode:  #FFFFFF -> #F2F9F3 -> #A8D5BA -> #2E8B57
    final c0 = isDark ? AppTheme.darkStage0 : AppTheme.lightStage0;
    final c1 = isDark ? AppTheme.darkStage1 : AppTheme.lightStage1;
    final c2 = isDark ? AppTheme.darkStage2 : AppTheme.lightStage2;
    final c3 = isDark ? AppTheme.darkStage3 : AppTheme.lightStage3;

    // At 0s: purely c0 (base color)
    if (elapsedSeconds <= 0) {
      return RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [c0, c0],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }

    // Natural spreading timeline (e.g. 0 to 1500s / 25 mins):
    // Stage 1 spreads from 0 to 300s (0 to 5m)
    // Stage 2 emerges at center and spreads from 300 to 900s (5 to 15m)
    // Stage 3 emerges at center and spreads from 900 to 1500s+ (15 to 25m+)
    if (elapsedSeconds <= 300) {
      final p = (elapsedSeconds / 300.0).clamp(0.05, 1.0);
      return RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [c1, Color.lerp(c1, c0, 0.4)!, c0, c0],
        stops: [0.0, p * 0.6, p, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else if (elapsedSeconds <= 900) {
      final p = ((elapsedSeconds - 300) / 600.0).clamp(0.05, 1.0);
      return RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [c2, Color.lerp(c2, c1, 0.5)!, c1, c0],
        stops: [0.0, p * 0.5, 0.5 + p * 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      final p = ((elapsedSeconds - 900) / 600.0).clamp(0.05, 1.0);
      return RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [c3, Color.lerp(c3, c2, 0.5)!, c2, c1],
        stops: [0.0, p * 0.4, 0.4 + p * 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }
  }

  @override
  bool shouldRepaint(covariant _MatteDiskPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFocusMode != isFocusMode;
  }
}
