import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_mapper.dart';

void main() {
  final requestOptions = RequestOptions(path: 'gifs/trending');

  DioException exceptionOf(DioExceptionType type, {Object? error}) =>
      DioException(requestOptions: requestOptions, type: type, error: error);

  DioException responseWith(int statusCode) => DioException.badResponse(
    statusCode: statusCode,
    requestOptions: requestOptions,
    response: Response<void>(
      requestOptions: requestOptions,
      statusCode: statusCode,
    ),
  );

  group('mapDioException', () {
    test('maps every timeout to TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(mapDioException(exceptionOf(type)), const TimeoutFailure());
      }
    });

    test('maps a connection error to NoConnectionFailure', () {
      expect(
        mapDioException(exceptionOf(DioExceptionType.connectionError)),
        const NoConnectionFailure(),
      );
    });

    test('maps an unknown SocketException to NoConnectionFailure', () {
      expect(
        mapDioException(
          exceptionOf(
            DioExceptionType.unknown,
            error: const SocketException('Failed host lookup'),
          ),
        ),
        const NoConnectionFailure(),
      );
    });

    test('maps malformed JSON to ParsingFailure', () {
      expect(
        mapDioException(
          exceptionOf(
            DioExceptionType.unknown,
            error: const FormatException('Unexpected character'),
          ),
        ),
        const ParsingFailure(),
      );
    });

    test('maps status codes', () {
      expect(mapDioException(responseWith(401)), const UnauthorizedFailure());
      expect(mapDioException(responseWith(403)), const UnauthorizedFailure());
      expect(mapDioException(responseWith(404)), const NotFoundFailure());
      expect(mapDioException(responseWith(429)), const RateLimitedFailure());
      expect(mapDioException(responseWith(500)), const ServerFailure(500));
    });

    test('maps anything else to UnknownFailure', () {
      expect(
        mapDioException(exceptionOf(DioExceptionType.cancel)),
        const UnknownFailure(),
      );
    });
  });

  group('mapMediaError', () {
    test('maps HTTP errors by status code', () {
      expect(
        mapMediaError(const HttpExceptionWithStatus(429, 'Too many requests')),
        const RateLimitedFailure(),
      );
    });

    test('maps socket errors to NoConnectionFailure', () {
      expect(
        mapMediaError(const SocketException('offline')),
        const NoConnectionFailure(),
      );
    });

    test('maps other errors to DecodingFailure', () {
      expect(
        mapMediaError(Exception('Invalid image data')),
        const DecodingFailure(),
      );
    });
  });

  group('Failure.isTransient', () {
    test('is true only for connection and timeout failures', () {
      expect(const NoConnectionFailure().isTransient, isTrue);
      expect(const TimeoutFailure().isTransient, isTrue);
      expect(const RateLimitedFailure().isTransient, isFalse);
      expect(const ServerFailure(500).isTransient, isFalse);
    });
  });
}
