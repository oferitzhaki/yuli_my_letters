// lib/services/profile_service.dart
// Children registered on this device: name, boy/girl, and an optional
// recording of the name in a parent's voice. Each child has separate
// progress (see ProgressService).

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/english_characters.dart';
import '../constants/hebrew_characters.dart';
import 'progress_service.dart';

class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    required this.isBoy,
    this.hasVoice = false,
    this.language = 'he',
  });

  final String id;
  String name;
  bool isBoy;
  bool hasVoice;

  /// What the child learns (and the app's language for them): 'he' or 'en'.
  String language;

  bool get isEnglish => language == 'en';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBoy': isBoy,
        'hasVoice': hasVoice,
        'language': language,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        isBoy: j['isBoy'] as bool? ?? false,
        hasVoice: j['hasVoice'] as bool? ?? false,
        language: j['language'] as String? ?? 'he',
      );
}

/// Picks the girl or boy form of a Hebrew text for the child who is playing.
String g(String female, String male) =>
    ProfileService.instance.isBoy ? male : female;

/// Picks the Hebrew or English text for the current language.
String tr(String hebrew, String english) =>
    ProfileService.instance.isEnglish ? english : hebrew;

/// Right-to-left for Hebrew, left-to-right for English.
TextDirection get appDirection =>
    ProfileService.instance.isEnglish ? TextDirection.ltr : TextDirection.rtl;

/// The alphabet the current child learns.
List<HebrewCharacter> get activeLetters =>
    ProfileService.instance.isEnglish ? englishCharacters : hebrewCharacters;

class ProfileService extends ChangeNotifier {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kProfiles = 'profiles';
  static const _kCurrent = 'current_profile';
  static const _kUiLanguage = 'ui_language';

  SharedPreferences? _prefs;
  final List<ChildProfile> _profiles = [];
  String? _currentId;
  String? _voiceUrl;
  String? _uiLanguage; // chosen on first launch; used when no child is active

  List<ChildProfile> get profiles => List.unmodifiable(_profiles);

  ChildProfile? get current {
    for (final p in _profiles) {
      if (p.id == _currentId) return p;
    }
    return null;
  }

  bool get isBoy => current?.isBoy ?? false;
  String get name => current?.name ?? '';

  /// The language of the child who is playing, or of the app itself.
  String get language => current?.language ?? _uiLanguage ?? 'he';
  bool get isEnglish => language == 'en';

  /// False until someone picks עברית / English on the very first launch.
  bool get uiLanguageChosen => _uiLanguage != null;

  Future<void> setUiLanguage(String lang) async {
    _uiLanguage = lang;
    await _prefs?.setString(_kUiLanguage, lang);
    notifyListeners();
  }

  /// The recorded name of the child who is playing (a data: URL), if any.
  String? get voiceUrl => _voiceUrl;

  String? voiceUrlOf(ChildProfile p) => _prefs?.getString(_voiceKey(p.id));

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      _uiLanguage = p.getString(_kUiLanguage);
      _profiles.clear();
      final raw = p.getString(_kProfiles);
      if (raw != null) {
        for (final e in jsonDecode(raw) as List) {
          _profiles.add(ChildProfile.fromJson(e as Map<String, dynamic>));
        }
      }
      if (_profiles.isEmpty) await _migrateSingleChildVersion();
      final saved = p.getString(_kCurrent);
      if (saved != null && _profiles.any((x) => x.id == saved)) {
        await select(saved);
        return;
      }
    } catch (e) {
      debugPrint('Profiles load failed: $e');
    }
    notifyListeners();
  }

  /// Devices that used the app before profiles existed keep their
  /// progress: it becomes Yuli's profile.
  Future<void> _migrateSingleChildVersion() async {
    final p = _prefs!;
    if (!ProgressService.hasLegacyProgress(p)) return;
    final yuli = ChildProfile(id: 'yuli', name: 'יולי', isBoy: false);
    _profiles.add(yuli);
    await ProgressService.migrateLegacy(p, yuli.id);
    await p.setString(_kCurrent, yuli.id);
    await p.setString(_kUiLanguage, 'he');
    _uiLanguage = 'he';
    await _saveProfiles();
  }

  Future<void> select(String id) async {
    _currentId = id;
    await _prefs?.setString(_kCurrent, id);
    _voiceUrl = _prefs?.getString(_voiceKey(id));
    await ProgressService.instance.loadFor(id);
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentId = null;
    _voiceUrl = null;
    await _prefs?.remove(_kCurrent);
    notifyListeners();
  }

  Future<ChildProfile> add({
    required String name,
    required bool isBoy,
    required String language,
    Uint8List? voice,
    String? voiceMime,
  }) async {
    final profile = ChildProfile(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      isBoy: isBoy,
      language: language,
    );
    _profiles.add(profile);
    if (voice != null && voiceMime != null) {
      await _saveVoice(profile, voice, voiceMime);
    }
    await _saveProfiles();
    notifyListeners();
    return profile;
  }

  Future<void> update(
    ChildProfile profile, {
    required String name,
    required bool isBoy,
    required String language,
    Uint8List? voice,
    String? voiceMime,
    bool removeVoice = false,
  }) async {
    profile.name = name.trim();
    profile.isBoy = isBoy;
    profile.language = language;
    if (removeVoice) {
      await _prefs?.remove(_voiceKey(profile.id));
      profile.hasVoice = false;
    }
    if (voice != null && voiceMime != null) {
      await _saveVoice(profile, voice, voiceMime);
    }
    await _saveProfiles();
    if (profile.id == _currentId) {
      _voiceUrl = _prefs?.getString(_voiceKey(profile.id));
    }
    notifyListeners();
  }

  Future<void> delete(ChildProfile profile) async {
    _profiles.removeWhere((x) => x.id == profile.id);
    await _prefs?.remove(_voiceKey(profile.id));
    await ProgressService.deleteFor(profile.id);
    if (_currentId == profile.id) await signOut();
    await _saveProfiles();
    notifyListeners();
  }

  String _voiceKey(String id) => 'voice_$id';

  Future<void> _saveVoice(
    ChildProfile profile,
    Uint8List bytes,
    String mime,
  ) async {
    await _prefs?.setString(
      _voiceKey(profile.id),
      'data:$mime;base64,${base64Encode(bytes)}',
    );
    profile.hasVoice = true;
  }

  Future<void> _saveProfiles() async {
    await _prefs?.setString(
      _kProfiles,
      jsonEncode([for (final x in _profiles) x.toJson()]),
    );
  }
}
