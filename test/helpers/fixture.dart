import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

// One 20×10 frame of solid (30, 120, 220) with a zero delay: the same shape as
// GIPHY's single-frame GIFs. The engine decodes these with SingleFrameCodec,
// which reads the ImageDescriptor lazily on getNextFrame.
Uint8List singleFrameGif() =>
    File('test/fixtures/single_frame.gif').readAsBytesSync();
