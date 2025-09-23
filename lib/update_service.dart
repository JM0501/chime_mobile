import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateService {
  static const String latestReleaseApi =
      "https://api.github.com/repos/JM0501/chime_mobile/releases/latest";

  // Called from main.dart
  static Future<bool> checkForUpdates() async {
    try {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Fetch latest release info from GitHub
      final res = await http.get(Uri.parse(latestReleaseApi));
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      String latestVersion = data["tag_name"].replaceAll("v", "");

      // Store APK URL so we can use it later in prompt
      _latestApkUrl = data["assets"][0]["browser_download_url"];
      _latestVersion = latestVersion;

      return _isNewerVersion(latestVersion, currentVersion);
    } catch (e) {
      debugPrint("Update check failed: $e");
      return false;
    }
  }

  //Called from main.dart when update is available
  static void promptUserToUpdate(BuildContext context) {
    if (_latestApkUrl == null || _latestVersion == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available"),
        content: Text("A new version ($_latestVersion) is available."),
        actions: [
          TextButton(
            child: const Text("Later"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Update Now"),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(context, _latestApkUrl!);
            },
          ),
        ],
      ),
    );
  }

  /// --- Private helpers ---

  static String? _latestApkUrl;
  static String? _latestVersion;

  static bool _isNewerVersion(String latest, String current) {
    List<int> latestParts =
        latest.split(".").map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts =
        current.split(".").map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > (i < currentParts.length ? currentParts[i] : 0)) {
        return true;
      } else if (latestParts[i] < (i < currentParts.length ? currentParts[i] : 0)) {
        return false;
      }
    }
    return false;
  }

  static Future<void> _downloadAndInstall(
      BuildContext context, String apkUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/chime-latest.apk";

      Dio dio = Dio();
      await dio.download(apkUrl, savePath, onReceiveProgress: (rec, total) {
        debugPrint("Downloading: ${(rec / total * 100).toStringAsFixed(0)}%");
      });

      // Open the downloaded APK → triggers installer
      await OpenFilex.open(savePath);
    } catch (e) {
      debugPrint("Download/install failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download update")),
        );
      }
    }
  }
}
