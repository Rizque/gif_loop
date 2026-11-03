import 'package:flutter/material.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/strings.dart';

extension FailurePresentation on Failure {
  String get title => switch (this) {
    NoConnectionFailure() => Strings.noConnectionTitle,
    TimeoutFailure() => Strings.timeoutTitle,
    RateLimitedFailure() => Strings.rateLimitedTitle,
    UnauthorizedFailure() => Strings.unauthorizedTitle,
    NotFoundFailure() => Strings.notFoundTitle,
    ServerFailure() => Strings.serverTitle,
    ParsingFailure() => Strings.parsingTitle,
    DecodingFailure() => Strings.decodingTitle,
    StorageFailure() => Strings.storageTitle,
    UnknownFailure() => Strings.unknownTitle,
  };

  String get message => switch (this) {
    NoConnectionFailure() => Strings.noConnectionMessage,
    TimeoutFailure() => Strings.timeoutMessage,
    RateLimitedFailure() => Strings.rateLimitedMessage,
    UnauthorizedFailure() => Strings.unauthorizedMessage,
    NotFoundFailure() => Strings.notFoundMessage,
    ServerFailure() => Strings.serverMessage,
    ParsingFailure() => Strings.parsingMessage,
    DecodingFailure() => Strings.decodingMessage,
    StorageFailure() => Strings.storageMessage,
    UnknownFailure() => Strings.unknownMessage,
  };

  IconData get icon => switch (this) {
    NoConnectionFailure() => Icons.wifi_off_rounded,
    TimeoutFailure() => Icons.hourglass_empty_rounded,
    RateLimitedFailure() => Icons.speed_rounded,
    UnauthorizedFailure() => Icons.key_off_rounded,
    NotFoundFailure() => Icons.search_off_rounded,
    ServerFailure() => Icons.cloud_off_rounded,
    ParsingFailure() => Icons.data_object_rounded,
    DecodingFailure() => Icons.broken_image_rounded,
    StorageFailure() => Icons.sd_card_alert_rounded,
    UnknownFailure() => Icons.error_outline_rounded,
  };
}
