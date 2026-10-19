import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';
import '../widgets/retro_matte_disk.dart';
import 'data_backup_screen.dart';

/// Screen providing information about Vord, repository details,
/// an interactive physical tape reel hub, update channel selection
/// (Release vs Action Builds with prominent data loss warning),
/// and automated in-app download and installation of APK packages.
class InfoUpdatesScreen extends StatefulWidget {
  final SessionService? sessionService;

  const InfoUpdatesScreen({
    super.key,
    this.sessionService,
  });

  @override
  State<InfoUpdatesScreen> createState() => _InfoUpdatesScreenState();
}

class _InfoUpdatesScreenState extends State<InfoUpdatesScreen> with SingleTickerProviderStateMixin {
  late final SessionService _sessionService;
  late final AnimationController _reelController;

  UpdateChannel _selectedChannel = UpdateChannel.release;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  UpdateInfo? _updateInfo;
  File? _downloadedApk;
  String? _installStatus;

  // Interactive UI state
  double _manualAngle = 0.0;
  bool _showTelemetry = false;
  String? _copiedNotification;

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService ?? SessionService();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _reelController.addListener(() {
      setState(() {
        _manualAngle = _reelController.value * 2 * math.pi * 3;
      });
    });
    _loadChannel();
  }

  @override
  void dispose() {
    _reelController.dispose();
    super.dispose();
  }

  Future<void> _loadChannel() async {
    final channel = await UpdateService.getUpdateChannel();
    if (mounted) {
      setState(() => _selectedChannel = channel);
    }
  }

  Future<void> _handleChannelChange(UpdateChannel channel) async {
    SoundService.playTapeSwitchClick();
    setState(() {
      _selectedChannel = channel;
      _updateInfo = null;
      _errorMessage = null;
      _downloadedApk = null;
      _installStatus = null;
    });
    await UpdateService.setUpdateChannel(channel);
  }

  void _spinInteractiveReel() {
    SoundService.playTapeTransportLatch();
    if (_reelController.isAnimating) {
      _reelController.stop();
    }
    _reelController.forward(from: 0.0);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    SoundService.playTapeSwitchClick();
    setState(() {
      _copiedNotification = label;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_copiedNotification == label) _copiedNotification = null;
        });
      }
    });
  }

  Future<void> _handleCheckForUpdates() async {
    SoundService.playTapeSwitchClick();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _updateInfo = null;
      _downloadedApk = null;
      _installStatus = null;
    });

    try {
      final info = await UpdateService.checkForUpdate(channel: _selectedChannel);
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to check updates: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownloadUpdate() async {
    final url = _updateInfo?.downloadUrl;
    if (url == null || url.isEmpty) {
      setState(() => _errorMessage = 'No download URL available for this update.');
      return;
    }

    SoundService.playTapeTransportLatch();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
      _installStatus = null;
    });

    try {
      final file = await UpdateService.downloadApk(
        downloadUrl: url,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadedBytes = received;
              _totalBytes = total;
              if (total > 0) {
                _downloadProgress = (received / total).clamp(0.0, 1.0);
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadedApk = file;
          _isDownloading = false;
          _installStatus = 'APK ready for installation (${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Download failed: $e';
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _handleInstallUpdate() async {
    final apk = _downloadedApk;
    if (apk == null || !apk.existsSync()) {
      setState(() => _errorMessage = 'Downloaded APK not found.');
      return;
    }

    SoundService.playTapeTransportLatch();
    setState(() {
      _installStatus = 'Launching package installer...';
    });

    final result = await UpdateService.installApk(apk.path);

    if (mounted) {
      setState(() {
        _installStatus = result.message;
        if (!result.success) {
          _errorMessage = 'Installer notification: ${result.message}';
        }
      });
    }
  }

  Future<void> _handleShareApk() async {
    final apk = _downloadedApk;
    if (apk != null && apk.existsSync()) {
      SoundService.playTapeSwitchClick();
      await UpdateService.shareApk(apk.path);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown date';
    final utc = dt.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')} UTC';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Machined Faceplate Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  bottom: BorderSide(color: borderCol, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  PhysicalMatteButton(
                    onTap: () {
                      SoundService.playTapeSwitchClick();
                      Navigator.pop(context);
                    },
                    borderRadius: 0.0,
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICE BAY // SPEC & UPDATES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CALIBRATION: ONLINE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  MachinedBolt(slotAngle: 0.45, isDark: isDark),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION 1: INTERACTIVE MECHANICAL TAPE REEL HUB
                    _buildSectionHeader('01 // TAPE TRANSPORT REEL HUB', textSecondary),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _spinInteractiveReel,
                      onPanUpdate: (details) {
                        setState(() {
                          _manualAngle += (details.delta.dx - details.delta.dy) * 0.02;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          border: Border.all(color: borderCol, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            // 4 corner bolts
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                MachinedBolt(slotAngle: 0.3, isDark: isDark),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  color: isDark ? const Color(0xFF14171A) : const Color(0xFFE4E8ED),
                                  child: Text(
                                    'SPEED: 4.76 CM/S',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                MachinedBolt(slotAngle: 1.2, isDark: isDark),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Spinning reel spindle
                            Center(
                              child: CustomPaint(
                                size: const Size(120, 120),
                                painter: _InteractiveHubPainter(
                                  angle: _manualAngle,
                                  isDark: isDark,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              'TAP OR DRAG SPINDLE TO TEST ROTATIONAL MECHANISM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                MachinedBolt(slotAngle: 2.1, isDark: isDark),
                                Text(
                                  'TEAC // CASSETTE DRIVE HUB',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: textSecondary,
                                  ),
                                ),
                                MachinedBolt(slotAngle: 0.7, isDark: isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: CHASSIS SPECIFICATION & PROVENANCE
                    _buildSectionHeader('02 // SPECIFICATION & REPOSITORY ARCHIVE', textSecondary),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border.all(color: borderCol, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VORD',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                  color: textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'v${UpdateService.currentVersion}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'A big, minimal, solid-state productivity timer inspired by classic reel-to-reel tape decks. Pure offline-first architecture with dynamic self-competition and tactile mechanical controls.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: textSecondary,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(height: 1, color: borderCol),
                          const SizedBox(height: 14),

                          // Repo Owner Row with interactive copy
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'REPO OWNER:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                UpdateService.repoOwner,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const Spacer(),
                              PhysicalMatteButton(
                                onTap: () => _copyToClipboard(UpdateService.repoOwner, 'OWNER COPIED'),
                                borderRadius: 0.0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  'COPY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Repository URL Row with interactive copy
                          Row(
                            children: [
                              Icon(Icons.code_rounded, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'REPOSITORY:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'github.com/${UpdateService.repoOwner}/${UpdateService.repoName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PhysicalMatteButton(
                                onTap: () => _copyToClipboard(UpdateService.repoUrl, 'URL COPIED'),
                                borderRadius: 0.0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  'COPY URL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_copiedNotification != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              color: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _copiedNotification!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          Container(height: 1, color: borderCol),
                          const SizedBox(height: 10),

                          // Toggle Telemetry Accordion
                          InkWell(
                            onTap: () {
                              SoundService.playTapeSwitchClick();
                              setState(() => _showTelemetry = !_showTelemetry);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tune_rounded, size: 14, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'HARDWARE TELEMETRY & SPECS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _showTelemetry ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_showTelemetry) ...[
                            const SizedBox(height: 8),
                            _buildTelemetryItem('CORE ARCHITECTURE', '100% OFFLINE-FIRST SANDBOX', textPrimary, textSecondary),
                            _buildTelemetryItem('PERSISTENCE ENGINE', 'ATOMIC MUTEX FILE SERIALIZER', textPrimary, textSecondary),
                            _buildTelemetryItem('ACOUSTICS', 'LOW-LATENCY TAPE LATCH SYNTHESIS', textPrimary, textSecondary),
                            _buildTelemetryItem('LICENSE', 'OPEN SOURCE MIT ARCHIVE', textPrimary, textSecondary),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 3: UPDATE CHANNEL SELECTOR
                    _buildSectionHeader('03 // UPDATE CHANNEL SELECTOR', textSecondary),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Official Release Selector
                        Expanded(
                          child: PhysicalMatteButton(
                            onTap: () => _handleChannelChange(UpdateChannel.release),
                            borderRadius: 0.0,
                            backgroundColor: _selectedChannel == UpdateChannel.release
                                ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3))
                                : surface,
                            borderColor: _selectedChannel == UpdateChannel.release
                                ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                : borderCol,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _selectedChannel == UpdateChannel.release
                                            ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                            : textSecondary.withAlpha(80),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'OFFICIAL RELEASE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _selectedChannel == UpdateChannel.release
                                            ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                            : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'STABLE MILESTONES',
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Commit Builds Selector
                        Expanded(
                          child: PhysicalMatteButton(
                            onTap: () => _handleChannelChange(UpdateChannel.commit),
                            borderRadius: 0.0,
                            backgroundColor: _selectedChannel == UpdateChannel.commit
                                ? (isDark ? const Color(0xFF2E1B1B) : const Color(0xFFFFF2F2))
                                : surface,
                            borderColor: _selectedChannel == UpdateChannel.commit
                                ? const Color(0xFFE5534B)
                                : borderCol,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _selectedChannel == UpdateChannel.commit
                                            ? const Color(0xFFE5534B)
                                            : textSecondary.withAlpha(80),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'COMMIT BUILDS',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _selectedChannel == UpdateChannel.commit
                                            ? const Color(0xFFE5534B)
                                            : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ACTION BUILDS',
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // CHANNEL STATUS & CAUTION HAZARD PLATE
                    if (_selectedChannel == UpdateChannel.commit)
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF241212) : const Color(0xFFFFF2F2),
                          border: Border.all(
                            color: const Color(0xFFE5534B),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: Color(0xFFE5534B),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'DANGER: HIGH DATA LOSS RISK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Color(0xFFE5534B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commit-wise updates carry a huge risk of losing every data! Experimental commit builds are compiled directly from the development branch and may contain unmigrated storage schemas, breaking changes, or regressions. Always export a backup file in Options > Data & Backup before installing commit updates.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFF79A95) : const Color(0xFFC02D28),
                              ),
                            ),
                            const SizedBox(height: 12),
                            PhysicalMatteButton(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DataBackupScreen(sessionService: _sessionService),
                                  ),
                                );
                              },
                              borderRadius: 0.0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: isDark ? const Color(0xFF381A1A) : const Color(0xFFFFE0E0),
                              borderColor: const Color(0xFFE5534B),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_alt_rounded, size: 14, color: Color(0xFFE5534B)),
                                  SizedBox(width: 6),
                                  Text(
                                    'SAFEGUARD DATA: EXPORT BACKUP NOW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFE5534B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: surface,
                          border: Border.all(color: borderCol, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Official releases are verified production milestones tested for backward compatibility and offline storage persistence.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // SECTION 4: SOFTWARE UPDATE BAY
                    _buildSectionHeader('04 // FIRMWARE & SOFTWARE UPDATE BAY', textSecondary),
                    const SizedBox(height: 10),

                    // Trigger Button
                    PhysicalMatteButton(
                      onTap: _isLoading ? () {} : _handleCheckForUpdates,
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      backgroundColor: isDark ? const Color(0xFF1F242B) : const Color(0xFFE8ECEF),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: textPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18, color: textPrimary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedChannel == UpdateChannel.commit
                                        ? 'FETCH LATEST ACTION BUILD'
                                        : 'CHECK FOR OFFICIAL RELEASE',
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

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF261414) : const Color(0xFFFFF0F0),
                          border: Border.all(color: const Color(0xFFE5534B), width: 1.2),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFE5534B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    if (_updateInfo != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: surface,
                          border: Border.all(color: borderCol, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Status Indicator
                            Row(
                              children: [
                                Icon(
                                  _updateInfo!.isAvailable
                                      ? (_updateInfo!.channel == UpdateChannel.commit ? Icons.build_circle_outlined : Icons.verified_rounded)
                                      : Icons.info_outline_rounded,
                                  size: 18,
                                  color: _updateInfo!.isAvailable
                                      ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _updateInfo!.channel == UpdateChannel.commit
                                        ? 'SUCCESSFUL ACTION BUILD'
                                        : (_updateInfo!.isAvailable ? 'OFFICIAL RELEASE: v${_updateInfo!.version}' : 'RELEASE STATUS'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Release or Build Title
                            Text(
                              _updateInfo!.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Description or Notes
                            Text(
                              _updateInfo!.notes,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: textSecondary,
                              ),
                            ),

                            if (_updateInfo!.publishedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Timestamp: ${_formatDate(_updateInfo!.publishedAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ],

                            if (_updateInfo!.fileSize != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Package size: ${_formatBytes(_updateInfo!.fileSize!)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // ACTIONS DEPENDING ON CHANNEL AND AVAILABILITY
                            if (!_updateInfo!.isAvailable && _updateInfo!.channel == UpdateChannel.release) ...[
                              // Official release is NOT available: clear message, NO download button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF14171A) : const Color(0xFFF2F4F7),
                                  border: Border.all(color: borderCol, width: 1.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NO OFFICIAL RELEASES AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No official release has been tagged for Vord yet. Switch to "COMMIT BUILDS" above to install the latest successful GitHub action build.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.3,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_isDownloading) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'DOWNLOADING PACKAGE...',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${(_downloadProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _downloadProgress > 0 ? _downloadProgress : null,
                                    backgroundColor: isDark ? const Color(0xFF282E37) : const Color(0xFFDFE4EA),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                    ),
                                    minHeight: 6,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatBytes(_downloadedBytes)} / ${_formatBytes(_totalBytes)}',
                                    style: TextStyle(fontSize: 10, color: textSecondary),
                                  ),
                                ],
                              ),
                            ] else if (_downloadedApk != null) ...[
                              // Ready to install
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PhysicalMatteButton(
                                    onTap: _handleInstallUpdate,
                                    borderRadius: 0.0,
                                    backgroundColor: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3),
                                    borderColor: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.system_update_alt_rounded,
                                            size: 18,
                                            color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'INSTALL UPDATE NOW (APK)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                              color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  PhysicalMatteButton(
                                    onTap: _handleShareApk,
                                    borderRadius: 0.0,
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Center(
                                      child: Text(
                                        'SHARE / BACKUP APK FILE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_updateInfo!.hasApk) ...[
                              PhysicalMatteButton(
                                onTap: _handleDownloadUpdate,
                                borderRadius: 0.0,
                                backgroundColor: isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3),
                                borderColor: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                padding: const EdgeInsets.symmetric(vertical: 14.0),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.file_download_outlined,
                                        size: 18,
                                        color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _updateInfo!.channel == UpdateChannel.commit
                                            ? 'DOWNLOAD ACTION BUILD (APK)'
                                            : 'DOWNLOAD APK UPDATE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            if (_installStatus != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _installStatus!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }

  Widget _buildTelemetryItem(String label, String value, Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: secondary),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the interactive cassette reel spindle hub
class _InteractiveHubPainter extends CustomPainter {
  final double angle;
  final bool isDark;

  const _InteractiveHubPainter({
    required this.angle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // 1. Outer rim
    final outerRimPaint = Paint()
      ..color = isDark ? const Color(0xFF2C323B) : const Color(0xFFCFD6DE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, outerRimPaint);

    final outerBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF3E4652) : const Color(0xFFAAB4BE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius, outerBorderPaint);

    // 2. Lathe circular grooves
    final groovePaint = Paint()
      ..color = isDark ? const Color(0xFF1B1E23) : const Color(0xFFE2E7EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.82, groovePaint);
    canvas.drawCircle(Offset.zero, radius * 0.65, groovePaint);

    // 3. Spindle body
    final bodyPaint = Paint()
      ..color = isDark ? const Color(0xFF16191D) : const Color(0xFFF0F3F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.50, bodyPaint);

    // 4. 3-teeth drive splines (standard cassette reel hub drive teeth)
    final splinePaint = Paint()
      ..color = isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final theta = i * (2 * math.pi / 3);
      final p1 = Offset(math.cos(theta - 0.22) * radius * 0.28, math.sin(theta - 0.22) * radius * 0.28);
      final p2 = Offset(math.cos(theta - 0.15) * radius * 0.52, math.sin(theta - 0.15) * radius * 0.52);
      final p3 = Offset(math.cos(theta + 0.15) * radius * 0.52, math.sin(theta + 0.15) * radius * 0.52);
      final p4 = Offset(math.cos(theta + 0.22) * radius * 0.28, math.sin(theta + 0.22) * radius * 0.28);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();
      canvas.drawPath(path, splinePaint);
    }

    // 5. Center spindle hole
    final centerHolePaint = Paint()
      ..color = isDark ? const Color(0xFF090A0C) : const Color(0xFFBAC3CC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.26, centerHolePaint);

    final centerPinPaint = Paint()
      ..color = isDark ? const Color(0xFF3F4652) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.08, centerPinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InteractiveHubPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isDark != isDark;
  }
}
