const int _kilobyte = 1024;
const int _megabyte = _kilobyte * 1024;

String formatByteSize(int bytes) => switch (bytes) {
  >= _megabyte => '${(bytes / _megabyte).toStringAsFixed(1)} MB',
  >= _kilobyte => '${(bytes / _kilobyte).toStringAsFixed(0)} KB',
  _ => '$bytes B',
};
