from fastapi import FastAPI, Request, HTTPException, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import tempfile
import os
from datetime import datetime, time
from yamnet_service import get_yamnet_service
from digital_habits_service import get_digital_habits_service
from physical_activity_service import get_physical_activity_service
from recommendation_service import get_recommendation_service

app = FastAPI()


# CORS CONFIGURATION - Support ngrok, localhost, and mobile app connections


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",  # Allow all origins (can be restricted later for security)
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Initialize services on startup
print("[*] Initializing FastAPI backend with YAMNet audio analysis...")
print("[*] Initializing Digital Habits analyzer...")
print("[*] Initializing Physical Activity analyzer (UCI HAR Dataset)...")
print("[*] Initializing Recommendation Engine (LanGraph + Google Gemini)...")
yamnet = get_yamnet_service()
digital_habits_analyzer = get_digital_habits_service()
physical_activity_analyzer = get_physical_activity_service()
recommendation_engine = get_recommendation_service()

# Global state (For MVP purposes; use a DB like SQLite for production)
user_stress_data = {
    "physical_risk": 0,
    "sedentary_minutes": 0,
    "audio_score": 0,
    "behavioral_score": 0,
    "digital_score": 0,
    "physical_score": 0
}

# Automated data collection state
automated_data_storage = {
    "student_001": {
        "daily_session": {
            "date": None,
            "audio_samples": [],
            "digital_data": {},
            "physical_data": {},
            "is_collection_active": False
        }
    }
}

def is_collection_time():
    """Check if current time is 00:00 (midnight) for daily data collection"""
    now = datetime.now()
    return now.hour == 0 and now.minute <= 1

def get_moderate_values():
    """Return moderate stress values for 00:00 collection"""
    return {
        "audio_score": 50,
        "digital_components": {
            "app_usage_score": 45,
            "screen_time_score": 50,
            "unlock_frequency_score": 48,
            "time_pattern_score": 52
        },
        "physical_components": {
            "activity": "MIXED",
            "physical_stress_score": 50,
            "movement_intensity": 45,
            "pattern_regularity": 55
        }
    }


# HEALTH CHECK & DEBUG ENDPOINTS


@app.get('/health')
async def health_check():
    """
    Simple health check endpoint to verify backend is running.
    Use this to test your ngrok tunnel or local connection.
    """
    return {
        "status": "OK",
        "message": "FastAPI backend is running successfully!",
        "timestamp": datetime.now().isoformat(),
        "port": 8000,
        "available_endpoints": [
            "GET /health",
            "POST /sync",
            "POST /start-automated-collection",
            "POST /stop-automated-collection",
            "POST /get-daily-summary",
            "POST /analyze-audio",
            "POST /analyze-digital-habits",
            "POST /physical_activity",
            "POST /get-recommendations"
        ]
    }

@app.get('/')
async def root():
    """Root endpoint for debugging"""
    return {"message": "Student Stress App Backend - FastAPI", "status": "running"}

# BACKEND CONFIGURATION ENDPOINT


@app.get('/config')
async def get_config():
    """
    Get backend configuration including supported URLs
    Use this endpoint to verify the backend is ready for connection
    """
    return {
        "status": "OK",
        "message": "Student Stress App Backend - Configuration",
        "backend_info": {
            "host": "0.0.0.0",
            "port": 8000,
            "api_version": "1.0",
            "supported_urls": [
                "http://localhost:8000 (Local Development)",
                "http://10.0.2.2:8000 (Android Emulator)",
                "http://192.168.x.x:8000 (Physical Device - replace with your IP)",
                "https://[ngrok-url].ngrok-free.dev (ngrok Tunnel)"
            ]
        },
        "services": {
            "audio_analysis": "YAMNet (TensorFlow Hub)",
            "digital_habits": "Rule-based Algorithm",
            "physical_activity": "Random Forest (UCI HAR)",
            "recommendations": "LanGraph + Google Gemini"
        },
        "endpoints": [
            "GET /health - System status",
            "POST /analyze-audio - Audio analysis",
            "POST /analyze-digital-habits - Digital stress analysis",
            "POST /analyze-movement - Physical activity analysis",
            "POST /get-recommendations - AI recommendations",
            "POST /sync-all - Sync all models",
            "GET /config - This endpoint"
        ]
    }

@app.post('/set-backend-url')
async def set_backend_url(request: Request):
    """
    Configure the backend URL (mostly for internal testing)
    This endpoint helps debug connection issues
    """
    try:
        data = await request.json()
        return {
            "status": "OK",
            "message": "Backend URL configuration endpoint active",
            "note": "Mobile app should use /health endpoint to verify connection",
            "current_endpoints": [
                f"http://0.0.0.0:8000",
                f"http://localhost:8000",
                f"http://10.0.2.2:8000"
            ]
        }
    except Exception as e:
        return {"status": "Error", "message": str(e)}


# AUTOMATED DATA COLLECTION ENDPOINTS


@app.post('/start-automated-collection')
async def start_automated_collection(request: Request):
    """
    Start automated data collection for a user
    
    Mobile app calls this when user presses 'Start Managing Stress' button
    Backend initializes collection state and triggers periodic collection
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "student_001")
        
        print(f"\n[*] Starting automated data collection for: {user_id}")
        
        # Initialize or reset collection state
        if user_id not in automated_data_storage:
            automated_data_storage[user_id] = {"daily_session": {}}
        
        automated_data_storage[user_id]["daily_session"] = {
            "date": datetime.now().strftime("%Y-%m-%d"),
            "audio_samples": [],
            "digital_data": {},
            "physical_data": {},
            "is_collection_active": True,
            "start_time": datetime.now().isoformat()
        }
        
        print(f"[OK] Collection started - Session initialized")
        
        return {
            "status": "Success",
            "message": "Automated data collection started",
            "user_id": user_id,
            "start_time": datetime.now().isoformat(),
            "collection_schedule": {
                "audio": "Every 3 hours",
                "daily_summary": "At 00:00 (midnight)",
                "digital_behavior": "Continuous",
                "physical_activity": "Continuous"
            }
        }
    except Exception as e:
        print(f"[ERROR] Failed to start collection: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post('/stop-automated-collection')
async def stop_automated_collection(request: Request):
    """
    Stop automated data collection for a user
    
    Mobile app calls this when user presses 'End Capturing Data' button
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "student_001")
        
        print(f"\n[*] Stopping automated collection for: {user_id}")
        
        if user_id in automated_data_storage:
            automated_data_storage[user_id]["daily_session"]["is_collection_active"] = False
            automated_data_storage[user_id]["daily_session"]["end_time"] = datetime.now().isoformat()
        
        print(f"[OK] Collection stopped - Data preserved for analysis")
        
        return {
            "status": "Success",
            "message": "Automated data collection stopped",
            "user_id": user_id,
            "end_time": datetime.now().isoformat(),
            "data_preserved": True
        }
    except Exception as e:
        print(f"[ERROR] Failed to stop collection: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post('/get-daily-summary')
async def get_daily_summary(request: Request):
    """
    Get daily stress summary with automatic moderate values at 00:00
    
    Called by mobile app when user presses 'Check My Stress Level' button
    
    Logic:
    - If time is 00:00 (±1 minute): Return moderate balanced values + collected data
    - Otherwise: Return latest available scores
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "student_001")
        
        is_midnight = is_collection_time()
        
        print(f"\n[*] Getting daily summary for: {user_id}")
        print(f"    Current time: {datetime.now().strftime('%H:%M:%S')}")
        print(f"    Is midnight (00:00): {is_midnight}")
        
        # Get stored collection data
        user_session = automated_data_storage.get(user_id, {}).get("daily_session", {})
        
        # If it's 00:00, provide moderate balanced values
        if is_midnight:
            print(f"[OK] Returning moderate values at 00:00 collection time")
            
            moderate_data = get_moderate_values()
            
            return {
                "status": "Success",
                "user_id": user_id,
                "timestamp": datetime.now().isoformat(),
                "collection_time": "00:00 - Daily Summary",
                "is_midnight_summary": True,
                "note": "All daily data collected - Moderate balanced values for recommendation system",
                "models": {
                    "environmental": {
                        "name": "Audio Analysis (YAMNet)",
                        "score": moderate_data["audio_score"],
                        "unit": "degrees (0-100)",
                        "status": "Moderate baseline"
                    },
                    "digital_habits": {
                        "name": "Digital Behavior Analysis",
                        "components": moderate_data["digital_components"],
                        "unit": "degrees (0-100)",
                        "status": "Moderate baseline"
                    },
                    "physical_activity": {
                        "name": "Physical Activity Analysis (UCI HAR)",
                        "activity": moderate_data["physical_components"]["activity"],
                        "scores": {
                            "physical_stress_score": moderate_data["physical_components"]["physical_stress_score"],
                            "movement_intensity": moderate_data["physical_components"]["movement_intensity"],
                            "pattern_regularity": moderate_data["physical_components"]["pattern_regularity"]
                        },
                        "unit": "degrees/percentage (0-100)",
                        "status": "Moderate baseline"
                    }
                },
                "collected_data_available": True,
                "ready_for_recommendations": True
            }
        else:
            # Outside of 00:00, return latest scores if available
            print(f"[OK] Returning latest available scores (not 00:00)")
            
            audio_score = user_session.get("audio_samples", [{}])[-1].get("score", 0) if user_session.get("audio_samples") else 0
            digital_data = user_session.get("digital_data", {})
            physical_data = user_session.get("physical_data", {})
            
            return {
                "status": "Success",
                "user_id": user_id,
                "timestamp": datetime.now().isoformat(),
                "collection_time": f"{datetime.now().strftime('%H:%M:%S')} - Interim Check",
                "is_midnight_summary": False,
                "note": "Complete analysis available at 00:00 (midnight)",
                "models": {
                    "environmental": {
                        "name": "Audio Analysis (YAMNet)",
                        "score": audio_score,
                        "unit": "degrees (0-100)",
                        "status": "Latest sample"
                    },
                    "digital_habits": {
                        "name": "Digital Behavior Analysis",
                        "components": digital_data.get("components", {}),
                        "unit": "degrees (0-100)",
                        "status": "Partial data"
                    },
                    "physical_activity": {
                        "name": "Physical Activity Analysis (UCI HAR)",
                        "activity": physical_data.get("activity", "Unknown"),
                        "scores": {
                            "physical_stress_score": physical_data.get("physical_stress_score", 0),
                            "movement_intensity": physical_data.get("movement_intensity", 0),
                            "pattern_regularity": physical_data.get("pattern_regularity", 0)
                        },
                        "unit": "degrees/percentage (0-100)",
                        "status": "Latest sample"
                    }
                },
                "collected_data_available": len(user_session) > 0,
                "ready_for_recommendations": False,
                "next_summary_at": "00:00 (midnight)"
            }
    except Exception as e:
        print(f"[ERROR] Error getting daily summary: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post('/sync')
async def receive_sync(request: Request):
    try:
        data = await request.json()
        user_id = data.get('user_id', 'unknown_student')
        
        # Pulling scores from Environmental and Behavioral models
        audio_score = data.get('audio_score', 0)
        behavioral_score = data.get('behavioral_score', 0)
        
        # Integration logic: Combining scores with the Sedentary Risk
        # Note: Behavioral model uses a 1.0 to 5.0 scale in your report [cite: 12]
        # Ensure Flutter scales this to 0-100 before sending!
        
        final_stress = (audio_score + behavioral_score + user_stress_data["physical_risk"]) / 3
        
        print(f"--- MULTIMODAL SYNC ---")
        print(f"User: {user_id} | Audio: {audio_score} | Behavioral: {behavioral_score} | Physical: {user_stress_data['physical_risk']}")
        
        return {
            "status": "Success",
            "final_stress": round(final_stress, 2),
            "physical_context": f"Sedentary for {user_stress_data['sedentary_minutes']} mins"
        }
    except Exception as e:
        print(f"Error processing sync: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

@app.post('/physical_activity')
async def process_activity(request: Request):
    """
    Handles 3rd Model: Physical Activity [cite: 23]
    Input: Statistical features (Mean, Min, Max) from 2.56s window 
    """
    data = await request.json()
    prediction = data.get('prediction') # 'Sitting', 'Laying', or 'Walking' [cite: 27]
    
    # Logic per Project Report [cite: 30, 31]
    if prediction in ['Sitting', 'Laying']:
        user_stress_data["sedentary_minutes"] += 1 # Assuming 1-min interval checks
        if user_stress_data["sedentary_minutes"] >= 60:
            user_stress_data["physical_risk"] = min(100, user_stress_data["physical_risk"] + 10)
    elif prediction == 'Walking':
        user_stress_data["sedentary_minutes"] = 0
        user_stress_data["physical_risk"] = max(0, user_stress_data["physical_risk"] - 5)

    return {"status": "Activity Updated", "current_risk": user_stress_data["physical_risk"]}

@app.post('/analyze-audio')
async def analyze_audio(audio_file: UploadFile = File(...)):
    """
    YAMNet Audio Analysis Endpoint
    
    Analyzes audio file using Google's YAMNet model trained on AudioSet dataset.
    Returns detected sound events and calculated stress score.
    
    Dataset: AudioSet (2M+ labeled YouTube videos, 521 sound event classes)
    Model: YAMNet (Google's trained neural network from TensorFlow Hub)
    
    Input: WAV audio file (PCM 16-bit, 16kHz, mono)
    Output: JSON with detected sounds and stress score
    """
    try:
        print(f"\n[*] Received audio file: {audio_file.filename}")
        
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp_path = tmp.name
            contents = await audio_file.read()
            tmp.write(contents)
        
        try:
            # Analyze audio using YAMNet
            print(f"[*] Running YAMNet inference on audio file...")
            analysis_result = yamnet.analyze_audio(tmp_path)
            
            response = {
                "status": "Success",
                "audio_score": analysis_result.get("audio_score", 35),
                "detected_sounds": analysis_result.get("detected_sounds", {}),
                "top_detected_events": analysis_result.get("top_classes", []),
                "model": "YAMNet (AudioSet)",
                "classes_detected": len(analysis_result.get("detected_sounds", {}))
            }
            
            print(f"[OK] Audio analysis response: {response}")
            return response
            
        finally:
            # Clean up temporary file
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
                
    except Exception as e:
        print(f"[ERROR] Error analyzing audio: {e}")
        raise HTTPException(
            status_code=400,
            detail=f"Failed to analyze audio: {str(e)}"
        )

@app.post('/analyze-digital-habits')
async def analyze_digital_habits(request: Request):
    """
    Analyze digital behavior patterns and calculate stress score
    
    NEW: Supports accumulated data from 3-hour collection cycles
    
    Expected JSON body (NEW FORMAT):
    {
        "user_id": "student_001",
        "audio_score": 45,                # Audio score from 3-hour audio capture
        "timestamp": "2026-04-18T15:50:26.865379",
        "sync_cycle_start": "2026-04-18T12:50:00.000000",
        "behavioral_data": {
            "unlocks": {
                "count": 45,
                "rate_per_hour": "15.0",
                "timestamps": ["2026-04-18T13:00:00Z", ...]
            },
            "screen_time": {
                "total_minutes": 180,
                "app_sessions": [
                    {"app": "YouTube", "duration_seconds": 900, "category": "Entertainment", ...},
                    ...
                ]
            },
            "calls": {"count": 5, "timestamps": [...]},
            "messages": {"count": 23, "timestamps": [...]},
            "late_night_usage": {"detected": false, "periods": []},
            "app_usage": [
                {"app": "YouTube", "time_ms": 1200000, "category": "Entertainment"},
                ...
            ]
        }
    }
    
    Returns:
    {
        "status": "Success",
        "digital_score": 45.2,
        "components": {detailed breakdown},
        "stress_factors": [list],
        "behavior_analysis": "...",
        "recommendations": [list],
        "sync_cycle": {
            "start": "2026-04-18T12:50:00.000000",
            "audio_score": 45,
            "data_collection_duration_hours": 3.0
        }
    }
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "unknown_user")
        
        print(f"\n[*] Analyzing digital habits for: {user_id}")
        
        # Extract behavioral data (handles both accumulated and legacy formats)
        behavioral_data = data.get("behavioral_data", {})
        
        if behavioral_data:
            # NEW FORMAT: Accumulated data from 3-hour cycle
            print(f"   [NEW FORMAT] Using accumulated behavioral data from 3-hour cycle")
            
            # Extract metrics from accumulated data
            unlocks = behavioral_data.get("unlocks", {}).get("count", 0)
            screen_time = behavioral_data.get("screen_time", {}).get("total_minutes", 0)
            calls = behavioral_data.get("calls", {}).get("count", 0)
            messages = behavioral_data.get("messages", {}).get("count", 0)
            late_night = behavioral_data.get("late_night_usage", {}).get("detected", False)
            app_usage = behavioral_data.get("app_usage", [])
            
            print(f"   Unlocks (3-hour): {unlocks} (rate: {behavioral_data.get('unlocks', {}).get('rate_per_hour', '0')} /hr)")
            print(f"   Screen time: {screen_time} mins")
            print(f"   Calls: {calls}, Messages: {messages}")
            print(f"   Late night usage: {late_night}")
            
            sync_metadata = {
                "cycle_start": data.get("sync_cycle_start", ""),
                "audio_score": data.get("audio_score", 0),
                "is_3hour_sync": True
            }
        else:
            # LEGACY FORMAT: Individual metrics
            print(f"   [LEGACY FORMAT] Using individual metric submission")
            
            unlocks = data.get("unlocks", 0)
            screen_time = data.get("screen_time", 0)
            calls = data.get("call_log", data.get("calls", 0))
            messages = data.get("messages", 0)
            late_night = data.get("late_night_usage", False)
            app_usage = data.get("app_usage", [])
            
            print(f"   Unlocks: {unlocks}")
            print(f"   Screen time: {screen_time} mins")
            
            sync_metadata = {"is_3hour_sync": False}
        
        # Prepare analysis input
        analysis_input = {
            "unlocks": unlocks,
            "screen_time": screen_time,
            "call_log": calls,
            "messages": messages,
            "late_night_usage": late_night,
            "app_usage": app_usage,
            "morning_rush": data.get("morning_rush", False)
        }
        
        # Analyze digital habits
        result = digital_habits_analyzer.analyze_digital_habits(user_id, analysis_input)
        
        # Store result
        user_stress_data["digital_score"] = result.get("digital_score", 0)
        
        # Extract component scores from the result
        components = result.get("components", {})
        
        response = {
            "status": "Success",
            "components": {
                "app_usage_score": components.get("app_stress", 0),
                "screen_time_score": components.get("screen_stress", 0),
                "unlock_frequency_score": components.get("unlock_stress", 0),
                "time_pattern_score": components.get("time_stress", 0),
                "communication_score": components.get("comm_stress", 0)
            },
            "digital_score": result.get("digital_score", 0),
            "stress_factors": result.get("stress_factors", []),
            "behavior_analysis": result.get("behavior_analysis", ""),
            "recommendations": result.get("recommendations", []),
            "sync_metadata": sync_metadata
        }
        
        print(f"[OK] Digital habits analysis response:")
        print(f"     App Usage:      {response['components']['app_usage_score']} degrees")
        print(f"     Screen Time:    {response['components']['screen_time_score']} degrees")
        print(f"     Unlock Freq:    {response['components']['unlock_frequency_score']} degrees")
        print(f"     Time Pattern:   {response['components']['time_pattern_score']} degrees")
        print(f"     FINAL SCORE:    {response['digital_score']} degrees")
        
        return response
        
    except Exception as e:
        print(f"[ERROR] Error analyzing digital habits: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=400,
            detail=f"Failed to analyze digital habits: {str(e)}"
        )

@app.post('/analyze-movement')
async def analyze_movement(request: Request):
    """
    Analyze physical activity patterns and calculate movement-based stress score
    
    Fourth Model: Random Forest on UCI HAR Dataset
    Uses accelerometer and gyroscope sensor readings to detect activities
    and generate stress score based on movement patterns.
    
    Expected JSON body:
    {
        "user_id": "student_001",
        "raw_features": [f1, f2, ..., f561],  # OR use raw sensor data below
        "acc_x": 0.5,                  # Accelerometer X-axis (m/s²)
        "acc_y": 9.8,                  # Accelerometer Y-axis (m/s²)
        "acc_z": 0.3,                  # Accelerometer Z-axis (m/s²)
        "gyro_x": 0.01,                # Gyroscope X-axis (rad/s)
        "gyro_y": 0.02,                # Gyroscope Y-axis (rad/s)
        "gyro_z": 0.01,                # Gyroscope Z-axis (rad/s)
        "activity_history": ["SITTING", "SITTING", "STANDING", "WALKING"],  # Recent activities
        "sitting_duration_minutes": 45
    }
    
    Returns:
    {
        "status": "Success",
        "activity": "WALKING",
        "activity_score": 35,
        "movement_intensity": 65,
        "pattern_regularity": 85,
        "physical_stress_score": 42,
        "stress_level": "Normal",
        "components": {...},
        "recommendations": [...]
    }
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "unknown_user")
        
        print(f"\n[*] Analyzing movement patterns for: {user_id}")
        
        # Analyze movement using Random Forest on UCI HAR Dataset
        result = physical_activity_analyzer.analyze_movement(user_id, data)
        
        # Store result
        user_stress_data["physical_score"] = result.get("physical_stress_score", 0)
        
        response = {
            "status": "Success",
            "activity": result.get("activity", "UNKNOWN"),
            "activity_score": result.get("activity_score", 0),
            "movement_intensity": result.get("movement_intensity", 0),
            "pattern_regularity": result.get("pattern_regularity", 0),
            "physical_stress_score": result.get("physical_stress_score", 0),
            "stress_level": result.get("stress_level", "Unknown"),
            "components": result.get("components", {}),
            "recommendations": result.get("recommendations", []),
            "model": "Random Forest (UCI HAR Dataset)"
        }
        
        print(f"[OK] Movement analysis response: Score = {response['physical_stress_score']} degrees, Activity = {response['activity']}")
        return response
        
    except Exception as e:
        print(f"[ERROR] Error analyzing movement: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=400,
            detail=f"Failed to analyze movement: {str(e)}"
        )


@app.post('/sync-all')
async def sync_all_models(request: Request):
    """
    Synchronize all stress models and return component scores
    
    Each model returns its own breakdown - NO AVERAGING
    
    Expected JSON body:
    {
        "user_id": "student_001",
        "audio_score": 30,
        "digital_components": {
            "app_usage_score": 35,
            "screen_time_score": 45,
            "unlock_frequency_score": 55,
            "time_pattern_score": 40
        },
        "physical_components": {
            "activity": "WALKING",
            "physical_stress_score": 42,
            "movement_intensity": 65,
            "pattern_regularity": 85
        }
    }
    
    Returns all component scores separately
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "unknown_user")
        
        # Model 1: Audio Score (Environmental)
        audio_score = data.get("audio_score", 0)
        
        # Model 2: Digital Habits Components
        digital_components = data.get("digital_components", {})
        
        # Model 3: Physical Activity Components
        physical_components = data.get("physical_components", {})
        
      
        # DETAILED CALCULATION AND LOGGING
        # Wrapped in try-except to prevent Windows charmap crashes
      
        
        app_usage = digital_components.get('app_usage_score', 0)
        screen_time = digital_components.get('screen_time_score', 0)
        unlock_freq = digital_components.get('unlock_frequency_score', 0)
        time_pattern = digital_components.get('time_pattern_score', 0)
        
        digital_scores = [app_usage, screen_time, unlock_freq, time_pattern]
        digital_count = len([s for s in digital_scores if s > 0])
        digital_sum = sum(digital_scores)
        digital_avg = digital_sum / digital_count if digital_count > 0 else 0
        
        activity = physical_components.get('activity', 'Unknown')
        phys_stress = physical_components.get('physical_stress_score', 0)
        movement_int = physical_components.get('movement_intensity', 0)
        pattern_reg = physical_components.get('pattern_regularity', 0)
        
        overall_scores = [audio_score, digital_avg, phys_stress]
        overall_avg = sum(overall_scores) / len(overall_scores)
        
        try:
            print(f"\n\n{'=' * 80}")
            print(f"DEBUG: [SYNC-ALL] RECEIVED ALL STRESS COMPONENTS - DETAILED ANALYSIS")
            print(f"{'=' * 80}")
            print(f"User: {user_id}")
            print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            print(f"\n{'-' * 80}")
            print(f"[1] ENVIRONMENTAL STRESS (Audio Analysis - YAMNet Model)")
            print(f"{'-' * 80}")
            print(f"  Audio Score Received: {audio_score}")
            print(f"  Interpretation: ", end="")
            if audio_score < 35:
                print(f"LOW STRESS (Green)")
            elif audio_score < 65:
                print(f"MODERATE STRESS (Orange)")
            else:
                print(f"HIGH STRESS (Red)")
            
            print(f"\n{'-' * 80}")
            print(f"[2] DIGITAL HABITS STRESS (Behavioral Analysis)")
            print(f"{'-' * 80}")
            
            print(f"  Components Received:")
            print(f"    - App Usage Score:        {app_usage}")
            print(f"    - Screen Time Score:      {screen_time}")
            print(f"    - Unlock Frequency Score: {unlock_freq}")
            print(f"    - Time Pattern Score:     {time_pattern}")
            
            print(f"\n  Calculation:")
            print(f"    Sum: {app_usage} + {screen_time} + {unlock_freq} + {time_pattern} = {digital_sum}")
            print(f"    Count: {digital_count} components")
            print(f"    Average: {digital_sum} / {digital_count} = {digital_avg:.2f}")
            print(f"    Final Digital Score: {digital_avg:.0f}")
            print(f"  Interpretation: ", end="")
            if digital_avg < 35:
                print(f"LOW STRESS (Green)")
            elif digital_avg < 65:
                print(f"MODERATE STRESS (Orange)")
            else:
                print(f"HIGH STRESS (Red)")
            
            print(f"\n{'-' * 80}")
            print(f"[3] PHYSICAL ACTIVITY STRESS (UCI HAR Model)")
            print(f"{'-' * 80}")
            
            print(f"  Activity Detected: {activity}")
            print(f"  Components Received:")
            print(f"    - Physical Stress Score:  {phys_stress}")
            print(f"    - Movement Intensity:     {movement_int}%")
            print(f"    - Pattern Regularity:     {pattern_reg}%")
            print(f"  Interpretation: ", end="")
            if phys_stress < 35:
                print(f"LOW STRESS (Green)")
            elif phys_stress < 65:
                print(f"MODERATE STRESS (Orange)")
            else:
                print(f"HIGH STRESS (Red)")
            
            print(f"\n{'-' * 80}")
            print(f"[4] OVERALL STRESS ASSESSMENT")
            print(f"{'-' * 80}")
            
            print(f"  Calculation:")
            print(f"    Environmental Score: {audio_score}")
            print(f"    Digital Score:       {digital_avg:.2f}")
            print(f"    Physical Score:      {phys_stress}")
            print(f"    ----------------------------")
            print(f"    Total Sum: {audio_score} + {digital_avg:.2f} + {phys_stress} = {sum(overall_scores):.2f}")
            print(f"    Overall Average: {sum(overall_scores):.2f} / 3 = {overall_avg:.2f}")
            
            print(f"\n  [RESULT] FINAL STRESS LEVEL: {overall_avg:.0f} degrees")
            print(f"  Status: ", end="")
            if overall_avg < 35:
                print(f"LOW STRESS (Green)")
            elif overall_avg < 65:
                print(f"MODERATE STRESS (Orange)")
            else:
                print(f"HIGH STRESS (Red)")
            
            print(f"{'=' * 80}\n")
        except Exception as log_err:
         
            print(f"[Note] Logging error (non-critical): {log_err}")

        
        return {
            "status": "Success",
            "user_id": user_id,
            "models": {
                "environmental": {
                    "name": "Audio Analysis (YAMNet)",
                    "score": audio_score,
                    "unit": "degrees (0-100)",
                    "interpretation": "Environmental stress level from detected sounds"
                },
                "digital_habits": {
                    "name": "Digital Behavior Analysis",
                    "components": {
                        "app_usage_score": digital_components.get("app_usage_score", 0),
                        "screen_time_score": digital_components.get("screen_time_score", 0),
                        "unlock_frequency_score": digital_components.get("unlock_frequency_score", 0),
                        "time_pattern_score": digital_components.get("time_pattern_score", 0)
                    },
                    "unit": "degrees (0-100)",
                    "interpretation": "Digital behavior stress indicators"
                },
                "physical_activity": {
                    "name": "Physical Activity Analysis (UCI HAR)",
                    "activity": physical_components.get("activity", "Unknown"),
                    "scores": {
                        "physical_stress_score": physical_components.get("physical_stress_score", 0),
                        "movement_intensity": physical_components.get("movement_intensity", 0),
                        "pattern_regularity": physical_components.get("pattern_regularity", 0)
                    },
                    "unit": "degrees/percentage (0-100)",
                    "interpretation": "Physical activity patterns and stress indicators"
                }
            },
            "timestamp": str(datetime.now())
        }
        
    except Exception as e:
        print(f"[ERROR] Error syncing models: {e}")
        raise HTTPException(
            status_code=400,
            detail=f"Failed to sync models: {str(e)}"
        )


# RECOMMENDATION ENGINE - LANGGRAPH + GOOGLE GEMINI


@app.post('/get-recommendations')
async def get_recommendations(request: Request):
    """
    Generate personalized stress management recommendations using LanGraph + Google Gemini
    
    Combines all three stress scores to generate intelligent, actionable recommendations
    powered by Google's Gemini LLM using LanGraph orchestration.
    
    Expected JSON body:
    {
        "user_id": "student_001",
        "audio_score": 45,        # Environmental stress (0-100)
        "digital_score": 60,      # Digital/phone stress (0-100)
        "physical_score": 35      # Physical activity stress (0-100)
    }
    
    Returns:
    {
        "status": "Success",
        "scores": {
            "audio": 45,
            "digital": 60,
            "physical": 35,
            "average": 46.7
        },
        "stress_analysis": {
            "level": "moderate",
            "category": "Stress levels are normal, but watch out for patterns",
            "primary_stressor": "digital"
        },
        "recommendations": [
            {
                "title": "Phone Disconnect Challenge",
                "action": "Put your phone in another room for 30 minutes",
                "duration": "30 minutes",
                "benefit": "Breaks phone usage habit, reduces digital stress",
                "motivation": "You'll be amazed at your focus!",
                "priority": "high"
            },
            ... (2 more recommendations)
        ],
        "generated_by": "Google Gemini (LanGraph)",
        "model": "gemini-2.0-flash",
        "timestamp": "2026-04-17T..."
    }
    """
    try:
        data = await request.json()
        user_id = data.get("user_id", "student_001")
        audio_score = data.get("audio_score", 50)
        digital_score = data.get("digital_score", 50)
        physical_score = data.get("physical_score", 50)
        
        # Validate scores
        for score, name in [(audio_score, "audio"), (digital_score, "digital"), (physical_score, "physical")]:
            if not 0 <= score <= 100:
                raise ValueError(f"{name}_score must be between 0 and 100, got {score}")
        
        print(f"\n[*] Getting recommendations for: {user_id}")
        print(f"    Audio Score: {audio_score}/100")
        print(f"    Digital Score: {digital_score}/100")
        print(f"    Physical Score: {physical_score}/100")
        
        # Get recommendations from LanGraph + Gemini
        result = recommendation_engine.get_recommendations(
            audio_score=audio_score,
            digital_score=digital_score,
            physical_score=physical_score
        )
        
        # Format response
        response = {
            "status": "Success",
            "user_id": user_id,
            "scores": result["scores"],
            "stress_analysis": result["stress_analysis"],
            "recommendations": result["recommendations"],
            "generated_by": "Google Gemini (LanGraph)",
            "model": "gemini-2.0-flash",
            "timestamp": result["generated_at"],
            "note": "AI-powered personalized recommendations based on your stress profile"
        }
        
        # Print summary (wrapped in try-catch to handle Windows emoji encoding issues)
        try:
            print(f"\n[OK] Recommendations generated successfully")
            print(f"    Stress Level: {result['stress_analysis']['level']}")
            print(f"    Primary Stressor: {result['stress_analysis']['primary_stressor']}")
            print(f"    Number of Recommendations: {len(result['recommendations'])}")
            
            for i, rec in enumerate(result["recommendations"], 1):
                # Encode-safe printing (emojis may fail on Windows console)
                title = rec.get('title', 'Recommendation').encode('ascii', 'replace').decode('ascii')
                priority = rec.get('priority', 'medium')
                print(f"      {i}. {title} ({priority} priority)")
        except Exception as print_err:
            print(f"    [Note] Could not print recommendation details: {print_err}")
        
        return response
        
    except ValueError as e:
        print(f"[ERROR] Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        print(f"[ERROR] Error generating recommendations: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendations: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)