// lib/widgets/blob_bytes_stub.dart
// Outside the browser there are no "blob:" addresses (see blob_bytes_web.dart).

import 'dart:typed_data';

Future<Uint8List?> readBlobUrl(String url) async => null;
