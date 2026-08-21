import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jhentai/src/network/nhentai_api_support.dart';
import 'package:jhentai/src/model/nhentai_api_models.dart';
import 'package:jhentai/src/setting/eh_setting.dart';
import 'package:jhentai/src/setting/nhentai_api_setting.dart';

void main() {
  group('nhentai API headers', () {
    test('sends API keys only to the official host', () {
      expect(
        NHentaiApiSupport.requestHeaders(
          host: 'www.nhentai.net',
          userAgent: 'JHenTai/test',
          apiKey: '  nhk_test  ',
        ),
        <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'JHenTai/test',
          'Authorization': 'Key nhk_test',
        },
      );

      expect(
        NHentaiApiSupport.requestHeaders(
          host: 'mirror.example',
          userAgent: 'JHenTai/test',
          apiKey: 'nhk_test',
        ),
        <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'JHenTai/test',
        },
      );
    });

    test('keeps legacy 429 fallback only when no API key is configured', () {
      expect(
        NHentaiApiSupport.shouldFallbackResponse(
          statusCode: 429,
          apiKeyConfigured: false,
        ),
        isTrue,
      );
      expect(
        NHentaiApiSupport.shouldFallbackResponse(
          statusCode: 429,
          apiKeyConfigured: true,
        ),
        isFalse,
      );
      expect(
        NHentaiApiSupport.shouldFallbackResponse(
          statusCode: 503,
          apiKeyConfigured: true,
        ),
        isTrue,
      );
    });
  });

  group('nhentai CDN config', () {
    final NHentaiCdnConfig config = NHentaiCdnConfig.fromJson(<String, dynamic>{
      'image_servers': <String>[
        'https://i1.nhentai.net',
        'https://i2.nhentai.net/',
      ],
      'thumb_servers': <String>[
        'https://t1.nhentai.net',
        'https://t2.nhentai.net/',
      ],
    });

    test('keeps API paths exact when selecting a server', () {
      final String image = config.resolveImagePath('galleries/4129494/2.webp');
      final String thumbnail = config.resolveThumbnailPath(
        'galleries/4129494/2t.webp.webp',
      );

      expect(
        image,
        anyOf(
          'https://i1.nhentai.net/galleries/4129494/2.webp',
          'https://i2.nhentai.net/galleries/4129494/2.webp',
        ),
      );
      expect(
        thumbnail,
        anyOf(
          'https://t1.nhentai.net/galleries/4129494/2t.webp.webp',
          'https://t2.nhentai.net/galleries/4129494/2t.webp.webp',
        ),
      );
    });

    test('leaves absolute URLs unchanged', () {
      expect(
        config.resolveImagePath('https://cdn.example/image.webp'),
        'https://cdn.example/image.webp',
      );
    });

    test('rotates to another server after a retry', () {
      final String first = config.resolveImagePath('galleries/4129494/2.webp');
      final String retry = config.resolveImagePath(
        'galleries/4129494/2.webp',
        serverOffset: 1,
      );

      expect(first, isNot(retry));
      expect(Uri.parse(first).path, Uri.parse(retry).path);
    });

    test('rejects unusable server lists', () {
      expect(
        () => NHentaiCdnConfig.fromJson(<String, dynamic>{
          'image_servers': <String>[],
          'thumb_servers': <String>['https://t1.nhentai.net'],
        }),
        throwsFormatException,
      );
    });
  });

  test('parses nhentai tag suggestions defensively', () {
    final NHentaiTagSuggestion suggestion = NHentaiTagSuggestion.fromJson(
      <String, dynamic>{
        'id': '9fd4c7d1-test',
        'gallery_id': 123,
        'tag': <String, dynamic>{
          'id': 456,
          'type': 'language',
          'name': 'english',
        },
        'action': 'add',
        'status': 'pending',
        'score': 3,
        'voter_count': 5,
        'proposer': <String, dynamic>{'username': 'fixture'},
        'created_at': '2026-08-21T10:00:00Z',
        'tier': 'trending',
      },
    );

    expect(suggestion.galleryId, 123);
    expect(suggestion.tagId, 456);
    expect(suggestion.namespace, 'language');
    expect(suggestion.tagName, 'english');
    expect(suggestion.voterCount, 5);
    expect(suggestion.createdAt?.isUtc, isTrue);
  });

  test('nhentai API key survives its dedicated setting round trip', () {
    final NHentaiApiSetting setting = NHentaiApiSetting();
    setting.applyBeanConfig(
      jsonEncode(<String, dynamic>{'apiKey': 'nhk_fixture'}),
    );

    expect(setting.apiKey.value, 'nhk_fixture');
    final Map<String, dynamic> stored =
        jsonDecode(setting.toConfigString()) as Map<String, dynamic>;
    expect(stored, <String, dynamic>{'apiKey': 'nhk_fixture'});
  });

  test('legacy EH settings expose the key for one-time migration only', () {
    final EHSetting legacy = EHSetting();
    legacy.applyBeanConfig(
      jsonEncode(<String, dynamic>{
        'site': 'EH',
        'nhentaiApiKey': 'nhk_legacy_fixture',
      }),
    );

    expect(legacy.legacyNhentaiApiKey, 'nhk_legacy_fixture');
    expect(
      (jsonDecode(legacy.toConfigString()) as Map<String, dynamic>).containsKey(
        'nhentaiApiKey',
      ),
      isFalse,
    );
  });
}
