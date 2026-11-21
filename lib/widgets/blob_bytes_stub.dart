// lib/widgets/blob_bytes_stub.dart
// Outside the browser the record package is used (see name_recorder.dart),
// so these are never called.

import 'dart:typed_data';

String get webRecordingMime => 'audio/mp4';

Future<void> webStartRecording() async =>
    throw UnsupportedError('Browser only');

Future<Uint8List?> webStopRecording() async => null;

Future<void> webCancelRecording() async {}
