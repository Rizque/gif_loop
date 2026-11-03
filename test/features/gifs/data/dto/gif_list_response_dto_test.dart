import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/gifs/data/dto/gif_dto.dart';
import 'package:gif_loop/features/gifs/data/dto/gif_list_response_dto.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';
import 'package:gif_loop/features/gifs/domain/gif_user.dart';

import '../../../../helpers/fixture.dart';

void main() {
  group('GifListResponseDto', () {
    test('parses pagination and meta', () {
      final response = GifListResponseDto.fromJson(
        fixture('trending_page.json'),
      );

      expect(response.data, hasLength(2));
      expect(response.offset, 0);
      expect(response.count, 2);
      expect(response.totalCount, 120);
      expect(response.status, 200);
      expect(response.isSynthetic, isFalse);
    });

    test('parses pagination numbers sent as strings', () {
      final response = GifListResponseDto.fromJson(
        fixture('malformed_items_page.json'),
      );

      expect(response.offset, 0);
      expect(response.count, 4);
      expect(response.totalCount, 4);
    });

    test('skips data entries that are not objects', () {
      final response = GifListResponseDto.fromJson(
        fixture('malformed_items_page.json'),
      );

      expect(response.data, hasLength(3));
    });

    test('detects the documented synthetic response', () {
      final response = GifListResponseDto.fromJson(
        fixture('synthetic_response.json'),
      );

      expect(response.isSynthetic, isTrue);
    });

    test('throws FormatException when data is not a list', () {
      expect(
        () => GifListResponseDto.fromJson(const {'data': 'nope'}),
        throwsFormatException,
      );
    });
  });

  group('GifDto.toDomain', () {
    List<Map<String, dynamic>> items(String name) =>
        (fixture(name)['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();

    test('maps a complete GIF', () {
      final gif = GifDto.fromJson(items('trending_page.json').first).toDomain();

      expect(gif, isNotNull);
      expect(gif!.id, '3o7TKSjRrfIPjeiVyM');
      expect(gif.title, 'Cat Typing GIF by Cats');
      expect(gif.url, 'https://giphy.com/gifs/cat-funny-3o7TKSjRrfIPjeiVyM');
      expect(gif.shareUrl, 'https://gph.is/2fYMfXl');
      expect(gif.rating, 'g');
      expect(gif.importDateTime, DateTime(2016, 10, 24, 18, 31, 22));
      expect(
        gif.user,
        const GifUser(
          username: 'catsofinstagram',
          displayName: 'Cats of Instagram',
          avatarUrl: 'https://media.giphy.com/avatars/cats/avatar.gif',
        ),
      );
      expect(gif.authorName, 'Cats of Instagram');
      expect(
        gif.preview,
        const GifRendition(
          url: 'https://media.giphy.com/media/3o7TKSjRrfIPjeiVyM/200w.webp',
          width: 200,
          height: 150,
          sizeBytes: 152039,
        ),
      );
      expect(gif.full.url, endsWith('giphy.gif'));
      expect(gif.full.width, 480);
      expect(gif.full.sizeBytes, 1734322);
    });

    test('falls back when optional fields are missing or empty', () {
      final gif = GifDto.fromJson(items('trending_page.json')[1]).toDomain()!;

      expect(gif.title, Strings.untitled);
      expect(gif.user, isNull);
      expect(gif.authorName, isNull);
      expect(gif.shareUrl, gif.url);
      expect(gif.importDateTime, isNull);
      expect(gif.preview.url, endsWith('200w.gif'));
      expect(gif.full.url, endsWith('giphy.gif'));
      expect(gif.full.frameCount, 60);
    });

    test('uses original as preview when fixed_width is null', () {
      final gif = GifDto.fromJson(items('malformed_items_page.json').last)
          .toDomain()!;

      expect(gif.preview, gif.full);
      expect(gif.full.width, 320);
      expect(gif.full.height, 0);
      expect(gif.full.aspectRatio, 1);
    });

    test('returns null without an id or without any rendition', () {
      final malformed = items('malformed_items_page.json');

      expect(GifDto.fromJson(malformed[0]).toDomain(), isNull);
      expect(GifDto.fromJson(malformed[1]).toDomain(), isNull);
    });

    test('builds a page url from the id when url is missing', () {
      final gif = GifDto.fromJson(const {
        'id': 'abc',
        'images': {
          'original': {'url': 'https://media.giphy.com/media/abc/giphy.gif'},
        },
      }).toDomain()!;

      expect(gif.url, 'https://giphy.com/gifs/abc');
      expect(gif.shareUrl, gif.url);
    });
  });
}
