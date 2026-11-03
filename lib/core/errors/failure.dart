import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const new();

  bool get isTransient => false;

  @override
  List<Object?> get props => [];
}

final class NoConnectionFailure extends Failure {
  const new();

  @override
  bool get isTransient => true;
}

final class TimeoutFailure extends Failure {
  const new();

  @override
  bool get isTransient => true;
}

final class RateLimitedFailure extends Failure {
  const new();
}

final class UnauthorizedFailure extends Failure {
  const new();
}

final class NotFoundFailure extends Failure {
  const new();
}

final class ServerFailure extends Failure {
  const new(this.statusCode);

  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

final class ParsingFailure extends Failure {
  const new();
}

final class DecodingFailure extends Failure {
  const new();
}

final class StorageFailure extends Failure {
  const new();
}

final class UnknownFailure extends Failure {
  const new();
}
