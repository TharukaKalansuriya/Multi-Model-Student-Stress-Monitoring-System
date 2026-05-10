# Student Stress Monitoring System

A comprehensive, full-stack digital health application designed to monitor and manage student stress levels through automated multi-modal data collection and AI-driven insights.

## Overview

This project consists of two main components:
1. **Flutter Mobile App (`student_stress_app`)**: The frontend client that collects real-time data from the user's environment and device usage. It performs automated 3-hour background data collection cycles.
2. **Python Backend (`python`)**: A microservices architecture that processes the collected data, analyzes stress patterns using machine learning models (e.g., YAMNet for audio stress analysis, Random Forest), and generates personalized well-being recommendations.

## Key Features

- **Multi-Modal Stress Tracking**: 
  - 🎤 **Audio Stress Analysis**: Uses microphone data and ML models to detect stress in the ambient environment.
  - 📱 **Digital Habits Monitoring**: Tracks screen time and application usage patterns.
  - 🏃 **Physical Activity Tracking**: Monitors physical movement and exercise routines.
- **Automated Data Collection**: Background scheduler runs every 3 hours to capture a holistic snapshot of the student's current state.
- **Intelligent Recommendations**: Calculates daily stress averages and provides actionable, personalized recommendations to improve mental well-being.
- **Interactive Dashboard**: A modern, user-friendly UI featuring dynamic circular progress bars and real-time health metrics.

## Project Structure

```text
neeew/
├── student_stress_app/     # Flutter mobile application
│   ├── lib/                # Dart source code (UI, Services, Widgets)
│   ├── assets/models/      # Machine Learning models
│   └── pubspec.yaml        # Flutter dependencies
├── python/                 # Python backend services
│   ├── main.py             # Main entry point for backend APIs
│   ├── *_service.py        # Microservices (Digital Habits, Physical Activity, etc.)
│   └── requirements.txt    # Python dependencies
└── .gitignore              # Unified gitignore for both Python and Flutter
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.8+](https://www.python.org/downloads/)

### Running the Python Backend

1. Navigate to the `python` directory:
   ```bash
   cd python
   ```
2. (Optional but recommended) Create a virtual environment:
   ```bash
   python -m venv venv
   .\venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the backend services:
   ```bash
   python main.py
   ```

### Running the Flutter Mobile App

1. Navigate to the `student_stress_app` directory:
   ```bash
   cd student_stress_app
   ```
2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```

## Technologies Used

* **Frontend**: Dart, Flutter
* **Backend**: Python, REST APIs
* **Machine Learning**: YAMNet, Scikit-Learn (Random Forest)
