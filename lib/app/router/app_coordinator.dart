import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/library_segment.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';

abstract interface class AppCoordinator {
  void showGifDetails(Gif gif);

  void showGifDetailsById(String id);

  void showFeed();

  void showLibrary({LibrarySegment? segment});

  void showRemixEditor(Gif gif, StudioSettings initial);

  void showRemix(Remix remix);

  void back();
}
