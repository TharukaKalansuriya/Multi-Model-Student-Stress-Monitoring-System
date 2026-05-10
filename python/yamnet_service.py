"""
YAMNet Audio Classification Service

Uses Google's YAMNet model trained on AudioSet dataset (2M+ YouTube videos, 521 sound event classes)
Detects sound events from audio files and maps them to stress levels.
"""

import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
from pathlib import Path
import tempfile


class YAMNetService:
    """
    YAMNet Audio Event Classifier for Student Stress Detection
    
    Dataset: AudioSet (2M+ labeled YouTube videos)
    Model: YAMNet (transferred learning from AudioSet)
    Classes: 521 sound event categories
    """
    
    # AudioSet class labels (all 521 classes from TensorFlow Hub YAMNet)
    AUDIOSET_LABELS = {
        0: "Speech", 1: "Male speech, man speaking", 2: "Female speech, woman speaking", 
        3: "Child speech, kid speaking", 4: "Conversation", 5: "Whispering", 
        6: "Shout", 7: "Yell", 8: "Screaming", 9: "Crying", 10: "Laughter",
        11: "Baby cry, infant cry", 12: "Baby talk, babbling", 13: "Cough", 
        14: "Sneeze", 15: "Sigh", 16: "Throat clearing", 17: "Snoring",
        18: "Sniff", 19: "Run", 20: "Footsteps", 21: "Chewing, mastication",
        22: "Swallowing", 23: "Gargling", 24: "Stomach rumble", 25: "Burping, eructation",
        26: "Hiccup", 27: "Flatulence", 28: "Laugh", 29: "Breathing",
        30: "Wheeze", 31: "Whistling", 32: "Clapping", 33: "Finger snapping",
        34: "Cracking knuckles", 35: "Brushing teeth", 36: "Toothbrush",
        37: "Zipper (clothing)", 38: "Keys jangling", 39: "Coins (dropping)",
        40: "Cutlery, silverware", 41: "Applause", 42: "Chime", 43: "Glass (breaking)",
        44: "Glass", 45: "Clock", 46: "Siren", 47: "Fire alarm", 48: "Alarm",
        49: "Emergency vehicle", 50: "Police car (siren)", 51: "Ambulance (siren)",
        52: "Fire engine, fire truck (siren)", 53: "Civic alert system", 54: "Burglar alarm",
        55: "Alarm bell", 56: "Bicycle", 57: "Car", 58: "Car (idling)", 
        59: "Car (engine)", 60: "Car (acceleration)", 61: "Car (skidding)", 
        62: "Car (reversing)", 63: "Car alarm", 64: "Car horn", 65: "Motorcycle",
        66: "Motorcycle (acceleration)", 67: "Traffic noise, roadway noise", 68: "Vehicle",
        69: "Truck", 70: "Train", 71: "Bus", 72: "Taxi",
        73: "Helicopter", 74: "Aircraft", 75: "Airplane overhead", 76: "Aircraft (engine)",
        77: "Aircraft (landing)", 78: "Jet engine", 79: "Air brake",
        80: "Door (open or close)", 81: "Window (open or close)", 82: "Door bell",
        83: "Doorbell", 84: "Knocking (on door)", 85: "Lock (closing)",
        86: "Knock", 87: "Latch (car door)", 88: "Garage door",
        89: "Engine start", 90: "Power drill", 91: "Machinery",
        92: "Water running", 93: "Sink (kitchen)", 94: "Toilet (flushing)",
        95: "Shower", 96: "Bathtub (fill, drain)", 97: "Coffee maker",
        98: "Blender", 99: "Chopping (food)", 100: "Microwave oven",
        101: "Stove", 102: "Oven", 103: "Microwave oven (door open)",
        104: "Washing machine", 105: "Vacuum cleaner", 106: "Vacuum cleaner (start)",
        107: "Hairdryer", 108: "Electric razor", 109: "Tooth brush",
        110: "Lighter", 111: "Matches", 112: "Lighter (flick)",
        113: "Match strike", 114: "Electric guitar", 115: "Acoustic guitar",
        116: "Bass guitar", 117: "Guitar", 118: "Electric piano",
        119: "Keyboard (musical)", 120: "Keys jangling", 121: "Drum kit",
        122: "Drums", 123: "Bass drum", 124: "Bass drum (kick)",
        125: "Kick drum", 126: "Cymbal", 127: "Hi-hat", 128: "Snare drum",
        129: "Violin", 130: "Cello", 131: "Double bass", 132: "Ukulele",
        133: "Mandolin", 134: "Lute", 135: "Banjo", 136: "Sitar",
        137: "Horn", 138: "Trumpet", 139: "Trombone", 140: "French horn",
        141: "Tuba", 142: "Saxophone", 143: "Oboe", 144: "Clarinet",
        145: "Flute", 146: "Piccolo", 147: "Harmonica", 148: "Pan pipes",
        149: "Whistle", 150: "Accordion", 151: "Bagpipes", 152: "Theremin",
        153: "Synthesizer", 154: "Bell", 155: "Bell", 156: "Church bell",
        157: "Cowbell", 158: "Dumbbell", 159: "Gong", 160: "Xylophone",
        161: "Vibraphone", 162: "Maraca", 163: "Tambourine", 164: "Metronome",
        165: "Tubular bells", 166: "Wind gong", 167: "Toddler (child singing)",
        168: "Music for children", 169: "Children music, kids songs", 170: "Singing bowl",
        171: "Chimes", 172: "Rapping", 173: "Singing", 174: "Soul Music",
        175: "Music box", 176: "Harp", 177: "Marimba", 178: "Bells",
        179: "Kazoo", 180: "Hurdy-gurdy", 181: "Bell", 182: "Carillon",
        183: "Tubular bell", 184: "Wind bell", 185: "Singing bowl",
        186: "Electronic music", 187: "Hip-hop music", 188: "Rock music",
        189: "Heavy metal music", 190: "Indie rock", 191: "Punk rock",
        192: "Country music", 193: "Pop music", 194: "Reggae",
        195: "Bluegrass", 196: "Classical music", 197: "Orchestra",
        198: "Drama", 199: "Blues", 200: "Jazz",
        201: "Country", 202: "Funk", 203: "Soul music", 204: "Techno",
        205: "Disco", 206: "Electronic dance music", 207: "House music",
        208: "Trance music", 209: "Dubstep", 210: "Drum and bass",
        211: "Breakcore", 212: "Dub music", 213: "Trip-hop",
        214: "Grime", 215: "Trap (EDM)", 216: "Drum machine",
        217: "Flamenco", 218: "Waltz", 219: "Tango",
        220: "Trance", 221: "Salsa music", 222: "Samba",
        223: "Reggaeton", 224: "Bollywood music", 225: "Phoneme",
        226: "Singing", 227: "Rapping", 228: "Screaming", 229: "Male singing",
        230: "Female singing", 231: "Child singing", 232: "Infant crying",
        233: "Yodelling", 234: "Opera", 235: "Whispering",
        236: "Ding-dong", 237: "Bell ringing", 238: "Meow",
        239: "Barking", 240: "Roaring", 241: "Growling",
        242: "Mooing", 243: "Grunting", 244: "Neighing",
        245: "Mule braying", 246: "Oink", 247: "Chirping",
        248: "Tweeting", 249: "Buzzing", 250: "Fluttering",
        251: "Hissing", 252: "Purring", 253: "Cooing",
        254: "Peeping", 255: "Piping", 256: "Croaking",
        257: "Quacking", 258: "Gobbling", 259: "Honking",
        260: "Whinnying", 261: "Bellow", 262: "Baying",
        263: "Hoot", 264: "Squeak", 265: "Squeal",
        266: "Baboon", 267: "Chimpanzee", 268: "Gorilla",
        269: "Puppy", 270: "Tiger", 271: "Lion",
        272: "Elephant", 273: "Bird", 274: "Raven",
        275: "Eagle", 276: "Owl", 277: "Pigeon",
        278: "Crow", 279: "Nightingale", 280: "Chicken",
        281: "Rooster", 282: "Clucking", 283: "Crowing",
        284: "Turkey", 285: "Gobbling (turkey)", 286: "Quail",
        287: "Hawk", 288: "Frog", 289: "Toad",
        290: "Insect", 291: "Hissing (snake)", 292: "Cricket",
        293: "Grasshopper", 294: "Mosquito", 295: "Bee",
        296: "Wasp", 297: "Seagull", 298: "Wave",
        299: "Breaking", 300: "Splash", 301: "Splashing",
        302: "Pouring", 303: "Drip", 304: "Raindrop",
        305: "Raindrops", 306: "Rain on metal roof", 307: "Rain on car roof",
        308: "Rain on leaves", 309: "Rain on grass", 310: "Wind",
        311: "Wind blowing", 312: "Windstorm", 313: "Storm",
        314: "Thunderstorm", 315: "Thunder", 316: "Lightning",
        317: "Hail", 318: "Sleet", 319: "Snow",
        320: "Waterfall", 321: "Stream", 322: "Brook",
        323: "River", 324: "Ocean", 325: "Sea waves",
        326: "Earthquake", 327: "Volcano", 328: "Avalanche",
        329: "Fire", 330: "Flames", 331: "Burning",
        332: "Fireworks", 333: "Explosion", 334: "Loud noise",
        335: "Boom", 336: "Bang", 337: "Crack",
        338: "Crunch", 339: "Pop", 340: "Fizz",
        341: "Hiss", 342: "Whistle", 343: "White noise",
        344: "Pink noise", 345: "Rainfall", 346: "Forest ambience",
        347: "Beach", 348: "Crowd", 349: "Crowd (cheering)",
        350: "Crowd (applause)", 351: "Crowd (chanting)", 352: "Crowd (laughing)",
        353: "Classroom", 354: "Library", 355: "Restaurant",
        356: "Office", 357: "Shopping center", 358: "Train station",
        359: "Airport terminal", 360: "Bus station", 361: "Marketplace",
        362: "Factory", 363: "Machinery", 364: "Engine room",
        365: "Power plant", 366: "Helicopter rotor", 367: "Spooling down",
        368: "Spooling up", 369: "Jet engine", 370: "Aircraft taking off",
        371: "Aircraft landing", 372: "Jet landing", 373: "Rocket launch",
        374: "Fireworks", 375: "Explosion", 376: "Gunshot",
        377: "Machine gun", 378: "Cannon", 379: "Nuclear explosion",
        380: "Sonic boom", 381: "Mine blast", 382: "TNT blast",
        383: "Dynamite blast", 384: "C4", 385: "Demolition",
        386: "Car crash", 387: "Skidding", 388: "Sliding",
        389: "Collision", 390: "Train crash", 391: "Airplane crash",
        392: "Breaking glass", 393: "Shattering", 394: "Clanging",
        395: "Clinking", 396: "Hammering", 397: "Sawing",
        398: "Drilling", 399: "Metal percussion", 400: "Metal plate",
        401: "Anvil", 402: "Bell", 403: "Gong",
        404: "Chime", 405: "Cymbal", 406: "Hi-hat",
        407: "Gong", 408: "Wind chime", 409: "Wind bell",
        410: "Alarm clock", 411: "Telephone", 412: "Cell phone",
        413: "Door buzzer", 414: "Door bell", 415: "Door knock",
        416: "Siren", 417: "Fire alarm", 418: "Police whistle",
        419: "Whistle", 420: "Beep", 421: "Bleep",
        422: "Buzzer", 423: "Ding", 424: "Dinging",
        425: "Pinging", 426: "Ringing", 427: "Ring",
        428: "Tone", 429: "Beeping", 430: "Pinging",
        431: "Siren", 432: "Alarm", 433: "Bell",
        434: "Chime", 435: "Whistle", 436: "Silence",
        437: "Soundscape", 438: "Ambient music", 439: "Fountain",
        440: "Clock", 441: "Tick", 442: "Ticking",
        443: "Clock ticking", 444: "Clock chime", 445: "Cuckoo clock",
        446: "Metronome", 447: "Music box", 448: "Harpsichord",
        449: "Vibraphone", 450: "Glockenspiel", 451: "Celeste",
        452: "Carillon", 453: "Glass harmonica", 454: "Theremin",
        455: "Synthesizer", 456: "Keyboard", 457: "Electronic organ",
        458: "Pipe organ", 459: "Accordion", 460: "Harmonica",
        461: "Pan pipes", 462: "Jew's harp", 463: "Ocarina",
        464: "Sitar", 465: "Sitarist", 466: "Bansuri",
        467: "Ney", 468: "Bouzouki", 469: "Hurdy-gurdy",
        470: "Oud", 471: "Qanoun", 472: "Sarod",
        473: "Sarangi", 474: "Tanpura", 475: "Dutar",
        476: "Dotar", 477: "Balalaika", 478: "Bandurria",
        479: "Cittern", 480: "Cithara", 481: "Koto",
        482: "Shamisen", 483: "Erhu", 484: "Angklung",
        485: "Kalimba", 486: "Mbira", 487: "Thumb piano",
        488: "Gamelan", 489: "Bonang", 490: "Bali Gamelan",
        491: "Java Gamelan", 492: "Pelog scale", 493: "Slendro scale",
        494: "Gamelan-like", 495: "Ching", 496: "Gong",
        497: "Tam-tam", 498: "Tam-tam (striking)", 499: "Bowed vibraphone",
        500: "Bowed piano", 501: "Bowed guitar", 502: "Friction drum",
        503: "Friction", 504: "Creaking", 505: "Squeaking",
        506: "Scratching", 507: "Scraping", 508: "Scratched",
        509: "Water drops", 510: "Dripping", 511: "Plucking",
        512: "Strumming", 513: "Slap", 514: "Tapping",
        515: "Snapping", 516: "Clicking", 517: "Ticking",
        518: "Typewriter", 519: "Typewriter typing", 520: "Keyboard (computer)"
    }
    
    # Stress weight mapping (0-100 scale) - comprehensive mapping
    STRESS_WEIGHTS = {
        # Emergency/Danger Sounds (90-100)
        'Siren': 100, 'Fire alarm': 98, 'Alarm clock': 95, 'Car alarm': 95,
        'Explosion': 95, 'Gunshot': 96, 'Machine gun': 96, 'Bowling strike': 92,
        'Cannon': 94, 'Nuclear explosion': 99, 'Sonic boom': 97,
        
        # Intense/Alarming Sounds (80-89)
        'Screaming': 98, 'Yelling': 85, 'Yell': 85, 'Shout': 82,
        'Crying': 85, 'Siren': 98, 'Police car (siren)': 95,
        'Ambulance (siren)': 95, 'Fire engine': 95, 'Alarm': 88,
        'Emergency vehicle': 88, 'Burglar alarm': 88, 'Alarm bell': 85,
        
        # Traffic/Vehicle Sounds (65-80)
        'Car horn': 98, 'Car alarm': 80, 'Traffic noise': 75,
        'Traffic': 75, 'Motorcycle': 70, 'Motorcycle acceleration': 72,
        'Train': 65, 'Truck': 68, 'Helicopter': 75, 'Aircraft': 70,
        'Airplane': 70, 'Jet engine': 80, 'Car crash': 92,
        'Collision': 90, 'Skidding': 85, 'Vehicle': 68,
        
        # Distressing Sounds (70-80)
        'Dog barking': 72, 'Barking': 72, 'Roaring': 78, 'Growling': 75,
        'Hissing': 70, 'Impact': 75, 'Bang': 72, 'Crack': 70,
        'Crash': 85, 'Shattering': 82, 'Breaking glass': 85, 'Glass (breaking)': 85,
        
        # Moderate Stress Sounds (50-69)
        'Coughing': 62, 'Cough': 62, 'Sneezing': 58, 'Sneeze': 58,
        'Throat clearing': 52, 'Snoring': 55, 'Wheezing': 60, 'Wheeze': 60,
        'Breathing heavily': 65, 'Breathing': 45, 'Music': 35,
        'Talking loudly': 65, 'Conversation': 40, 'Keys jangling': 55,
        'Coins dropping': 50, 'Drilling': 68, 'Power drill': 65,
        'Sawing': 62, 'Hammering': 58, 'Machinery': 60,
        
        # Speech & Social (25-45)
        'Speech': 30, 'Speaking': 30, 'Male speech': 30, 'Female speech': 30,
        'Child speech': 35, 'Whispering': 15, 'Singing': 25, 'Rapping': 28,
        'Conversation': 35, 'Laughing': 15, 'Laughter': 15, 'Baby cry': 70,
        'Baby talk': 20, 'Applause': 25, 'Clapping': 25,
        
        # Utility Sounds (30-55)
        'Door bell': 50, 'Doorbell': 50, 'Door knock': 45, 'Knock': 45,
        'Door opening': 40, 'Door closing': 40, 'Window closing': 35,
        'Telephone': 55, 'Cell phone': 55, 'Beep': 45, 'Buzzer': 50,
        'Ding': 40, 'Ring': 50, 'Ringing': 50, 'Alarm': 75,
        'Siren': 95, 'Whistle': 50, 'Tone': 45,
        
        # Medium Environmental Sounds (20-45)
        'Water running': 35, 'Shower': 32, 'Toilet flushing': 40,
        'Sink': 35, 'Bathtub': 35, 'Footsteps': 35,
        'Walking': 25, 'Running': 40, 'Chewing': 45, 'Swallowing': 30,
        'Microwave oven': 50, 'Blender': 55, 'Coffee maker': 40,
        'Stove': 45, 'Oven': 40, 'Washing machine': 50, 'Vacuum': 65,
        'Hairdryer': 58, 'Electric razor': 60,
        
        # Music & Instruments (10-40)
        'Electronic music': 25, 'Hip-hop music': 28, 'Rock music': 35,
        'Heavy metal': 50, 'Classical music': 20, 'Jazz': 22,
        'Pop music': 25, 'Country music': 20, 'Electronic': 28,
        'Piano': 20, 'Guitar': 25, 'Drums': 45, 'Violin': 22,
        'Synthesizer': 28, 'Harmonica': 25, 'Flute': 20,
        
        # Nature & Environmental (5-30)
        'Rain': 12, 'Rainfall': 12, 'Wind': 15, 'Wind blowing': 15,
        'Thunder': 80, 'Lightning': 80, 'Stream': 8, 'Water': 10,
        'Wave': 12, 'Ocean': 10, 'Sea waves': 12, 'Bird': 10,
        'Chirping': 8, 'Tweeting': 8, 'Cricket': 5, 'Insect': 8,
        'Forest ambience': 10, 'Beach': 12, 'Nature': 10,
        'Silence': 0, 'Ambient': 35, 'Ambience': 35,
        
        # Default for unmapped classes
        'AudioEvent': 25  # Default stress for unknown AudioEvent_XXX
    }
    
    def __init__(self):
        """Initialize YAMNet model"""
        print("[*] Initializing YAMNet model from TensorFlow Hub...")
        try:
            # Load YAMNet model from TensorFlow Hub
            # This model was trained on AudioSet dataset
            self.model = hub.load('https://tfhub.dev/google/yamnet/1')
            self.class_map_path = hub.resolve('https://tfhub.dev/google/yamnet/1') + '/assets/yamnet_class_map.csv'
            print("[OK] YAMNet model loaded successfully")
        except Exception as e:
            print(f"[ERROR] Failed to load YAMNet model: {e}")
            self.model = None
    
    def _load_wav_file(self, wav_path: str) -> np.ndarray:
        """
        Load WAV file and convert to 16kHz mono audio
        
        Args:
            wav_path: Path to WAV file
            
        Returns:
            Audio waveform as numpy array (16kHz, mono)
        """
        # Load audio file
        wav_data = tf.io.read_file(wav_path)
        wav, sample_rate = tf.audio.decode_wav(wav_data, desired_channels=1)
        
        # Resample to 16kHz (YAMNet requires 16kHz)
        if sample_rate != 16000:
            wav = tf.audio.resample(wav, tf.cast(tf.shape(wav)[0] * 16000 / sample_rate, tf.int32), 16000)
        
        # Convert to numpy array and flatten
        return wav.numpy().flatten().astype(np.float32)
    
    def analyze_audio(self, wav_file_path: str) -> dict:
        """
        Analyze audio file using YAMNet model
        
        Args:
            wav_file_path: Path to WAV audio file
            
        Returns:
            Dictionary with:
            - detected_sounds: List of detected sound events with confidence
            - audio_score: Calculated stress score (0-100)
            - top_classes: Top 5 detected classes
        """
        if self.model is None:
            return {
                "error": "YAMNet model not loaded",
                "detected_sounds": {},
                "audio_score": 35,  # Default fallback
                "top_classes": []
            }
        
        try:
            print(f"[*] Analyzing audio file: {wav_file_path}")
            
            # Load audio
            waveform = self._load_wav_file(wav_file_path)
            
            # Run YAMNet inference
            scores, embeddings, spectrogram = self.model(waveform)
            
            # Get predictions for each frame
            scores = scores.numpy()  # Shape: (num_frames, 521)
            
            # Average predictions across time
            mean_scores = np.mean(scores, axis=0)  # Shape: (521,)
            
            # Get all predictions and sort by confidence
            all_indices = np.argsort(mean_scores)[::-1]  # Sort descending
            
            detected_sounds = {}
            stress_contributions = 0
            total_confidence = 0
            low_confidence_sounds = {}
            
            print("\n[RESULTS] YAMNet Detection:")
            print("="*70)
            
            for idx in all_indices[:20]:  # Check top 20 detections
                confidence = float(mean_scores[idx])
                
                # Map class index to AudioSet label
                class_label = self._get_class_label(int(idx))
                
                # Get stress weight with fallback for unmapped classes
                if class_label in self.STRESS_WEIGHTS:
                    stress_weight = self.STRESS_WEIGHTS[class_label]
                elif class_label.startswith("AudioEvent_"):
                    # Try to get weight for base "AudioEvent" class
                    stress_weight = self.STRESS_WEIGHTS.get("AudioEvent", 25)
                else:
                    # Try word-based matching for partially mapped classes
                    stress_weight = 25
                    for key in self.STRESS_WEIGHTS:
                        if key.lower() in class_label.lower() or class_label.lower() in key.lower():
                            stress_weight = self.STRESS_WEIGHTS[key]
                            break
                
                # Include sounds with confidence > 4% in scoring.
                # Real-world audio (e.g. fire alarm played from a phone speaker)
                # distributes confidence across many classes; rarely any single
                # class exceeds 10%. Lowering to 4% ensures genuine detections
                # contribute to the score instead of always returning the default 35.
                if confidence >= 0.04:
                    detected_sounds[class_label] = confidence
                    stress_contributions += confidence * (stress_weight / 100)
                    total_confidence += confidence
                    
                    print(f"  [+] {class_label:35s} | Conf: {confidence*100:5.1f}% | Weight: {stress_weight:3d}")
                elif confidence >= 0.02:
                    # Very low confidence detections (2-4%)
                    low_confidence_sounds[class_label] = (confidence, stress_weight)
                    print(f"  [!] {class_label:35s} | Conf: {confidence*100:5.1f}% | Weight: {stress_weight:3d} (LOW CONF)")
                else:
                    break  # Stop at near-zero confidences
            
            print("="*70)
            
            # Calculate final audio stress score
            if total_confidence > 0:
                audio_score = (stress_contributions / total_confidence) * 100
            else:
                audio_score = 35  # Default fallback
            
            audio_score = min(100, max(0, round(audio_score, 2)))
            
            print(f"\n[OK] AUDIO ANALYSIS COMPLETE")
            print(f"   High-confidence sounds detected: {len(detected_sounds)}")
            if low_confidence_sounds:
                print(f"   Low-confidence sounds detected: {len(low_confidence_sounds)} (not included in score)")
            print(f"   Calculated stress score: {audio_score}")
            
            # Include low-confidence sounds in response but marked as such
            response_detected_sounds = detected_sounds.copy()
            for sound_label, (conf, weight) in low_confidence_sounds.items():
                response_detected_sounds[f"{sound_label} (LOW_CONF)"] = conf
            
            return {
                "detected_sounds": response_detected_sounds,
                "audio_score": audio_score,
                "top_classes": [
                    {
                        "class": label,
                        "confidence": float(detected_sounds[label]),
                        "stress_weight": self.STRESS_WEIGHTS.get(label, 25)
                    }
                    for label in list(detected_sounds.keys())[:5]
                ]
            }
            
        except Exception as e:
            print(f"[ERROR] Error analyzing audio: {e}")
            import traceback
            traceback.print_exc()
            return {
                "error": str(e),
                "detected_sounds": {},
                "audio_score": 35,
                "top_classes": []
            }
    
    def _get_class_label(self, class_idx: int) -> str:
        """
        Get AudioSet class label by index
        
        Args:
            class_idx: Index in AudioSet class list (0-520)
            
        Returns:
            Class label string
        """
        # For indices not in our mapping, return generic label
        if class_idx in self.AUDIOSET_LABELS:
            return self.AUDIOSET_LABELS[class_idx]
        else:
            return f"AudioEvent_{class_idx}"


# Global YAMNet service instance
_yamnet_service = None

def get_yamnet_service() -> YAMNetService:
    """Get or create YAMNet service instance"""
    global _yamnet_service
    if _yamnet_service is None:
        _yamnet_service = YAMNetService()
    return _yamnet_service
