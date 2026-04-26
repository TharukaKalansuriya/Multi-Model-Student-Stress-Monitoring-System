#!/usr/bin/env python3
"""
Test all backend endpoints to verify they're working correctly
Run this after starting: python main.py
"""

import requests
import time
import json

BASE_URL = "http://localhost:8000"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def test_health():
    """Test health check endpoint"""
    print(f"\n{Colors.BLUE}[1/5] Testing /health endpoint...{Colors.END}")
    try:
        r = requests.get(f"{BASE_URL}/health", timeout=5)
        if r.status_code == 200:
            print(f"{Colors.GREEN}✓ Health check: OK (Status: {r.status_code}){Colors.END}")
            data = r.json()
            print(f"   Available endpoints: {len(data.get('available_endpoints', []))}")
            return True
        else:
            print(f"{Colors.RED}✗ Health check failed (Status: {r.status_code}){Colors.END}")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}")
        return False

def test_analyze_audio():
    """Test audio analysis endpoint"""
    print(f"\n{Colors.BLUE}[2/5] Testing /analyze-audio endpoint...{Colors.END}")
    try:
        # Create a dummy audio file
        import tempfile
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
            # Write minimal WAV header (silent 1-second audio at 16kHz)
            import struct
            sample_rate = 16000
            duration = 1
            num_samples = sample_rate * duration
            
            # WAV header
            wav_header = b'RIFF'
            file_size = 36 + num_samples * 2  # 2 bytes per sample (16-bit)
            wav_header += struct.pack('<I', file_size)
            wav_header += b'WAVE'
            wav_header += b'fmt '
            wav_header += struct.pack('<I', 16)  # Subchunk1Size
            wav_header += struct.pack('<HHIIHH', 1, 1, sample_rate, sample_rate * 2, 2, 16)  # PCM format
            wav_header += b'data'
            wav_header += struct.pack('<I', num_samples * 2)
            
            f.write(wav_header)
            f.write(b'\x00' * (num_samples * 2))  # Silent audio
            temp_path = f.name
        
        with open(temp_path, 'rb') as audio_file:
            files = {'audio_file': audio_file}
            r = requests.post(f"{BASE_URL}/analyze-audio", files=files, timeout=10)
        
        if r.status_code == 200:
            print(f"{Colors.GREEN}✓ Audio analysis: OK (Status: {r.status_code}){Colors.END}")
            data = r.json()
            print(f"   Audio Score: {data.get('audio_score', 'N/A')}")
            print(f"   Model: {data.get('model', 'N/A')}")
            return True
        else:
            print(f"{Colors.RED}✗ Audio analysis failed (Status: {r.status_code}){Colors.END}")
            print(f"   Response: {r.text[:200]}")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}")
        return False

def test_digital_habits():
    """Test digital habits analysis endpoint"""
    print(f"\n{Colors.BLUE}[3/5] Testing /analyze-digital-habits endpoint...{Colors.END}")
    try:
        payload = {
            "user_id": "test_student",
            "unlocks": 20,
            "screen_time": 300,
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
        
        if r.status_code == 200:
            print(f"{Colors.GREEN}✓ Digital habits analysis: OK (Status: {r.status_code}){Colors.END}")
            data = r.json()
            print(f"   Digital Score: {data.get('digital_score', 'N/A')}")
            print(f"   Stress Factors: {len(data.get('stress_factors', []))} identified")
            return True
        else:
            print(f"{Colors.RED}✗ Digital habits analysis failed (Status: {r.status_code}){Colors.END}")
            print(f"   Response: {r.text[:300]}")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}")
        return False

def test_daily_summary():
    """Test daily summary endpoint"""
    print(f"\n{Colors.BLUE}[4/5] Testing /get-daily-summary endpoint...{Colors.END}")
    try:
        # First start collection
        start_payload = {"user_id": "test_student"}
        requests.post(f"{BASE_URL}/start-automated-collection", json=start_payload, timeout=5)
        
        # Then get summary
        summary_payload = {"user_id": "test_student"}
        r = requests.post(f"{BASE_URL}/get-daily-summary", json=summary_payload, timeout=10)
        
        if r.status_code == 200:
            print(f"{Colors.GREEN}✓ Daily summary: OK (Status: {r.status_code}){Colors.END}")
            data = r.json()
            print(f"   Status: {data.get('status', 'N/A')}")
            print(f"   Collection Ready: {data.get('ready_for_recommendations', False)}")
            return True
        else:
            print(f"{Colors.RED}✗ Daily summary failed (Status: {r.status_code}){Colors.END}")
            print(f"   Response: {r.text[:300]}")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}")
        return False

def test_recommendations():
    """Test recommendations endpoint"""
    print(f"\n{Colors.BLUE}[5/5] Testing /get-recommendations endpoint...{Colors.END}")
    try:
        payload = {
            "audio_score": 45,
            "digital_score": 50,
            "physical_score": 55
        }
        
        r = requests.post(f"{BASE_URL}/get-recommendations", json=payload, timeout=30)
        
        if r.status_code == 200:
            print(f"{Colors.GREEN}✓ Recommendations: OK (Status: {r.status_code}){Colors.END}")
            data = r.json()
            print(f"   Status: {data.get('status', 'N/A')}")
            print(f"   Stress Level: {data.get('stress_analysis', {}).get('level', 'N/A').upper()}")
            recommendations = data.get('recommendations', [])
            print(f"   Recommendations Generated: {len(recommendations)}")
            if recommendations:
                for i, rec in enumerate(recommendations, 1):
                    print(f"      {i}. {rec.get('title', 'Recommendation')}")
            return True
        else:
            print(f"{Colors.RED}✗ Recommendations failed (Status: {r.status_code}){Colors.END}")
            print(f"   Response: {r.text[:300]}")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}")
        return False

def main():
    print(f"\n{Colors.YELLOW}{'='*60}")
    print("  BACKEND ENDPOINT TEST SUITE")
    print(f"{'='*60}{Colors.END}")
    print(f"Backend URL: {BASE_URL}")
    print(f"Test Time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Check if backend is running
    try:
        requests.get(f"{BASE_URL}/health", timeout=3)
    except:
        print(f"\n{Colors.RED}[ERROR] Backend is not responding at {BASE_URL}{Colors.END}")
        print("Make sure to run: python main.py")
        return
    
    results = {
        "Health": test_health(),
        "Digital Habits": test_digital_habits(),
        "Daily Summary": test_daily_summary(),
        "Recommendations": test_recommendations(),
        "Audio": test_analyze_audio(),
    }
    
    print(f"\n{Colors.YELLOW}{'='*60}")
    print("  TEST RESULTS SUMMARY")
    print(f"{'='*60}{Colors.END}")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for name, result in results.items():
        status = f"{Colors.GREEN}✓ PASS{Colors.END}" if result else f"{Colors.RED}✗ FAIL{Colors.END}"
        print(f"  {name:20} {status}")
    
    print(f"\n  {Colors.BLUE}Total: {passed}/{total} tests passed{Colors.END}")
    print(f"{Colors.YELLOW}{'='*60}{Colors.END}\n")
    
    if passed == total:
        print(f"{Colors.GREEN}✓ All endpoints are working! Backend is ready for mobile app.{Colors.END}\n")
    else:
        print(f"{Colors.RED}✗ Some endpoints failed. Check the output above for details.{Colors.END}\n")

if __name__ == "__main__":
    main()
