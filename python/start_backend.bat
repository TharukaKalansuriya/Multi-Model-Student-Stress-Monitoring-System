@echo off
REM Batch script to start FastAPI backend
REM Make sure FastAPI runs on port 8000
REM Use ngrok http 8000 (NOT 80!)

echo.
echo [*] Starting Student Stress App Backend
echo [*] FastAPI will run on http://localhost:8000
echo.

cd /d "D:\FYP\after akilas model edit\python"

echo [*] Checking Python installation...
python --version

echo.
echo [*] Checking required packages...
python -c "import fastapi, uvicorn, tensorflow, tensorflow_hub, langchain, langgraph; print('[OK] All packages available')" || (
    echo [ERROR] Missing packages! Run: pip install -r requirements.txt
    pause
    exit /b 1
)

echo.
echo [*] Starting backend on port 8000...
echo [*] For ngrok tunnel: ngrok http 8000
echo.

python main.py

pause
