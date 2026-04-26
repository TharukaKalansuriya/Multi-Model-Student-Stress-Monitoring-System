#!/usr/bin/env python3
"""
Quick test script for mobile app backend connection
Run this to verify the backend is working correctly
"""

import requests
import json
import sys
from datetime import datetime

BACKEND_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("🔍 Testing health endpoint...")
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health check PASSED")
            print(f"   Response: {response.text}")
            return True
        else:
            print(f"❌ Health check FAILED: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check ERROR: {e}")
        return False

def test_digital_habits():
    """Test digital habits analysis endpoint"""
    print("\n🔍 Testing digital habits analysis...")
    
    data = {
        "user_id": "test_mobile_app",
        "unlocks": 45,
        "screen_time": 120,
        "app_usage": [],
        "call_log": 5,
        "messages": 10,
        "late_night_usage": False,
        "morning_rush": False
    }
    
    try:
        response = requests.post(
            f"{BACKEND_URL}/analyze-digital-habits",
            json=data,
            timeout=15
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Digital habits analysis PASSED")
            print(f"   Digital Score: {result.get('digital_score', 'N/A')}")
            print(f"   Status: {result.get('status', 'N/A')}")
            return True
        else:
            print(f"❌ Analysis FAILED: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Analysis ERROR: {e}")
        return False

def test_recommendations():
    """Test recommendations endpoint"""
    print("\n🔍 Testing recommendations endpoint...")
    
    data = {
        "audio_score": 50,
        "digital_score": 60,
        "physical_score": 40
    }
    
    try:
        response = requests.post(
            f"{BACKEND_URL}/get-recommendations",
            json=data,
            timeout=15
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Recommendations endpoint PASSED")
            recs = result.get('recommendations', [])
            print(f"   Recommendations returned: {len(recs)}")
            print(f"   Stress level: {result.get('stress_analysis', {}).get('level', 'N/A')}")
            return True
        else:
            print(f"❌ Endpoint FAILED: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Endpoint ERROR: {e}")
        return False

def main():
    print("=" * 60)
    print("MOBILE APP BACKEND CONNECTION TEST")
    print("=" * 60)
    print(f"🔗 Backend URL: {BACKEND_URL}")
    print(f"⏰ Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    results = {
        "health": test_health(),
        "digital_habits": test_digital_habits(),
        "recommendations": test_recommendations()
    }
    
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {test}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests PASSED! Backend is working correctly.")
        print("🚀 Mobile app should connect successfully.")
        return 0
    else:
        print("\n⚠️  Some tests FAILED. Check backend is running:")
        print("  cd d:\\FYP\\New folder\\python")
        print("  python main.py")
        return 1

if __name__ == "__main__":
    sys.exit(main())
