import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gif_loop/core/errors/failure.dart';

Failure mapDioException(DioException exception) => switch (exception.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout => const TimeoutFailure(),
  DioExceptionType.connectionError => const NoConnectionFailure(),
  DioExceptionType.badResponse => mapStatusCode(exception.response?.statusCode),
  DioExceptionType.unknown => _mapUnderlyingError(exception.error),
  DioExceptionType.badCertificate ||
  DioExceptionType.cancel => const UnknownFailure(),
};

Failure mapStatusCode(int? statusCode) => switch (statusCode) {
  401 || 403 => const UnauthorizedFailure(),
  404 => const NotFoundFailure(),
  429 => const RateLimitedFailure(),
  _ => ServerFailure(statusCode),
};

Failure mapMediaError(Object error) => switch (error) {
  HttpExceptionWithStatus(:final statusCode) => mapStatusCode(statusCode),
  SocketException() || HttpException() => const NoConnectionFailure(),
  _ => const DecodingFailure(),
};

Failure _mapUnderlyingError(Object? error) => switch (error) {
  SocketException() => const NoConnectionFailure(),
  FormatException() => const ParsingFailure(),
  _ => const UnknownFailure(),
};
