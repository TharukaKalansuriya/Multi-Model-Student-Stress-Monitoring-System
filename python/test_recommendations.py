import requests
import json

print('Testing /get-recommendations endpoint (with 120s timeout)...\n')
print('This may take 10-30 seconds on first run due to Gemini API call...\n')

payload = {
    'audio_score': 45,
    'digital_score': 50,
    'physical_score': 55
}

try:
    r = requests.post('http://localhost:8000/get-recommendations', json=payload, timeout=120)
    print(f'Status Code: {r.status_code}\n')
    
    if r.status_code == 200:
        data = r.json()
        print(f'✓ SUCCESS\n')
        print(f'Stress Level: {data["stress_analysis"]["level"].upper()}')
        print(f'Primary Stressor: {data["stress_analysis"]["primary_stressor"].upper()}')
        print(f'Stress Category: {data["stress_analysis"]["category"]}\n')
        
        print(f'Recommendations ({len(data["recommendations"])} total):')
        for i, rec in enumerate(data['recommendations'], 1):
            print(f'  {i}. {rec.get("title", "Recommendation")}')
            print(f'     Duration: {rec.get("duration", "N/A")}')
            print(f'     Priority: {rec.get("priority", "N/A").upper()}')
            print(f'     Action: {rec.get("action", "N/A")[:60]}...\n')
    else:
        print(f'Error: {r.text}')
except requests.exceptions.Timeout:
    print('✗ Request timed out - The Gemini API call took too long')
    print('Try again - it may be faster on the second attempt')
except Exception as e:
    print(f'✗ Error: {type(e).__name__}: {e}')
