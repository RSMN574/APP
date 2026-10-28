import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/app_release.dart';

class UpdateService {
  UpdateService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static final Uri latestReleaseUri =
      Uri.parse('https://api.github.com/repos/RSMN574/APP/releases/latest');

  final http.Client _client;
  final Duration timeout;

  Future<AppRelease> fetchLatestRelease() async {
    final response = await _client.get(
      latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ).timeout(timeout);

    if (response.statusCode == 404) {
      throw const UpdateCheckException(
        '找不到正式 Release。請確認 GitHub 專案已有公開的正式版本。',
      );
    }
    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'GitHub API 回應異常（HTTP ${response.statusCode}）。',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GitHub 回傳資料格式不正確。');
    }

    final release = AppRelease.fromJson(decoded);
    if (release.isPrerelease) {
      throw const UpdateCheckException('最新項目是預發布版本，暫不作為正式更新。');
    }
    return release;
  }

  /// Returns true when [latest] is newer than [current].
  /// Supports versions such as 1.2.3, v1.2.3, and 1.2.3-beta.1.
  static bool isNewerVersion(String current, String latest) {
    final a = _Version.parse(current);
    final b = _Version.parse(latest);
    if (a == null || b == null) {
      throw FormatException('無法比較版本：目前「$current」、最新「$latest」。');
    }
    return b.compareTo(a) > 0;
  }

  void dispose() => _client.close();
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _Version implements Comparable<_Version> {
  const _Version(this.major, this.minor, this.patch, this.prerelease);

  final int major;
  final int minor;
  final int patch;
  final String? prerelease;

  static final _pattern = RegExp(
    r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
  );

  static _Version? parse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;
    return _Version(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      match.group(4),
    );
  }

  @override
  int compareTo(_Version other) {
    final core = major.compareTo(other.major);
    if (core != 0) return core;
    final minorResult = minor.compareTo(other.minor);
    if (minorResult != 0) return minorResult;
    final patchResult = patch.compareTo(other.patch);
    if (patchResult != 0) return patchResult;

    // A stable release is newer than the same version's prerelease.
    if (prerelease == null && other.prerelease == null) return 0;
    if (prerelease == null) return 1;
    if (other.prerelease == null) return -1;
    return _comparePrerelease(prerelease!, other.prerelease!);
  }

  int _comparePrerelease(String a, String b) {
    final aa = a.split('.');
    final bb = b.split('.');
    for (var i = 0; i < aa.length && i < bb.length; i++) {
      final an = int.tryParse(aa[i]);
      final bn = int.tryParse(bb[i]);
      final result = an != null && bn != null
          ? an.compareTo(bn)
          : an != null
              ? -1
              : bn != null
                  ? 1
                  : aa[i].compareTo(bb[i]);
      if (result != 0) return result;
    }
    return aa.length.compareTo(bb.length);
  }
}
