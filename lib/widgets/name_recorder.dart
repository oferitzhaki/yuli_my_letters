// lib/widgets/name_recorder.dart
// Records the child's name in a parent's voice (up to 4 seconds).
// Works on Android and in the browser (iPhone/iPad via Safari).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  final AudioRecorder _recorder = AudioRecorder();
  final LetterAudio _audio = LetterAudio();
  Timer? _autoStop;
  bool _recording = false;
  String? _url;
  String? _error;
  AudioEncoder _encoder = AudioEncoder.aacLc;

  @override
  void initState() {
    super.initState();
    _url = widget.existingUrl;
  }

  @override
  void dispose() {
    _autoStop?.cancel();
    _recorder.dispose();
    _audio.dispose();
    super.dispose();
  }

  String get _mime {
    switch (_encoder) {
      case AudioEncoder.opus:
        return 'audio/webm';
      case AudioEncoder.wav:
        return 'audio/wav';
      default:
        return 'audio/mp4';
    }
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _error = 'צריך לאשר גישה למיקרופון');
        return;
      }
      for (final e in [AudioEncoder.aacLc, AudioEncoder.opus, AudioEncoder.wav]) {
        if (await _recorder.isEncoderSupported(e)) {
          _encoder = e;
          break;
        }
      }
      var path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/name_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _recorder.start(
        RecordConfig(encoder: _encoder, numChannels: 1),
        path: path,
      );
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
      final out = await _recorder.stop();
      setState(() => _recording = false);
      if (out == null) return;
      final bytes = await XFile(out).readAsBytes();
      if (bytes.isEmpty) return;
      final recorded = RecordedName(bytes, _mime);
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
