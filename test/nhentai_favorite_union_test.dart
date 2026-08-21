import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jhentai/src/model/gallery.dart';
import 'package:jhentai/src/model/gallery_count.dart';
import 'package:jhentai/src/model/gallery_image.dart';
import 'package:jhentai/src/model/gallery_page.dart';
import 'package:jhentai/src/model/gallery_tag.dart';
import 'package:jhentai/src/model/gallery_url.dart';
import 'package:jhentai/src/service/nhentai_favorite_service.dart';

void main() {
  test('native empty page cannot hide synced nhentai favorites', () {
    final NHentaiFavoriteService service = NHentaiFavoriteService();
    service.applyBeanConfig(
      jsonEncode(<Map<String, dynamic>>[
        _favoriteEntry(_gallery(101, title: 'Synced favorite')),
      ]),
    );
    final String storedBeforeMerge = service.toConfigString();

    final GalleryPageInfo merged = service.mergeRemoteFavoritePage(
      remotePage: GalleryPageInfo(gallerys: const <Gallery>[]),
      includeLocalFavorites: true,
    );

    expect(merged.gallerys.map((Gallery gallery) => gallery.gid), <int>[101]);
    expect(merged.gallerys.single.title, 'Synced favorite');
    expect(service.toConfigString(), storedBeforeMerge);
  });

  test('native and synced favorites form a de-duplicated paged union', () {
    final NHentaiFavoriteService service = NHentaiFavoriteService();
    service.applyBeanConfig(
      jsonEncode(<Map<String, dynamic>>[
        _favoriteEntry(_gallery(101, title: 'Local 101')),
        _favoriteEntry(_gallery(202, title: 'Local 202')),
      ]),
    );

    final GalleryPageInfo firstPage = service.mergeRemoteFavoritePage(
      remotePage: GalleryPageInfo(
        gallerys: <Gallery>[
          _gallery(202, title: 'Remote duplicate'),
          _gallery(303, title: 'Remote 303'),
        ],
        totalCount: const GalleryCount(
          type: GalleryCountType.accurate,
          count: '2',
        ),
        nextGid: '2',
      ),
      includeLocalFavorites: true,
    );

    expect(firstPage.gallerys.map((Gallery gallery) => gallery.gid), <int>[
      101,
      202,
      303,
    ]);
    expect(
      firstPage.gallerys
          .singleWhere((Gallery gallery) => gallery.gid == 202)
          .title,
      'Local 202',
    );
    expect(firstPage.nextGid, '2');
    expect(firstPage.totalCount, isNull);

    final GalleryPageInfo nextPage = service.mergeRemoteFavoritePage(
      remotePage: GalleryPageInfo(
        gallerys: <Gallery>[
          _gallery(101, title: 'Later remote duplicate'),
          _gallery(404, title: 'Remote 404'),
        ],
      ),
      includeLocalFavorites: false,
    );

    expect(nextPage.gallerys.map((Gallery gallery) => gallery.gid), <int>[404]);
  });
}

Map<String, dynamic> _favoriteEntry(Gallery gallery) => <String, dynamic>{
  'gallery': gallery.toJson(),
  'favoritedTime': '2026-08-20T10:00:00.000Z',
  'favoriteCategoryIndex': 2,
};

Gallery _gallery(int gid, {required String title}) => Gallery(
  galleryUrl: GalleryUrl(
    isEH: true,
    isNH: true,
    gid: gid,
    token: 'nhentai',
    sourceHost: 'nhentai.net',
  ),
  title: title,
  category: 'manga',
  cover: GalleryImage(url: 'https://example.test/cover.jpg'),
  pageCount: 20,
  rating: 0,
  hasRated: false,
  language: 'english',
  uploader: 'fixture',
  publishTime: '2026-08-19 10:00',
  isExpunged: false,
  tags: LinkedHashMap<String, List<GalleryTag>>(),
);
