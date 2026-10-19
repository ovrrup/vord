import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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
  });
}

class InstallResult {
  final bool success;
  final String message;

  const InstallResult({required this.success, required this.message});
}

/// Service managing in-app updates from GitHub for both
/// official releases and bleeding-edge commit builds.
class UpdateService {
  static const String currentVersion = '0.1.0';
  static const String repoOwner = 'ovrrup';
  static const String repoName = 'vord';
  static const String repoUrl = 'https://github.com/ovrrup/vord';

  static const String _channelPrefKey = 'vord_update_channel';

  // Mock callback for unit/widget testing without network
  static Future<UpdateInfo>? Function(UpdateChannel channel)? mockCheckHandler;
  static Future<InstallResult>? Function(String path)? mockInstallHandler;

  /// Get persisted update channel (default: release)
  static Future<UpdateChannel> getUpdateChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_channelPrefKey);
      if (saved == 'commit') return UpdateChannel.commit;
    } catch (_) {}
    return UpdateChannel.release;
  }

  /// Persist update channel
  static Future<void> setUpdateChannel(UpdateChannel channel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _channelPrefKey,
        channel == UpdateChannel.commit ? 'commit' : 'release',
      );
    } catch (_) {}
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
          title: 'No Releases Found',
          notes: 'No official releases have been published yet on this repository.',
          hasApk: false,
          isNewer: false,
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
        channel: UpdateChannel.release,
      );
    } finally {
      client.close();
    }
  }

  /// Check latest commit on `main` branch
  static Future<UpdateInfo> _checkCommitUpdate() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      // 1. Fetch latest commit
      final commitRequest = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/commits/main'),
      );
      commitRequest.headers.set('User-Agent', 'Vord-App');
      commitRequest.headers.set('Accept', 'application/vnd.github.v3+json');

      final commitResponse = await commitRequest.close();
      if (commitResponse.statusCode != 200) {
        throw HttpException('GitHub API error: HTTP ${commitResponse.statusCode}');
      }

      final commitBody = await commitResponse.transform(utf8.decoder).join();
      final commitData = jsonDecode(commitBody) as Map<String, dynamic>;

      final fullSha = commitData['sha'] as String? ?? 'unknown';
      final shortSha = fullSha.length > 7 ? fullSha.substring(0, 7) : fullSha;
      final commitObj = commitData['commit'] as Map<String, dynamic>? ?? {};
      final message = (commitObj['message'] as String? ?? 'Commit $shortSha').split('\n').first;
      final authorObj = commitObj['author'] as Map<String, dynamic>? ?? {};
      final dateStr = authorObj['date'] as String?;
      final commitDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

      // 2. Look for nightly/pre-release build APK
      String? apkUrl;
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
              apkUrl = asset['browser_download_url'] as String?;
              apkSize = asset['size'] as int?;
              break;
            }
          }
        }
      } catch (_) {}

      // Fallback: direct nightly download url pattern if tagged
      apkUrl ??= 'https://github.com/$repoOwner/$repoName/releases/download/nightly/app-release.apk';

      return UpdateInfo(
        version: shortSha,
        commitSha: fullSha,
        title: message,
        notes: 'Commit SHA: $fullSha\nBranch: main\nWARNING: Bleeding-edge build. May cause data loss.',
        publishedAt: commitDate,
        downloadUrl: apkUrl,
        fileSize: apkSize,
        hasApk: true,
        isNewer: true, // Always allow pulling latest commit builds
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
  static Future<InstallResult> installApk(String filePath) async {
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
