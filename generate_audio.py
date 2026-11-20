#!/usr/bin/env python3
"""
Generate the app's audio with Google Cloud TTS (files in assets/audio/):
  <id>.mp3              letter names (אָלֶף ... / "ay" ...)
  animal_<id>.mp3       picture words (אַרְיֵה ... / "Apple" ...)
  fb_*.mp3              spoken feedback: Hebrew, fb_en_* English, fb_ro_* Romanian
  tr_<lang>_<id>.mp3    a picture word translated into the language the app
                        speaks, e.g. tr_ro_alef = "leu". English and Romanian
                        words are read from lib/constants/translations.dart, so
                        what is heard always matches what is shown.
Existing files are skipped, so it is safe to run again.
Needs google_credentials.json next to this script.
"""

import os
import re
from google.cloud import texttospeech
from google.oauth2 import service_account

LETTERS = [
    ("alef", "אָלֶף"), ("bet", "בֵּית"), ("gimel", "גִּימֶל"), ("dalet", "דָּלֶת"),
    ("he", "הֵא"), ("vav", "וָו"), ("zayin", "זַיִן"), ("het", "חֵית"),
    ("tet", "טֵית"), ("yod", "יוֹד"), ("kaf", "כַּף"), ("lamed", "לָמֶד"),
    ("mem", "מֵם"), ("nun", "נוּן"), ("samekh", "סָמֶךְ"), ("ayin", "עַיִן"),
    ("pe", "פֵּא"), ("tsadi", "צָדִי"), ("qof", "קוֹף"), ("resh", "רֵישׁ"),
    ("shin", "שִׁין"), ("tav", "תָּו"),
]

ANIMALS = [
    ("alef", "אַרְיֵה"), ("bet", "בַּרְוָז"), ("gimel", "גָּמָל"), ("dalet", "דָּג"),
    ("he", "הִיפּוֹפּוֹטָם"), ("vav", "וֶרֶד"), ("zayin", "זֶבְּרָה"), ("het", "חָתוּל"),
    ("tet", "טְרַקְטוֹר"), ("yod", "יָד"), ("kaf", "כֶּלֶב"), ("lamed", "לִימוֹן"),
    ("mem", "מְכוֹנִית"), ("nun", "נָחָשׁ"), ("samekh", "סוּס"), ("ayin", "עַכְבָּר"),
    ("pe", "פִּיל"), ("tsadi", "צָב"), ("qof", "קוֹף"), ("resh", "רַכֶּבֶת"),
    ("shin", "שֶׁמֶשׁ"), ("tav", "תַּפּוּחַ"),
]

# Spoken feedback, without a name (each child's name is recorded in the
# app by a parent). _f = girl, _m = boy, _n = the same for both.
PHRASES = [
    ("fb_praise_n_1", "כָּל הַכָּבוֹד!"),
    ("fb_praise_n_2", "מְצֻיָּן!"),
    ("fb_praise_f_1", "יוֹפִי, הִצְלַחְתְּ!"),
    ("fb_praise_m_1", "יוֹפִי, הִצְלַחְתָּ!"),
    ("fb_praise_f_2", "אַתְּ אַלּוּפָה!"),
    ("fb_praise_m_2", "אַתָּה אַלּוּף!"),
    ("fb_try_f_1", "כִּמְעַט! נַסִּי שׁוּב"),
    ("fb_try_m_1", "כִּמְעַט! נַסֵּה שׁוּב"),
    ("fb_try_f_2", "לֹא נוֹרָא, נַסִּי עוֹד פַּעַם"),
    ("fb_try_m_2", "לֹא נוֹרָא, נַסֵּה עוֹד פַּעַם"),
    ("fb_round_f", "כָּל הַכָּבוֹד! סִיַּמְתְּ אֶת הַסִּבּוּב!"),
    ("fb_round_m", "כָּל הַכָּבוֹד! סִיַּמְתָּ אֶת הַסִּבּוּב!"),
    ("fb_unlock_f", "נִפְתְּחוּ לָךְ אוֹתִיּוֹת חֲדָשׁוֹת!"),
    ("fb_unlock_m", "נִפְתְּחוּ לְךָ אוֹתִיּוֹת חֲדָשׁוֹת!"),
    ("fb_intro_done_n", "כָּל הַכָּבוֹד! עַכְשָׁו אֶפְשָׁר לְשַׂחֵק"),
    ("fb_write_f", "כִּתְבִי אֶת הָאוֹת"),
    ("fb_write_m", "כְּתֹב אֶת הָאוֹת"),
]

# ---------- English ABC ----------
# Letter names use SSML so "A" is read as the letter ("ay"), not a word.
EN_LETTERS = [(f"en_{c.lower()}", c) for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
EN_WORDS = [
    ("en_a", "Apple"), ("en_b", "Ball"), ("en_c", "Cat"), ("en_d", "Dog"),
    ("en_e", "Egg"), ("en_f", "Fish"), ("en_g", "Grapes"), ("en_h", "Hat"),
    ("en_i", "Ice cream"), ("en_j", "Juice"), ("en_k", "Kite"), ("en_l", "Lion"),
    ("en_m", "Moon"), ("en_n", "Nose"), ("en_o", "Orange"), ("en_p", "Pig"),
    ("en_q", "Queen"), ("en_r", "Rabbit"), ("en_s", "Sun"), ("en_t", "Tree"),
    ("en_u", "Umbrella"), ("en_v", "Van"), ("en_w", "Watermelon"),
    ("en_x", "X-ray"), ("en_y", "Yo-yo"), ("en_z", "Zebra"),
]
EN_PHRASES = [
    ("fb_en_praise_1", "Great job!"),
    ("fb_en_praise_2", "Well done!"),
    ("fb_en_praise_3", "Awesome!"),
    ("fb_en_praise_4", "You're a star!"),
    ("fb_en_try_1", "Almost! Try again."),
    ("fb_en_try_2", "Oops! Try one more time."),
    ("fb_en_round", "Great job! You finished the round!"),
    ("fb_en_unlock", "New letters are waiting for you!"),
    ("fb_en_intro_done", "Well done! Now let's play!"),
    ("fb_en_write", "Write the letter"),
]

# ---------- Romanian: instructions and praise ----------
RO_PHRASES = [
    ("fb_ro_praise_1", "Bravo!"),
    ("fb_ro_praise_2", "Foarte bine!"),
    ("fb_ro_praise_3", "Super!"),
    ("fb_ro_praise_4", "Excelent!"),
    ("fb_ro_try_1", "Aproape! Mai încearcă."),
    ("fb_ro_try_2", "Nu-i nimic, mai încearcă o dată."),
    ("fb_ro_round", "Bravo! Ai terminat runda!"),
    ("fb_ro_unlock", "Te așteaptă litere noi!"),
    ("fb_ro_intro_done", "Foarte bine! Acum hai să ne jucăm!"),
    ("fb_ro_write", "Scrie litera"),
]

# Hebrew translations of the English picture words, with vowel marks so
# they are pronounced correctly (the app shows them without marks).
HE_TRANSLATIONS = {
    "en_a": "תַּפּוּחַ", "en_b": "כַּדּוּר", "en_c": "חָתוּל", "en_d": "כֶּלֶב",
    "en_e": "בֵּיצָה", "en_f": "דָּג", "en_g": "עֲנָבִים", "en_h": "כּוֹבַע",
    "en_i": "גְּלִידָה", "en_j": "מִיץ", "en_k": "עֲפִיפוֹן", "en_l": "אַרְיֵה",
    "en_m": "יָרֵחַ", "en_n": "אַף", "en_o": "תַּפּוּז", "en_p": "חֲזִיר",
    "en_q": "מַלְכָּה", "en_r": "אַרְנָב", "en_s": "שֶׁמֶשׁ", "en_t": "עֵץ",
    "en_u": "מִטְרִיָּה", "en_v": "טֶנְדֶּר", "en_w": "אֲבַטִּיחַ",
    "en_x": "צִלּוּם רֶנְטְגֶן", "en_y": "יוֹ-יוֹ", "en_z": "זֶבְּרָה",
}

TRANSLATIONS_FILE = "lib/constants/translations.dart"
WORDS_FILE = "lib/constants/words.dart"
LETTERS_FILE = "lib/constants/hebrew_characters.dart"

# ---------- word games ----------
# Final letter names (ids match finalLetterIds in words.dart).
FINAL_LETTERS = [
    ("final_kaf", "כָּף סוֹפִית"),
    ("final_mem", "מֵם סוֹפִית"),
    ("final_nun", "נוּן סוֹפִית"),
    ("final_pe", "פֵּא סוֹפִית"),
    ("final_tsadi", "צָדִי סוֹפִית"),
]


def read_words():
    """[(id, spoken, lang)] from words.dart; English ids start with en_."""
    text = open(WORDS_FILE, encoding="utf-8").read()
    found = re.findall(r"WordItem\('(\w+)', '[^']+', '[^']+', '([^']+)'", text)
    return [(i, spoken, "en" if i.startswith("en_") else "he") for i, spoken in found]


# Syllables: SAME rules as syllableText() in lib/constants/syllables.dart.
DAGESH, SHIN_DOT = "\u05BC", "\u05C1"
VOWEL_MARKS = {
    "a": "\u05B8",          # kamatz
    "e": "\u05B5",          # tsere
    "i": "\u05B4",          # hiriq
    "o": "\u05D5\u05B9",    # holam male  וֹ
    "u": "\u05D5\u05BC",    # shuruk  וּ
}


def read_syllables():
    """[(syl_<letterId>_<vowel>, text)] for every Hebrew letter except ו."""
    text = open(LETTERS_FILE, encoding="utf-8").read()
    letters = re.findall(r"id: '(\w+)',\s*letter: '(.)'", text)
    out = []
    for letter_id, letter in letters:
        if letter_id == "vav":
            continue
        base = letter
        if letter_id in ("bet", "kaf", "pe"):
            base += DAGESH
        elif letter_id == "shin":
            base += SHIN_DOT
        for vowel, mark in VOWEL_MARKS.items():
            out.append((f"syl_{letter_id}_{vowel}", base + mark))
    return out


def read_translations():
    """{(lang, id): word} for English and Romanian, from the Dart file."""
    text = open(TRANSLATIONS_FILE, encoding="utf-8").read()
    block = text.split("wordTranslations", 1)[1].split("};", 1)[0]
    found = {}
    for letter_id, body in re.findall(r"'(\w+)':\s*\{([^}]*)\}", block):
        for lang, word in re.findall(r"'(\w+)':\s*'([^']*)'", body):
            if lang in ("en", "ro"):
                found[(lang, letter_id)] = word
    return found


# Preferred voices; if one is not offered, the best available voice for
# that language is used instead.
PREFERRED_VOICES = {
    "he": ("he-IL", ["he-IL-Wavenet-A"]),
    "en": ("en-US", ["en-US-Wavenet-F"]),
    "ro": ("ro-RO", ["ro-RO-Wavenet-A", "ro-RO-Wavenet-B", "ro-RO-Standard-A"]),
}


def pick_voices(client):
    voices = {}
    for lang, (code, preferred) in PREFERRED_VOICES.items():
        offered = [v.name for v in client.list_voices(language_code=code).voices]
        name = next((n for n in preferred if n in offered), None)
        if name is None:
            ranked = sorted(offered, key=lambda n: (
                "Wavenet" not in n and "Neural2" not in n, n))
            name = ranked[0] if ranked else None
        print(f"Voice for {lang}: {name or code + ' (default)'}")
        voices[lang] = (texttospeech.VoiceSelectionParams(language_code=code, name=name)
                        if name else texttospeech.VoiceSelectionParams(language_code=code))
    return voices


OUTPUT_DIR = "assets/audio"


def main():
    if not os.path.exists("google_credentials.json"):
        print("Error: google_credentials.json not found next to this script")
        return 1

    credentials = service_account.Credentials.from_service_account_file(
        "google_credentials.json"
    )
    client = texttospeech.TextToSpeechClient(credentials=credentials)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    voices = pick_voices(client)
    translations = read_translations()
    words = read_words()
    syllables = read_syllables()
    # Letters and words a bit slower for clarity; feedback at normal pace
    # so praise comes quickly.
    LEARN_RATE = 0.8
    FEEDBACK_RATE = 1.05

    # (file, text, speaking rate, language, text is SSML?)
    jobs = [(f"{i}.mp3", t, LEARN_RATE, "he", False) for i, t in LETTERS] + \
           [(f"animal_{i}.mp3", t, LEARN_RATE, "he", False) for i, t in ANIMALS] + \
           [(f"{n}.mp3", t, FEEDBACK_RATE, "he", False) for n, t in PHRASES] + \
           [(f"{i}.mp3",
             f'<speak><say-as interpret-as="characters">{t}</say-as></speak>',
             LEARN_RATE, "en", True) for i, t in EN_LETTERS] + \
           [(f"animal_{i}.mp3", t, LEARN_RATE, "en", False) for i, t in EN_WORDS] + \
           [(f"{n}.mp3", t, FEEDBACK_RATE, "en", False) for n, t in EN_PHRASES] + \
           [(f"{n}.mp3", t, FEEDBACK_RATE, "ro", False) for n, t in RO_PHRASES] + \
           [(f"tr_{lang}_{i}.mp3", w, LEARN_RATE, lang, False)
            for (lang, i), w in sorted(translations.items())] + \
           [(f"tr_he_{i}.mp3", w, LEARN_RATE, "he", False)
            for i, w in HE_TRANSLATIONS.items()] + \
           [(f"word_{i}.mp3", w, LEARN_RATE, lang, False) for i, w, lang in words] + \
           [(f"{n}.mp3", t, LEARN_RATE, "he", False) for n, t in FINAL_LETTERS] + \
           [(f"{n}.mp3", t, LEARN_RATE, "he", False) for n, t in syllables]

    made = skipped = failed = 0
    for filename, text, rate, lang, is_ssml in jobs:
        path = os.path.join(OUTPUT_DIR, filename)
        if os.path.exists(path):
            skipped += 1
            continue
        try:
            response = client.synthesize_speech(
                input=(texttospeech.SynthesisInput(ssml=text) if is_ssml
                       else texttospeech.SynthesisInput(text=text)),
                voice=voices[lang],
                audio_config=texttospeech.AudioConfig(
                    audio_encoding=texttospeech.AudioEncoding.MP3,
                    speaking_rate=rate,
                ),
            )
            with open(path, "wb") as out:
                out.write(response.audio_content)
            print(f"OK   {filename}")
            made += 1
        except Exception as e:
            print(f"FAIL {filename}: {e}")
            failed += 1

    print(f"\nDone: {made} created, {skipped} already existed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
