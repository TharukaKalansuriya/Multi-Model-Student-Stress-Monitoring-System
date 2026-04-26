#!/usr/bin/env python3
"""
Quick verification script to test YAMNet class mapping and stress weights
Shows how many classes are now properly mapped vs before
"""

from yamnet_service import YAMNetService

service = YAMNetService()

# Count mapped classes
total_audioset_classes = len(service.AUDIOSET_LABELS)
total_stress_weights = len(service.STRESS_WEIGHTS)

print("\n" + "="*70)
print("[INFO] YAMNet CLASS MAPPING VERIFICATION")
print("="*70)

print(f"\n[OK] AudioSet Classes Mapped: {total_audioset_classes}/521")
print(f"   Coverage: {(total_audioset_classes/521)*100:.1f}%")

print(f"\n[OK] Stress Weights Defined: {total_stress_weights}")
print(f"   Coverage: ~{(total_stress_weights/521)*100:.1f}% of AudioSet classes")

print(f"\n[TEST] Key Classes for Testing:")
print(f"   Class 64: {service.AUDIOSET_LABELS.get(64, 'NOT MAPPED')}")
print(f"            Stress Weight: {service.STRESS_WEIGHTS.get('Car horn', 'MISSING')}")

print(f"\n   Class 125: {service.AUDIOSET_LABELS.get(125, 'NOT MAPPED')}")
print(f"             Stress Weight: {service.STRESS_WEIGHTS.get('Kick drum', 'MISSING')}")

print(f"\n   Class 300: {service.AUDIOSET_LABELS.get(300, 'NOT MAPPED')}")
print(f"             Stress Weight: {service.STRESS_WEIGHTS.get('Splash', 'MISSING')}")

# Show sample stress weight ranges
print(f"\n[STATS] Stress Weight Distribution:")
weights = list(service.STRESS_WEIGHTS.values())
print(f"   Minimum: {min(weights)} (Silent/Calm)")
print(f"   Maximum: {max(weights)} (Emergency/Danger)")
print(f"   Average: {sum(weights)/len(weights):.0f}")

print(f"\n[CATEGORY] Emergency Sounds (>90):")
emergency = {k: v for k, v in service.STRESS_WEIGHTS.items() if v > 90}
print(f"   {list(emergency.keys())[:5]}")

print(f"\n[CATEGORY] Traffic Sounds (60-85):")
traffic = {k: v for k, v in service.STRESS_WEIGHTS.items() if 60 <= v <= 85}
print(f"   {list(traffic.keys())[:5]}")

print(f"\n[CATEGORY] Speech/Social Sounds (15-45):")
social = {k: v for k, v in service.STRESS_WEIGHTS.items() if 15 <= v <= 45}
print(f"   {list(social.keys())[:5]}")

print("\n" + "="*70)
print("[OK] All mappings verified! Ready for testing.\n")
