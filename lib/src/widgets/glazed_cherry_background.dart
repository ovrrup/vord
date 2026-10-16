import 'dart:ui';
import 'package:flutter/material.dart';

class GlazedCherryBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const GlazedCherryBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<GlazedCherryBackground> createState() => _GlazedCherryBackgroundState();
}

class _GlazedCherryBackgroundState extends State<GlazedCherryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Subtle orbital floating coordinates
        final orb1X = -0.3 + 0.2 * t;
        final orb1Y = -0.5 + 0.3 * (1 - t);
        final orb2X = 0.4 - 0.25 * t;
        final orb2Y = 0.2 - 0.2 * t;

        return Stack(
          children: [
            // Deep obsidian cherry foundation
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F0407), // Deep black-cherry
                      Color(0xFF070204),
                    ],
                  ),
                ),
              ),
            ),

            // Top-left primary glazed cherry nebula
            Positioned.fill(
              child: CustomPaint(
                painter: _CherryOrbPainter(
                  alignment: Alignment(orb1X, orb1Y),
                  radiusRatio: 0.75,
                  colors: const [
                    Color(0x808B0018), // Deep rich crimson
                    Color(0x40D2122E), // Glazed cherry red
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Bottom-right secondary glazed cherry nebula
            Positioned.fill(
              child: CustomPaint(
                painter: _CherryOrbPainter(
                  alignment: Alignment(orb2X, orb2Y),
                  radiusRatio: 0.65,
                  colors: const [
                    Color(0x66660000), // Dark ruby
                    Color(0x33FF2A4D), // Glaze highlight red
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Center subtle ambient glow
            Positioned.fill(
              child: CustomPaint(
                painter: _CherryOrbPainter(
                  alignment: const Alignment(0.0, -0.1),
                  radiusRatio: 0.45 + (0.05 * t),
                  colors: const [
                    Color(0x40E5383B),
                    Color(0x15A4161A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Frosted glass atmospheric diffusion blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
                child: const SizedBox.expand(),
              ),
            ),

            // Subtle glossy specular overlay
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      Color(0x18FFFFFF), // Delicate specular rim glaze
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),

            // Content on top
            widget.child,
          ],
        );
      },
    );
  }
}

class _CherryOrbPainter extends CustomPainter {
  final Alignment alignment;
  final double radiusRatio;
  final List<Color> colors;

  _CherryOrbPainter({
    required this.alignment,
    required this.radiusRatio,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      (alignment.x + 1) / 2 * size.width,
      (alignment.y + 1) / 2 * size.height,
    );
    final radius = size.shortestSide * radiusRatio;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CherryOrbPainter oldDelegate) {
    return oldDelegate.alignment != alignment ||
        oldDelegate.radiusRatio != radiusRatio ||
        oldDelegate.colors != colors;
  }
}
