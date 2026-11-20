// lib/services/profile_service.dart
// Children registered on this device. Each child has:
//  * a name (and optionally that name recorded in a parent's voice)
//  * boy/girl (used for Hebrew grammar: "כתבי" / "כתוב")
//  * the alphabet they LEARN: Hebrew ('he') or English ('en')
//  * the language the app SPEAKS to them: Hebrew, English or Romanian
//    ('he' / 'en' / 'ro') - buttons, instructions and spoken praise.
// For example, a Romanian-speaking child learns Hebrew letters
// (learn 'he') with Romanian instructions (ui 'ro').
// Each child has separate progress (see ProgressService).

import 'dart:convert';
import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/english_characters.dart';
import '../constants/hebrew_characters.dart';
import '../constants/romanian_texts.dart';
import '../constants/translations.dart';
import 'progress_service.dart';

/// The languages the app can speak to a child, in display order.
const List<String> uiLanguages = ['he', 'en', 'ro'];

/// Each language's own name, as shown on its button.
const Map<String, String> uiLanguageNames = {
  'he': 'עברית',
  'en': 'English',
  'ro': 'Română',
};

class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    required this.isBoy,
    this.hasVoice = false,
    this.language = 'he',
    String? uiLanguage,
  }) : uiLanguage = uiLanguage ?? language;

  final String id;
  String name;
  bool isBoy;
  bool hasVoice;

  /// The alphabet the child learns: 'he' or 'en'.
  String language;

  /// The language the app speaks to the child: 'he', 'en' or 'ro'.
  String uiLanguage;

  bool get learnsEnglish => language == 'en';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBoy': isBoy,
        'hasVoice': hasVoice,
        'language': language,
        'ui': uiLanguage,
      };

  // Profiles saved before 'ui' existed spoke the language they learned.
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        isBoy: j['isBoy'] as bool? ?? false,
        hasVoice: j['hasVoice'] as bool? ?? false,
        language: j['language'] as String? ?? 'he',
        uiLanguage: j['ui'] as String?,
      );
}

/// The language the app speaks right now: the playing child's, or the
/// app's own language when no child is selected.
String get uiLang => ProfileService.instance.uiLanguage;

/// Picks the girl or boy form of a Hebrew text for the child who is playing.
String g(String female, String male) =>
    ProfileService.instance.isBoy ? male : female;

/// Picks the text for the current language. The Romanian text is either
/// given here (texts with names or numbers inside them) or looked up by
/// its English text in romanianTexts; if missing, English is shown.
String tr(String hebrew, String english, [String? romanian]) {
  switch (uiLang) {
    case 'he':
      return hebrew;
    case 'ro':
      return romanian ?? romanianTexts[english] ?? english;
    default:
      return english;
  }
}

/// A Romanian count: "1 stea", "10 stele", "25 de stele" (numbers whose
/// last two digits are 20-99 or 00 take "de").
String roCount(int n, String one, String many) {
  if (n == 1) return '1 $one';
  final lastTwo = n % 100;
  final de = n != 0 && (lastTwo == 0 || lastTwo >= 20);
  return de ? '$n de $many' : '$n $many';
}

/// Screens follow the language the app speaks: right-to-left for Hebrew.
TextDirection get appDirection =>
    uiLang == 'he' ? TextDirection.rtl : TextDirection.ltr;

/// Rows of letters follow the alphabet being learned: Hebrew right-to-left.
TextDirection get learnDirection => ProfileService.instance.learnsEnglish
    ? TextDirection.ltr
    : TextDirection.rtl;

/// The alphabet the current child learns.
List<HebrewCharacter> get activeLetters => ProfileService.instance.learnsEnglish
    ? englishCharacters
    : hebrewCharacters;

/// The picture word in the language the app speaks, e.g. אריה -> "leu".
/// Null when the child learns in their own language (nothing to translate).
String? translationOf(HebrewCharacter c) {
  if (uiLang == ProfileService.instance.learnLanguage) return null;
  return wordTranslations[c.id]?[uiLang];
}

/// How a Hebrew letter sounds, written the child's way, e.g. צ -> "Ț".
String? soundHintOf(HebrewCharacter c) {
  if (uiLang == ProfileService.instance.learnLanguage) return null;
  return letterSoundHints[c.id]?[uiLang];
}

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
  String? _appLanguage; // chosen on first launch; used when no child is active

  List<ChildProfile> get profiles => List.unmodifiable(_profiles);

  ChildProfile? get current {
    for (final p in _profiles) {
      if (p.id == _currentId) return p;
    }
    return null;
  }

  bool get isBoy => current?.isBoy ?? false;
  String get name => current?.name ?? '';

  /// The alphabet the playing child learns ('he' or 'en').
  String get learnLanguage => current?.language ?? 'he';
  bool get learnsEnglish => learnLanguage == 'en';

  /// The language the app speaks now: the child's, or the app's own.
  String get uiLanguage => current?.uiLanguage ?? appLanguage;

  /// The app's own language (first screens, "who is playing?").
  String get appLanguage => _appLanguage ?? 'he';

  /// False until someone picks a language on the very first launch.
  bool get uiLanguageChosen => _appLanguage != null;

  Future<void> setUiLanguage(String lang) async {
    _appLanguage = lang;
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
      _appLanguage = p.getString(_kUiLanguage);
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
    _appLanguage = 'he';
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
    required String uiLanguage,
    Uint8List? voice,
    String? voiceMime,
  }) async {
    final profile = ChildProfile(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      isBoy: isBoy,
      language: language,
      uiLanguage: uiLanguage,
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
    required String uiLanguage,
    Uint8List? voice,
    String? voiceMime,
    bool removeVoice = false,
  }) async {
    final languageChanged = profile.language != language;
    profile.name = name.trim();
    profile.isBoy = isBoy;
    profile.language = language;
    profile.uiLanguage = uiLanguage;
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
      // A different alphabet has its own progress.
      if (languageChanged) await ProgressService.instance.loadFor(profile.id);
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
