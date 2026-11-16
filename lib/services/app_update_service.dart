import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:insol8_mobile/services/api_client.dart';

/// A newer Android build than the one installed, from `GET /app/updates/latest`.
class AppUpdate {
  const AppUpdate({
    required this.build,
    required this.downloadUrl,
    required this.forced,
    this.version,
    this.notes,
    this.sizeBytes,
  });

  /// The APK's versionCode; compared with the installed build.
  final int build;
  final String? version;
  final String? notes;
  final int? sizeBytes;

  /// Presigned S3 link, valid for about 15 minutes after the check.
  final String downloadUrl;

  /// The installed build is below the backend's `minSupportedBuild`: the user
  /// must update before using the app.
  final bool forced;

  /// "v0.6.1" when [version] is a version number; null for a branch name such
  /// as "main" (a build started from the Actions tab instead of a tag).
  String? get displayVersion {
    final match = RegExp(r'^v?(\d+(?:\.\d+){0,3})$').firstMatch(version ?? '');
    return match == null ? null : 'v${match.group(1)}';
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);
  final String message;

  @override
  String toString() => 'AppUpdateException($message)';
}

/// The Android side of in-app updates (MainActivity's `insol8/app_update`
/// channel). An interface so tests can fake it.
abstract class AppUpdatePlatform {
  Future<int> installedBuild();
  Future<String> updateDir();
  Future<bool> canInstallPackages();
  Future<void> openInstallPermissionSettings();
  Future<void> installApk(String path);
}

class MethodChannelAppUpdatePlatform implements AppUpdatePlatform {
  const MethodChannelAppUpdatePlatform();

  static const _channel = MethodChannel('insol8/app_update');

  @override
  Future<int> installedBuild() async =>
      (await _channel.invokeMethod<int>('installedBuild')) ?? 0;

  @override
  Future<String> updateDir() async =>
      (await _channel.invokeMethod<String>('updateDir'))!;

  @override
  Future<bool> canInstallPackages() async =>
      (await _channel.invokeMethod<bool>('canInstallPackages')) ?? false;

  @override
  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallPermissionSettings');

  @override
  Future<void> installApk(String path) =>
      _channel.invokeMethod<void>('installApk', {'path': path});
}

/// Checks the backend for a newer APK, downloads it, and opens Android's
/// installer. Android release builds only: the user still confirms every
/// install, and iOS cannot install apps this way at all.
///
/// Debug and profile builds are the separate "inSOL8 Dev" app
/// (com.insol8.mobile.debug); the APKs on S3 are the release app, so offering
/// them there would install a second app instead of updating this one.
class AppUpdateService {
  AppUpdateService({
    ApiClient? api,
    AppUpdatePlatform? platform,
    http.Client? httpClient,
    bool? isAndroid,
  }) : _api = api ?? ApiClient(),
       _platform = platform ?? const MethodChannelAppUpdatePlatform(),
       _http = httpClient ?? http.Client(),
       _isAndroid = isAndroid ?? (Platform.isAndroid && kReleaseMode);

  final ApiClient _api;
  final AppUpdatePlatform _platform;
  final http.Client _http;
  final bool _isAndroid;

  /// False off Android, where in-app updates are not possible.
  bool get isSupported => _isAndroid;

  /// The installed APK's versionCode, or null off Android.
  Future<int?> installedBuild() async =>
      _isAndroid ? await _platform.installedBuild() : null;

  /// Null when the app is up to date, not on Android, or no build exists yet.
  Future<AppUpdate?> check() async {
    if (!_isAndroid) return null;
    final installed = await _platform.installedBuild();
    // Public route: the check also runs before sign-in.
    final data = await _api.get('/app/updates/latest', authenticated: false);
    return updateFrom(data, installedBuild: installed);
  }

  /// Turns the route's `data` into an update, or null if nothing is newer.
  static AppUpdate? updateFrom(
    Map<String, dynamic> data, {
    required int installedBuild,
  }) {
    final latest = data['latest'];
    if (latest is! Map<String, dynamic>) return null;
    final build = (latest['build'] as num?)?.toInt();
    final url = latest['downloadUrl'] as String?;
    if (build == null || url == null || build <= installedBuild) return null;
    final minSupported = (data['minSupportedBuild'] as num?)?.toInt() ?? 0;
    return AppUpdate(
      build: build,
      downloadUrl: url,
      forced: installedBuild < minSupported,
      version: latest['version'] as String?,
      notes: latest['notes'] as String?,
      sizeBytes: (latest['sizeBytes'] as num?)?.toInt(),
    );
  }

  Future<bool> canInstallPackages() => _platform.canInstallPackages();

  Future<void> openInstallPermissionSettings() =>
      _platform.openInstallPermissionSettings();

  /// Downloads [update] and returns the APK's path. [onProgress] gets 0..1, or
  /// null while the size is unknown.
  Future<String> download(
    AppUpdate update, {
    void Function(double? progress)? onProgress,
  }) async {
    // The link from check() expires after ~15 minutes; ask for a fresh one.
    var url = update.downloadUrl;
    try {
      url = (await check())?.downloadUrl ?? url;
    } on Exception {
      // Keep the original link; the download below reports any real failure.
    }

    final dir = Directory(await _platform.updateDir());
    for (final old in dir.listSync().whereType<File>()) {
      if (old.path.endsWith('.apk')) old.deleteSync();
    }
    final file = File('${dir.path}/insol8-${update.build}.apk');

    final http.StreamedResponse response;
    try {
      response = await _http.send(http.Request('GET', Uri.parse(url)));
    } on http.ClientException {
      throw const AppUpdateException(
        'Check your internet connection and try again.',
      );
    }
    if (response.statusCode != 200) {
      throw const AppUpdateException('The download failed. Please try again.');
    }

    final total = response.contentLength ?? update.sizeBytes;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(
          total == null || total == 0 ? null : (received / total).clamp(0, 1),
        );
      }
    } on Exception {
      await sink.close();
      if (file.existsSync()) file.deleteSync();
      throw const AppUpdateException(
        'The download was interrupted. Please try again.',
      );
    }
    await sink.close();
    return file.path;
  }

  /// Opens Android's installer for a downloaded APK.
  Future<void> install(String path) async {
    try {
      await _platform.installApk(path);
    } on PlatformException catch (error) {
      throw AppUpdateException(
        error.message ?? 'Could not open the installer.',
      );
    }
  }
}
