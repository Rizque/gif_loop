import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';

class RemixEditorArgs {
  const new({required this.gif, required this.initialSettings});

  final Gif gif;
  final StudioSettings initialSettings;
}
