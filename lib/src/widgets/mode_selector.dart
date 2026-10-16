import 'package:flutter/material.dart';
import '../models/session_mode.dart';

class ModeSelector extends StatelessWidget {
  final SessionMode currentMode;
  final ValueChanged<SessionMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x9916181D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x4D2E323D),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SessionMode.all.map((mode) {
          final isSelected = mode.type == currentMode.type;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onModeChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xCC2E323D)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  letterSpacing: 0.3,
                  color: isSelected
                      ? mode.accentColor
                      : const Color(0xCC7A7F8D),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
