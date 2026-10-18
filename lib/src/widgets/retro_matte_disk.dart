import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Component 2: A retro tape-recorder styled matte disk with spool holes/cutouts
/// that mechanically rotates while running.
///
/// Time display is hidden while a session is ongoing to immerse the user.
/// As time passes, progressive colors spread organically from the center outward
/// across 4 stages based on previous session duration and randomized milestones.
class RetroMatteDisk extends StatefulWidget {
  final int elapsedSeconds;
  final bool isRunning;
  final bool isFocusMode;
  final bool animate;
  final String formattedTime;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  const RetroMatteDisk({
    super.key,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.isFocusMode,
    this.animate = true,
    required this.formattedTime,
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
    // Authentic vintage reel rotation rate (approx 25 seconds per full revolution)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
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
        final diameter = math.min(constraints.maxWidth * 0.90, 310.0);

        return SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating Tape Recorder Spool with Spreading Colors
              AnimatedBuilder(
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

              // Upright Stopwatch Display in Center: ONLY visible when NOT running
              // (User requirement: "we dont show them the time while session is ongoing")
              if (!widget.isRunning)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.formattedTime,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: diameter * 0.17,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
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

    // 3. Draw Rotating Tape Recorder Spool Mechanics (Spool Holes, Hub, Drive Splines, Ribs)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawTapeSpoolElements(canvas, radius);

    canvas.restore();

    // 4. Draw outer static physical matte casing / bezel
    final outerBezelPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3136) : const Color(0xFFD0D7DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerBezelPaint);

    final innerBezelPaint = Paint()
      ..color = isDark ? const Color(0x22000000) : const Color(0x10000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 5, innerBezelPaint);
  }

  void _drawTapeSpoolElements(Canvas canvas, double radius) {
    // A. Concentric reel track grooves
    final groovePaint = Paint()
      ..color = isDark ? const Color(0x18FFFFFF) : const Color(0x10000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.40, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.65, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.86, groovePaint);

    // B. The 3 Iconic Reel Cutout Spool Windows (Holes at 0°, 120°, 240°)
    const holeCount = 3;
    final holeDistance = radius * 0.54;
    final holeRadius = radius * 0.18;

    final cutoutFillPaint = Paint()
      ..color = isDark ? const Color(0xFF0C0D0E) : const Color(0xFFE4E8EC)
      ..style = PaintingStyle.fill;

    final cutoutShadowPaint = Paint()
      ..color = isDark ? const Color(0x44000000) : const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cutoutBevelPaint = Paint()
      ..color = isDark ? const Color(0x33FFFFFF) : const Color(0x2B000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < holeCount; i++) {
      final angle = (i * 2 * math.pi) / holeCount;
      final holeCenter = Offset(
        holeDistance * math.cos(angle),
        holeDistance * math.sin(angle),
      );

      // Recessed background behind spool hole
      canvas.drawCircle(holeCenter, holeRadius, cutoutFillPaint);
      // Inner shadow edge
      canvas.drawCircle(holeCenter, holeRadius - 1.2, cutoutShadowPaint);
      // Physical machined rim bevel
      canvas.drawCircle(holeCenter, holeRadius, cutoutBevelPaint);
    }

    // C. 3 Structural spoke ribs connecting hub to outer rim (at 60°, 180°, 300°)
    final spokePaint = Paint()
      ..color = isDark ? const Color(0x33FFFFFF) : const Color(0x28000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final rivetFillPaint = Paint()
      ..color = isDark ? const Color(0xFF282D33) : const Color(0xFFCAD1D9)
      ..style = PaintingStyle.fill;

    final rivetStrokePaint = Paint()
      ..color = isDark ? const Color(0x44FFFFFF) : const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      final p1 = Offset(radius * 0.24 * math.cos(angle), radius * 0.24 * math.sin(angle));
      final p2 = Offset(radius * 0.86 * math.cos(angle), radius * 0.86 * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);

      // Flange hardware rivet / screw along spoke rib
      final rivetCenter = Offset(radius * 0.33 * math.cos(angle), radius * 0.33 * math.sin(angle));
      canvas.drawCircle(rivetCenter, 3.2, rivetFillPaint);
      canvas.drawCircle(rivetCenter, 3.2, rivetStrokePaint);
    }

    // D. Outer reel rim graduations / strobe tick marks
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x38FFFFFF) : const Color(0x28000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0x75FFFFFF) : const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

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

    // E. Center Spindle Hub & 3-prong drive splines
    final hubRadius = radius * 0.23;
    final hubPaint = Paint()
      ..color = isDark ? const Color(0xFF1D2126) : const Color(0xFFEFF2F5)
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF353C44) : const Color(0xFFB5BDC6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, hubRadius, hubPaint);
    canvas.drawCircle(Offset.zero, hubRadius, hubBorderPaint);

    // 3 drive splines (teeth) radiating from spindle hole into hub
    final splinePaint = Paint()
      ..color = isDark ? const Color(0xFF111315) : const Color(0xFF30363D)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      canvas.save();
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset(radius * 0.12, 0),
        width: radius * 0.08,
        height: radius * 0.038,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), splinePaint);
      canvas.restore();
    }

    // Central spindle axle hole
    final spindleRadius = radius * 0.075;
    final spindleFillPaint = Paint()
      ..color = isDark ? const Color(0xFF090A0B) : const Color(0xFF222529)
      ..style = PaintingStyle.fill;
    final spindleBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF48515C) : const Color(0xFF8B949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, spindleRadius, spindleFillPaint);
    canvas.drawCircle(Offset.zero, spindleRadius, spindleBorderPaint);
  }

  Shader _buildRadialDiffusionShader(Offset center, double radius) {
    // Exact requested color progression stages:
    // Black theme: #121212 -> #1B2E24 -> #28593D -> #3FA36C
    // White mode:  #FFFFFF -> #F2F9F3 -> #A8D5BA -> #2E8B57
    final c0 = isDark ? AppTheme.darkStage0 : AppTheme.lightStage0;
    final c1 = isDark ? AppTheme.darkStage1 : AppTheme.lightStage1;
    final c2 = isDark ? AppTheme.darkStage2 : AppTheme.lightStage2;
    final c3 = isDark ? AppTheme.darkStage3 : AppTheme.lightStage3;

    // Neutral baseline for rest mode or 0 seconds
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
      // Stage 2: c1 expands outward, c2 starts spreading from center as user nears last session limit
      final p = ((elapsedSeconds - t1) / (t2 - t1)).clamp(0.0, 1.0);
      colors = [c2, Color.lerp(c2, c1, 0.4)!, c1, c0];
      rawStops = [0.0, (p * 0.5).clamp(0.0, 1.0), (0.5 + p * 0.4).clamp(0.0, 1.0), 1.0];
    } else if (elapsedSeconds < t3) {
      // Stage 3: Deadline passed! c2 covers outer disk, c3 blooms from center during extra time
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

    // Guarantee strictly non-decreasing stops to prevent gradient shader assertion failures
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
