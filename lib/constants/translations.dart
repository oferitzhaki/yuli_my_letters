// lib/constants/translations.dart
// Helps a child who learns letters in a language that is not their own.
//
// wordTranslations: the picture word in the language the app speaks,
//   e.g. a Romanian-speaking child learning א sees and hears
//   "אריה" and then "leu". Spoken versions are in generate_audio.py
//   (files tr_<lang>_<id>.mp3) and must stay in step with this file.
//
// letterSoundHints: how a Hebrew letter sounds, written with the child's
//   own letters, e.g. צ = Ț in Romanian. Shown when meeting each letter.

const Map<String, Map<String, String>> wordTranslations = {
  // ---------- Hebrew letters: the word in English and Romanian ----------
  'alef': {'en': 'lion', 'ro': 'leu'},
  'bet': {'en': 'duck', 'ro': 'rață'},
  'gimel': {'en': 'camel', 'ro': 'cămilă'},
  'dalet': {'en': 'fish', 'ro': 'pește'},
  'he': {'en': 'hippo', 'ro': 'hipopotam'},
  'vav': {'en': 'rose', 'ro': 'trandafir'},
  'zayin': {'en': 'zebra', 'ro': 'zebră'},
  'het': {'en': 'cat', 'ro': 'pisică'},
  'tet': {'en': 'tractor', 'ro': 'tractor'},
  'yod': {'en': 'hand', 'ro': 'mână'},
  'kaf': {'en': 'dog', 'ro': 'câine'},
  'lamed': {'en': 'lemon', 'ro': 'lămâie'},
  'mem': {'en': 'car', 'ro': 'mașină'},
  'nun': {'en': 'snake', 'ro': 'șarpe'},
  'samekh': {'en': 'horse', 'ro': 'cal'},
  'ayin': {'en': 'mouse', 'ro': 'șoarece'},
  'pe': {'en': 'elephant', 'ro': 'elefant'},
  'tsadi': {'en': 'turtle', 'ro': 'țestoasă'},
  'qof': {'en': 'monkey', 'ro': 'maimuță'},
  'resh': {'en': 'train', 'ro': 'tren'},
  'shin': {'en': 'sun', 'ro': 'soare'},
  'tav': {'en': 'apple', 'ro': 'măr'},

  // ---------- English letters: the word in Hebrew and Romanian ----------
  'en_a': {'he': 'תפוח', 'ro': 'măr'},
  'en_b': {'he': 'כדור', 'ro': 'minge'},
  'en_c': {'he': 'חתול', 'ro': 'pisică'},
  'en_d': {'he': 'כלב', 'ro': 'câine'},
  'en_e': {'he': 'ביצה', 'ro': 'ou'},
  'en_f': {'he': 'דג', 'ro': 'pește'},
  'en_g': {'he': 'ענבים', 'ro': 'struguri'},
  'en_h': {'he': 'כובע', 'ro': 'pălărie'},
  'en_i': {'he': 'גלידה', 'ro': 'înghețată'},
  'en_j': {'he': 'מיץ', 'ro': 'suc'},
  'en_k': {'he': 'עפיפון', 'ro': 'zmeu'},
  'en_l': {'he': 'אריה', 'ro': 'leu'},
  'en_m': {'he': 'ירח', 'ro': 'lună'},
  'en_n': {'he': 'אף', 'ro': 'nas'},
  'en_o': {'he': 'תפוז', 'ro': 'portocală'},
  'en_p': {'he': 'חזיר', 'ro': 'porc'},
  'en_q': {'he': 'מלכה', 'ro': 'regină'},
  'en_r': {'he': 'ארנב', 'ro': 'iepure'},
  'en_s': {'he': 'שמש', 'ro': 'soare'},
  'en_t': {'he': 'עץ', 'ro': 'copac'},
  'en_u': {'he': 'מטרייה', 'ro': 'umbrelă'},
  'en_v': {'he': 'טנדר', 'ro': 'dubă'},
  'en_w': {'he': 'אבטיח', 'ro': 'pepene'},
  'en_x': {'he': 'צילום רנטגן', 'ro': 'radiografie'},
  'en_y': {'he': 'יו-יו', 'ro': 'yo-yo'},
  'en_z': {'he': 'זברה', 'ro': 'zebră'},
};

/// How each Hebrew letter sounds, written in Romanian and English letters.
/// "—" marks the two letters that make no sound of their own.
const Map<String, Map<String, String>> letterSoundHints = {
  'alef': {'ro': '— (nu se aude)', 'en': '— (silent)'},
  'bet': {'ro': 'B / V', 'en': 'B / V'},
  'gimel': {'ro': 'G', 'en': 'G'},
  'dalet': {'ro': 'D', 'en': 'D'},
  'he': {'ro': 'H', 'en': 'H'},
  'vav': {'ro': 'V (sau O, U)', 'en': 'V (or O, U)'},
  'zayin': {'ro': 'Z', 'en': 'Z'},
  'het': {'ro': 'H (ca în „hrean”)', 'en': 'Kh (as in Bach)'},
  'tet': {'ro': 'T', 'en': 'T'},
  'yod': {'ro': 'I', 'en': 'Y'},
  'kaf': {'ro': 'K / H', 'en': 'K / Kh'},
  'lamed': {'ro': 'L', 'en': 'L'},
  'mem': {'ro': 'M', 'en': 'M'},
  'nun': {'ro': 'N', 'en': 'N'},
  'samekh': {'ro': 'S', 'en': 'S'},
  'ayin': {'ro': '— (nu se aude)', 'en': '— (silent)'},
  'pe': {'ro': 'P / F', 'en': 'P / F'},
  'tsadi': {'ro': 'Ț', 'en': 'Ts'},
  'qof': {'ro': 'K', 'en': 'K'},
  'resh': {'ro': 'R', 'en': 'R'},
  'shin': {'ro': 'Ș / S', 'en': 'Sh / S'},
  'tav': {'ro': 'T', 'en': 'T'},
};
