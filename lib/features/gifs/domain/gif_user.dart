import 'package:equatable/equatable.dart';

class GifUser extends Equatable {
  const new({
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  final String username;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [username, displayName, avatarUrl];
}
