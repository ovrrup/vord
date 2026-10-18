import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Data and Backup Archive Screen.
/// Enables users to export session history as a JSON backup,
/// import and restore sessions (merge or overwrite), and manage data archives.
class DataBackupScreen extends StatefulWidget {
  final SessionService sessionService;

  const DataBackupScreen({
    super.key,
    required this.sessionService,
  });

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final TextEditingController _importController = TextEditingController();
  bool _showPreview = false;
  String? _feedbackMessage;
  bool _isFeedbackSuccess = true;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds % 60}s';
  }

  void _handleCopyBackup() {
    SoundService.playTapeSwitchClick();
    final jsonText = widget.sessionService.exportBackupJson();
    Clipboard.setData(ClipboardData(text: jsonText));

    setState(() {
      _feedbackMessage = 'Backup JSON copied to clipboard!';
      _isFeedbackSuccess = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup JSON copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePasteClipboard() async {
    SoundService.playTapeSwitchClick();
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _importController.text = data.text!;
        _feedbackMessage = null;
      });
    }
  }

  Future<void> _handleImport({required bool replace}) async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please paste backup JSON into the input area first.';
        _isFeedbackSuccess = false;
      });
      return;
    }

    if (replace) {
      final confirmed = await _showReplaceConfirmDialog();
      if (!confirmed) return;
    }

    SoundService.playTapeTransportLatch();
    final result = await widget.sessionService.importBackupJson(text, replace: replace);

    setState(() {
      _feedbackMessage = result.message;
      _isFeedbackSuccess = result.success;
      if (result.success) {
        _importController.clear();
      }
    });
  }

  Future<bool> _showReplaceConfirmDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'OVERWRITE ALL DATA?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'This will delete all current sessions on this device and replace them with the imported archive. This action cannot be reversed.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'OVERWRITE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFE5534B),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleClearAll() async {
    SoundService.playTapeSwitchClick();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'CLEAR ALL SESSIONS?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'All recorded focus sessions and rest intervals will be permanently wiped.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'WIPE DATA',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFE5534B),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SoundService.playTapeTransportLatch();
      await widget.sessionService.clearAllSessions();
      setState(() {
        _feedbackMessage = 'All session archives have been cleared.';
        _isFeedbackSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final totalCount = widget.sessionService.totalSessionCount;
    final focusSec = widget.sessionService.allTimeFocusSeconds;
    final breakSec = widget.sessionService.allTimeBreakSeconds;
    final sizeKb = (widget.sessionService.storageSizeBytes / 1024.0).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Razor-Sharp Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
                border: Border(
                  bottom: BorderSide(color: borderCol, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 38,
                    child: PhysicalMatteButton(
                      onTap: () {
                        SoundService.playTapeSwitchClick();
                        Navigator.pop(context);
                      },
                      borderRadius: 0.0,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATA & BACKUP ARCHIVE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'JSON EXPORT, IMPORT & STORAGE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Scrollable Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Archive Readout Metrics Bar
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141619) : const Color(0xFFF7F9FB),
                        border: Border.all(color: borderCol, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SESSIONS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$totalCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1.5, height: 32, color: borderCol),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FOCUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDuration(focusSec),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1.5, height: 32, color: borderCol),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDuration(breakSec),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1.5, height: 32, color: borderCol),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SIZE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$sizeKb KB',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Feedback Banner (If any)
                    if (_feedbackMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: _isFeedbackSuccess
                              ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE9F5ED))
                              : (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFBEAEA)),
                          border: Border.all(
                            color: _isFeedbackSuccess
                                ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                : const Color(0xFFE5534B),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isFeedbackSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              size: 18,
                              color: _isFeedbackSuccess
                                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                  : const Color(0xFFE5534B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _feedbackMessage!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // B. EXPORT BACKUP SECTION
                    Text(
                      'BACKUP EXPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: PhysicalMatteButton(
                              onTap: _handleCopyBackup,
                              borderRadius: 0.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'COPY BACKUP JSON',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: PhysicalMatteButton(
                            onTap: () {
                              SoundService.playTapeSwitchClick();
                              setState(() => _showPreview = !_showPreview);
                            },
                            borderRadius: 0.0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(
                              _showPreview ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_showPreview) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1114) : const Color(0xFFECEFF3),
                          border: Border.all(color: borderCol, width: 1.2),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            widget.sessionService.exportBackupJson(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF1E7B44),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // C. IMPORT & RESTORE SECTION
                    Text(
                      'BACKUP IMPORT & RESTORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111316) : const Color(0xFFF9FAFB),
                        border: Border.all(color: borderCol, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _importController,
                            maxLines: 4,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste backup JSON archive here...',
                              hintStyle: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: textSecondary.withAlpha(140),
                              ),
                              contentPadding: const EdgeInsets.all(12.0),
                              border: InputBorder.none,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF16191D) : const Color(0xFFEFF2F6),
                              border: Border(top: BorderSide(color: borderCol, width: 1.0)),
                            ),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _handlePasteClipboard,
                                  icon: Icon(Icons.paste_rounded, size: 14, color: textSecondary),
                                  label: Text(
                                    'PASTE CLIPBOARD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_importController.text.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      SoundService.playTapeSwitchClick();
                                      setState(() {
                                        _importController.clear();
                                        _feedbackMessage = null;
                                      });
                                    },
                                    child: Text(
                                      'CLEAR',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: PhysicalMatteButton(
                              onTap: () => _handleImport(replace: false),
                              borderRadius: 0.0,
                              child: Center(
                                child: Text(
                                  'MERGE SESSIONS',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: PhysicalMatteButton(
                              onTap: () => _handleImport(replace: true),
                              borderRadius: 0.0,
                              borderColor: const Color(0xFFE5534B).withAlpha(150),
                              child: const Center(
                                child: Text(
                                  'OVERWRITE ALL',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: Color(0xFFE5534B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // D. DATA MAINTENANCE / RESET
                    Text(
                      'DATA MAINTENANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 46,
                      child: PhysicalMatteButton(
                        onTap: _handleClearAll,
                        borderRadius: 0.0,
                        borderColor: const Color(0xFFE5534B),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFE5534B)),
                            SizedBox(width: 8),
                            Text(
                              'CLEAR ALL RECORDED SESSIONS',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Color(0xFFE5534B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
