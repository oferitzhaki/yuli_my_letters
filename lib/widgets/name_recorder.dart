// lib/widgets/name_recorder.dart
// Records the child's name in a parent's voice (up to 4 seconds).
// The microphone audio is collected straight into memory and turned into
// a small WAV file, so it works the same on Android and in the browser
// (iPhone/iPad via Safari) without temporary files.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/letter_audio.dart';

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
  bool _recording = false;
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
    setState(() => _error = null);
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _error = 'צריך לאשר גישה למיקרופון');
        return;
      }
      if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
        setState(() => _error = 'המכשיר לא תומך בהקלטה');
        return;
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
      setState(() => _recording = true);
      _autoStop = Timer(maxLength, _stop);
    } catch (e) {
      setState(() => _error = 'ההקלטה לא הצליחה');
      debugPrint('Record start failed: $e');
    }
  }

  Future<void> _stop() async {
    _autoStop?.cancel();
    if (!_recording) return;
    try {
      await _recorder.stop();
      await _stream?.cancel();
      _stream = null;
      setState(() => _recording = false);

      // Less than a quarter of a second = nothing was really said.
      if (_pcm.length < _sampleRate ~/ 2) {
        setState(() => _error = 'ההקלטה קצרה מדי, נסו שוב');
        return;
      }
      final recorded = RecordedName(_toWav(_pcm), 'audio/wav');
      setState(() => _url = recorded.dataUrl);
      widget.onRecorded(recorded);
      _audio.playUrl(recorded.dataUrl);
    } catch (e) {
      setState(() {
        _recording = false;
        _error = 'ההקלטה לא הצליחה';
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
          const Text(
            '🎙️ הקלטת השם (לא חובה)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'לוחצים, אומרים את השם בקול, ולוחצים שוב. '
            'האפליקציה תשמיע את השם הזה במשובים.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _recording ? _stop : _start,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(
                  _recording
                      ? 'עצירה'
                      : _url == null
                          ? 'הקלטה'
                          : 'הקלטה מחדש',
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
                  label: const Text('השמעה', style: TextStyle(fontSize: 17)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _url = null);
                    widget.onRemoved();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('מחיקה', style: TextStyle(fontSize: 17)),
                ),
              ],
            ],
          ),
          if (_recording)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '🔴 מקליט... אמרו את השם עכשיו',
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
