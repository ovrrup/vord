import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Component 2: A big, minimal, solid realistic matte tape-recorder spool disk.
/// Rotates smoothly while running with zero digital time numbers.
/// Progressive colors spread organically from the center hub across 4 stages.
class RetroMatteDisk extends StatefulWidget {
  final int elapsedSeconds;
  final bool isRunning;
  final bool isFocusMode;
  final bool animate;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  const RetroMatteDisk({
    super.key,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.isFocusMode,
    this.animate = true,
    this.baselineSeconds = 1200,
    this.extra3Seconds = 180,
    this.extra4Seconds = 240,
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
      duration: const Duration(seconds: 22),
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
        // Generous, large disk size that fills the available center area
        final availableSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final diameter = math.min(availableSize * 0.94, 350.0);

        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Realistic physical ambient occlusion shadow underneath the solid matte disk
              BoxShadow(
                color: isDark ? const Color(0x80000000) : const Color(0x22000000),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: isDark ? const Color(0x40000000) : const Color(0x10000000),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              final rotationAngle = widget.animate && widget.isRunning
                  ? _rotationController.value * 2 * math.pi
                  : 0.0;

              return CustomPaint(
                size: Size(diameter, diameter),
                painter: _SolidMatteDiskPainter(
                  elapsedSeconds: widget.elapsedSeconds,
                  rotationAngle: rotationAngle,
                  isDark: isDark,
                  isFocusMode: widget.isFocusMode,
                  baselineSeconds: widget.baselineSeconds,
                  extra3Seconds: widget.extra3Seconds,
                  extra4Seconds: widget.extra4Seconds,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SolidMatteDiskPainter extends CustomPainter {
  final int elapsedSeconds;
  final double rotationAngle;
  final bool isDark;
  final bool isFocusMode;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  _SolidMatteDiskPainter({
    required this.elapsedSeconds,
    required this.rotationAngle,
    required this.isDark,
    required this.isFocusMode,
    required this.baselineSeconds,
    required this.extra3Seconds,
    required this.extra4Seconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw solid matte disk face with organic 4-stage center-outward spreading colors
    final diskShader = _buildRadialDiffusionShader(center, radius);
    final diskPaint = Paint()..shader = diskShader;
    canvas.drawCircle(center, radius - 2, diskPaint);

    // 2. Draw rotating tape spool mechanics (3 large spool windows, spoke ribs, hub)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawSpoolMechanics(canvas, radius);

    canvas.restore();

    // 3. Solid precision-machined outer rim / casing
    final outerRimPaint = Paint()
      ..color = isDark ? const Color(0xFF2C323A) : const Color(0xFFCBD2DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerRimPaint);

    // Subtle inner bevel shadow for solid recessed depth
    final innerBevelPaint = Paint()
      ..color = isDark ? const Color(0x30000000) : const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 5, innerBevelPaint);
  }

  void _drawSpoolMechanics(Canvas canvas, double radius) {
    // A. Subtle concentric matte groove rings
    final groovePaint = Paint()
      ..color = isDark ? const Color(0x18FFFFFF) : const Color(0x10000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.40, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.65, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.86, groovePaint);

    // B. The 3 Big, Clean Tape Reel Spool Windows (at 0°, 120°, 240°)
    const holeCount = 3;
    final holeDistance = radius * 0.54;
    final holeRadius = radius * 0.19;

    final cutoutFillPaint = Paint()
      ..color = isDark ? const Color(0xFF0C0E10) : const Color(0xFFE2E6EB)
      ..style = PaintingStyle.fill;

    final cutoutShadowPaint = Paint()
      ..color = isDark ? const Color(0x55000000) : const Color(0x28000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cutoutRimPaint = Paint()
      ..color = isDark ? const Color(0x30FFFFFF) : const Color(0x28000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < holeCount; i++) {
      final angle = (i * 2 * math.pi) / holeCount;
      final holeCenter = Offset(
        holeDistance * math.cos(angle),
        holeDistance * math.sin(angle),
      );

      // Recessed interior through the spool face
      canvas.drawCircle(holeCenter, holeRadius, cutoutFillPaint);
      canvas.drawCircle(holeCenter, holeRadius - 1.2, cutoutShadowPaint);
      canvas.drawCircle(holeCenter, holeRadius, cutoutRimPaint);
    }

    // C. 3 Clean structural spoke ribs (at 60°, 180°, 300°)
    final spokePaint = Paint()
      ..color = isDark ? const Color(0x35FFFFFF) : const Color(0x2B000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      final p1 = Offset(radius * 0.25 * math.cos(angle), radius * 0.25 * math.sin(angle));
      final p2 = Offset(radius * 0.86 * math.cos(angle), radius * 0.86 * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);
    }

    // D. Outer rim graduations (clean minimal ticks)
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x38FFFFFF) : const Color(0x25000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0x75FFFFFF) : const Color(0x50000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const tickCount = 60;
    for (int i = 0; i < tickCount; i++) {
      final isMajor = i % 5 == 0;
      final tickAngle = (i * 2 * math.pi) / tickCount;
      final outerR = radius - 6;
      final innerR = isMajor ? radius - 15 : radius - 11;

      final p1 = Offset(innerR * math.cos(tickAngle), innerR * math.sin(tickAngle));
      final p2 = Offset(outerR * math.cos(tickAngle), outerR * math.sin(tickAngle));
      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // E. Solid Physical Center Hub
    final hubRadius = radius * 0.24;
    final hubPaint = Paint()
      ..color = isDark ? const Color(0xFF191D22) : const Color(0xFFE8ECF0)
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF38404A) : const Color(0xFFA5ADB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset.zero, hubRadius, hubPaint);
    canvas.drawCircle(Offset.zero, hubRadius, hubBorderPaint);

    // 3 Solid Drive Splines / Teeth
    final splinePaint = Paint()
      ..color = isDark ? const Color(0xFF0F1114) : const Color(0xFF282D33)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      canvas.save();
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset(radius * 0.125, 0),
        width: radius * 0.08,
        height: radius * 0.038,
      );
      canvas.drawRect(rect, splinePaint);
      canvas.restore();
    }

    // Central Spindle Axle Hole
    final spindleRadius = radius * 0.075;
    final spindleFill = Paint()
      ..color = isDark ? const Color(0xFF070809) : const Color(0xFF1E2226)
      ..style = PaintingStyle.fill;
    final spindleBorder = Paint()
      ..color = isDark ? const Color(0xFF4A5462) : const Color(0xFF8B949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, spindleRadius, spindleFill);
    canvas.drawCircle(Offset.zero, spindleRadius, spindleBorder);
  }

  Shader _buildRadialDiffusionShader(Offset center, double radius) {
    // Exact requested color progression:
    // Black theme: #121212 -> #1B2E24 -> #28593D -> #3FA36C
    // White mode:  #FFFFFF -> #F2F9F3 -> #A8D5BA -> #2E8B57
    final c0 = isDark ? AppTheme.darkStage0 : AppTheme.lightStage0;
    final c1 = isDark ? AppTheme.darkStage1 : AppTheme.lightStage1;
    final c2 = isDark ? AppTheme.darkStage2 : AppTheme.lightStage2;
    final c3 = isDark ? AppTheme.darkStage3 : AppTheme.lightStage3;

    if (!isFocusMode || elapsedSeconds <= 0) {
      return RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [c0, c0],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }

    final b = baselineSeconds > 0 ? baselineSeconds : 1200;
    final t1 = (b * 0.70).round().clamp(60, b - 30);
    final t2 = b;
    final t3 = t2 + (extra3Seconds > 0 ? extra3Seconds : 180);
    final t4 = t3 + (extra4Seconds > 0 ? extra4Seconds : 240);

    List<Color> colors;
    List<double> rawStops;

    if (elapsedSeconds < t1) {
      final p = (elapsedSeconds / t1).clamp(0.0, 1.0);
      colors = [c1, Color.lerp(c1, c0, 0.4)!, c0, c0];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), p.clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t2) {
      final p = ((elapsedSeconds - t1) / (t2 - t1)).clamp(0.0, 1.0);
      colors = [c2, Color.lerp(c2, c1, 0.4)!, c1, c0];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), (0.5 + p * 0.4).clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t3) {
      final p = ((elapsedSeconds - t2) / (t3 - t2)).clamp(0.0, 1.0);
      colors = [c3, Color.lerp(c3, c2, 0.4)!, c2, c1];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), (0.5 + p * 0.45).clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t4) {
      final p = ((elapsedSeconds - t3) / (t4 - t3)).clamp(0.0, 1.0);
      colors = [c3, c3, Color.lerp(c2, c3, p)!];
      rawStops = [0.0, (0.4 + p * 0.55).clamp(0.0, 1.0), 1.0];
    } else {
      colors = [c3, c3];
      rawStops = const [0.0, 1.0];
    }

    final stops = <double>[];
    double prev = 0.0;
    for (int i = 0; i < rawStops.length; i++) {
      final s = rawStops[i].clamp(prev, 1.0);
      stops.add(s);
      prev = s;
    }

    return RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldRepaint(covariant _SolidMatteDiskPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFocusMode != isFocusMode ||
        oldDelegate.baselineSeconds != baselineSeconds ||
        oldDelegate.extra3Seconds != extra3Seconds ||
        oldDelegate.extra4Seconds != extra4Seconds;
  }
}
