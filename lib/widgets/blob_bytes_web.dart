// lib/widgets/blob_bytes_web.dart
// In the browser a finished recording is a "blob:" address. This reads the
// bytes behind it so the recording can be saved with the child's profile.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('fetch')
external JSPromise<JSObject> _fetch(JSString url);

Future<Uint8List?> readBlobUrl(String url) async {
  final response = await _fetch(url.toJS).toDart;
  final buffer = await response
      .callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS)
      .toDart;
  return buffer.toDart.asUint8List();
}
