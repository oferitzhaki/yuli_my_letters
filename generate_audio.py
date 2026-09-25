#!/usr/bin/env python3
"""
Generate Hebrew audio with Google Cloud TTS:
  assets/audio/<id>.mp3         - letter names (אָלֶף, בֵּית ...)
  assets/audio/animal_<id>.mp3  - animal names (אַרְיֵה, בַּרְוָז ...)
Existing files are skipped, so it is safe to run again.
Needs google_credentials.json next to this script.
"""

import os
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

    voices = {
        "he": texttospeech.VoiceSelectionParams(
            language_code="he-IL", name="he-IL-Wavenet-A"),
        "en": texttospeech.VoiceSelectionParams(
            language_code="en-US", name="en-US-Wavenet-F"),
    }
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
           [(f"{n}.mp3", t, FEEDBACK_RATE, "en", False) for n, t in EN_PHRASES]

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
