import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Data and Backup Archive Screen.
/// File-based backup export and import for session records.
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
  String? _statusMessage;
  bool _isSuccess = true;
  bool _isLoading = false;
  List<File> _localBackups = [];
  bool _hasPreWipe = false;

  @override
  void initState() {
    super.initState();
    _refreshLocalBackups();
  }

  Future<void> _refreshLocalBackups() async {
    final backups = await widget.sessionService.getLocalBackupFiles();
    final hasWipe = await widget.sessionService.hasPreWipeSnapshot();
    if (mounted) {
      setState(() {
        _localBackups = backups;
        _hasPreWipe = hasWipe;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds % 60}s';
  }

  Future<void> _handleExportFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await widget.sessionService.saveLocalBackupFile();
      final jsonText = widget.sessionService.exportBackupJson();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'vord_backup_$timestamp.json';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonText, flush: true);

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Vord Session Backup',
            text: 'Vord backup archive: $fileName',
          ),
        );
      } catch (_) {}

      await _refreshLocalBackups();

      if (mounted) {
        setState(() {
          _statusMessage = 'Exported & saved archive: $fileName';
          _isSuccess = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Export failed: $e';
          _isSuccess = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestoreFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final pickedFile = await FilePicker.pickFile();

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final content = utf8.decode(bytes);

      if (!mounted) return;

      await _processRestoreContent(content);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Restore failed: $e';
          _isSuccess = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processRestoreContent(String content) async {
    final replace = await _showImportModeDialog();
    if (replace == null) {
      setState(() => _isLoading = false);
      return;
    }

    final importResult =
        await widget.sessionService.importBackupJson(content, replace: replace);
    await _refreshLocalBackups();

    if (mounted) {
      setState(() {
        _statusMessage = importResult.message;
        _isSuccess = importResult.success;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRestorePreWipeSnapshot() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final result = await widget.sessionService.restorePreWipeSnapshot();
    await _refreshLocalBackups();

    if (mounted) {
      setState(() {
        _statusMessage = result.message;
        _isSuccess = result.success;
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showImportModeDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'RESTORE SESSIONS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'How would you like to restore sessions from this file?',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'MERGE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'OVERWRITE ALL',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFE5534B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClearAll() async {
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
      await widget.sessionService.clearAllSessions();
      await _refreshLocalBackups();
      setState(() {
        _statusMessage = 'All session archives have been wiped (recovery snapshot preserved).';
        _isSuccess = true;
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.sessionService,
          builder: (context, _) {
            final totalCount = widget.sessionService.totalSessionCount;
            final focusSec = widget.sessionService.allTimeFocusSeconds;
            final breakSec = widget.sessionService.allTimeBreakSeconds;
            final sizeKb = (widget.sessionService.storageSizeBytes / 1024.0).toStringAsFixed(1);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // 1. Header
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
                      onTap: () => Navigator.pop(context),
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
                  Text(
                    'DATA & BACKUP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Metrics Bar
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

                    const SizedBox(height: 20),

                    // Status Message Banner
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE9F5ED))
                              : (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFBEAEA)),
                          border: Border.all(
                            color: _isSuccess
                                ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                : const Color(0xFFE5534B),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              size: 18,
                              color: _isSuccess
                                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                  : const Color(0xFFE5534B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // B. FILE EXPORT BUTTON
                    SizedBox(
                      height: 52,
                      child: PhysicalMatteButton(
                        onTap: _isLoading ? () {} : _handleExportFile,
                        borderRadius: 0.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'EXPORT BACKUP FILE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // C. FILE IMPORT BUTTON
                    SizedBox(
                      height: 52,
                      child: PhysicalMatteButton(
                        onTap: _isLoading ? () {} : _handleRestoreFile,
                        borderRadius: 0.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              size: 20,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'RESTORE FROM FILE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pre-Wipe Recovery Safety Net
                    if (_hasPreWipe) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEDF7F1),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'SAFETY SNAPSHOT AVAILABLE',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: PhysicalMatteButton(
                                onTap: _isLoading ? () {} : _handleRestorePreWipeSnapshot,
                                borderRadius: 0.0,
                                child: Text(
                                  'RESTORE SAFETY SNAPSHOT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Local Saved Archives
                    if (_localBackups.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'SAVED LOCAL ARCHIVES (${_localBackups.length})',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._localBackups.take(5).map((file) {
                        final name = file.path.split('/').last;
                        final kb = (file.lengthSync() / 1024.0).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141619) : const Color(0xFFF7F9FB),
                              border: Border.all(color: borderCol, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined, size: 16, color: textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$kb KB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 28,
                                  child: PhysicalMatteButton(
                                    onTap: () async {
                                      final content = await file.readAsString();
                                      await _processRestoreContent(content);
                                    },
                                    borderRadius: 0.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: const Text(
                                      'LOAD',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 32),

                    // D. WIPE DATA BUTTON
                    SizedBox(
                      height: 48,
                      child: PhysicalMatteButton(
                        onTap: _handleClearAll,
                        borderRadius: 0.0,
                        borderColor: const Color(0xFFE5534B).withAlpha(160),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFE5534B)),
                            SizedBox(width: 8),
                            Text(
                              'CLEAR ALL SESSIONS',
                              style: TextStyle(
                                fontSize: 12,
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
        );
      },
    ),
  ),
);
  }
}
