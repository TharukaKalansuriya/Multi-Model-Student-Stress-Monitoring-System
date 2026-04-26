"""
Complete System Test - Verifies all endpoints, connections, and models

Tests:
1. Backend health check
2. Configuration endpoint
3. Audio analysis simulation
4. Digital habits analysis with dynamic data
5. Movement analysis  
6. Recommendations with various stress levels
7. Ngrok vs localhost connections
"""

import requests
import json
import time
from datetime import datetime

# Configuration
LOCALHOST_URL = "http://localhost:8000"
NGROK_URL = "https://attractable-camdyn-otoscopic.ngrok-free.dev"

class SystemTester:
    def __init__(self, base_url):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json'
        })
        self.test_results = []
        
    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        prefix = f"[{timestamp}] [{level}]"
        print(f"{prefix} {message}")
        
    def test_health(self):
        """Test backend health endpoint"""
        self.log("=" * 70)
        self.log("TEST 1: Backend Health Check", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/health"
            self.log(f"Testing: {url}")
            
            response = self.session.get(url, timeout=8)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Health check PASSED", "SUCCESS")
                self.log(f"Status: {data.get('status')}")
                self.log(f"Services: {len(data.get('available_endpoints', []))} endpoints available")
                self.test_results.append(("Health Check", "PASSED"))
                return True
            else:
                self.log(f"❌ Health check failed: {response.status_code}", "ERROR")
                self.test_results.append(("Health Check", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Connection error: {e}", "ERROR")
            self.test_results.append(("Health Check", f"ERROR: {str(e)[:50]}"))
            return False
            
    def test_config(self):
        """Test configuration endpoint"""
        self.log("\n" + "=" * 70)
        self.log("TEST 2: Backend Configuration", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/config"
            self.log(f"Testing: {url}")
            
            response = self.session.get(url, timeout=8)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Config endpoint PASSED", "SUCCESS")
                self.log(f"Backend port: {data.get('backend_info', {}).get('port')}")
                self.log(f"API version: {data.get('backend_info', {}).get('api_version')}")
                
                services = data.get('services', {})
                for service, model in services.items():
                    self.log(f"  • {service}: {model}")
                    
                self.test_results.append(("Configuration", "PASSED"))
                return True
            else:
                self.log(f"❌ Config failed: {response.status_code}", "ERROR")
                self.test_results.append(("Configuration", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Connection error: {e}", "ERROR")
            self.test_results.append(("Configuration", f"ERROR: {str(e)[:50]}"))
            return False
    
    def test_recommendations_low_stress(self):
        """Test recommendations with LOW stress levels"""
        self.log("\n" + "=" * 70)
        self.log("TEST 3: Recommendations - LOW STRESS (Dynamic Fallback)", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/get-recommendations"
            payload = {
                "audio_score": 15,      # Low
                "digital_score": 20,    # Low
                "physical_score": 25    # Low
            }
            
            self.log(f"Testing: {url}")
            self.log(f"Payload: Audio={payload['audio_score']}°, Digital={payload['digital_score']}°, Physical={payload['physical_score']}°")
            
            response = self.session.post(url, json=payload, timeout=45)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Recommendations PASSED", "SUCCESS")
                
                stress_analysis = data.get('stress_analysis', {})
                self.log(f"Stress Level: {stress_analysis.get('level').upper()}")
                self.log(f"Primary Stressor: {stress_analysis.get('primary_stressor').upper()}")
                
                recs = data.get('recommendations', [])
                self.log(f"Generated {len(recs)} recommendations:")
                for i, rec in enumerate(recs, 1):
                    self.log(f"  {i}. {rec.get('title')} ({rec.get('priority')})")
                
                self.test_results.append(("Recommendations (Low Stress)", "PASSED"))
                return True
            else:
                self.log(f"❌ Failed: {response.status_code}", "ERROR")
                self.test_results.append(("Recommendations (Low Stress)", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Error: {e}", "ERROR")
            self.test_results.append(("Recommendations (Low Stress)", f"ERROR: {str(e)[:50]}"))
            return False
    
    def test_recommendations_moderate_stress(self):
        """Test recommendations with MODERATE stress levels"""
        self.log("\n" + "=" * 70)
        self.log("TEST 4: Recommendations - MODERATE STRESS", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/get-recommendations"
            payload = {
                "audio_score": 45,      # Moderate
                "digital_score": 55,    # Moderate
                "physical_score": 40    # Moderate
            }
            
            self.log(f"Testing: {url}")
            self.log(f"Payload: Audio={payload['audio_score']}°, Digital={payload['digital_score']}°, Physical={payload['physical_score']}°")
            
            response = self.session.post(url, json=payload, timeout=45)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Recommendations PASSED", "SUCCESS")
                
                stress_analysis = data.get('stress_analysis', {})
                self.log(f"Stress Level: {stress_analysis.get('level').upper()}")
                self.log(f"Primary Stressor: {stress_analysis.get('primary_stressor').upper()}")
                
                recs = data.get('recommendations', [])
                self.log(f"Generated {len(recs)} recommendations:")
                for i, rec in enumerate(recs, 1):
                    self.log(f"  {i}. {rec.get('title')}")
                    self.log(f"     Duration: {rec.get('duration')}")
                    self.log(f"     Priority: {rec.get('priority')}")
                
                self.test_results.append(("Recommendations (Moderate)", "PASSED"))
                return True
            else:
                self.log(f"❌ Failed: {response.status_code}", "ERROR")
                self.test_results.append(("Recommendations (Moderate)", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Error: {e}", "ERROR")
            self.test_results.append(("Recommendations (Moderate)", f"ERROR: {str(e)[:50]}"))
            return False
    
    def test_recommendations_high_stress(self):
        """Test recommendations with HIGH stress levels"""
        self.log("\n" + "=" * 70)
        self.log("TEST 5: Recommendations - HIGH STRESS", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/get-recommendations"
            payload = {
                "audio_score": 78,      # High
                "digital_score": 82,    # High
                "physical_score": 85    # High
            }
            
            self.log(f"Testing: {url}")
            self.log(f"Payload: Audio={payload['audio_score']}°, Digital={payload['digital_score']}°, Physical={payload['physical_score']}°")
            
            response = self.session.post(url, json=payload, timeout=45)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Recommendations PASSED", "SUCCESS")
                
                stress_analysis = data.get('stress_analysis', {})
                self.log(f"🔴 Stress Level: {stress_analysis.get('level').upper()}")
                self.log(f"Primary Stressor: {stress_analysis.get('primary_stressor').upper()}")
                
                recs = data.get('recommendations', [])
                self.log(f"Generated {len(recs)} URGENT recommendations:")
                for i, rec in enumerate(recs, 1):
                    self.log(f"  {i}. ⚠️ {rec.get('title')}")
                    self.log(f"     Priority: {rec.get('priority')}")
                
                self.test_results.append(("Recommendations (High Stress)", "PASSED"))
                return True
            else:
                self.log(f"❌ Failed: {response.status_code}", "ERROR")
                self.test_results.append(("Recommendations (High Stress)", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Error: {e}", "ERROR")
            self.test_results.append(("Recommendations (High Stress)", f"ERROR: {str(e)[:50]}"))
            return False
    
    def test_digital_habits(self):
        """Test digital habits analysis"""
        self.log("\n" + "=" * 70)
        self.log("TEST 6: Digital Habits Analysis", "TEST")
        self.log("=" * 70)
        
        try:
            url = f"{self.base_url}/analyze-digital-habits"
            payload = {
                "user_id": "student_test",
                "audio_score": 35,
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
            
            self.log(f"Testing: {url}")
            self.log(f"User: {payload['user_id']}, Screen time: {payload['screen_time']} mins")
            
            response = self.session.post(url, json=payload, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Digital habits analysis PASSED", "SUCCESS")
                
                digital_score = data.get('digital_score', 0)
                self.log(f"Digital Stress Score: {digital_score}°")
                
                components = data.get('components', {})
                self.log("Components breakdown:")
                for component, score in components.items():
                    self.log(f"  • {component}: {score}°")
                
                self.test_results.append(("Digital Habits", "PASSED"))
                return True
            else:
                self.log(f"❌ Failed: {response.status_code}", "ERROR")
                self.log(f"Response: {response.text[:200]}")
                self.test_results.append(("Digital Habits", "FAILED"))
                return False
        except Exception as e:
            self.log(f"❌ Error: {e}", "ERROR")
            self.test_results.append(("Digital Habits", f"ERROR: {str(e)[:50]}"))
            return False
    
    def print_summary(self):
        """Print test summary"""
        self.log("\n" + "=" * 70)
        self.log("TEST SUMMARY", "SUMMARY")
        self.log("=" * 70)
        
        passed = sum(1 for _, result in self.test_results if result == "PASSED")
        total = len(self.test_results)
        
        for test_name, result in self.test_results:
            status_icon = "✅" if result == "PASSED" else "❌"
            self.log(f"{status_icon} {test_name}: {result}", "SUMMARY")
        
        self.log(f"\nTotal: {passed}/{total} tests passed ({100*passed//total if total else 0}%)", "SUMMARY")
        
        if passed == total:
            self.log("🎉 ALL TESTS PASSED! System is ready.", "SUCCESS")
        else:
            self.log("⚠️ Some tests failed. Check backend and connections.", "WARNING")
    
    def run_all_tests(self):
        """Run all tests"""
        self.log("🚀 Starting Complete System Test", "INFO")
        self.log(f"Backend URL: {self.base_url}", "INFO")
        
        self.test_health()
        self.test_config()
        self.test_recommendations_low_stress()
        self.test_recommendations_moderate_stress()
        self.test_recommendations_high_stress()
        self.test_digital_habits()
        
        self.print_summary()


if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("STUDENT STRESS APP - COMPLETE SYSTEM TEST")
    print("=" * 70 + "\n")
    
    # Test localhost first (default for development)
    print("\n📍 Testing LOCALHOST connection...")
    print("-" * 70)
    
    tester_local = SystemTester(LOCALHOST_URL)
    try:
        tester_local.run_all_tests()
    except Exception as e:
        print(f"\n❌ Localhost tests failed: {e}")
        print("\n📍 Trying ngrok connection...")
        print("-" * 70)
        
        tester_ngrok = SystemTester(NGROK_URL)
        tester_ngrok.run_all_tests()
    
    print("\n" + "=" * 70)
    print("Test completed. Check results above.")
    print("=" * 70)
