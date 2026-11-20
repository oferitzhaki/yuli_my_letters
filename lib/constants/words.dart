// lib/constants/words.dart
// Short picture words for the word games ("last letter", "build a word").
// Each word is heard from assets/audio/word_<id>.mp3; `spoken` is what the
// audio script reads (Hebrew with vowel marks so it is pronounced right).
// `translations` are shown when the app speaks another language.

class WordItem {
  const WordItem(this.id, this.word, this.emoji, this.spoken, this.translations);

  final String id;
  final String word; // as shown: Hebrew without vowel marks, English in capitals
  final String emoji;
  final String spoken;
  final Map<String, String> translations;

  List<String> get letters => word.split('');
  String get lastLetter => letters.last;
}

/// Hebrew final letters and the regular letter each one belongs to.
const Map<String, String> finalToBase = {
  'ך': 'כ',
  'ם': 'מ',
  'ן': 'נ',
  'ף': 'פ',
  'ץ': 'צ',
};

/// Audio for each final letter's name: assets/audio/`<id>`.mp3
const Map<String, String> finalLetterIds = {
  'ך': 'final_kaf',
  'ם': 'final_mem',
  'ן': 'final_nun',
  'ף': 'final_pe',
  'ץ': 'final_tsadi',
};

/// The regular form of a letter (ף -> פ); other letters stay as they are.
String baseForm(String letter) => finalToBase[letter] ?? letter;

bool isFinalLetter(String letter) => finalToBase.containsKey(letter);

const List<WordItem> hebrewWords = [
  // two letters
  WordItem('dag', 'דג', '🐟', 'דָּג', {'en': 'fish', 'ro': 'pește'}),
  WordItem('yad', 'יד', '✋', 'יָד', {'en': 'hand', 'ro': 'mână'}),
  WordItem('tsav', 'צב', '🐢', 'צָב', {'en': 'turtle', 'ro': 'țestoasă'}),
  WordItem('af', 'אף', '👃', 'אַף', {'en': 'nose', 'ro': 'nas'}),
  WordItem('ets', 'עץ', '🌳', 'עֵץ', {'en': 'tree', 'ro': 'copac'}),
  WordItem('yam', 'ים', '🌊', 'יָם', {'en': 'sea', 'ro': 'mare'}),
  WordItem('kaf_spoon', 'כף', '🥄', 'כַּף', {'en': 'spoon', 'ro': 'lingură'}),
  WordItem('ner', 'נר', '🕯️', 'נֵר', {'en': 'candle', 'ro': 'lumânare'}),
  WordItem('shen', 'שן', '🦷', 'שֵׁן', {'en': 'tooth', 'ro': 'dinte'}),
  WordItem('hets', 'חץ', '🏹', 'חֵץ', {'en': 'arrow', 'ro': 'săgeată'}),
  // three letters
  WordItem('sus', 'סוס', '🐴', 'סוּס', {'en': 'horse', 'ro': 'cal'}),
  WordItem('pil', 'פיל', '🐘', 'פִּיל', {'en': 'elephant', 'ro': 'elefant'}),
  WordItem('kof', 'קוף', '🐵', 'קוֹף', {'en': 'monkey', 'ro': 'maimuță'}),
  WordItem('dov', 'דוב', '🐻', 'דּוֹב', {'en': 'bear', 'ro': 'urs'}),
  WordItem('gezer', 'גזר', '🥕', 'גֶּזֶר', {'en': 'carrot', 'ro': 'morcov'}),
  WordItem('bayit', 'בית', '🏠', 'בַּיִת', {'en': 'house', 'ro': 'casă'}),
  WordItem('lechem', 'לחם', '🍞', 'לֶחֶם', {'en': 'bread', 'ro': 'pâine'}),
  WordItem('melech', 'מלך', '🤴', 'מֶלֶךְ', {'en': 'king', 'ro': 'rege'}),
  WordItem('sefer', 'ספר', '📖', 'סֵפֶר', {'en': 'book', 'ro': 'carte'}),
  WordItem('tut', 'תות', '🍓', 'תּוּת', {'en': 'strawberry', 'ro': 'căpșună'}),
  WordItem('perach', 'פרח', '🌸', 'פֶּרַח', {'en': 'flower', 'ro': 'floare'}),
  WordItem('yareach', 'ירח', '🌙', 'יָרֵחַ', {'en': 'moon', 'ro': 'lună'}),
  WordItem('chalav', 'חלב', '🥛', 'חָלָב', {'en': 'milk', 'ro': 'lapte'}),
  WordItem('dvash', 'דבש', '🍯', 'דְּבַשׁ', {'en': 'honey', 'ro': 'miere'}),
  WordItem('gamal', 'גמל', '🐪', 'גָּמָל', {'en': 'camel', 'ro': 'cămilă'}),
  WordItem('nachash', 'נחש', '🐍', 'נָחָשׁ', {'en': 'snake', 'ro': 'șarpe'}),
  WordItem('kelev', 'כלב', '🐕', 'כֶּלֶב', {'en': 'dog', 'ro': 'câine'}),
  // four letters
  WordItem('balon', 'בלון', '🎈', 'בָּלוֹן', {'en': 'balloon', 'ro': 'balon'}),
  WordItem('shaon', 'שעון', '⏰', 'שָׁעוֹן', {'en': 'clock', 'ro': 'ceas'}),
  WordItem('karich', 'כריך', '🥪', 'כָּרִיךְ', {'en': 'sandwich', 'ro': 'sandviș'}),
  WordItem('kadur', 'כדור', '⚽', 'כַּדּוּר', {'en': 'ball', 'ro': 'minge'}),
  WordItem('chatul', 'חתול', '🐱', 'חָתוּל', {'en': 'cat', 'ro': 'pisică'}),
];

const List<WordItem> englishWords = [
  // three letters
  WordItem('en_cat', 'CAT', '🐱', 'cat', {'he': 'חתול', 'ro': 'pisică'}),
  WordItem('en_dog', 'DOG', '🐶', 'dog', {'he': 'כלב', 'ro': 'câine'}),
  WordItem('en_sun', 'SUN', '☀️', 'sun', {'he': 'שמש', 'ro': 'soare'}),
  WordItem('en_bus', 'BUS', '🚌', 'bus', {'he': 'אוטובוס', 'ro': 'autobuz'}),
  WordItem('en_car', 'CAR', '🚗', 'car', {'he': 'מכונית', 'ro': 'mașină'}),
  WordItem('en_hat', 'HAT', '🎩', 'hat', {'he': 'כובע', 'ro': 'pălărie'}),
  WordItem('en_pig', 'PIG', '🐷', 'pig', {'he': 'חזיר', 'ro': 'porc'}),
  WordItem('en_bed', 'BED', '🛏️', 'bed', {'he': 'מיטה', 'ro': 'pat'}),
  WordItem('en_cup', 'CUP', '🥤', 'cup', {'he': 'כוס', 'ro': 'pahar'}),
  WordItem('en_box', 'BOX', '📦', 'box', {'he': 'קופסה', 'ro': 'cutie'}),
  WordItem('en_fox', 'FOX', '🦊', 'fox', {'he': 'שועל', 'ro': 'vulpe'}),
  WordItem('en_egg', 'EGG', '🥚', 'egg', {'he': 'ביצה', 'ro': 'ou'}),
  WordItem('en_bee', 'BEE', '🐝', 'bee', {'he': 'דבורה', 'ro': 'albină'}),
  WordItem('en_cow', 'COW', '🐮', 'cow', {'he': 'פרה', 'ro': 'vacă'}),
  WordItem('en_key', 'KEY', '🔑', 'key', {'he': 'מפתח', 'ro': 'cheie'}),
  WordItem('en_pen', 'PEN', '🖊️', 'pen', {'he': 'עט', 'ro': 'pix'}),
  WordItem('en_bag', 'BAG', '👜', 'bag', {'he': 'תיק', 'ro': 'geantă'}),
  WordItem('en_ant', 'ANT', '🐜', 'ant', {'he': 'נמלה', 'ro': 'furnică'}),
  WordItem('en_owl', 'OWL', '🦉', 'owl', {'he': 'ינשוף', 'ro': 'bufniță'}),
  WordItem('en_nut', 'NUT', '🥜', 'nut', {'he': 'אגוז', 'ro': 'nucă'}),
  WordItem('en_map', 'MAP', '🗺️', 'map', {'he': 'מפה', 'ro': 'hartă'}),
  WordItem('en_van', 'VAN', '🚐', 'van', {'he': 'טנדר', 'ro': 'dubă'}),
  WordItem('en_web', 'WEB', '🕸️', 'web', {'he': 'קורי עכביש', 'ro': 'pânză de păianjen'}),
  // four letters
  WordItem('en_fish', 'FISH', '🐟', 'fish', {'he': 'דג', 'ro': 'pește'}),
  WordItem('en_frog', 'FROG', '🐸', 'frog', {'he': 'צפרדע', 'ro': 'broască'}),
  WordItem('en_duck', 'DUCK', '🦆', 'duck', {'he': 'ברווז', 'ro': 'rață'}),
  WordItem('en_moon', 'MOON', '🌙', 'moon', {'he': 'ירח', 'ro': 'lună'}),
  WordItem('en_star', 'STAR', '⭐', 'star', {'he': 'כוכב', 'ro': 'stea'}),
  WordItem('en_book', 'BOOK', '📖', 'book', {'he': 'ספר', 'ro': 'carte'}),
  WordItem('en_cake', 'CAKE', '🎂', 'cake', {'he': 'עוגה', 'ro': 'tort'}),
  WordItem('en_tree', 'TREE', '🌳', 'tree', {'he': 'עץ', 'ro': 'copac'}),
];
