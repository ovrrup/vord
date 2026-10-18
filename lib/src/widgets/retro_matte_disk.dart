import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

/// Component 2: A big, solid realistic matte tape-recorder spool disk.
/// Instead of a continuous color spread, concentric rings of that stage's color
/// appear one after another for clear, highly visible countdowns and milestone indication.
/// Features authentic mechanical rotational inertia (spin-up acceleration and braking friction).
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
  late final Ticker _ticker;
  double _rotationAngle = 0.0;
  double _currentVelocity = 0.0; // -1.0 (rest mode reverse) to +1.0 (focus mode forward)
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (!widget.animate) {
      if (_currentVelocity != 0.0) {
        setState(() => _currentVelocity = 0.0);
      }
      return;
    }

    // In Rest Mode, target velocity is -1.0 (opposite counter-clockwise rotation)
    // In Focus Mode, target velocity is +1.0 (forward clockwise rotation)
    final double targetVelocity;
    if (!widget.isRunning) {
      targetVelocity = 0.0;
    } else if (widget.isFocusMode) {
      targetVelocity = 1.0;
    } else {
      targetVelocity = -1.0;
    }

    // Physical rotational inertia: motor spin-up acceleration and mechanical braking friction
    double newVelocity = _currentVelocity;
    if (newVelocity < targetVelocity) {
      newVelocity = math.min(targetVelocity, newVelocity + dt * 1.1); // Acceleration
    } else if (newVelocity > targetVelocity) {
      newVelocity = math.max(targetVelocity, newVelocity - dt * 1.3); // Deceleration / reverse acceleration
    }

    if (newVelocity != 0.0 || newVelocity != _currentVelocity) {
      // Base rotation rate: 1 revolution every 18 seconds
      const baseAngularVelocity = (2 * math.pi) / 18.0;
      // Analog wow & flutter (subtle organic rotational micro-variance ±1.2%)
      final flutter = 1.0 + 0.012 * math.sin(elapsed.inMilliseconds / 280.0);

      setState(() {
        _currentVelocity = newVelocity;
        double nextAngle = _rotationAngle + dt * baseAngularVelocity * _currentVelocity * flutter;
        while (nextAngle < 0) {
          nextAngle += 2 * math.pi;
        }
        while (nextAngle >= 2 * math.pi) {
          nextAngle -= 2 * math.pi;
        }
        _rotationAngle = nextAngle;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
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
              // Deep, realistic physical drop shadows giving solid 3D elevation
              BoxShadow(
                color: isDark ? const Color(0x80000000) : const Color(0x24000000),
                blurRadius: 30,
                offset: const Offset(0, 16),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: isDark ? const Color(0x40000000) : const Color(0x12000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(diameter, diameter),
            painter: _ConcentricRingsSpoolPainter(
              elapsedSeconds: widget.elapsedSeconds,
              rotationAngle: _rotationAngle,
              isDark: isDark,
              isFocusMode: widget.isFocusMode,
              baselineSeconds: widget.baselineSeconds,
              extra3Seconds: widget.extra3Seconds,
              extra4Seconds: widget.extra4Seconds,
            ),
          ),
        );
      },
    );
  }
}

class _ConcentricRingsSpoolPainter extends CustomPainter {
  final int elapsedSeconds;
  final double rotationAngle;
  final bool isDark;
  final bool isFocusMode;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  _ConcentricRingsSpoolPainter({
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

    // 1. Draw Solid Matte Base Disk Face
    final baseColor = isDark ? const Color(0xFF141619) : const Color(0xFFF2F5F8);
    final diskPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, diskPaint);

    // 2. Draw Concentric Rings that appear one after another as countdown/milestones
    _drawConcentricRings(canvas, center, radius);

    // 3. Draw Rotating Tape Spool Mechanics (Cutout windows, spoke ribs, center hub)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawSpoolMechanics(canvas, radius);

    canvas.restore();

    // 4. Solid Precision-Machined Outer Casing Rim
    final outerRimPaint = Paint()
      ..color = isDark ? const Color(0xFF2C323B) : const Color(0xFFCAD1DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerRimPaint);

    // Subtle inner bevel shadow for recessed physical depth
    final innerBevelPaint = Paint()
      ..color = isDark ? const Color(0x35000000) : const Color(0x16000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 5, innerBevelPaint);
  }

  void _drawConcentricRings(Canvas canvas, Offset center, double radius) {
    // 4 concentric annular rings:
    // Ring 1 (innermost): radius 0.26R to 0.40R
    // Ring 2 (mid-inner): radius 0.41R to 0.55R
    // Ring 3 (mid-outer): radius 0.56R to 0.70R
    // Ring 4 (outermost): radius 0.71R to 0.86R
    final b = baselineSeconds > 0 ? baselineSeconds : 1200;
    final t1 = (b * 0.70).round().clamp(60, b - 30);
    final t2 = b;
    final t3 = t2 + (extra3Seconds > 0 ? extra3Seconds : 180);
    final t4 = t3 + (extra4Seconds > 0 ? extra4Seconds : 240);

    // Palette Colors:
    // Dark: #121212 -> #1B2E24 -> #28593D -> #3FA36C
    // White: #FFFFFF -> #F2F9F3 -> #A8D5BA -> #2E8B57
    final cUnlit = isDark ? const Color(0xFF181B1F) : const Color(0xFFE9EDF2);
    final c1 = isDark ? AppTheme.darkStage1 : const Color(0xFFD6EFE0); // Mint/Emerald
    final c2 = isDark ? AppTheme.darkStage2 : AppTheme.lightStage2;     // Muted Moss / Sage
    final c3 = isDark ? AppTheme.darkStage3 : AppTheme.lightStage3;     // Leaf Green / Forest Green
    final c4 = isDark ? const Color(0xFF4FD18B) : const Color(0xFF1E7B44); // Electric / Deep Green

    final grooveColor = isDark ? const Color(0xFF282E37) : const Color(0xFFCBD2DA);

    // Calculate ring activation states
    // Ring 1: Active when t > 0
    final ring1Active = isFocusMode && elapsedSeconds > 0;
    final p1 = ring1Active ? (elapsedSeconds / t1).clamp(0.0, 1.0) : 0.0;

    // Ring 2: Active when t >= t1
    final ring2Active = isFocusMode && elapsedSeconds >= t1;
    final p2 = ring2Active ? ((elapsedSeconds - t1) / (t2 - t1)).clamp(0.0, 1.0) : 0.0;

    // Ring 3: Active when t >= t2 (Previous record surpassed!)
    final ring3Active = isFocusMode && elapsedSeconds >= t2;
    final p3 = ring3Active ? ((elapsedSeconds - t2) / (t3 - t2)).clamp(0.0, 1.0) : 0.0;

    // Ring 4: Active when t >= t3 (Extending into new limit!)
    final ring4Active = isFocusMode && elapsedSeconds >= t3;
    final p4 = ring4Active ? ((elapsedSeconds - t3) / (t4 - t3)).clamp(0.0, 1.0) : 0.0;

    final ringConfigs = [
      _RingConfig(0.26 * radius, 0.40 * radius, ring1Active ? Color.lerp(cUnlit, c1, p1)! : cUnlit, ring1Active),
      _RingConfig(0.41 * radius, 0.55 * radius, ring2Active ? Color.lerp(cUnlit, c2, p2)! : cUnlit, ring2Active),
      _RingConfig(0.56 * radius, 0.70 * radius, ring3Active ? Color.lerp(cUnlit, c3, p3)! : cUnlit, ring3Active),
      _RingConfig(0.71 * radius, 0.86 * radius, ring4Active ? Color.lerp(cUnlit, c4, p4)! : cUnlit, ring4Active),
    ];

    for (final rc in ringConfigs) {
      final ringThickness = rc.outerR - rc.innerR;
      final midRadius = (rc.innerR + rc.outerR) / 2;

      // Draw concentric ring band
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness
        ..color = rc.color;
      canvas.drawCircle(center, midRadius, paint);

      // Draw sharp concentric separator groove lines
      final sepPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = grooveColor;
      canvas.drawCircle(center, rc.innerR, sepPaint);
      canvas.drawCircle(center, rc.outerR, sepPaint);
    }
  }

  void _drawSpoolMechanics(Canvas canvas, double radius) {
    // 3 Big Clean Tape Reel Spool Windows (at 0°, 120°, 240°)
    const holeCount = 3;
    final holeDistance = radius * 0.54;
    final holeRadius = radius * 0.19;

    final cutoutFillPaint = Paint()
      ..color = isDark ? const Color(0xFF0A0C0E) : const Color(0xFFDEE3E9)
      ..style = PaintingStyle.fill;

    final cutoutShadowPaint = Paint()
      ..color = isDark ? const Color(0x60000000) : const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cutoutRimPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x30000000)
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

    // 3 Clean structural spoke ribs (at 60°, 180°, 300°)
    final spokePaint = Paint()
      ..color = isDark ? const Color(0x38FFFFFF) : const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    for (int i = 0; i < 3; i++) {
      final angle = (math.pi / 3) + (i * 2 * math.pi / 3);
      final p1 = Offset(radius * 0.25 * math.cos(angle), radius * 0.25 * math.sin(angle));
      final p2 = Offset(radius * 0.86 * math.cos(angle), radius * 0.86 * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);
    }

    // Outer rim graduations (clean minimal ticks)
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x2A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0x80FFFFFF) : const Color(0x55000000)
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

    // Solid Physical Center Hub
    final hubRadius = radius * 0.24;
    final hubPaint = Paint()
      ..color = isDark ? const Color(0xFF181B20) : const Color(0xFFE6EBF0)
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF38404B) : const Color(0xFFA5ADB8)
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

  @override
  bool shouldRepaint(covariant _ConcentricRingsSpoolPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFocusMode != isFocusMode ||
        oldDelegate.baselineSeconds != baselineSeconds ||
        oldDelegate.extra3Seconds != extra3Seconds ||
        oldDelegate.extra4Seconds != extra4Seconds;
  }
}

class _RingConfig {
  final double innerR;
  final double outerR;
  final Color color;
  final bool isActive;

  const _RingConfig(this.innerR, this.outerR, this.color, this.isActive);
}
