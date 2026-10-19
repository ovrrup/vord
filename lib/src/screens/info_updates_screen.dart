import 'dart:io';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Screen providing information about Vord, repository details,
/// update channel selection (Release vs Commits with data loss warning),
/// and automated in-app download and installation of APK packages.
class InfoUpdatesScreen extends StatefulWidget {
  const InfoUpdatesScreen({super.key});

  @override
  State<InfoUpdatesScreen> createState() => _InfoUpdatesScreenState();
}

class _InfoUpdatesScreenState extends State<InfoUpdatesScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadChannel();
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

  Future<void> _handleCheckForUpdates() async {
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
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: Text(
                      'INFO & UPDATES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1.5,
              color: borderCol,
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: About the App & Repository
                    Text(
                      'ABOUT APPLICATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16.0),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'A big, minimal, solid-state productivity timer inspired by classic reel-to-reel tape decks. Built offline-first with dynamic self-competition and tactile mechanical controls.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: borderCol),
                          const SizedBox(height: 14),

                          // Owner
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'REPO OWNER:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                UpdateService.repoOwner,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Repo URL
                          Row(
                            children: [
                              Icon(Icons.code_rounded, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'REPOSITORY:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'github.com/${UpdateService.repoOwner}/${UpdateService.repoName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Update Channel Selection
                    Text(
                      'UPDATE CHANNEL',
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
                        // Releases Channel Tab
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Center(
                              child: Text(
                                'OFFICIAL RELEASE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: _selectedChannel == UpdateChannel.release
                                      ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                      : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Commits Channel Tab
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Center(
                              child: Text(
                                'COMMIT BUILDS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: _selectedChannel == UpdateChannel.commit
                                      ? const Color(0xFFE5534B)
                                      : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // CHANNEL DESCRIPTION & DANGER WARNING
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
                                'Official releases are stable milestones tested for data integrity and backwards compatibility.',
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

                    // Section 3: Updates Check & In-App Installation
                    Text(
                      'SOFTWARE UPDATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Check for Updates Button
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
                                        ? 'CHECK LATEST COMMIT'
                                        : 'CHECK FOR UPDATES',
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
                            Row(
                              children: [
                                Icon(
                                  _updateInfo!.isNewer || _updateInfo!.channel == UpdateChannel.commit
                                      ? Icons.new_releases_outlined
                                      : Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: _updateInfo!.isNewer || _updateInfo!.channel == UpdateChannel.commit
                                      ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _updateInfo!.channel == UpdateChannel.commit
                                        ? 'LATEST COMMIT: ${_updateInfo!.version}'
                                        : 'AVAILABLE: v${_updateInfo!.version}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _updateInfo!.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _updateInfo!.notes,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: textSecondary,
                              ),
                            ),
                            if (_updateInfo!.fileSize != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Package size: ${_formatBytes(_updateInfo!.fileSize!)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Download / Install Actions
                            if (_isDownloading) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'DOWNLOADING UPDATE...',
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
                                            'INSTALL UPDATE NOW',
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
                                        'DOWNLOAD APK UPDATE',
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
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2228) : const Color(0xFFF4F6F9),
                                  border: Border.all(color: borderCol, width: 1.0),
                                ),
                                child: Text(
                                  'No APK asset package is currently attached to this update milestone.',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
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
}
