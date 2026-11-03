import 'package:gif_loop/features/gifs/domain/gif.dart';

abstract interface class AppCoordinator {
  void showGifDetails(Gif gif);

  void showGifDetailsById(String id);

  void showFeed();

  void showLibrary();

  void back();
}
