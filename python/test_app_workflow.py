#!/usr/bin/env python3
"""
Complete test workflow simulating the mobile app flow
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

def test_complete_workflow():
    print("\n" + "="*70)
    print("COMPLETE APP WORKFLOW TEST")
    print("="*70)
    print(f"Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Step 1: Start Collection
    print("[Step 1] Start Collection")
    print("-" * 70)
    try:
        payload = {"user_id": "test_student"}
        r = requests.post(f"{BASE_URL}/start-automated-collection", json=payload, timeout=5)
        print(f"✓ Status: {r.status_code}")
        print(f"  Message: {r.json().get('message', 'OK')}\n")
    except Exception as e:
        print(f"✗ Error: {e}\n")
        return
    
    # Step 2: Get Daily Summary (before 00:00)
    print("[Step 2] Get Daily Summary")
    print("-" * 70)
    try:
        payload = {"user_id": "test_student"}
        r = requests.post(f"{BASE_URL}/get-daily-summary", json=payload, timeout=5)
        summary_data = r.json()
        print(f"✓ Status: {r.status_code}")
        print(f"  Ready for Recommendations: {summary_data.get('ready_for_recommendations', False)}\n")
    except Exception as e:
        print(f"✗ Error: {e}\n")
    
    # Step 3: Test Individual Endpoints
    print("[Step 3] Test Individual Stress Analyzers")
    print("-" * 70)
    
    # 3a: Audio Analysis
    print("  [3a] Audio Analysis (YAMNet):")
    try:
        import tempfile, struct
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
            sample_rate = 16000
            duration = 1
            num_samples = sample_rate * duration
            wav_header = b'RIFF'
            file_size = 36 + num_samples * 2
            wav_header += struct.pack('<I', file_size)
            wav_header += b'WAVE'
            wav_header += b'fmt '
            wav_header += struct.pack('<I', 16)
            wav_header += struct.pack('<HHIIHH', 1, 1, sample_rate, sample_rate * 2, 2, 16)
            wav_header += b'data'
            wav_header += struct.pack('<I', num_samples * 2)
            f.write(wav_header)
            f.write(b'\x00' * (num_samples * 2))
            temp_path = f.name
        
        with open(temp_path, 'rb') as audio_file:
            files = {'audio_file': audio_file}
            r = requests.post(f"{BASE_URL}/analyze-audio", files=files, timeout=10)
        
        audio_score = r.json().get('audio_score', 0)
        print(f"    ✓ Audio Score: {audio_score}/100")
    except Exception as e:
        audio_score = 50
        print(f"    ✗ Error: {e} (using default 50)")
    
    # 3b: Digital Habits Analysis
    print("  [3b] Digital Habits Analysis:")
    try:
        payload = {
            "user_id": "test_student",
            "unlocks": 25,
            "screen_time": 240,
            "late_night_usage": False,
            "morning_rush": False,
            "call_log": 5,
            "messages": 30,
            "app_usage": [
                {"app": "YouTube", "time_ms": 600000},
                {"app": "Instagram", "time_ms": 450000}
            ]
        }
        r = requests.post(f"{BASE_URL}/analyze-digital-habits", json=payload, timeout=10)
        digital_score = r.json().get('digital_score', 0)
        print(f"    ✓ Digital Score: {digital_score}/100")
        print(f"      Components: {r.json().get('components', {})}")
    except Exception as e:
        digital_score = 50
        print(f"    ✗ Error: {e} (using default 50)")
    
    # 3c: Physical Activity Analysis  
    print("  [3c] Physical Activity Analysis:")
    try:
        payload = {
            "user_id": "test_student",
            "acc_x": 0.5,
            "acc_y": 9.8,
            "acc_z": 0.3,
            "gyro_x": 0.01,
            "gyro_y": 0.02,
            "gyro_z": 0.01,
            "activity_history": ["SITTING", "SITTING", "STANDING", "WALKING"],
            "sitting_duration_minutes": 45
        }
        r = requests.post(f"{BASE_URL}/analyze-movement", json=payload, timeout=10)
        physical_score = r.json().get('physical_stress_score', 0)
        print(f"    ✓ Physical Score: {physical_score}/100")
    except Exception as e:
        physical_score = 50
        print(f"    ✗ Error: {e} (using default 50)")
    
    # Step 4: Get Recommendations with All Three Scores
    print("\n[Step 4] Get AI Recommendations (With All Scores)")
    print("-" * 70)
    print(f"Scores being sent:")
    print(f"  - Audio: {audio_score}")
    print(f"  - Digital: {digital_score}")
    print(f"  - Physical: {physical_score}\n")
    
    try:
        payload = {
            "audio_score": int(audio_score),
            "digital_score": int(digital_score),
            "physical_score": int(physical_score)
        }
        print(f"Sending payload: {json.dumps(payload)}\n")
        
        r = requests.post(f"{BASE_URL}/get-recommendations", json=payload, timeout=120)
        
        if r.status_code == 200:
            data = r.json()
            print(f"✓ Status: {r.status_code}")
            print(f"\nStress Analysis:")
            print(f"  Level: {data['stress_analysis']['level'].upper()}")
            print(f"  Category: {data['stress_analysis']['category']}")
            print(f"  Primary Stressor: {data['stress_analysis']['primary_stressor'].upper()}")
            
            recs = data.get('recommendations', [])
            print(f"\nRecommendations ({len(recs)} total):")
            for i, rec in enumerate(recs, 1):
                print(f"\n  {i}. {rec.get('title', 'Recommendation')}")
                print(f"     Action: {rec.get('action', 'N/A')[:60]}...")
                print(f"     Duration: {rec.get('duration', 'N/A')}")
                print(f"     Priority: {rec.get('priority', 'N/A').upper()}")
                print(f"     Benefit: {rec.get('benefit', 'N/A')[:50]}...")
                
                # Check if this is a fallback (hardcoded) recommendation
                fallback_titles = ['Find a Quiet Space', 'Use Noise Canceling', 'Phone Disconnect Challenge', 
                                  'Quick Movement Break', 'Gym or Exercise Session']
                is_fallback = rec.get('title', '') in fallback_titles
                status = "FALLBACK" if is_fallback else "AI-GENERATED"
                print(f"     Status: {status}")
        else:
            print(f"✗ Error Status: {r.status_code}")
            print(f"Response: {r.text[:300]}")
            
    except requests.exceptions.Timeout:
        print("✗ Request timed out - Gemini API taking too long")
    except Exception as e:
        print(f"✗ Error: {type(e).__name__}: {e}")
    
    print("\n" + "="*70)
    print("TEST COMPLETE")
    print("="*70 + "\n")

if __name__ == "__main__":
    test_complete_workflow()
