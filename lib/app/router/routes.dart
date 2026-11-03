abstract final class Routes {
  static const String feed = '/';
  static const String library = '/library';
  static const String librarySegmentParam = 'segment';
  static const String gifIdParam = 'id';
  static const String gifDetailsPattern = '/gif/:$gifIdParam';
  static const String remixEditorPattern = '/gif/:$gifIdParam/remix';
  static const String remixIdParam = 'remixId';
  static const String remixPattern = '/remix/:$remixIdParam';

  static String gifDetails(String id) => '/gif/${Uri.encodeComponent(id)}';

  static String remixEditor(String gifId) => '${gifDetails(gifId)}/remix';

  static String remix(String id) => '/remix/${Uri.encodeComponent(id)}';

  static String librarySegment(String segment) => Uri(
    path: library,
    queryParameters: {librarySegmentParam: segment},
  ).toString();
}
