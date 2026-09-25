// lib/screens/register_screen.dart
// Add a child (or edit one): name, girl/boy, recorded name.
// Written for the parent, so the wording is neutral.

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../widgets/name_recorder.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.editing});

  /// The child being edited, or null to add a new child.
  final ChildProfile? editing;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  bool _isBoy = false;
  late String _language; // 'he' or 'en' - what the child learns
  RecordedName? _recording;
  bool _voiceRemoved = false;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _language = e?.language ?? ProfileService.instance.language;
    if (e != null) {
      _name.text = e.name;
      _isBoy = e.isBoy;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('צריך לכתוב שם 🙂', 'Please enter a name 🙂'))),
      );
      return;
    }
    setState(() => _saving = true);
    final service = ProfileService.instance;
    final e = widget.editing;
    if (e == null) {
      final created = await service.add(
        name: name,
        isBoy: _isBoy,
        language: _language,
        voice: _recording?.bytes,
        voiceMime: _recording?.mime,
      );
      await service.select(created.id);
    } else {
      await service.update(
        e,
        name: name,
        isBoy: _isBoy,
        language: _language,
        voice: _recording?.bytes,
        voiceMime: _recording?.mime,
        removeVoice: _voiceRemoved && _recording == null,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final existingVoice = widget.editing == null
        ? null
        : ProfileService.instance.voiceUrlOf(widget.editing!);

    return Directionality(
      textDirection: appDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          title: Text(_isEdit
              ? tr('עריכת פרטים', 'Edit details')
              : tr('הרשמה', 'Sign up')),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    tr('שם הילד/ה', "Child's name"),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26),
                    decoration: InputDecoration(
                      hintText: tr('למשל: נועה / Noa', 'e.g. Noa'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr('מה לומדים?', 'What to learn?'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'he',
                        label: Text(tr('אותיות בעברית', 'Hebrew letters'),
                            style: const TextStyle(fontSize: 18)),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(tr('ABC באנגלית', 'English ABC'),
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ],
                    selected: {_language},
                    onSelectionChanged: (s) =>
                        setState(() => _language = s.first),
                  ),
                  // Boy/girl only matters for Hebrew ("כתבי" / "כתוב").
                  if (_language == 'he') ...[
                    const SizedBox(height: 24),
                    Text(
                      tr('בן או בת?', 'Boy or girl?'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('כדי שהאפליקציה תדבר אליו/ה נכון ("כתבי" או "כתוב")',
                          'So the app speaks Hebrew correctly (girl or boy forms)'),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(tr('בת 👧', 'Girl 👧'),
                              style: const TextStyle(fontSize: 20)),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(tr('בן 👦', 'Boy 👦'),
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ],
                      selected: {_isBoy},
                      onSelectionChanged: (s) =>
                          setState(() => _isBoy = s.first),
                    ),
                  ],
                  const SizedBox(height: 24),
                  NameRecorder(
                    existingUrl: existingVoice,
                    onRecorded: (r) => setState(() {
                      _recording = r;
                      _voiceRemoved = false;
                    }),
                    onRemoved: () => setState(() {
                      _recording = null;
                      _voiceRemoved = true;
                    }),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isEdit
                          ? tr('שמירה', 'Save')
                          : tr('בואו נתחיל! 🎉', "Let's start! 🎉"),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
