#!/usr/bin/env python3
"""
Generate Hebrew letter pronunciation audio files using Google Cloud TTS
Place google_credentials.json in the same directory as this script
"""

import os
import json
from google.cloud import texttospeech
from google.oauth2 import service_account

# Hebrew letters and their names
HEBREW_LETTERS = [
    ("alef", "אַלֶף"),
    ("bet", "בֵּית"),
    ("gimel", "גִּימֶל"),
    ("dalet", "דָּלֶת"),
    ("he", "הֵא"),
    ("vav", "וָו"),
    ("zayin", "זַיִן"),
    ("het", "חֵת"),
    ("tet", "טֵת"),
    ("yod", "יוֹד"),
    ("kaf", "כַּף"),
    ("lamed", "לָמֶד"),
    ("mem", "מֵם"),
    ("nun", "נוּן"),
    ("samekh", "סָמֶךְ"),
    ("ayin", "עַיִן"),
    ("pe", "פֵּא"),
    ("tsadi", "צָדִי"),
    ("qof", "קוֹף"),
    ("resh", "רֵישׁ"),
    ("shin", "שִׁין"),
    ("tav", "תָּו"),
]

def generate_audio_files():
    """Generate audio files for all Hebrew letters"""
    
    # Load credentials
    credentials_path = "google_credentials.json"
    if not os.path.exists(credentials_path):
        print("❌ Error: google_credentials.json not found!")
        print("   Please download it from Google Cloud Console")
        return False
    
    # Initialize TTS client
    credentials = service_account.Credentials.from_service_account_file(
        credentials_path
    )
    client = texttospeech.TextToSpeechClient(credentials=credentials)
    
    # Create output directory
    output_dir = "assets/audio"
    os.makedirs(output_dir, exist_ok=True)
    
    print("🎵 Generating Hebrew letter audio files...")
    print(f"📁 Output directory: {output_dir}\n")
    
    success_count = 0
    
    for filename, hebrew_text in HEBREW_LETTERS:
        try:
            # Prepare TTS request
            synthesis_input = texttospeech.SynthesisInput(text=hebrew_text)
            
            # Voice config - Hebrew
            voice = texttospeech.VoiceSelectionParams(
                language_code="he-IL",
                name="he-IL-Wavenet-A",  # Hebrew female voice
                ssml_gender=texttospeech.SsmlVoiceGender.FEMALE,
            )
            
            # Audio config
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.MP3,
                pitch=0.0,
                speaking_rate=0.8,  # Slightly slower for kids
            )
            
            # Generate audio
            response = client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config,
            )
            
            # Save to file
            output_path = os.path.join(output_dir, f"{filename}.mp3")
            with open(output_path, "wb") as out:
                out.write(response.audio_content)
            
            print(f"✅ {filename:10} → {hebrew_text} ({output_path})")
            success_count += 1
            
        except Exception as e:
            print(f"❌ {filename:10} → Error: {str(e)}")
    
    print(f"\n🎉 Done! Generated {success_count}/{len(HEBREW_LETTERS)} files")
    return success_count == len(HEBREW_LETTERS)

if __name__ == "__main__":
    success = generate_audio_files()
    exit(0 if success else 1)
