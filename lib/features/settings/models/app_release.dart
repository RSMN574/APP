class AppRelease {
  const AppRelease({
    required this.version,
    required this.tagName,
    required this.releaseUrl,
    required this.notes,
    required this.isPrerelease,
  });

  final String version;
  final String tagName;
  final Uri releaseUrl;
  final String notes;
  final bool isPrerelease;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final tag = (json['tag_name'] as String?)?.trim() ?? '';
    final versionFromName = name.replaceFirst(RegExp(r'^[vV]'), '');
    final versionFromTag = tag.replaceFirst(RegExp(r'^[vV]'), '');

    final version = _looksLikeVersion(versionFromName)
        ? versionFromName
        : versionFromTag;

    final urlText = json['html_url'] as String?;
    final url = Uri.tryParse(urlText ?? '');
    if (version.isEmpty || url == null || !url.hasScheme) {
      throw const FormatException('GitHub Release 欄位不完整或版本格式不正確。');
    }

    return AppRelease(
      version: version,
      tagName: tag,
      releaseUrl: url,
      notes: (json['body'] as String?)?.trim() ?? '',
      isPrerelease: json['prerelease'] == true,
    );
  }

  static bool _looksLikeVersion(String value) =>
      RegExp(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$').hasMatch(value);
}
