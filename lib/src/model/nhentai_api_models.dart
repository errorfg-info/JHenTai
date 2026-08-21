class NHentaiDownloadLink {
  final String url;
  final int expiresAt;

  const NHentaiDownloadLink({required this.url, required this.expiresAt});

  factory NHentaiDownloadLink.fromJson(Map<String, dynamic> json) {
    return NHentaiDownloadLink(
      url: json['url']?.toString() ?? '',
      expiresAt: _parseInt(json['expires_at']) ?? 0,
    );
  }
}

class NHentaiUserProfile {
  final int id;
  final String username;
  final String slug;
  final String avatarUrl;

  const NHentaiUserProfile({
    required this.id,
    required this.username,
    required this.slug,
    required this.avatarUrl,
  });

  factory NHentaiUserProfile.fromJson(Map<String, dynamic> json) {
    return NHentaiUserProfile(
      id: _parseInt(json['id']) ?? 0,
      username: json['username']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }
}

class NHentaiTagSuggestion {
  final String id;
  final int galleryId;
  final int tagId;
  final String namespace;
  final String tagName;
  final String action;
  final String status;
  final int? score;
  final int voterCount;
  final String proposer;
  final DateTime? createdAt;
  final String? tier;

  const NHentaiTagSuggestion({
    required this.id,
    required this.galleryId,
    required this.tagId,
    required this.namespace,
    required this.tagName,
    required this.action,
    required this.status,
    required this.score,
    required this.voterCount,
    required this.proposer,
    required this.createdAt,
    required this.tier,
  });

  factory NHentaiTagSuggestion.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> tag =
        ((json['tag'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> proposer =
        ((json['proposer'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();

    return NHentaiTagSuggestion(
      id: json['id']?.toString() ?? '',
      galleryId: _parseInt(json['gallery_id']) ?? 0,
      tagId: _parseInt(tag['id']) ?? 0,
      namespace: tag['type']?.toString() ?? 'tag',
      tagName: tag['name']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      score: _parseInt(json['score']),
      voterCount: _parseInt(json['voter_count']) ?? 0,
      proposer: proposer['username']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      tier: json['tier']?.toString(),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}
