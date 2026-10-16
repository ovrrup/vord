import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../theme/app_theme.dart';

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
        color: AppTheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentMuted.withOpacity(0.3),
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
                    ? AppTheme.accentMuted.withOpacity(0.8)
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
                      : AppTheme.textSecondary.withOpacity(0.8),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
