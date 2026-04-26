#!/usr/bin/env python
"""
Diagnostic Script - Tests all backend dependencies and services
Run this BEFORE trying to start the main backend
"""

import sys
import subprocess
from pathlib import Path

print("\n" + "="*80)
print("STUDENT STRESS APP - BACKEND DIAGNOSTIC")
print("="*80)

# Test 1: Python version
print("\n[TEST 1] Python Installation")
print(f"  Python: {sys.version}")
print(f"  Location: {sys.executable}")
print("  ✅ PASSED")

# Test 2: Check required packages
print("\n[TEST 2] Required Packages")
required_packages = {
    'fastapi': 'FastAPI Web Framework',
    'uvicorn': 'ASGI Server',
    'tensorflow': 'TensorFlow (YAMNet)',
    'tensorflow_hub': 'TensorFlow Hub Models',
    'numpy': 'NumPy',
    'python-multipart': 'File Upload Support',
    'scikit-learn': 'Scikit-learn (Random Forest)',
    'joblib': 'Model Serialization',
    'langchain': 'LangChain Framework',
    'langgraph': 'LanGraph Orchestration',
    'langchain_google_genai': 'Google Gemini Integration',
    'python-dotenv': 'Environment Variables',
}

missing_packages = []
for package, description in required_packages.items():
    try:
        __import__(package)
        print(f"  ✅ {package:<25} - {description}")
    except ImportError as e:
        print(f"  ❌ {package:<25} - {description} (MISSING)")
        missing_packages.append(package)

if missing_packages:
    print(f"\n  [ERROR] Missing {len(missing_packages)} packages!")
    print(f"  Run: pip install {' '.join(missing_packages)}")
    print(f"  Or:  pip install -r requirements.txt")
    sys.exit(1)
else:
    print("  ✅ PASSED - All packages installed")

# Test 3: Check .env file
print("\n[TEST 3] Environment Configuration (.env)")
env_file = Path('.env')
if env_file.exists():
    with open('.env', 'r') as f:
        content = f.read()
        if 'GOOGLE_API_KEY' in content:
            # Hide the actual key for security
            print(f"  ✅ .env file found")
            print(f"  ✅ GOOGLE_API_KEY is set")
            print("  ✅ PASSED")
        else:
            print(f"  ❌ .env file missing GOOGLE_API_KEY")
            sys.exit(1)
else:
    print(f"  ❌ .env file not found at {env_file.absolute()}")
    sys.exit(1)

# Test 4: Import services individually
print("\n[TEST 4] Service Imports")

try:
    print("  [*] Importing YAMNet Service...")
    from yamnet_service import get_yamnet_service
    print("  ✅ YAMNet Service")
except Exception as e:
    print(f"  ❌ YAMNet Service: {e}")
    missing_packages.append("YAMNet")

try:
    print("  [*] Importing Digital Habits Service...")
    from digital_habits_service import get_digital_habits_service
    print("  ✅ Digital Habits Service")
except Exception as e:
    print(f"  ❌ Digital Habits Service: {e}")
    missing_packages.append("Digital Habits")

try:
    print("  [*] Importing Physical Activity Service...")
    from physical_activity_service import get_physical_activity_service
    print("  ✅ Physical Activity Service")
except Exception as e:
    print(f"  ❌ Physical Activity Service: {e}")
    missing_packages.append("Physical Activity")

try:
    print("  [*] Importing Recommendation Service...")
    from recommendation_service import get_recommendation_service
    print("  ✅ Recommendation Service")
except Exception as e:
    print(f"  ❌ Recommendation Service: {e}")
    missing_packages.append("Recommendation")

if not missing_packages:
    print("  ✅ PASSED - All services imported successfully")
else:
    print(f"  ❌ FAILED - {len(missing_packages)} services failed to import")
    print("\n[NEXT STEPS]")
    print("  1. Check Python error messages above")
    print("  2. Verify .env file has correct GOOGLE_API_KEY")
    print("  3. Run: pip install -r requirements.txt")
    print("  4. Try again")
    sys.exit(1)

# Test 5: Try to initialize FastAPI app
print("\n[TEST 5] FastAPI Application")
try:
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    
    app = FastAPI()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    @app.get('/health')
    async def health():
        return {"status": "OK"}
    
    print("  ✅ FastAPI app created successfully")
    print("  ✅ CORS middleware configured")
    print("  ✅ Health check endpoint registered")
    print("  ✅ PASSED")
except Exception as e:
    print(f"  ❌ FastAPI app creation failed: {e}")
    sys.exit(1)

# Test 6: Summary and recommendations
print("\n" + "="*80)
print("DIAGNOSTIC SUMMARY")
print("="*80)
print("\n✅ ALL TESTS PASSED!")
print("\n[NEXT STEPS]")
print("  1. Start the backend:")
print("     cd D:\\FYP\\after akilas model edit\\python")
print("     python main.py")
print("\n  2. In another terminal, start ngrok with PORT 8000:")
print("     ngrok http 8000")
print("     (NOT ngrok http 80!)")
print("\n  3. Your ngrok URL will look like:")
print("     https://xxxx-yyyy-zzzz.ngrok-free.dev")
print("\n  4. Test the health endpoint:")
print("     curl http://localhost:8000/health")
print("\n  5. Configure mobile app:")
print("     await backend.switchToNgrok('https://xxxx-yyyy-zzzz.ngrok-free.dev')")
print("\n" + "="*80 + "\n")
