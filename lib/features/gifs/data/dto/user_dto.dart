import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif_user.dart';

class UserDto {
  const new({this.username, this.displayName, this.avatarUrl});

  factory fromJson(Map<String, dynamic> json) => UserDto(
    username: readString(json['username']),
    displayName: readString(json['display_name']),
    avatarUrl: readString(json['avatar_url']),
  );

  final String? username;
  final String? displayName;
  final String? avatarUrl;

  GifUser? toDomain() {
    final name = displayName ?? username;
    if (name == null) return null;
    return GifUser(
      username: username ?? '',
      displayName: name,
      avatarUrl: avatarUrl,
    );
  }
}
