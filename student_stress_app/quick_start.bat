@echo off
REM Quick start script for Flutter mobile app

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   STUDENT STRESS APP - Mobile App Quick Start          ║
echo ║   Version 1.0.0 - Recommendations & Notifications      ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Check if Flutter is installed
flutter --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERROR: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo ✅ Flutter found
echo.

REM Navigate to app directory
cd /d "D:\FYP\New folder\student_stress_app"
if %errorlevel% neq 0 (
    echo ❌ ERROR: Could not navigate to app directory
    pause
    exit /b 1
)

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   INSTALL DEPENDENCIES                                 ║
echo ╚════════════════════════════════════════════════════════╝
echo.

echo 📦 Running: flutter pub get
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed
echo.

REM Show available devices
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   AVAILABLE DEVICES                                    ║
echo ╚════════════════════════════════════════════════════════╝
echo.

flutter devices
if %errorlevel% neq 0 (
    echo ❌ WARNING: No devices found
    echo.
    echo 📝 Please start an emulator or connect a device
    echo.
    goto :choice
)

:choice
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   LAUNCH OPTIONS                                       ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo [1] Run on Android emulator/device (auto-select)
echo [2] Run with debug to specific device
echo [3] Show available devices and skip
echo [Q] Quit
echo.
set /p choice="Enter your choice (1/2/3/Q): "

if /i "%choice%"=="1" (
    echo.
    echo 🚀 Launching app...
    flutter run
    goto :end
)

if /i "%choice%"=="2" (
    echo.
    echo 🎯 Running with debugging enabled...
    echo.
    flutter devices
    echo.
    set /p device_id="Enter device ID (or leave blank for default): "
    if "%device_id%"=="" (
        flutter run --debug
    ) else (
        flutter run -d %device_id% --debug
    )
    goto :end
)

if /i "%choice%"=="3" (
    flutter devices
    goto :end
)

if /i "%choice%"=="Q" (
    echo Cancelled.
    goto :end
)

echo Invalid choice. Try again.
goto :choice

:end
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   💡 TESTING TIPS                                      ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo 1. Tap "Start Collection" to enable notifications
echo 2. Tap "Check Stress Level" to fetch scores
echo 3. Tap "View Recommendations" (✨) to see AI suggestions
echo 4. Notifications appear every 3 hours (or sooner for testing)
echo.
echo 📝 Full documentation: RECOMMENDATIONS_SETUP_GUIDE.md
echo.
pause
