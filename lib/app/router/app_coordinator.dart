import 'package:gif_loop/features/gifs/domain/gif.dart';

abstract interface class AppCoordinator {
  void showGifDetails(Gif gif);

  void showGifDetailsById(String id);

  void showGame();

  void showFeed();

  void back();
}
