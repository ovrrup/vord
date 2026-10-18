import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Component 2: A sharp, retro tape-recorder styled matte disk with mechanical spool cutouts
/// that rotates while running.
///
/// Absolutely NO digital time text is displayed on the disk per user specification.
/// As time passes, progressive colors spread organically from the center hub outward
/// across 4 stages based on previous session duration and randomized milestones.
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
    // Steady vintage tape reel transport speed (approx 20s per revolution)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
        final diameter = math.min(constraints.maxWidth * 0.92, 320.0);

        return SizedBox(
          width: diameter,
          height: diameter,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              final rotationAngle = widget.animate && widget.isRunning
                  ? _rotationController.value * 2 * math.pi
                  : 0.0;

              return CustomPaint(
                size: Size(diameter, diameter),
                painter: _MatteTapeSpoolPainter(
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

class _MatteTapeSpoolPainter extends CustomPainter {
  final int elapsedSeconds;
  final double rotationAngle;
  final bool isDark;
  final bool isFocusMode;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  _MatteTapeSpoolPainter({
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

    // 1. Calculate color progression from center outward
    final diskShader = _buildRadialDiffusionShader(center, radius);

    // 2. Draw physical matte disk background with spreading colors
    final diskPaint = Paint()..shader = diskShader;
    canvas.drawCircle(center, radius - 2, diskPaint);

    // 3. Draw Rotating Sharp Tape Recorder Spool Mechanics
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawSharpTapeSpoolElements(canvas, radius);

    canvas.restore();

    // 4. Draw outer static physical matte casing / bezel
    final outerBezelPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3136) : const Color(0xFFC0C7D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerBezelPaint);

    final innerBezelPaint = Paint()
      ..color = isDark ? const Color(0x33000000) : const Color(0x18000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 5, innerBezelPaint);

    // 5. Tape Path Tension Pins / Guide Rollers (flanking top left and right)
    _drawTapeGuidePins(canvas, center, radius);
  }

  void _drawTapeGuidePins(Canvas canvas, Offset center, double radius) {
    final pinDistance = radius * 0.92;
    const pinRadius = 6.0;

    final pinFillPaint = Paint()
      ..color = isDark ? const Color(0xFF22262B) : const Color(0xFFE2E6EA)
      ..style = PaintingStyle.fill;
    final pinBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF3F4752) : const Color(0xFF8B949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final pinCorePaint = Paint()
      ..color = isDark ? const Color(0xFF0F1114) : const Color(0xFF4A515A)
      ..style = PaintingStyle.fill;

    // Left and Right guide rollers
    final leftPin = Offset(center.dx - pinDistance * 0.72, center.dy - pinDistance * 0.70);
    final rightPin = Offset(center.dx + pinDistance * 0.72, center.dy - pinDistance * 0.70);

    for (final pin in [leftPin, rightPin]) {
      canvas.drawCircle(pin, pinRadius, pinFillPaint);
      canvas.drawCircle(pin, pinRadius, pinBorderPaint);
      canvas.drawCircle(pin, 2.0, pinCorePaint);
    }
  }

  void _drawSharpTapeSpoolElements(Canvas canvas, double radius) {
    // A. Concentric micro-grooves
    final groovePaint = Paint()
      ..color = isDark ? const Color(0x22FFFFFF) : const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.38, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.64, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.86, groovePaint);

    // B. 3 Precision-Cut Tape Reel Cutout Windows (at 0°, 120°, 240°)
    const holeCount = 3;
    final holeDistance = radius * 0.54;
    final holeRadius = radius * 0.18;

    final cutoutFillPaint = Paint()
      ..color = isDark ? const Color(0xFF0A0B0D) : const Color(0xFFE2E6EA)
      ..style = PaintingStyle.fill;

    final cutoutShadowPaint = Paint()
      ..color = isDark ? const Color(0x55000000) : const Color(0x28000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cutoutBevelPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x35000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < holeCount; i++) {
      final angle = (i * 2 * math.pi) / holeCount;
      final holeCenter = Offset(
        holeDistance * math.cos(angle),
        holeDistance * math.sin(angle),
      );

      canvas.drawCircle(holeCenter, holeRadius, cutoutFillPaint);
      canvas.drawCircle(holeCenter, holeRadius - 1.2, cutoutShadowPaint);
      canvas.drawCircle(holeCenter, holeRadius, cutoutBevelPaint);
    }

    // C. 3 Structural Spoke Ribs with Hardware Screws (at 60°, 180°, 300°)
    final spokePaint = Paint()
      ..color = isDark ? const Color(0x44FFFFFF) : const Color(0x35000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    final screwFill = Paint()
      ..color = isDark ? const Color(0xFF282D33) : const Color(0xFFC5CBD3)
      ..style = PaintingStyle.fill;

    final screwBorder = Paint()
      ..color = isDark ? const Color(0xFF505A66) : const Color(0xFF4A515A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final screwSlot = Paint()
      ..color = isDark ? const Color(0xFF101214) : const Color(0xFF2A2E33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      final p1 = Offset(radius * 0.25 * math.cos(angle), radius * 0.25 * math.sin(angle));
      final p2 = Offset(radius * 0.86 * math.cos(angle), radius * 0.86 * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);

      // Chassis machine screw along spoke rib
      final screwCenter = Offset(radius * 0.33 * math.cos(angle), radius * 0.33 * math.sin(angle));
      canvas.drawCircle(screwCenter, 3.4, screwFill);
      canvas.drawCircle(screwCenter, 3.4, screwBorder);

      // Slotted screw head line
      final slotP1 = Offset(screwCenter.dx - 2.2 * math.cos(angle + math.pi / 2),
          screwCenter.dy - 2.2 * math.sin(angle + math.pi / 2));
      final slotP2 = Offset(screwCenter.dx + 2.2 * math.cos(angle + math.pi / 2),
          screwCenter.dy + 2.2 * math.sin(angle + math.pi / 2));
      canvas.drawLine(slotP1, slotP2, screwSlot);
    }

    // D. Outer Reel Rim Graduations (60 strobe index ticks)
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;

    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0x85FFFFFF) : const Color(0x60000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

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

    // E. Heavy-Duty Center Spindle Hub & 3-Tooth NAB Splines
    final hubRadius = radius * 0.24;
    final hubPaint = Paint()
      ..color = isDark ? const Color(0xFF191D22) : const Color(0xFFE8ECF0)
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF38404A) : const Color(0xFFA5ADB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(Offset.zero, hubRadius, hubPaint);
    canvas.drawCircle(Offset.zero, hubRadius, hubBorderPaint);

    // 3 Sharp Rectangular Drive Teeth radiating into hub
    final splinePaint = Paint()
      ..color = isDark ? const Color(0xFF0F1114) : const Color(0xFF282D33)
      ..style = PaintingStyle.fill;
    final splineBorder = Paint()
      ..color = isDark ? const Color(0xFF404854) : const Color(0xFF6E7781)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

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
      canvas.drawRect(rect, splineBorder);
      canvas.restore();
    }

    // Central Spindle Axle Hole with metallic collar ring
    final spindleRadius = radius * 0.075;
    final spindleFill = Paint()
      ..color = isDark ? const Color(0xFF070809) : const Color(0xFF1E2226)
      ..style = PaintingStyle.fill;
    final spindleBorder = Paint()
      ..color = isDark ? const Color(0xFF505A66) : const Color(0xFF8B949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, spindleRadius, spindleFill);
    canvas.drawCircle(Offset.zero, spindleRadius, spindleBorder);
  }

  Shader _buildRadialDiffusionShader(Offset center, double radius) {
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
      // Stage 1: Base disk (c0), c1 emerges from center naturally
      final p = (elapsedSeconds / t1).clamp(0.0, 1.0);
      colors = [c1, Color.lerp(c1, c0, 0.4)!, c0, c0];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), p.clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t2) {
      // Stage 2: c1 expands outward, c2 starts spreading from center
      final p = ((elapsedSeconds - t1) / (t2 - t1)).clamp(0.0, 1.0);
      colors = [c2, Color.lerp(c2, c1, 0.4)!, c1, c0];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), (0.5 + p * 0.4).clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t3) {
      // Stage 3: Deadline passed! c2 covers outer disk, c3 blooms from center
      final p = ((elapsedSeconds - t2) / (t3 - t2)).clamp(0.0, 1.0);
      colors = [c3, Color.lerp(c3, c2, 0.4)!, c2, c1];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), (0.5 + p * 0.45).clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t4) {
      // Stage 4: User surpassed last limit! c3 expands until it completely paints the entire disk
      final p = ((elapsedSeconds - t3) / (t4 - t3)).clamp(0.0, 1.0);
      colors = [c3, c3, Color.lerp(c2, c3, p)!];
      rawStops = [0.0, (0.4 + p * 0.55).clamp(0.0, 1.0), 1.0];
    } else {
      // Fully turned into 4th stage color
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
  bool shouldRepaint(covariant _MatteTapeSpoolPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFocusMode != isFocusMode ||
        oldDelegate.baselineSeconds != baselineSeconds ||
        oldDelegate.extra3Seconds != extra3Seconds ||
        oldDelegate.extra4Seconds != extra4Seconds;
  }
}
