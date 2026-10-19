import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

/// Component 2: Authentic audio cassette tape cartridge housing holding a rotating
/// matte tape spool disk inside. Features precision cassette shell mechanics:
/// tactile side grip ribs, recessed spool observation well, magnetic tape path,
/// turnaround guide rollers, lower trapezoidal tape-head bay with capstan holes,
/// 4 flush corner assembly bolts, and a top-right sharp 4-segment milestone light bar
/// in a single contiguous row without spacing.
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
        // Balanced cassette cartridge dimensions that fill the available center space
        final availableSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final boxSize = math.min(availableSize * 0.96, 360.0);
        final diskDiameter = boxSize * 0.68;

        return Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15181C) : const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF282D36) : const Color(0xFFD2D8E0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x60000000) : const Color(0x18000000),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: isDark ? const Color(0x30000000) : const Color(0x0C000000),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Physical Cassette Shell Anatomy:
              // Side grip ribs, recessed observation well, tape ribbon path,
              // turnaround idler guide rollers, and lower trapezoidal tape-head bay
              Positioned.fill(
                child: CustomPaint(
                  painter: _CassetteShellPainter(
                    isDark: isDark,
                    diskRadius: diskDiameter / 2,
                  ),
                ),
              ),

              // 2. Rotating Matte Tape Spool Disk sitting inside the observation well
              Center(
                child: Container(
                  width: diskDiameter,
                  height: diskDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? const Color(0x60000000) : const Color(0x18000000),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: Size(diskDiameter, diskDiameter),
                    painter: _RetroSpoolPainter(
                      rotationAngle: _rotationAngle,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              // 3. Machined Flush Assembly Bolts at the 4 corners of the cassette housing
              Positioned(
                top: 13,
                left: 13,
                child: MachinedBolt(
                  slotAngle: 0.65, // ~37°
                  isDark: isDark,
                ),
              ),
              Positioned(
                top: 13,
                right: 13,
                child: MachinedBolt(
                  slotAngle: 1.95, // ~112°
                  isDark: isDark,
                ),
              ),
              Positioned(
                bottom: 13,
                left: 13,
                child: MachinedBolt(
                  slotAngle: 1.12, // ~64°
                  isDark: isDark,
                ),
              ),
              Positioned(
                bottom: 13,
                right: 13,
                child: MachinedBolt(
                  slotAngle: 2.58, // ~148°
                  isDark: isDark,
                ),
              ),

              // 4. Top-Right Sharp 4-Segment Milestone Light Bar in One Row Without Spacing
              Positioned(
                top: 13,
                right: 34,
                child: TopRightInfoPanel(
                  elapsedSeconds: widget.elapsedSeconds,
                  isFocusMode: widget.isFocusMode,
                  isDark: isDark,
                  baselineSeconds: widget.baselineSeconds,
                  extra3Seconds: widget.extra3Seconds,
                  extra4Seconds: widget.extra4Seconds,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Precision-drawn cassette shell anatomy.
class _CassetteShellPainter extends CustomPainter {
  final bool isDark;
  final double diskRadius;

  const _CassetteShellPainter({
    required this.isDark,
    required this.diskRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Inset Outer Chamfer Line around cassette shell
    final chamferPaint = Paint()
      ..color = isDark ? const Color(0xFF222730) : const Color(0xFFDDE3EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final chamferRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 3.5, w - 7.0, h - 7.0),
      const Radius.circular(22),
    );
    canvas.drawRRect(chamferRRect, chamferPaint);

    // 2. Tactile Side Grip Ribs (5 recessed horizontal serration lines on left and right)
    final ribDarkColor = isDark ? const Color(0xFF101317) : const Color(0xFFCAD1DA);
    final ribLightColor = isDark ? const Color(0xFF262C36) : const Color(0xFFFFFFFF);
    final ribDarkPaint = Paint()
      ..color = ribDarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final ribLightPaint = Paint()
      ..color = ribLightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const ribCount = 5;
    final ribStartY = h * 0.38;
    const ribSpacing = 7.0;
    const ribLength = 11.0;

    for (int i = 0; i < ribCount; i++) {
      final y = ribStartY + i * ribSpacing;
      // Left side grip ribs
      canvas.drawLine(Offset(4.5, y), Offset(4.5 + ribLength, y), ribDarkPaint);
      canvas.drawLine(Offset(4.5, y + 1.2), Offset(4.5 + ribLength, y + 1.2), ribLightPaint);

      // Right side grip ribs
      canvas.drawLine(Offset(w - 4.5 - ribLength, y), Offset(w - 4.5, y), ribDarkPaint);
      canvas.drawLine(Offset(w - 4.5 - ribLength, y + 1.2), Offset(w - 4.5, y + 1.2), ribLightPaint);
    }

    // 3. Central Observation Well (Recessed cavity where the spool disk rotates)
    final wellRadius = diskRadius + 4.5;
    final wellFill = Paint()
      ..color = isDark ? const Color(0xFF101215) : const Color(0xFFE8EDF2)
      ..style = PaintingStyle.fill;
    final wellBorder = Paint()
      ..color = isDark ? const Color(0xFF202630) : const Color(0xFFD0D7E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, wellRadius, wellFill);
    canvas.drawCircle(center, wellRadius, wellBorder);

    // Inner drop shadow rim for optical mechanical depth inside the cassette cavity
    final innerShadow = Paint()
      ..color = isDark ? const Color(0x60000000) : const Color(0x18000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, wellRadius - 1.5, innerShadow);

    // Tape Pack Calibration Scale (5 subtle index tick marks at left and right of the observation well)
    final tickPaint = Paint()
      ..color = isDark ? const Color(0x40FFFFFF) : const Color(0x35000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = -2; i <= 2; i++) {
      final tickY = center.dy + i * 10.0;
      // Left calibration ticks
      canvas.drawLine(Offset(center.dx - wellRadius + 2, tickY), Offset(center.dx - wellRadius + 7, tickY), tickPaint);
      // Right calibration ticks
      canvas.drawLine(Offset(center.dx + wellRadius - 7, tickY), Offset(center.dx + wellRadius - 2, tickY), tickPaint);
    }

    // 4. Magnetic Tape Ribbon & Lower Turnaround Guide Rollers
    final leftRollerCenter = Offset(w * 0.19, h * 0.825);
    final rightRollerCenter = Offset(w * 0.81, h * 0.825);

    // Magnetic oxide tape path ribbon
    final tapePaint = Paint()
      ..color = isDark ? const Color(0xFF0B0D0F) : const Color(0xFF24282D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Horizontal bottom tape span across rollers
    canvas.drawLine(leftRollerCenter, rightRollerCenter, tapePaint);

    // Left diagonal tape feed up to spool
    final leftTangentPoint = Offset(center.dx - diskRadius * 0.75, center.dy + diskRadius * 0.65);
    canvas.drawLine(leftRollerCenter, leftTangentPoint, tapePaint);

    // Right diagonal tape feed up to spool
    final rightTangentPoint = Offset(center.dx + diskRadius * 0.75, center.dy + diskRadius * 0.65);
    canvas.drawLine(rightRollerCenter, rightTangentPoint, tapePaint);

    // Turnaround Guide Rollers (Concentric precision idler pulleys)
    _drawGuideRoller(canvas, leftRollerCenter, 7.5, isDark);
    _drawGuideRoller(canvas, rightRollerCenter, 7.5, isDark);

    // 5. Trapezoidal Lower Tape-Head Bay
    final bayTopY = h * 0.855;
    final bayBottomY = h - 3.5;
    final halfTopW = (w * 0.58) / 2;
    final halfBottomW = (w * 0.46) / 2;

    final headBayPath = Path()
      ..moveTo(center.dx - halfTopW, bayTopY)
      ..lineTo(center.dx + halfTopW, bayTopY)
      ..lineTo(center.dx + halfBottomW, bayBottomY)
      ..lineTo(center.dx - halfBottomW, bayBottomY)
      ..close();

    final bayFill = Paint()
      ..color = isDark ? const Color(0xFF131518) : const Color(0xFFEDF1F6)
      ..style = PaintingStyle.fill;
    final bayBorder = Paint()
      ..color = isDark ? const Color(0xFF242A33) : const Color(0xFFCAD2DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(headBayPath, bayFill);
    canvas.drawPath(headBayPath, bayBorder);

    // Two Capstan Shaft Clearance Holes inside the head bay
    final leftCapstanCenter = Offset(center.dx - w * 0.15, h * 0.905);
    final rightCapstanCenter = Offset(center.dx + w * 0.15, h * 0.905);
    _drawCapstanHole(canvas, leftCapstanCenter, 3.2, isDark);
    _drawCapstanHole(canvas, rightCapstanCenter, 3.2, isDark);

    // Center Playhead Window Notch
    final headNotchRect = Rect.fromCenter(
      center: Offset(center.dx, h * 0.905),
      width: 14.0,
      height: 7.0,
    );
    final notchPaint = Paint()
      ..color = isDark ? const Color(0xFF090A0D) : const Color(0xFFD6DCE4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(headNotchRect, notchPaint);
  }

  void _drawGuideRoller(Canvas canvas, Offset center, double outerRadius, bool isDark) {
    // Outer flanged guide collar
    final flangePaint = Paint()
      ..color = isDark ? const Color(0xFF282E37) : const Color(0xFFCCD3DD)
      ..style = PaintingStyle.fill;
    final flangeBorder = Paint()
      ..color = isDark ? const Color(0xFF38404D) : const Color(0xFFB5BDC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius, flangePaint);
    canvas.drawCircle(center, outerRadius, flangeBorder);

    // Inner tape race groove
    final racePaint = Paint()
      ..color = isDark ? const Color(0xFF14171A) : const Color(0xFFE2E7ED)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius * 0.65, racePaint);

    // Polished stainless steel center axle pin
    final pinPaint = Paint()
      ..color = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius * 0.28, pinPaint);
  }

  void _drawCapstanHole(Canvas canvas, Offset center, double radius, bool isDark) {
    final holePaint = Paint()
      ..color = isDark ? const Color(0xFF090A0C) : const Color(0xFF1E2226)
      ..style = PaintingStyle.fill;
    final collarPaint = Paint()
      ..color = isDark ? const Color(0xFF2B323C) : const Color(0xFFBCC4CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, holePaint);
    canvas.drawCircle(center, radius + 1.5, collarPaint);
  }

  @override
  bool shouldRepaint(covariant _CassetteShellPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.diskRadius != diskRadius;
  }
}

/// Precision-machined flush chassis screw/bolt.
class MachinedBolt extends StatelessWidget {
  final double slotAngle;
  final bool isDark;

  const MachinedBolt({
    super.key,
    required this.slotAngle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 14),
      painter: _MachinedBoltPainter(
        slotAngle: slotAngle,
        isDark: isDark,
      ),
    );
  }
}

class _MachinedBoltPainter extends CustomPainter {
  final double slotAngle;
  final bool isDark;

  const _MachinedBoltPainter({
    required this.slotAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer recessed counterbore
    final holePaint = Paint()
      ..color = isDark ? const Color(0xFF0C0E11) : const Color(0xFFDCE2E9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, holePaint);

    // Inner screw head
    final headRadius = radius * 0.80;
    final headPaint = Paint()
      ..color = isDark ? const Color(0xFF2C323A) : const Color(0xFFCAD1DA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, headRadius, headPaint);

    // Screw head bevel border
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF3F4854) : const Color(0xFFB5BDC7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, headRadius, borderPaint);

    // Precision screw drive slot
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(slotAngle);

    final slotPaint = Paint()
      ..color = isDark ? const Color(0xFF101316) : const Color(0xFF7E8794)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(-radius * 0.52, 0), Offset(radius * 0.52, 0), slotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MachinedBoltPainter oldDelegate) {
    return oldDelegate.slotAngle != slotAngle || oldDelegate.isDark != isDark;
  }
}

/// Top-right info panel housing 4 sharp, contiguous box lights in a single row without spacing.
class TopRightInfoPanel extends StatelessWidget {
  final int elapsedSeconds;
  final bool isFocusMode;
  final bool isDark;
  final int baselineSeconds;
  final int extra3Seconds;
  final int extra4Seconds;

  const TopRightInfoPanel({
    super.key,
    required this.elapsedSeconds,
    required this.isFocusMode,
    required this.isDark,
    required this.baselineSeconds,
    required this.extra3Seconds,
    required this.extra4Seconds,
  });

  @override
  Widget build(BuildContext context) {
    final b = baselineSeconds > 0 ? baselineSeconds : 1200;
    final t1 = (b * 0.70).round().clamp(60, b - 30);
    final t2 = b;
    final t3 = t2 + (extra3Seconds > 0 ? extra3Seconds : 180);
    final t4 = t3 + (extra4Seconds > 0 ? extra4Seconds : 240);

    // The lights ONLY glow when their decided milestone time is up
    final isActive = isFocusMode && elapsedSeconds > 0;
    final stage1Lit = isActive && elapsedSeconds >= t1;
    final stage2Lit = isActive && elapsedSeconds >= t2;
    final stage3Lit = isActive && elapsedSeconds >= t3;
    final stage4Lit = isActive && elapsedSeconds >= t4;

    return Container(
      key: const Key('info_area_stage_lights'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1013) : const Color(0xFFE2E7EC),
        borderRadius: BorderRadius.zero, // Razor-sharp industrial container
        border: Border.all(
          color: isDark ? const Color(0xFF222830) : const Color(0xFFCAD1DA),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // In one row WITHOUT any spacing between them
        children: [
          StageBoxLight(
            key: const Key('box_light_1'),
            index: 1,
            isLit: stage1Lit,
            isDark: isDark,
            isFirst: true,
            isLast: false,
          ),
          StageBoxLight(
            key: const Key('box_light_2'),
            index: 2,
            isLit: stage2Lit,
            isDark: isDark,
            isFirst: false,
            isLast: false,
          ),
          StageBoxLight(
            key: const Key('box_light_3'),
            index: 3,
            isLit: stage3Lit,
            isDark: isDark,
            isFirst: false,
            isLast: false,
          ),
          StageBoxLight(
            key: const Key('box_light_4'),
            index: 4,
            isLit: stage4Lit,
            isDark: isDark,
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

/// A single sharp rectangular box light segment in the contiguous milestone indicator bar.
class StageBoxLight extends StatelessWidget {
  final int index; // 1, 2, 3, 4
  final bool isLit;
  final bool isDark;
  final bool isFirst;
  final bool isLast;

  const StageBoxLight({
    super.key,
    required this.index,
    required this.isLit,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;

    if (!isLit) {
      fillColor = isDark ? const Color(0xFF14171A) : const Color(0xFFF0F3F6);
      borderColor = isDark ? const Color(0xFF242A32) : const Color(0xFFD0D7DE);
      shadows = const [];
    } else if (isDark) {
      switch (index) {
        case 1:
          fillColor = AppTheme.darkStage1; // #1B2E24 Deep Emerald
          borderColor = const Color(0xFF2E6347);
          shadows = const [
            BoxShadow(
              color: Color(0x901B2E24),
              blurRadius: 5,
              spreadRadius: 0.5,
            ),
          ];
          break;
        case 2:
          fillColor = AppTheme.darkStage2; // #28593D Muted Moss
          borderColor = const Color(0xFF3FA36C);
          shadows = const [
            BoxShadow(
              color: Color(0xA028593D),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ];
          break;
        case 3:
          fillColor = AppTheme.darkStage3; // #3FA36C Vibrant Leaf Green
          borderColor = const Color(0xFF5AD491);
          shadows = const [
            BoxShadow(
              color: Color(0xC03FA36C),
              blurRadius: 7,
              spreadRadius: 1.5,
            ),
          ];
          break;
        case 4:
        default:
          fillColor = const Color(0xFF52D18D); // Luminescent Emerald Surge
          borderColor = const Color(0xFF7EFFBA);
          shadows = const [
            BoxShadow(
              color: Color(0xE052D18D),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ];
          break;
      }
    } else {
      // White Mode
      switch (index) {
        case 1:
          fillColor = const Color(0xFFD4EBD9); // Mint Tint
          borderColor = const Color(0xFFA3D4B1);
          shadows = const [
            BoxShadow(
              color: Color(0x60A8D5BA),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ];
          break;
        case 2:
          fillColor = AppTheme.lightStage2; // #A8D5BA Soft Sage
          borderColor = const Color(0xFF67B583);
          shadows = const [
            BoxShadow(
              color: Color(0x80A8D5BA),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ];
          break;
        case 3:
          fillColor = const Color(0xFF3FA36C); // Vibrant Leaf Green
          borderColor = const Color(0xFF2E8B57);
          shadows = const [
            BoxShadow(
              color: Color(0x903FA36C),
              blurRadius: 6,
              spreadRadius: 1.5,
            ),
          ];
          break;
        case 4:
        default:
          fillColor = AppTheme.lightStage3; // #2E8B57 Pleasant Forest Green
          borderColor = const Color(0xFF1B633B);
          shadows = const [
            BoxShadow(
              color: Color(0xB02E8B57),
              blurRadius: 7,
              spreadRadius: 2,
            ),
          ];
          break;
      }
    }

    final dividerColor = isDark ? const Color(0xFF222830) : const Color(0xFFCAD1DA);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 15,
      height: 9,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.zero, // Razor-sharp rectangular segment
        border: Border(
          top: BorderSide(color: isLit ? borderColor : Colors.transparent, width: 0.8),
          bottom: BorderSide(color: isLit ? borderColor : Colors.transparent, width: 0.8),
          left: isFirst ? BorderSide(color: isLit ? borderColor : Colors.transparent, width: 0.8) : BorderSide.none,
          right: isLast
              ? BorderSide(color: isLit ? borderColor : Colors.transparent, width: 0.8)
              : BorderSide(color: dividerColor, width: 1.0),
        ),
        boxShadow: shadows,
      ),
    );
  }
}

/// Clean, mechanical rotating matte spool painter.
/// Pure reel mechanics with zero color rings drawn on the spool face itself.
class _RetroSpoolPainter extends CustomPainter {
  final double rotationAngle;
  final bool isDark;

  _RetroSpoolPainter({
    required this.rotationAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Solid Matte Base Disk Face
    final baseColor = isDark ? const Color(0xFF141619) : const Color(0xFFF2F5F8);
    final diskPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, diskPaint);

    // 2. Rotating Tape Spool Mechanics (Cutout windows, spoke ribs, center hub)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawSpoolMechanics(canvas, radius);

    canvas.restore();

    // 3. Precision-Machined Outer Casing Rim
    final outerRimPaint = Paint()
      ..color = isDark ? const Color(0xFF2C323B) : const Color(0xFFCAD1DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, outerRimPaint);

    // Inner bevel shadow for recessed physical depth
    final innerBevelPaint = Paint()
      ..color = isDark ? const Color(0x35000000) : const Color(0x16000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 5, innerBevelPaint);
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
  bool shouldRepaint(covariant _RetroSpoolPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark;
  }
}
