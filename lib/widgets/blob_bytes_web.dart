// lib/widgets/blob_bytes_web.dart
// A tiny microphone recorder for the browser. It hands the microphone
// straight to the browser's MediaRecorder (m4a on Safari, webm on Chrome),
// with no audio-processing step in between - on iPhone that step stays
// paused and records nothing.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

JSObject? _recorder;
JSObject? _micStream;
final List<JSAny> _chunks = [];
String _mime = '';

/// The type of the last recording, e.g. "audio/mp4".
String get webRecordingMime => _mime.isEmpty ? 'audio/mp4' : _mime;

/// Safari's audio session as it was before recording (see below).
String? _sessionTypeBefore;

/// Safari on iPhone has an "audio session" that the app's sound player sets
/// to playback only, and then the microphone is refused ("AudioSession
/// category is not compatible with audio capture"). Switch it to
/// play-and-record while recording, and back afterwards.
void _setAudioSession(String? type) {
  try {
    final navigator = globalContext['navigator']! as JSObject;
    final session = navigator['audioSession'] as JSObject?;
    if (session == null) return; // not Safari: nothing to do
    if (type == null) {
      final before = _sessionTypeBefore;
      _sessionTypeBefore = null;
      if (before != null) session['type'] = before.toJS;
    } else {
      _sessionTypeBefore ??= (session['type'] as JSString?)?.toDart ?? 'auto';
      session['type'] = type.toJS;
    }
  } catch (_) {}
}

Future<void> webStartRecording() async {
  await webCancelRecording();
  _setAudioSession('play-and-record');
  final navigator = globalContext['navigator']! as JSObject;
  final mediaDevices = navigator['mediaDevices']! as JSObject;
  final constraints = JSObject()..['audio'] = true.toJS;
  final stream = await mediaDevices
      .callMethod<JSPromise<JSObject>>('getUserMedia'.toJS, constraints)
      .toDart;
  _micStream = stream;

  final recorderClass = globalContext['MediaRecorder']! as JSFunction;
  bool supported(String type) => (recorderClass as JSObject)
      .callMethod<JSBoolean>('isTypeSupported'.toJS, type.toJS)
      .toDart;
  _mime = supported('audio/mp4')
      ? 'audio/mp4'
      : supported('audio/webm')
          ? 'audio/webm'
          : '';

  final options = JSObject();
  if (_mime.isNotEmpty) options['mimeType'] = _mime.toJS;
  final recorder = recorderClass.callAsConstructor<JSObject>(stream, options);
  _chunks.clear();
  recorder['ondataavailable'] = ((JSObject event) {
    final data = event['data'];
    if (data != null) _chunks.add(data);
  }).toJS;
  recorder.callMethod<JSAny?>('start'.toJS);
  _recorder = recorder;

  final actual = (recorder['mimeType'] as JSString?)?.toDart ?? '';
  if (actual.isNotEmpty) _mime = actual.split(';').first;
}

/// Stops recording and returns the recorded file, or null if nothing came.
Future<Uint8List?> webStopRecording() async {
  final recorder = _recorder;
  if (recorder == null) return null;
  final done = Completer<void>();
  recorder['onstop'] = (() {
    if (!done.isCompleted) done.complete();
  }).toJS;
  recorder.callMethod<JSAny?>('stop'.toJS);
  await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  _recorder = null;
  _releaseMic();
  if (_chunks.isEmpty) return null;

  final blobClass = globalContext['Blob']! as JSFunction;
  final blobOptions = JSObject()..['type'] = webRecordingMime.toJS;
  final blob = blobClass.callAsConstructor<JSObject>(_chunks.toJS, blobOptions);
  _chunks.clear();
  final buffer = await blob
      .callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS)
      .toDart;
  return buffer.toDart.asUint8List();
}

/// Stops without keeping anything and frees the microphone.
Future<void> webCancelRecording() async {
  final recorder = _recorder;
  _recorder = null;
  if (recorder != null) {
    try {
      recorder.callMethod<JSAny?>('stop'.toJS);
    } catch (_) {}
  }
  _chunks.clear();
  _releaseMic();
}

void _releaseMic() {
  final stream = _micStream;
  _micStream = null;
  if (stream == null) {
    _setAudioSession(null);
    return;
  }
  final tracks = stream.callMethod<JSArray<JSObject>>('getTracks'.toJS).toDart;
  for (final track in tracks) {
    track.callMethod<JSAny?>('stop'.toJS);
  }
  _setAudioSession(null);
}
