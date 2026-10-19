import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';
import 'data_backup_screen.dart';

/// Clean, modern About & Updates screen.
/// Promotes the author (@ovrrup) and repository (ovrrup/vord, ovrrup/Lumia)
/// with interactive links, and provides clean update channel management.
class InfoUpdatesScreen extends StatefulWidget {
  final SessionService? sessionService;

  const InfoUpdatesScreen({super.key, this.sessionService});

  @override
  State<InfoUpdatesScreen> createState() => _InfoUpdatesScreenState();
}

class _InfoUpdatesScreenState extends State<InfoUpdatesScreen> {
  late final SessionService _sessionService;

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
  String? _notificationMessage;
  Timer? _notificationTimer;

  static const String authorUsername = 'ovrrup';
  static const String authorUrl = 'https://github.com/ovrrup';
  static const String repoName = 'ovrrup/vord';
  static const String repoUrl = 'https://github.com/ovrrup/vord';
  static const String lumiaRepoUrl = 'https://github.com/ovrrup/Lumia';

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService ?? SessionService();
    _loadChannel();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChannel() async {
    final channel = await UpdateService.getUpdateChannel();
    if (mounted) {
      setState(() => _selectedChannel = channel);
    }
  }

  Future<void> _handleChannelChange(UpdateChannel channel) async {
    setState(() {
      _selectedChannel = channel;
      _updateInfo = null;
      _errorMessage = null;
      _downloadedApk = null;
      _installStatus = null;
    });
    await UpdateService.setUpdateChannel(channel);
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _copyToClipboard(urlString, 'URL Copied to Clipboard');
      }
    } catch (_) {
      _copyToClipboard(urlString, 'URL Copied to Clipboard');
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    _notificationTimer?.cancel();
    setState(() {
      _notificationMessage = message;
    });
    _notificationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_notificationMessage == message) _notificationMessage = null;
        });
      }
    });
  }

  Future<void> _handleCheckForUpdates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _updateInfo = null;
      _downloadedApk = null;
      _installStatus = null;
    });

    try {
      final info = await UpdateService.checkForUpdate(
        channel: _selectedChannel,
      );
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not fetch updates: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownloadApk(String url) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
      _downloadedApk = null;
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
                _downloadProgress = received / total;
              }
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _downloadedApk = file;
        _isDownloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Download failed: $e';
        _isDownloading = false;
      });
    }
  }

  Future<void> _handleInstallApk() async {
    if (_downloadedApk == null) return;

    setState(() {
      _installStatus = 'Starting installer...';
    });

    try {
      final result = await UpdateService.installApk(
        _downloadedApk!.path,
        commitSha: _updateInfo?.commitSha,
      );
      if (!mounted) return;
      setState(() {
        _installStatus = result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installStatus = 'Install error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16191D)
                    : const Color(0xFFF2F5F8),
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
                  Expanded(
                    child: Text(
                      'ABOUT & UPDATES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notification Feedback Banner
            if (_notificationMessage != null)
              Container(
                color: isDark
                    ? const Color(0xFF142B1E)
                    : const Color(0xFFE2F3E9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF3FA36C)
                          : const Color(0xFF2E8B57),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _notificationMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF3FA36C)
                            : const Color(0xFF2E8B57),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: App Branding & Overview
                    _buildAppHeaderCard(
                      isDark,
                      borderCol,
                      textPrimary,
                      textSecondary,
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Author Showcase (Promote Author)
                    _buildAuthorCard(
                      isDark,
                      borderCol,
                      textPrimary,
                      textSecondary,
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Repository Showcase (Promote Repo)
                    _buildRepositoryCard(
                      isDark,
                      borderCol,
                      textPrimary,
                      textSecondary,
                    ),

                    const SizedBox(height: 24),

                    // Section 4: Update Channels & Installer
                    _buildUpdateSection(
                      isDark,
                      borderCol,
                      textPrimary,
                      textSecondary,
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

  Widget _buildAppHeaderCard(
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
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
                  letterSpacing: 3.0,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2026)
                      : const Color(0xFFE4E9EF),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E3640)
                        : const Color(0xFFCAD1DA),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'v${UpdateService.currentVersion}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Minimalist, distraction-free study and focus timer. Engineered for 100% offline operation, self-competition pacing, and zero telemetry.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    final activeGreen = isDark
        ? const Color(0xFF3FA36C)
        : const Color(0xFF2E8B57);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTHOR & DEVELOPER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
            border: Border.all(color: borderCol, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2026)
                          : const Color(0xFFE2E7ED),
                      border: Border.all(color: borderCol, width: 1.2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: activeGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorUsername,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Creator of Vord & Lumia',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PhysicalMatteButton(
                    onTap: () =>
                        _copyToClipboard(authorUsername, 'OWNER COPIED'),
                    borderRadius: 0.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      'COPY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Independent software developer crafting clean, offline-first mobile applications with refined mechanical aesthetics.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Interactive Profile Button
              Row(
                children: [
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () => _openUrl(authorUrl),
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: activeGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VISIT GITHUB PROFILE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Lumia Cross-Promotion Button
              PhysicalMatteButton(
                onTap: () => _openUrl(lumiaRepoUrl),
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFFE5A93C)
                          : const Color(0xFFC7841B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EXPLORE LUMIA (STUDY TRACKER)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepositoryCard(
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    final activeGreen = isDark
        ? const Color(0xFF3FA36C)
        : const Color(0xFF2E8B57);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPOSITORY & SOURCE CODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
            border: Border.all(color: borderCol, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code_rounded, size: 20, color: activeGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'github.com/$repoName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  PhysicalMatteButton(
                    onTap: () => _copyToClipboard(repoUrl, 'REPO URL COPIED'),
                    borderRadius: 0.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      'COPY URL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Open-source repository hosted on GitHub. Star the project, track commit history, or inspect the codebase.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Action Buttons Row: View Repo & Star Repo
              Row(
                children: [
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () => _openUrl(repoUrl),
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.launch_rounded,
                              size: 15,
                              color: activeGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'VIEW REPO',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () => _openUrl('$repoUrl/stargazers'),
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: const Color(0xFFE5A93C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'STAR ON GITHUB',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Secondary links: Releases & Issues
              Row(
                children: [
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () => _openUrl('$repoUrl/releases'),
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          'RELEASES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () => _openUrl('$repoUrl/issues'),
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          'ISSUES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateSection(
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isRelease = _selectedChannel == UpdateChannel.release;
    final isCommit = _selectedChannel == UpdateChannel.commit;
    final activeGreen = isDark
        ? const Color(0xFF3FA36C)
        : const Color(0xFF2E8B57);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPDATE CHANNELS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // Channel Selector Buttons
        Row(
          children: [
            Expanded(
              child: PhysicalMatteButton(
                onTap: () => _handleChannelChange(UpdateChannel.release),
                backgroundColor: isRelease
                    ? (isDark
                          ? const Color(0xFF142B1E)
                          : const Color(0xFFE2F3E9))
                    : null,
                borderColor: isRelease ? activeGreen : null,
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      'OFFICIAL RELEASE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isRelease ? activeGreen : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Stable Releases',
                      style: TextStyle(fontSize: 9.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PhysicalMatteButton(
                onTap: () => _handleChannelChange(UpdateChannel.commit),
                backgroundColor: isCommit
                    ? (isDark
                          ? const Color(0xFF2E2414)
                          : const Color(0xFFFFF4E0))
                    : null,
                borderColor: isCommit ? const Color(0xFFE5A93C) : null,
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      'COMMIT BUILDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isCommit ? const Color(0xFFE5A93C) : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Action Builds',
                      style: TextStyle(fontSize: 9.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Data Loss Notice for Commit Channel
        if (isCommit) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261919) : const Color(0xFFFDECEB),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFE5534B)
                    : const Color(0xFFD73A49),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFE5534B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DANGER: HIGH DATA LOSS RISK',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Color(0xFFE5534B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Commit-wise updates carry a huge risk of losing every data! Experimental builds are compiled directly from development and may contain unmigrated database schemas or breaking changes.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFF8A6A0)
                        : const Color(0xFF86181D),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                PhysicalMatteButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DataBackupScreen(sessionService: _sessionService),
                      ),
                    );
                  },
                  borderRadius: 0.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Text(
                      'SAFEGUARD DATA: EXPORT BACKUP NOW',
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

        const SizedBox(height: 16),

        // Check for Updates Button
        PhysicalMatteButton(
          onTap: _isLoading || _isDownloading ? () {} : _handleCheckForUpdates,
          borderRadius: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Center(
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'CHECKING GITHUB...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isCommit
                        ? 'FETCH LATEST ACTION BUILD'
                        : 'CHECK FOR UPDATES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: textPrimary,
                    ),
                  ),
          ),
        ),

        // Error Banner
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261919) : const Color(0xFFFDECEB),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFE5534B)
                    : const Color(0xFFD73A49),
                width: 1.0,
              ),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFFF8A6A0)
                    : const Color(0xFF86181D),
              ),
            ),
          ),
        ],

        // Download Progress Indicator
        if (_isDownloading) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
              border: Border.all(color: borderCol, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DOWNLOADING APK PACKAGE...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: activeGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: isDark
                      ? const Color(0xFF1E242C)
                      : const Color(0xFFD8DFE8),
                  valueColor: AlwaysStoppedAnimation(activeGreen),
                  minHeight: 6,
                ),
                if (_totalBytes > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${(_downloadedBytes / 1048576).toStringAsFixed(1)} MB / ${(_totalBytes / 1048576).toStringAsFixed(1)} MB',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Update Info Result Card
        if (_updateInfo != null && !_isDownloading) ...[
          const SizedBox(height: 14),
          _buildUpdateResultCard(isDark, borderCol, textPrimary, textSecondary),
        ],

        // Install Status Banner
        if (_installStatus != null) ...[
          const SizedBox(height: 10),
          Text(
            _installStatus!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpdateResultCard(
    bool isDark,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    final info = _updateInfo!;
    final isCommit = _selectedChannel == UpdateChannel.commit;
    final activeGreen = isDark
        ? const Color(0xFF3FA36C)
        : const Color(0xFF2E8B57);

    // Official release channel with 0 releases published
    if (!isCommit && !info.isAvailable && !info.hasApk) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'NO OFFICIAL RELEASES AVAILABLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No official release versions have been published yet for Vord. Switch to "COMMIT BUILDS" above to install the latest successful GitHub action build.',
              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCommit ? 'SUCCESSFUL ACTION BUILD' : 'OFFICIAL RELEASE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: activeGreen,
                ),
              ),
              if (info.isNewer)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: activeGreen,
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF142B1E) : const Color(0xFFE2F3E9),
                    border: Border.all(color: activeGreen, width: 1.0),
                  ),
                  child: Text(
                    'UP TO DATE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: activeGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info.version,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          if (!info.isNewer) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: activeGreen),
                const SizedBox(width: 6),
                Text(
                  'Your installed version is already up to date with this build.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: activeGreen,
                  ),
                ),
              ],
            ),
          ],
          if (info.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.title,
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
          ],
          if (info.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info.notes,
              style: TextStyle(
                fontSize: 10.5,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Download or Install Button
          if (_downloadedApk != null)
            PhysicalMatteButton(
              onTap: _handleInstallApk,
              borderRadius: 0.0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update_rounded,
                      size: 16,
                      color: activeGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'INSTALL APK PACKAGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (info.downloadUrl != null && info.downloadUrl!.isNotEmpty)
            PhysicalMatteButton(
              onTap: () => _handleDownloadApk(info.downloadUrl!),
              borderRadius: 0.0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, size: 16, color: activeGreen),
                    const SizedBox(width: 8),
                    Text(
                      isCommit
                          ? (info.isNewer
                              ? 'DOWNLOAD ACTION BUILD (APK)'
                              : 'RE-DOWNLOAD BUILD (APK)')
                          : (info.isNewer
                              ? 'DOWNLOAD RELEASE APK'
                              : 'RE-DOWNLOAD RELEASE APK'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
