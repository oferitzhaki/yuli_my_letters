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
    ("he", "הִיפּוֹפּוֹטָם"), ("vav", "וַרְוָר"), ("zayin", "זְאֵב"), ("het", "חָתוּל"),
    ("tet", "טַוָּס"), ("yod", "יוֹנָה"), ("kaf", "כֶּלֶב"), ("lamed", "לְטָאָה"),
    ("mem", "מֵדוּזָה"), ("nun", "נָמֵר"), ("samekh", "סוּס"), ("ayin", "עַכְבָּר"),
    ("pe", "פִּיל"), ("tsadi", "צָב"), ("qof", "קוֹף"), ("resh", "רָקוּן"),
    ("shin", "שׁוּעָל"), ("tav", "תַּרְנְגוֹל"),
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

    voice = texttospeech.VoiceSelectionParams(
        language_code="he-IL",
        name="he-IL-Wavenet-A",
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=0.8,  # a bit slower for kids
    )

    jobs = [(f"{i}.mp3", t) for i, t in LETTERS] + \
           [(f"animal_{i}.mp3", t) for i, t in ANIMALS]

    made = skipped = failed = 0
    for filename, text in jobs:
        path = os.path.join(OUTPUT_DIR, filename)
        if os.path.exists(path):
            skipped += 1
            continue
        try:
            response = client.synthesize_speech(
                input=texttospeech.SynthesisInput(text=text),
                voice=voice,
                audio_config=audio_config,
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
