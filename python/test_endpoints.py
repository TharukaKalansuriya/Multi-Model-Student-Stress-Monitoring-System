#!/usr/bin/env python
"""
Backend Endpoint Tester - Tests all score-generating endpoints
Run this AFTER the backend is started and working
"""

import requests
import json
import time

BASE_URL = "http://localhost:8000"

print("\n" + "="*80)
print("BACKEND ENDPOINT TESTER - Score Generation")
print("="*80)

def test_health():
    """Test health endpoint"""
    print("\n[TEST 1] Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print("  ✅ Backend is running")
            data = response.json()
            print(f"  Status: {data.get('status')}")
            print(f"  Port: {data.get('port')}")
            return True
        else:
            print(f"  ❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"  ❌ Connection error: {e}")
        return False

def test_config():
    """Test config endpoint"""
    print("\n[TEST 2] Configuration")
    try:
        response = requests.get(f"{BASE_URL}/config", timeout=5)
        if response.status_code == 200:
            print("  ✅ Config endpoint working")
            data = response.json()
            services = data.get('services', {})
            for service, model in services.items():
                print(f"    • {service}: {model}")
            return True
        else:
            print(f"  ❌ Config failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def test_recommendations():
    """Test recommendations with different score levels"""
    print("\n[TEST 3] Recommendations (Score Generation)")
    
    test_cases = [
        ("LOW", {"audio_score": 20, "digital_score": 25, "physical_score": 15}),
        ("MODERATE", {"audio_score": 45, "digital_score": 55, "physical_score": 40}),
        ("HIGH", {"audio_score": 75, "digital_score": 80, "physical_score": 70}),
    ]
    
    for level, payload in test_cases:
        print(f"\n  [{level} STRESS] Testing with scores: {payload}")
        try:
            start = time.time()
            response = requests.post(
                f"{BASE_URL}/get-recommendations",
                json=payload,
                timeout=45
            )
            elapsed = time.time() - start
            
            if response.status_code == 200:
                data = response.json()
                stress = data.get('stress_analysis', {})
                recs = data.get('recommendations', [])
                
                print(f"    ✅ Success ({elapsed:.1f}s)")
                print(f"      Stress Level: {stress.get('level').upper()}")
                print(f"      Primary: {stress.get('primary_stressor').upper()}")
                print(f"      Recommendations: {len(recs)} generated")
                
                for i, rec in enumerate(recs, 1):
                    print(f"        {i}. {rec.get('title')}")
            else:
                print(f"    ❌ Failed: {response.status_code}")
                print(f"       {response.text[:100]}")
                
        except requests.exceptions.Timeout:
            print(f"    ⚠️  Timeout (Gemini API is slow, fallback used)")
        except Exception as e:
            print(f"    ❌ Error: {e}")

def test_digital_habits():
    """Test digital habits analysis"""
    print("\n[TEST 4] Digital Habits Analysis")
    payload = {
        "user_id": "test_user",
        "unlocks": 12,
        "screen_time": 180,
        "call_log": 3,
        "messages": 15,
        "late_night_usage": False,
        "app_usage": [
            {"app": "YouTube", "time_ms": 600000, "category": "Entertainment"},
            {"app": "WhatsApp", "time_ms": 300000, "category": "Communication"},
            {"app": "Gmail", "time_ms": 120000, "category": "Academic"}
        ]
    }
    
    print(f"  Payload: Screen time={payload['screen_time']}min, Unlocks={payload['unlocks']}")
    try:
        response = requests.post(
            f"{BASE_URL}/analyze-digital-habits",
            json=payload,
            timeout=15
        )
        
        if response.status_code == 200:
            data = response.json()
            score = data.get('digital_score', 0)
            print(f"  ✅ Digital Score Generated: {score}°")
            
            components = data.get('components', {})
            print(f"     Components:")
            for comp, val in components.items():
                print(f"       • {comp}: {val}°")
        else:
            print(f"  ❌ Failed: {response.status_code}")
            print(f"     {response.text[:100]}")
            
    except Exception as e:
        print(f"  ❌ Error: {e}")

def test_movement_analysis():
    """Test movement analysis"""
    print("\n[TEST 5] Physical Activity Analysis")
    payload = {
        "user_id": "test_user",
        "acc_x": 0.5,
        "acc_y": 9.8,
        "acc_z": 0.3,
        "gyro_x": 0.01,
        "gyro_y": 0.02,
        "gyro_z": 0.01,
        "activity_history": ["SITTING", "SITTING", "STANDING", "WALKING"],
        "sitting_duration_minutes": 45
    }
    
    print(f"  Testing with activity history: {payload['activity_history']}")
    try:
        response = requests.post(
            f"{BASE_URL}/analyze-movement",
            json=payload,
            timeout=15
        )
        
        if response.status_code == 200:
            data = response.json()
            activity = data.get('activity', 'UNKNOWN')
            score = data.get('physical_stress_score', 0)
            
            print(f"  ✅ Physical Activity Analysis Generated")
            print(f"     Activity Detected: {activity}")
            print(f"     Physical Score: {score}°")
            print(f"     Intensity: {data.get('movement_intensity', 0)}%")
        else:
            print(f"  ❌ Failed: {response.status_code}")
            print(f"     {response.text[:100]}")
            
    except Exception as e:
        print(f"  ❌ Error: {e}")

def main():
    """Run all tests"""
    print("\nStarting endpoint tests...")
    print("Make sure backend is running: python main.py\n")
    
    # Test 1: Health
    if not test_health():
        print("\n❌ BACKEND NOT RUNNING!")
        print("Start it with: python main.py")
        return
    
    # Test 2: Config
    test_config()
    
    # Test 3: Score Generation
    test_recommendations()
    
    # Test 4: Digital Habits
    test_digital_habits()
    
    # Test 5: Movement
    test_movement_analysis()
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    print("\nAll tests completed! Check results above.")
    print("\nIf any endpoint failed:")
    print("  1. Check backend console for errors")
    print("  2. Verify .env file has GOOGLE_API_KEY")
    print("  3. Run diagnose_backend.py for package check")
    print("\n" + "="*80 + "\n")

if __name__ == "__main__":
    main()
