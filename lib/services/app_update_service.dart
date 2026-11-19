import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseNotes;
  final bool isUpdateAvailable;
  final bool forceUpdate;
  final String playStoreUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseNotes,
    required this.isUpdateAvailable,
    this.forceUpdate = false,
    this.playStoreUrl = AppUpdateService.playStoreWebUrl,
  });
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String currentVersion = '1.10.2';
  static const int currentBuildNumber = 18;
  static const String playStorePackage = 'com.caloriefit.app';
  static const String playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$playStorePackage';
  static const String playStoreMarketUrl = 'market://details?id=$playStorePackage';

  static const List<String> _manifestUrls = [
    'https://kashif-malik12.github.io/CalorieFit/version.json',
    'https://raw.githubusercontent.com/kashif-malik12/CalorieFit/main/version.json',
  ];

  static const String _kLastDismissedBuildKey = 'caloriefit_last_dismissed_update_build';
  static const String _kLastDismissedTimeKey = 'caloriefit_last_dismissed_update_time';
  static const String _kLastCheckTimeKey = 'caloriefit_last_update_check_time';

  /// Open Google Play Store directly on the app's listing page.
  Future<bool> openPlayStore() async {
    final marketUri = Uri.parse(playStoreMarketUrl);
    final webUri = Uri.parse(playStoreWebUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return false;
  }

  /// Check if an update is available from remote manifest.
  Future<AppUpdateInfo> checkForUpdate({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!force) {
      final lastDismissedBuild = prefs.getInt(_kLastDismissedBuildKey) ?? 0;
      final lastDismissedTime = prefs.getInt(_kLastDismissedTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // If user dismissed this version within 24 hours, don't re-prompt automatically
      if (lastDismissedBuild > currentBuildNumber && (now - lastDismissedTime) < 86400000) {
        return AppUpdateInfo(
          latestVersion: currentVersion,
          latestBuildNumber: currentBuildNumber,
          releaseNotes: '',
          isUpdateAvailable: false,
        );
      }
    }

    Map<String, dynamic>? data;

    for (final url in _manifestUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          data = jsonDecode(res.body) as Map<String, dynamic>?;
          if (data != null) break;
        }
      } catch (_) {
        // try next fallback
      }
    }

    if (data == null) {
      return AppUpdateInfo(
        latestVersion: currentVersion,
        latestBuildNumber: currentBuildNumber,
        releaseNotes: '',
        isUpdateAvailable: false,
      );
    }

    final remoteVersion = (data['version'] as String?) ?? currentVersion;
    final remoteBuild = (data['build_number'] as num?)?.toInt() ?? currentBuildNumber;
    final notes = (data['release_notes'] as String?) ?? 'A new version with performance improvements and bug fixes is ready.';
    final forceUpdate = (data['force_update'] as bool?) ?? false;
    final playUrl = (data['play_store_url'] as String?) ?? playStoreWebUrl;

    await prefs.setInt(_kLastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);

    final isNewer = remoteBuild > currentBuildNumber || _isVersionHigher(remoteVersion, currentVersion);

    return AppUpdateInfo(
      latestVersion: remoteVersion,
      latestBuildNumber: remoteBuild,
      releaseNotes: notes,
      isUpdateAvailable: isNewer,
      forceUpdate: forceUpdate && isNewer,
      playStoreUrl: playUrl,
    );
  }

  /// Compare two semantic version strings like 1.9.1 vs 1.9.0
  static bool _isVersionHigher(String remote, String current) {
    try {
      final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final len = rParts.length > cParts.length ? rParts.length : cParts.length;

      for (int i = 0; i < len; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Mark build as dismissed so user is not prompted again immediately
  Future<void> dismissUpdate(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastDismissedBuildKey, buildNumber);
    await prefs.setInt(_kLastDismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check in background and show update dialog if available
  Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final info = await checkForUpdate(force: false);
      if (info.isUpdateAvailable && context.mounted) {
        showUpdateDialog(context, info);
      }
    } catch (_) {}
  }

  /// User-initiated manual check with feedback dialogs
  Future<void> manualCheckForUpdates(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Checking for updates...', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final info = await checkForUpdate(force: true);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (info.isUpdateAvailable) {
        showUpdateDialog(context, info);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            title: const Text('You\'re Up to Date!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CalorieFit v$currentVersion (Build $currentBuildNumber) is currently the latest version available on Google Play.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text('Latest Official Release', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check for updates: $e')),
      );
    }
  }

  /// Show the modern update dialog
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !info.forceUpdate,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.system_update_alt, color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Update Available!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v$currentVersion  ➔  v${info.latestVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What\'s New:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        info.releaseNotes,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (!info.forceUpdate) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              dismissUpdate(info.latestBuildNumber);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Later'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: info.forceUpdate ? 1 : 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            openPlayStore();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
