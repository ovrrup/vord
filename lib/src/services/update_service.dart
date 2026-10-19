import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'app_settings_service.dart';

/// Available update channels
enum UpdateChannel {
  release,
  commit,
}

/// Information about an available update
class UpdateInfo {
  final String version;
  final String title;
  final String notes;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final int? fileSize;
  final bool hasApk;
  final bool isNewer;
  final UpdateChannel channel;
  final String? commitSha;
  final int? actionRunNumber;
  final bool isAvailable;

  const UpdateInfo({
    required this.version,
    required this.title,
    required this.notes,
    this.publishedAt,
    this.downloadUrl,
    this.fileSize,
    required this.hasApk,
    required this.isNewer,
    required this.channel,
    this.commitSha,
    this.actionRunNumber,
    this.isAvailable = true,
  });
}

class InstallResult {
  final bool success;
  final String message;

  const InstallResult({required this.success, required this.message});
}

/// Service managing in-app updates from GitHub for both
/// official releases and bleeding-edge commit action builds.
class UpdateService {
  static const String currentVersion = '0.1.0';
  static const String repoOwner = 'ovrrup';
  static const String repoName = 'vord';
  static const String repoUrl = 'https://github.com/ovrrup/vord';

  static const String _channelPrefKey = 'vord_update_channel';

  /// Compile-time commit SHA and build number injected via `--dart-define`
  static const String currentCommitSha =
      String.fromEnvironment('APP_COMMIT_SHA', defaultValue: '');
  static const String currentBuildNumber =
      String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '');

  @visibleForTesting
  static String? mockCurrentCommitSha;
  @visibleForTesting
  static String? mockCurrentBuildNumber;

  // Mock callback for unit/widget testing without network
  static Future<UpdateInfo>? Function(UpdateChannel channel)? mockCheckHandler;
  static Future<InstallResult>? Function(String path)? mockInstallHandler;

  /// Get persisted last installed commit SHA
  static Future<String?> getInstalledCommitSha() async {
    try {
      await AppSettingsService.instance.init();
      return AppSettingsService.instance.lastInstalledCommitSha;
    } catch (_) {
      return null;
    }
  }

  /// Persist installed commit SHA
  static Future<void> setInstalledCommitSha(String sha) async {
    try {
      await AppSettingsService.instance.setLastInstalledCommitSha(sha);
    } catch (_) {}
  }

  /// Get persisted update channel (default: release)
  static Future<UpdateChannel> getUpdateChannel() async {
    try {
      await AppSettingsService.instance.init();
      final saved = AppSettingsService.instance.updateChannel;
      if (saved == 'commit') return UpdateChannel.commit;
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString(_channelPrefKey);
        if (saved == 'commit') return UpdateChannel.commit;
      } catch (_) {}
    }
    return UpdateChannel.release;
  }

  /// Persist update channel
  static Future<void> setUpdateChannel(UpdateChannel channel) async {
    try {
      await AppSettingsService.instance.setUpdateChannel(
        channel == UpdateChannel.commit ? 'commit' : 'release',
      );
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _channelPrefKey,
          channel == UpdateChannel.commit ? 'commit' : 'release',
        );
      } catch (_) {}
    }
  }

  /// Check for updates on the selected or specified channel
  static Future<UpdateInfo> checkForUpdate({UpdateChannel? channel}) async {
    final targetChannel = channel ?? await getUpdateChannel();

    if (mockCheckHandler != null) {
      final mock = await mockCheckHandler!(targetChannel);
      if (mock != null) return mock;
    }

    if (targetChannel == UpdateChannel.commit) {
      return _checkCommitUpdate();
    } else {
      return _checkReleaseUpdate();
    }
  }

  /// Check official releases on GitHub
  static Future<UpdateInfo> _checkReleaseUpdate() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'),
      );
      request.headers.set('User-Agent', 'Vord-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();

      if (response.statusCode == 404) {
        return const UpdateInfo(
          version: currentVersion,
          title: 'No Official Releases Found',
          notes: 'No official releases have been published yet for Vord on this repository.\n\nTo download the latest automated action builds, switch the update channel to "COMMIT BUILDS".',
          hasApk: false,
          isNewer: false,
          isAvailable: false,
          channel: UpdateChannel.release,
        );
      }

      if (response.statusCode != 200) {
        throw HttpException('GitHub API error: HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? currentVersion;
      final title = data['name'] as String? ?? 'Release $tagName';
      final notes = data['body'] as String? ?? 'No release notes provided.';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      String? apkUrl;
      int? apkSize;

      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkSize = asset['size'] as int?;
          break;
        }
      }

      final isNewer = _compareVersions(tagName, currentVersion) > 0;

      return UpdateInfo(
        version: tagName,
        title: title,
        notes: notes,
        publishedAt: publishedAt,
        downloadUrl: apkUrl,
        fileSize: apkSize,
        hasApk: apkUrl != null,
        isNewer: isNewer,
        isAvailable: true,
        channel: UpdateChannel.release,
      );
    } finally {
      client.close();
    }
  }

  /// Check latest successful GitHub Actions workflow run on `main` branch
  static Future<UpdateInfo> _checkCommitUpdate() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      // 1. Query the latest successful GitHub Actions workflow run on main branch
      final runsRequest = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/actions/runs?branch=main&status=success&per_page=1'),
      );
      runsRequest.headers.set('User-Agent', 'Vord-App');
      runsRequest.headers.set('Accept', 'application/vnd.github.v3+json');

      final runsResponse = await runsRequest.close();
      if (runsResponse.statusCode != 200) {
        throw HttpException('GitHub Actions API error: HTTP ${runsResponse.statusCode}');
      }

      final runsBody = await runsResponse.transform(utf8.decoder).join();
      final runsData = jsonDecode(runsBody) as Map<String, dynamic>;
      final runsList = runsData['workflow_runs'] as List<dynamic>? ?? [];

      if (runsList.isEmpty) {
        return const UpdateInfo(
          version: 'None',
          title: 'No Action Builds Found',
          notes: 'No successful GitHub Actions workflow runs found on the main branch.',
          hasApk: false,
          isNewer: false,
          isAvailable: false,
          channel: UpdateChannel.commit,
        );
      }

      final run = runsList.first as Map<String, dynamic>;
      final runNumber = run['run_number'] as int? ?? 1;
      final fullSha = run['head_sha'] as String? ?? 'unknown';
      final shortSha = fullSha.length > 7 ? fullSha.substring(0, 7) : fullSha;
      final headCommit = run['head_commit'] as Map<String, dynamic>? ?? {};
      final commitMsg = (headCommit['message'] as String? ?? 'Action build #$runNumber').split('\n').first;
      final updatedAtStr = run['updated_at'] as String? ?? run['created_at'] as String?;
      final buildDate = updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null;

      // 2. Query nightly release asset for size if available
      int? apkSize;
      try {
        final nightlyRequest = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/tags/nightly'),
        );
        nightlyRequest.headers.set('User-Agent', 'Vord-App');
        nightlyRequest.headers.set('Accept', 'application/vnd.github.v3+json');
        final nightlyResponse = await nightlyRequest.close();

        if (nightlyResponse.statusCode == 200) {
          final nightlyBody = await nightlyResponse.transform(utf8.decoder).join();
          final nightlyData = jsonDecode(nightlyBody) as Map<String, dynamic>;
          final assets = nightlyData['assets'] as List<dynamic>? ?? [];
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkSize = asset['size'] as int?;
              break;
            }
          }
        }
      } catch (_) {}

      const apkUrl = 'https://github.com/ovrrup/vord/releases/download/nightly/app-release.apk';

      final effectiveCommitSha = mockCurrentCommitSha ?? currentCommitSha;
      final effectiveBuildNumber = mockCurrentBuildNumber ?? currentBuildNumber;
      final installedSha = await getInstalledCommitSha();

      bool isNewer = true;

      // 1. Check if compile-time SHA matches GitHub run head SHA
      if (effectiveCommitSha.isNotEmpty && fullSha.isNotEmpty && fullSha != 'unknown') {
        if (fullSha.toLowerCase().startsWith(effectiveCommitSha.toLowerCase()) ||
            effectiveCommitSha.toLowerCase().startsWith(fullSha.toLowerCase())) {
          isNewer = false;
        }
      }

      // 2. Check if compile-time action run number matches or is newer
      if (effectiveBuildNumber.isNotEmpty) {
        final currentRun = int.tryParse(effectiveBuildNumber);
        if (currentRun != null && runNumber <= currentRun) {
          isNewer = false;
        }
      }

      // 3. Check if user already installed this commit build
      if (installedSha != null && installedSha.isNotEmpty && fullSha.isNotEmpty && fullSha != 'unknown') {
        if (fullSha.toLowerCase().startsWith(installedSha.toLowerCase()) ||
            installedSha.toLowerCase().startsWith(fullSha.toLowerCase())) {
          isNewer = false;
        }
      }

      return UpdateInfo(
        version: 'Action Build #$runNumber ($shortSha)',
        commitSha: fullSha,
        actionRunNumber: runNumber,
        title: commitMsg,
        notes: 'Latest successful GitHub Actions build from main branch.\nCommit: $fullSha\nRun ID: ${run['id']}',
        publishedAt: buildDate,
        downloadUrl: apkUrl,
        fileSize: apkSize,
        hasApk: true,
        isNewer: isNewer,
        isAvailable: true,
        channel: UpdateChannel.commit,
      );
    } finally {
      client.close();
    }
  }

  /// Download APK with streaming byte progress callback
  static Future<File> downloadApk({
    required String downloadUrl,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set('User-Agent', 'Vord-App');

      final response = await request.close();

      // Handle HTTP redirects (e.g., 302 Found to AWS S3)
      if (response.isRedirect) {
        final redirectUrl = response.headers.value(HttpHeaders.locationHeader);
        if (redirectUrl != null) {
          return await downloadApk(
            downloadUrl: redirectUrl,
            onProgress: onProgress,
          );
        }
      }

      if (response.statusCode != 200) {
        throw HttpException('Download failed with status ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/vord_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int received = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, contentLength);
      }

      await sink.flush();
      await sink.close();

      return apkFile;
    } finally {
      client.close();
    }
  }

  /// Trigger Android Package Installer to install APK
  static Future<InstallResult> installApk(String filePath, {String? commitSha}) async {
    if (commitSha != null && commitSha.isNotEmpty) {
      await setInstalledCommitSha(commitSha);
    }

    if (mockInstallHandler != null) {
      final mock = await mockInstallHandler!(filePath);
      if (mock != null) return mock;
    }

    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      final isSuccess = result.type == ResultType.done;
      return InstallResult(
        success: isSuccess,
        message: result.message,
      );
    } catch (e) {
      return InstallResult(
        success: false,
        message: 'Install launch error: $e',
      );
    }
  }

  /// Share APK file as instant fallback
  static Future<void> shareApk(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Vord APK Installer Package',
        text: 'Vord Update APK Package: $filePath',
      ),
    );
  }

  /// Semantic version comparison (v1 > v2 => 1, v1 == v2 => 0, v1 < v2 => -1)
  static int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < maxLen; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
      }
      return 0;
    } catch (_) {
      return v1.compareTo(v2);
    }
  }
}
