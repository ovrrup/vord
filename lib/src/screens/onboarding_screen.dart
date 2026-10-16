import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      step: '01 / PHILOSOPHY',
      title: 'Pure focus.\nZero distraction.',
      description:
          'VORD is built to protect your attention. No feeds, no bloated settings—just your time and your deep work.',
      illustrationType: _IllustrationType.focus,
    ),
    _OnboardingData(
      step: '02 / GESTURES',
      title: 'One touch controls\neverything.',
      description:
          'Tap anywhere on the ring to start or pause. Long press to reset. Tap your daily dots to view study history.',
      illustrationType: _IllustrationType.gestures,
    ),
    _OnboardingData(
      step: '03 / CADENCE',
      title: 'Work and rest in\nharmony.',
      description:
          'Study for 25 minutes, refresh for 5. Complete 4 focus sessions to unlock a deep 15-minute recovery.',
      illustrationType: _IllustrationType.cadence,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Branding & Skip Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VORD',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLastPage)
                    GestureDetector(
                      onTap: widget.onComplete,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'SKIP',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),

              // Page Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bespoke minimal graphic
                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: _OnboardingGraphic(type: data.illustrationType),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Step label
                        Text(
                          data.step,
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 2.0,
                            color: const Color(0xFF81E6D9), // Soft muted teal
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          data.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          data.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Area: Page Dots Indicator + Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        width: isSelected ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : const Color(0x4D7A7F8D),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Action
                  GestureDetector(
                    onTap: _onNext,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isLastPage
                            ? AppTheme.textPrimary
                            : const Color(0x332E323D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLastPage
                              ? Colors.transparent
                              : const Color(0x667A7F8D),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastPage ? 'BEGIN' : 'NEXT',
                            style: theme.textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.5,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isLastPage
                                  ? AppTheme.background
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isLastPage
                                ? AppTheme.background
                                : AppTheme.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

enum _IllustrationType { focus, gestures, cadence }

class _OnboardingData {
  final String step;
  final String title;
  final String description;
  final _IllustrationType illustrationType;

  const _OnboardingData({
    required this.step,
    required this.title,
    required this.description,
    required this.illustrationType,
  });
}

class _OnboardingGraphic extends StatelessWidget {
  final _IllustrationType type;

  const _OnboardingGraphic({required this.type});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GraphicPainter(type: type),
    );
  }
}

class _GraphicPainter extends CustomPainter {
  final _IllustrationType type;

  _GraphicPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case _IllustrationType.focus:
        // Elegant concentric focus rings
        final outerPaint = Paint()
          ..color = const Color(0x337A7F8D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 70, outerPaint);

        final midPaint = Paint()
          ..color = const Color(0x667A7F8D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 45, midPaint);

        final innerPaint = Paint()
          ..color = AppTheme.textPrimary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 8, innerPaint);
        break;

      case _IllustrationType.gestures:
        // Minimalist touch diagram
        final ringPaint = Paint()
          ..color = const Color(0x667A7F8D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 60, ringPaint);

        // Tap ripple / pulsing focal point
        final pulsePaint = Paint()
          ..color = const Color(0xFF81E6D9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 6, pulsePaint);

        final ripplePaint = Paint()
          ..color = const Color(0x3381E6D9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 22, ripplePaint);
        break;

      case _IllustrationType.cadence:
        // 4 rhythmic cadence dots with interconnecting arc
        final arcPaint = Paint()
          ..color = const Color(0x337A7F8D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 60, arcPaint);

        const dotCount = 4;
        for (var i = 0; i < dotCount; i++) {
          final angle = (i * (2 * 3.1415926535 / dotCount)) - (3.1415926535 / 2);
          final x = center.dx + 60 * (i == 1 || i == 3 ? (i == 1 ? 1 : -1) : 0);
          final y = center.dy + 60 * (i == 0 ? -1 : (i == 2 ? 1 : 0));

          final dotPaint = Paint()
            ..color = i == 0 ? AppTheme.textPrimary : const Color(0x667A7F8D)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(x, y), i == 0 ? 5 : 3.5, dotPaint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GraphicPainter oldDelegate) =>
      oldDelegate.type != type;
}
