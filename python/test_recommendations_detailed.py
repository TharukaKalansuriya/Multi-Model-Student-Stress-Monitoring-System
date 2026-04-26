import requests
import json

print('Testing /get-recommendations with improved JSON parsing...\n')
print('=' * 70)

payload = {
    'audio_score': 25,
    'digital_score': 48,
    'physical_score': 68
}

try:
    r = requests.post('http://localhost:8000/get-recommendations', json=payload, timeout=120)
    print(f'Status Code: {r.status_code}\n')
    
    if r.status_code == 200:
        data = r.json()
        recs = data.get('recommendations', [])
        
        print(f'Stress Analysis:')
        print(f'  Level: {data["stress_analysis"]["level"].upper()}')
        print(f'  Primary Stressor: {data["stress_analysis"]["primary_stressor"].upper()}')
        print(f'  Category: {data["stress_analysis"]["category"]}\n')
        
        print(f'Recommendations ({len(recs)} total):')
        print('-' * 70)
        
        # List of fallback recommendation titles
        fallback_titles = [
            'Find a Quiet Space', 'Use Noise Canceling', 'Phone Disconnect Challenge', 
            'Quick Movement Break', 'Gym or Exercise Session', 'Stand & Move Goals', 
            'Schedule Silent Hours', 'Disable Notifications', 'Evening Tech Curfew'
        ]
        
        for i, rec in enumerate(recs, 1):
            is_fallback = rec.get('title', '') in fallback_titles
            status = '(FALLBACK - Hardcoded)' if is_fallback else '(AI-GENERATED ✓ DYNAMIC)'
            
            print(f'\n{i}. {rec.get("title", "N/A")}')
            print(f'   Status: {status}')
            print(f'   Duration: {rec.get("duration", "N/A")}')
            print(f'   Priority: {rec.get("priority", "N/A").upper()}')
            print(f'   Action: {rec.get("action", "N/A")[:70]}...')
            print(f'   Benefit: {rec.get("benefit", "N/A")[:60]}...')
        
        # Summary
        ai_count = sum(1 for r in recs if r.get('title', '') not in fallback_titles)
        fallback_count = len(recs) - ai_count
        
        print(f'\n' + '=' * 70)
        print(f'Summary:')
        print(f'  AI-Generated: {ai_count}')
        print(f'  Fallback: {fallback_count}')
        
        if ai_count == 3:
            print(f'\n✓ SUCCESS: All recommendations are AI-generated from Gemini!')
        else:
            print(f'\n⚠ PARTIAL: Some recommendations are fallback (hardcoded)')
    else:
        print(f'Error Status: {r.status_code}')
        print(f'Response: {r.text}')
        
except requests.exceptions.Timeout:
    print('Timeout - Gemini API taking too long')
except Exception as e:
    print(f'Error: {type(e).__name__}: {e}')

print('=' * 70)
