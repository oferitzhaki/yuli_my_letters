// lib/widgets/name_recorder.dart
// Records the child's name in a parent's voice (up to 4 seconds).
// On Android the microphone audio is collected straight into memory and
// turned into a small WAV file. In the browser (iPhone/iPad via Safari)
// the browser's own recorder is used instead (m4a on Safari, webm on
// Chrome), because Safari can hang on the live-audio route.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/letter_audio.dart';
import '../services/profile_service.dart';
import 'blob_bytes_stub.dart' if (dart.library.js_interop) 'blob_bytes_web.dart';

class RecordedName {
  RecordedName(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;
  String get dataUrl => 'data:$mime;base64,${base64Encode(bytes)}';
}

class NameRecorder extends StatefulWidget {
  const NameRecorder({
    super.key,
    required this.existingUrl,
    required this.onRecorded,
    required this.onRemoved,
  });

  /// A recording that is already saved (when editing), or null.
  final String? existingUrl;
  final ValueChanged<RecordedName> onRecorded;
  final VoidCallback onRemoved;

  @override
  State<NameRecorder> createState() => _NameRecorderState();
}

class _NameRecorderState extends State<NameRecorder> {
  static const maxLength = Duration(seconds: 4);
  static const int _sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();
  final LetterAudio _audio = LetterAudio();
  StreamSubscription<Uint8List>? _stream;
  final List<int> _pcm = [];
  Timer? _autoStop;
  bool _starting = false;
  bool _recording = false;
  String _webMime = 'audio/mp4';
  String? _url;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = widget.existingUrl;
  }

  @override
  void dispose() {
    _autoStop?.cancel();
    _stream?.cancel();
    _recorder.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _recording) return;
    setState(() {
      _error = null;
      _starting = true;
    });
    try {
      // In the browser start() asks for the microphone itself; asking twice
      // in a row can leave Safari on iPhone stuck.
      if (!kIsWeb && !await _recorder.hasPermission()) {
        setState(() => _error =
            tr('צריך לאשר גישה למיקרופון', 'Please allow microphone access'));
        return;
      }
      if (kIsWeb) {
        await _startWeb().timeout(const Duration(seconds: 20));
      } else {
        await _startStream().timeout(const Duration(seconds: 6));
      }
      if (!mounted) return;
      setState(() => _recording = true);
      _autoStop = Timer(maxLength, _stop);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = '${tr('ההקלטה לא הצליחה', 'Recording failed')}\n($e)');
      }
      debugPrint('Record start failed: $e');
      try {
        await _recorder.cancel();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Browser: the built-in recorder. Safari makes m4a (AAC), Chrome webm.
  Future<void> _startWeb() async {
    var encoder = AudioEncoder.aacLc;
    _webMime = 'audio/mp4';
    if (!await _recorder.isEncoderSupported(encoder)) {
      encoder = AudioEncoder.opus;
      _webMime = 'audio/webm';
    }
    await _recorder.start(
      RecordConfig(encoder: encoder, numChannels: 1),
      path: '',
    );
  }

  /// Android: raw samples into memory, wrapped as WAV when done.
  Future<void> _startStream() async {
    if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
      throw 'pcm16bits not supported';
    }
    _pcm.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ),
    );
    _stream = stream.listen(_pcm.addAll);
  }

  Future<void> _stop() async {
    _autoStop?.cancel();
    if (!_recording) return;
    try {
      final blobUrl = await _recorder.stop();
      await _stream?.cancel();
      _stream = null;
      setState(() => _recording = false);

      final RecordedName recorded;
      if (kIsWeb) {
        final bytes = blobUrl == null ? null : await readBlobUrl(blobUrl);
        // A few hundred bytes = nothing was really recorded.
        if (bytes == null || bytes.length < 1000) {
          setState(() => _error =
              tr('ההקלטה קצרה מדי, נסו שוב', 'Too short, please try again'));
          return;
        }
        recorded = RecordedName(bytes, _webMime);
      } else {
        // Less than a quarter of a second = nothing was really said.
        if (_pcm.length < _sampleRate ~/ 2) {
          setState(() => _error =
              tr('ההקלטה קצרה מדי, נסו שוב', 'Too short, please try again'));
          return;
        }
        recorded = RecordedName(_toWav(_pcm), 'audio/wav');
      }
      setState(() => _url = recorded.dataUrl);
      widget.onRecorded(recorded);
      _audio.playUrl(recorded.dataUrl);
    } catch (e) {
      setState(() {
        _recording = false;
        _error = '${tr('ההקלטה לא הצליחה', 'Recording failed')}\n($e)';
      });
      debugPrint('Record stop failed: $e');
    }
  }

  /// Wraps raw 16-bit mono samples in a standard WAV header.
  Uint8List _toWav(List<int> pcm) {
    final header = ByteData(44);
    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // format chunk size
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, _sampleRate * 2, Endian.little); // bytes per second
    header.setUint16(32, 2, Endian.little); // bytes per sample
    header.setUint16(34, 16, Endian.little); // bits per sample
    text(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);

    final out = Uint8List(44 + pcm.length);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, out.length, pcm);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('🎙️ הקלטת השם (לא חובה)',
                "🎙️ Record the child's name (optional)"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            tr('לוחצים, אומרים את השם בקול, ולוחצים שוב. האפליקציה תשמיע את השם הזה במשובים.',
                'Tap, say the name out loud, and tap again. The app will use it when praising.'),
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _starting ? null : (_recording ? _stop : _start),
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(
                  _starting
                      ? tr('רגע...', 'One moment...')
                      : _recording
                      ? tr('עצירה', 'Stop')
                      : _url == null
                          ? tr('הקלטה', 'Record')
                          : tr('הקלטה מחדש', 'Record again'),
                  style: const TextStyle(fontSize: 17),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _recording ? Colors.red : Colors.deepOrange,
                ),
              ),
              if (_url != null && !_recording) ...[
                OutlinedButton.icon(
                  onPressed: () => _audio.playUrl(_url!),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr('השמעה', 'Play'),
                      style: const TextStyle(fontSize: 17)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _url = null);
                    widget.onRemoved();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(tr('מחיקה', 'Delete'),
                      style: const TextStyle(fontSize: 17)),
                ),
              ],
            ],
          ),
          if (_recording)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                tr('🔴 מקליט... אמרו את השם עכשיו',
                    '🔴 Recording... say the name now'),
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
