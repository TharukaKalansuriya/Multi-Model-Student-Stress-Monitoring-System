#!/usr/bin/env python3
"""
Quick System Verification Script
Verifies all components are working before running the main app
"""

import os
import sys
import subprocess
from pathlib import Path

def print_header(text):
    print("\n" + "="*70)
    print(f"  {text}")
    print("="*70)

def print_ok(text):
    print(f"✅ {text}")

def print_error(text):
    print(f"❌ {text}")

def print_warning(text):
    print(f"⚠️  {text}")

def print_info(text):
    print(f"ℹ️  {text}")

def check_env_file():
    """Check if .env file exists with API key"""
    print_header("1. Checking .env Configuration")
    
    env_path = Path(".env")
    
    if not env_path.exists():
        print_error(".env file not found!")
        print_info("Please create: .env")
        print_info("Content: GOOGLE_API_KEY=AIzaSy_YOUR_KEY_HERE")
        return False
    
    with open(env_path, 'r') as f:
        content = f.read()
    
    if "GOOGLE_API_KEY" not in content:
        print_error(".env file doesn't contain GOOGLE_API_KEY")
        return False
    
    if "YOUR_KEY_HERE" in content or "AIzaSy" not in content:
        print_error("GOOGLE_API_KEY value not set correctly")
        print_info("Go to https://ai.google.dev/ to get your key")
        return False
    
    print_ok(".env file configured correctly")
    return True

def check_dependencies():
    """Check if all required packages are installed"""
    print_header("2. Checking Python Dependencies")
    
    required_packages = [
        'fastapi',
        'uvicorn',
        'tensorflow',
        'tensorflow_hub',
        'numpy',
        'scikit-learn',
        'joblib',
        'langchain',
        'langgraph',
        'langchain_google_genai',
        'dotenv'
    ]
    
    missing = []
    for package in required_packages:
        try:
            __import__(package.replace('_', '-').split('-')[0] if '_' in package else package)
            print_ok(f"{package}")
        except ImportError:
            print_error(f"{package} - NOT INSTALLED")
            missing.append(package)
    
    if missing:
        print_warning(f"\nInstall missing packages:")
        print(f"  pip install {' '.join(missing)}")
        return False
    
    return True

def check_models():
    """Check if trained model files exist"""
    print_header("3. Checking Model Files")
    
    models_to_check = {
        "UCI HAR Random Forest": "uci_har_random_forest.pkl",
    }
    
    all_exist = True
    for name, filepath in models_to_check.items():
        if Path(filepath).exists():
            print_ok(f"{name}: {filepath}")
        else:
            print_warning(f"{name}: {filepath} (not found - will train if needed)")
    
    # Check if YAMNet will be downloaded
    print_info("YAMNet model: Will auto-download from TensorFlow Hub on first run (~100MB)")
    
    return True

def check_services():
    """Check if all service files exist"""
    print_header("4. Checking Service Files")
    
    services = {
        "Audio Service": "yamnet_service.py",
        "Digital Service": "digital_habits_service.py",
        "Physical Service": "physical_activity_service.py",
        "Recommendation Service": "recommendation_service.py",
        "Main Backend": "main.py"
    }
    
    all_exist = True
    for name, filepath in services.items():
        if Path(filepath).exists():
            print_ok(f"{name}: {filepath}")
        else:
            print_error(f"{name}: {filepath} - MISSING!")
            all_exist = False
    
    return all_exist

def check_port():
    """Check if port 8000 is available"""
    print_header("5. Checking Port Availability")
    
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('127.0.0.1', 8000))
        sock.close()
        
        if result == 0:
            print_warning("Port 8000 is already in use!")
            print_info("A server might already be running on this port")
            print_info("Either: kill the process or use a different port")
            return False
        else:
            print_ok("Port 8000 is available")
            return True
    except Exception as e:
        print_error(f"Could not check port: {e}")
        return False

def test_imports():
    """Test importing key modules"""
    print_header("6. Testing Module Imports")
    
    try:
        print_info("Importing fastapi...")
        import fastapi
        print_ok("FastAPI imported")
        
        print_info("Importing tensorflow...")
        import tensorflow
        print_ok("TensorFlow imported")
        
        print_info("Importing langgraph...")
        import langgraph
        print_ok("LanGraph imported")
        
        print_info("Importing recommendation service...")
        from recommendation_service import get_recommendation_service
        print_ok("Recommendation Service imported")
        
        return True
    except Exception as e:
        print_error(f"Import failed: {e}")
        return False

def print_next_steps():
    """Print next steps"""
    print_header("📋 Next Steps")
    
    print("\n1️⃣  If all checks passed:")
    print("   python main.py")
    print("   # Backend will start on http://127.0.0.1:8000")
    
    print("\n2️⃣  In another terminal, test it:")
    print("   curl http://localhost:8000/health")
    
    print("\n3️⃣  From Flutter app, call:")
    print("   POST http://YOUR_PC_IP:8000/get-recommendations")
    print("   {")
    print("     'audio_score': 45,")
    print("     'digital_score': 60,")
    print("     'physical_score': 35")
    print("   }")
    
    print("\nℹ️  To find YOUR_PC_IP:")
    print("   ipconfig | findstr 'IPv4'")

def main():
    print("\n")
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║     STUDENT STRESS APP - SYSTEM VERIFICATION CHECKLIST          ║")
    print("║     ML Models + Gemini AI Integration                           ║")
    print("╚══════════════════════════════════════════════════════════════════╝")
    
    checks = [
        ("Environment Configuration", check_env_file),
        ("Python Dependencies", check_dependencies),
        ("Model Files", check_models),
        ("Service Files", check_services),
        ("Port Availability", check_port),
        ("Module Imports", test_imports),
    ]
    
    results = {}
    for name, check_func in checks:
        try:
            results[name] = check_func()
        except Exception as e:
            print_error(f"Check failed: {e}")
            results[name] = False
    
    # Summary
    print_header("📊 Verification Summary")
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status}: {name}")
    
    print(f"\n  Total: {passed}/{total} checks passed")
    
    if passed == total:
        print("\n🎉 ALL SYSTEMS GO! Ready to launch backend!")
        print_next_steps()
        return 0
    else:
        print("\n⚠️  Some checks failed. Please fix issues above before proceeding.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
