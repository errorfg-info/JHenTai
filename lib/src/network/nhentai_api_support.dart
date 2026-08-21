class NHentaiApiSupport {
  static const String officialHost = 'nhentai.net';

  static Map<String, String> requestHeaders({
    required String host,
    required String userAgent,
    String? apiKey,
  }) {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': userAgent,
    };

    final String normalizedHost = _normalizeHost(host);
    final String normalizedApiKey = apiKey?.trim() ?? '';
    if (normalizedHost == officialHost && normalizedApiKey.isNotEmpty) {
      headers['Authorization'] = 'Key $normalizedApiKey';
    }

    return headers;
  }

  static bool isOfficialHost(String host) =>
      _normalizeHost(host) == officialHost;

  static bool shouldFallbackResponse({
    required int? statusCode,
    required bool apiKeyConfigured,
  }) {
    return statusCode == 404 ||
        statusCode == 403 ||
        (statusCode == 429 && !apiKeyConfigured) ||
        (statusCode != null && statusCode >= 500);
  }

  static String _normalizeHost(String host) {
    String normalized = host.trim().toLowerCase();
    if (normalized.startsWith('www.')) {
      normalized = normalized.substring(4);
    }
    return normalized;
  }
}

class NHentaiCdnConfig {
  final List<String> imageServers;
  final List<String> thumbnailServers;

  const NHentaiCdnConfig({
    required this.imageServers,
    required this.thumbnailServers,
  });

  factory NHentaiCdnConfig.fromJson(Map<String, dynamic> json) {
    return NHentaiCdnConfig(
      imageServers: _parseServers(json['image_servers'], 'image_servers'),
      thumbnailServers: _parseServers(json['thumb_servers'], 'thumb_servers'),
    );
  }

  String resolveImagePath(String path, {int serverOffset = 0}) =>
      _resolve(imageServers, path, serverOffset: serverOffset);

  String resolveThumbnailPath(String path, {int serverOffset = 0}) =>
      _resolve(thumbnailServers, path, serverOffset: serverOffset);

  static List<String> _parseServers(dynamic raw, String fieldName) {
    if (raw is! List) {
      throw FormatException('Missing nhentai CDN field: $fieldName');
    }

    final List<String> servers = raw
        .whereType<String>()
        .map((String value) => value.trim())
        .where((String value) {
          final Uri? uri = Uri.tryParse(value);
          return uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty;
        })
        .map((String value) => value.replaceFirst(RegExp(r'/+$'), ''))
        .toList(growable: false);

    if (servers.isEmpty) {
      throw FormatException('No usable nhentai CDN servers in $fieldName');
    }
    return servers;
  }

  static String _resolve(
    List<String> servers,
    String path, {
    required int serverOffset,
  }) {
    final String normalizedPath = path.trim();
    if (normalizedPath.startsWith('https://') ||
        normalizedPath.startsWith('http://')) {
      return normalizedPath;
    }
    if (normalizedPath.startsWith('//')) {
      return 'https:$normalizedPath';
    }
    if (normalizedPath.isEmpty) {
      throw const FormatException('Empty nhentai CDN path');
    }

    final String relativePath = normalizedPath.startsWith('/')
        ? normalizedPath.substring(1)
        : normalizedPath;
    final int serverIndex =
        (_stableIndex(relativePath, servers.length) + serverOffset) %
        servers.length;
    return '${servers[serverIndex]}/$relativePath';
  }

  static int _stableIndex(String value, int length) {
    int hash = 0;
    for (final int codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash % length;
  }
}
