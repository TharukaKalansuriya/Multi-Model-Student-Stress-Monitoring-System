"""
Recommendation Service using LanGraph + Google Gemini

Generates personalized stress management recommendations based on:
- Audio stress score (environmental factors)
- Digital stress score (phone usage)
- Physical stress score (activity level)

Uses Google Gemini for intelligent LLM reasoning.
"""

import os
import json
from typing import TypedDict, Annotated
from dotenv import load_dotenv
from hashlib import md5
from datetime import datetime, timedelta

# LanGraph imports
from langgraph.graph import StateGraph, END
from langchain_google_genai import ChatGoogleGenerativeAI

# Load environment variables
load_dotenv()

# Cache for recommendations to avoid repeated Gemini API calls
_recommendation_cache = {}

class RecommendationState(TypedDict):
    """State for recommendation workflow"""
    audio_score: int
    digital_score: int
    physical_score: int
    primary_stressor: str  # "audio" | "digital" | "physical"
    stress_level: str      # "low" | "moderate" | "high" | "critical"
    stress_category: str   # Brief category description
    recommendations: list[dict]
    generated_at: str


class RecommendationService:
    """Service for generating AI-powered stress recommendations"""
    
    def __init__(self):
        """Initialize the recommendation service with Gemini"""
        api_key = os.getenv("GOOGLE_API_KEY")
        
        if not api_key:
            raise ValueError(
                "GOOGLE_API_KEY not found in environment variables. "
                "Please create a .env file with your API key."
            )
        
        # Initialize Gemini LLM
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash",
            google_api_key=api_key,
            temperature=0.7,  # Balanced creativity and consistency
            top_p=0.9,
            max_retries=0     # Fail fast instead of hanging on quota errors
        )
        
        # Build LanGraph workflow
        self.graph = self._build_graph()
        self.chain = self.graph.compile()
        
        print("[*] Recommendation Service initialized with Google Gemini")
        print(f"    Model: gemini-2.0-flash")
        print(f"    Free tier: 60 requests/minute")
    
    def _build_graph(self) -> StateGraph:
        """Build LanGraph workflow for recommendations"""
        
        graph = StateGraph(RecommendationState)
        
        # Add nodes
        graph.add_node("analyze", self._analyze_scores_node)
        graph.add_node("classify", self._classify_stress_node)
        graph.add_node("generate", self._generate_recommendations_node)
        
        # Add edges
        graph.add_edge("analyze", "classify")
        graph.add_edge("classify", "generate")
        graph.add_edge("generate", END)
        
        # Set entry point
        graph.set_entry_point("analyze")
        
        return graph
    
    def _analyze_scores_node(self, state: RecommendationState) -> RecommendationState:
        """
        Analyze the three stress scores and identify primary stressor.
        """
        print("[*] Analyzing stress scores...")
        
        # Calculate average and total
        scores = {
            "audio": state["audio_score"],
            "digital": state["digital_score"],
            "physical": state["physical_score"]
        }
        
        average_score = (state["audio_score"] + state["digital_score"] + state["physical_score"]) / 3
        
        # Identify primary stressor
        state["primary_stressor"] = max(scores, key=scores.get)
        
        print(f"    Audio Score: {state['audio_score']}/100")
        print(f"    Digital Score: {state['digital_score']}/100")
        print(f"    Physical Score: {state['physical_score']}/100")
        print(f"    Average: {average_score:.1f}/100")
        print(f"    Primary Stressor: {state['primary_stressor'].upper()}")
        
        return state
    
    def _classify_stress_node(self, state: RecommendationState) -> RecommendationState:
        """
        Classify overall stress level based on scores.
        """
        print("[*] Classifying stress level...")
        
        average_score = (state["audio_score"] + state["digital_score"] + state["physical_score"]) / 3
        
        # Determine stress level
        if average_score < 30:
            state["stress_level"] = "low"
            state["stress_category"] = "You're managing stress well"
        elif average_score < 50:
            state["stress_level"] = "moderate"
            state["stress_category"] = "Stress levels are normal, but watch out for patterns"
        elif average_score < 75:
            state["stress_level"] = "high"
            state["stress_category"] = "Your stress is elevated - intervention recommended"
        else:
            state["stress_level"] = "critical"
            state["stress_category"] = "Immediate stress management needed"
        
        print(f"    Stress Level: {state['stress_level'].upper()}")
        print(f"    Category: {state['stress_category']}")
        
        return state
    
    def _generate_recommendations_node(self, state: RecommendationState) -> RecommendationState:
        """
        Use Gemini to generate intelligent, personalized recommendations.
        """
        print("[*] Generating recommendations with Gemini...")
        
        # Build context for LLM
        stressor_descriptions = {
            "audio": f"Environmental noise/sounds ({state['audio_score']}/100) - Consider quieter spaces, noise management",
            "digital": f"Digital phone usage habits ({state['digital_score']}/100) - Consider screen time reduction",
            "physical": f"Physical activity/movement ({state['physical_score']}/100) - Consider more or better exercise"
        }
        
        prompt = f"""You are a supportive stress management advisor for a university student.

STUDENT'S STRESS PROFILE:
- Audio Stress (environmental): {state['audio_score']}/100
- Digital Stress (phone usage): {state['digital_score']}/100  
- Physical Stress (activity level): {state['physical_score']}/100
- Overall Stress Level: {state['stress_level'].upper()}
- Primary Stressor: {state['primary_stressor'].upper()}

Primary Stressor Details: {stressor_descriptions[state['primary_stressor']]}

TASK: Generate exactly 3 actionable, specific recommendations for stress management.

Requirements for each recommendation:
1. Be SPECIFIC and immediately actionable (not generic advice)
2. Include estimated time commitment (in minutes)
3. Explain the BENEFIT related to their primary stressor
4. Add a motivation tip or encouraging statement
5. Prioritize addressing the PRIMARY stressor first

Format your response as a JSON array with exactly 3 objects. Each object should have:
{{
  "title": "Short, catchy recommendation title",
  "action": "Specific, detailed action to take (1-2 sentences)",
  "duration": "time in minutes (e.g., '10 minutes')",
  "benefit": "How this helps with {{their stressor}} stress",
  "motivation": "Encouraging/motivational phrase",
  "priority": "high" | "medium" | "low"
}}

Generate recommendations that are:
- STUDENT-FRIENDLY (not parent advice)
- REALISTIC (can be done today)
- TARGETED (address their specific stressor)

Response MUST be valid JSON only, no other text."""

        try:
            # Call Gemini
            response = self.llm.invoke(prompt)
            response_text = response.content
            
            print(f"    [*] Raw response length: {len(response_text)} chars")
            
            # Parse JSON response - handle multiple markdown formats
            original_text = response_text
            
            # Try to extract JSON from markdown code blocks
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0]
                print(f"    [*] Extracted from ```json block")
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0]
                print(f"    [*] Extracted from ``` block")
            
            # Remove any remaining markdown or control characters
            response_text = response_text.strip()
            
            # Try to find JSON array if there's extra text
            if not response_text.startswith('['):
                # Look for the first [ and last ]
                start_idx = response_text.find('[')
                end_idx = response_text.rfind(']')
                if start_idx >= 0 and end_idx > start_idx:
                    response_text = response_text[start_idx:end_idx+1]
                    print(f"    [*] Extracted JSON array from within text")
            
            print(f"    [*] Cleaned response length: {len(response_text)} chars")
            print(f"    [*] Cleaned response: {response_text[:100]}...")
            
            recommendations = json.loads(response_text)
            
            # Validate structure
            if not isinstance(recommendations, list):
                print(f"    [!] Response is not a list, attempting to wrap...")
                recommendations = [recommendations] if isinstance(recommendations, dict) else []
            
            if len(recommendations) != 3:
                print(f"    [!] Warning: Expected 3 recommendations, got {len(recommendations)}")
            
            state["recommendations"] = recommendations
            print(f"    [OK] Generated {len(recommendations)} AI recommendations from Gemini")
            
            for i, rec in enumerate(recommendations, 1):
                print(f"      {i}. {rec.get('title', 'Recommendation')} ({rec.get('duration', 'N/A')})")
            
        except json.JSONDecodeError as e:
            print(f"    [ERROR] Failed to parse JSON: {e}")
            print(f"    [*] Attempting response: {response_text[:200]}")
            # Fallback to generic recommendations
            state["recommendations"] = self._fallback_recommendations(state)
        except Exception as e:
            print(f"    [ERROR] Gemini API error: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
            state["recommendations"] = self._fallback_recommendations(state)
        
        # Add timestamp
        from datetime import datetime
        state["generated_at"] = datetime.now().isoformat()
        
        return state
    
    def _fallback_recommendations(self, state: RecommendationState) -> list[dict]:
        """Fallback recommendations dynamically based on actual stress scores - NOT hardcoded"""
        
        audio_score = state["audio_score"]
        digital_score = state["digital_score"]
        physical_score = state["physical_score"]
        average_score = (audio_score + digital_score + physical_score) / 3
        
        recommendations = []
        
        # Rank stress sources (highest to lowest)
        stressors = [
            ('audio', audio_score, 'Environmental/Audio Stress'),
            ('digital', digital_score, 'Digital/Phone Stress'),
            ('physical', physical_score, 'Physical Activity Stress'),
        ]
        stressors.sort(key=lambda x: x[1], reverse=True)
        
        primary_stressor, primary_score, primary_label = stressors[0]
        secondary_stressor, secondary_score, secondary_label = stressors[1]
        
        # Generate 3 recommendations based on current stress profile
        
        # Recommendation 1: Address PRIMARY stressor (with dynamic thresholds)
        if primary_stressor == 'audio':
            if primary_score > 70:
                recommendations.append({
                    "title": f"Critical Noise - Find Silent Space NOW",
                    "action": "Your environment noise is severe ({:.0f}). Move to a quiet library, empty classroom, or use active noise-canceling earbuds immediately.".format(primary_score),
                    "duration": "15-20 minutes",
                    "benefit": f"Directly reduces your {primary_score:.0f} environmental stress level",
                    "motivation": "Your brain will feel immediate relief in quiet environments",
                    "priority": "high"
                })
            elif primary_score > 50:
                recommendations.append({
                    "title": f"Reduce Noise ({primary_score:.0f})",
                    "action": "Environmental noise is elevated. Use headphones with lo-fi music, white noise, or move to quieter space",
                    "duration": "15 minutes",
                    "benefit": f"Addresses your {primary_score:.0f} audio stress level",
                    "motivation": "Sound management is key to focus",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Maintain Audio Awareness ({primary_score:.0f})",
                    "action": "Your audio stress is manageable. Continue monitoring noise levels and use earplugs if needed",
                    "duration": "Ongoing",
                    "benefit": f"Keeps your {primary_score:.0f} audio stress stable",
                    "motivation": "Good job managing your sound environment",
                    "priority": "low"
                })
                
        elif primary_stressor == 'digital':
            if primary_score > 70:
                recommendations.append({
                    "title": f"URGENT: Phone Crisis ({primary_score:.0f})",
                    "action": "Digital stress is critical! Put your phone in another room for 1 hour - NO notifications, NO distractions. Set a specific time block",
                    "duration": "60 minutes minimum",
                    "benefit": f"Breaks the severe phone addiction cycle at {primary_score:.0f} stress",
                    "motivation": "Your focus and mental health depend on this - you CAN do it",
                    "priority": "high"
                })
            elif primary_score > 50:
                recommendations.append({
                    "title": f"Phone Detox ({primary_score:.0f})",
                    "action": "Put your phone in another room for 30 minutes - no notifications. Focus on one task",
                    "duration": "30 minutes",
                    "benefit": f"Addresses your {primary_score:.0f} digital stress through immediate disconnect",
                    "motivation": "You'll regain focus within 5 minutes",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Healthy Digital Habits ({primary_score:.0f})",
                    "action": "Your phone usage is under control. Set boundaries: no phones during meals, last hour before bed",
                    "duration": "Ongoing habit",
                    "benefit": f"Maintains your healthy {primary_score:.0f} digital stress level",
                    "motivation": "Keep this balance - it's working!",
                    "priority": "medium"
                })
                
        elif primary_stressor == 'physical':
            if primary_score > 70:
                recommendations.append({
                    "title": f"URGENT: Physical Inactivity ({primary_score:.0f})",
                    "action": "Critical inactivity stress! Do 20 jumping jacks, run up stairs, or take a 10-minute jog RIGHT NOW",
                    "duration": "10-15 minutes intense",
                    "benefit": f"Combat your critical {primary_score:.0f} physical stress with immediate high-intensity movement",
                    "motivation": "Exercise creates immediate endorphins - stress relief in minutes",
                    "priority": "high"
                })
            elif primary_score > 50:
                recommendations.append({
                    "title": f"Get Moving ({primary_score:.0f})",
                    "action": "Do 10 jumping jacks, stretch, or take a quick 5-minute walk around campus",
                    "duration": "10 minutes",
                    "benefit": f"Address your {primary_score:.0f} physical stress with immediate movement",
                    "motivation": "Movement is medicine - your body will thank you",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Stay Active ({primary_score:.0f})",
                    "action": "Keep your current activity level. Do light stretches every hour and aim for 30 mins of activity daily",
                    "duration": "Ongoing",
                    "benefit": f"Maintains your excellent {primary_score:.0f} physical stress management",
                    "motivation": "Your movement patterns are healthy - maintain this!",
                    "priority": "low"
                })
        
        # Recommendation 2: Address SECONDARY stressor with dynamic recommendations
        if secondary_stressor == 'digital' and secondary_score >= 35:
            if secondary_score > 60:
                recommendations.append({
                    "title": f"Aggressive Notification Control ({secondary_score:.0f})",
                    "action": "Immediately: Turn OFF all notifications except calls from contacts. Enable Focus Mode/Do Not Disturb",
                    "duration": "5 minutes setup",
                    "benefit": f"Blocks notification interruptions contributing to {secondary_score:.0f} stress",
                    "motivation": "Reclaim your attention and peace of mind",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Notification Limits ({secondary_score:.0f})",
                    "action": "Disable non-essential app notifications. Keep only important ones (messages, calls, calendar)",
                    "duration": "5 minutes to configure",
                    "benefit": f"Reduces digital stress interruptions at level {secondary_score:.0f}",
                    "motivation": "Less pinging = more peace",
                    "priority": "medium"
                })
                
        elif secondary_stressor == 'physical' and secondary_score >= 35:
            if secondary_score > 60:
                recommendations.append({
                    "title": f"Anti-Sedentary Protocol ({secondary_score:.0f})",
                    "action": "Set hourly alarms to stand, stretch, and walk for 2-3 minutes. Cannot stay sitting more than 45 mins",
                    "duration": "2-3 mins per hour",
                    "benefit": f"Prevents dangerous sedentary stress buildup at {secondary_score:.0f} level",
                    "motivation": "Movement breaks compound - you'll feel 50% better by end of day",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Movement Breaks ({secondary_score:.0f})",
                    "action": "Every 30-45 minutes, stand up and move for 2 minutes. Stretch, walk, or do light exercises",
                    "duration": "2-3 minutes per break",
                    "benefit": f"Breaks up sedentary time and lowers {secondary_score:.0f} stress buildup",
                    "motivation": "Small movements = big stress relief",
                    "priority": "medium"
                })
                
        elif secondary_stressor == 'audio' and secondary_score >= 35:
            if secondary_score > 60:
                recommendations.append({
                    "title": f"Audio Masking ({secondary_score:.0f})",
                    "action": "Use high-quality noise-canceling earbuds or headphones with lo-fi, ambient, or brown noise continuously",
                    "duration": "Ongoing during work",
                    "benefit": f"Actively masks environmental triggers of your {secondary_score:.0f} audio stress",
                    "motivation": "Consistent background audio keeps your mind focused",
                    "priority": "high"
                })
            else:
                recommendations.append({
                    "title": f"Acoustic Environment ({secondary_score:.0f})",
                    "action": "Use headphones with lo-fi music or nature sounds during study sessions",
                    "duration": "As needed during focus time",
                    "benefit": f"Reduces environmental noise contribution to {secondary_score:.0f} stress",
                    "motivation": "Sound design improves focus",
                    "priority": "medium"
                })
        else:
            # Default secondary recommendation if no secondary stressor is significant
            recommendations.append({
                "title": "Maintain Balance",
                "action": "Your secondary stress is under control. Continue balanced habits across all domains",
                "duration": "Ongoing",
                "benefit": "Prevents secondary stress from escalating",
                "motivation": "You're managing well!",
                "priority": "low"
            })
        
        # Recommendation 3: Overall stress management (based on average)
        if average_score > 70:
            recommendations.append({
                "title": f"CRISIS: Overall Stress {average_score:.0f} - Immediate Action",
                "action": "Take 10 deep breaths (4-count in, 6-count out), step outside for 5 mins, or call a trusted friend. Do this RIGHT NOW",
                "duration": "5-10 minutes",
                "benefit": "Activates parasympathetic nervous system - shifts your body from stress response",
                "motivation": "Your body can shift out of crisis mode with just minutes of conscious breathing",
                "priority": "high"
            })
        elif average_score > 55:
            recommendations.append({
                "title": f"Elevated Stress Management ({average_score:.0f})",
                "action": "Combine all three strategies: (1) Quiet time 15 mins, (2) Phone break 30 mins, (3) Move for 10 mins",
                "duration": "55 minutes total",
                "benefit": f"Addresses all stress domains simultaneously to reduce overall {average_score:.0f} level",
                "motivation": "Multi-domain approach works faster than single interventions",
                "priority": "high"
            })
        elif average_score > 40:
            recommendations.append({
                "title": f"Moderate Stress Routine ({average_score:.0f})",
                "action": "Build a daily routine: 20-min focus blocks with 5-min breaks, one 15-min walk, phone-free dinner",
                "duration": "Build over days",
                "benefit": f"Sustainable practices that lower your {average_score:.0f} stress over time",
                "motivation": "Consistency beats intensity - small daily habits compound",
                "priority": "medium"
            })
        else:
            recommendations.append({
                "title": f"Excellent Stress Level ({average_score:.0f})",
                "action": "Maintain your current habits! You've found a good balance. Consider helping others manage their stress",
                "duration": "Ongoing",
                "benefit": f"Sustain your optimal {average_score:.0f} stress level and mental well-being",
                "motivation": "You're thriving - keep this momentum going!",
                "priority": "low"
            })
        
        return recommendations[:3]  # Return exactly top 3
    
    def get_recommendations(self, audio_score: int, digital_score: int, physical_score: int) -> dict:
        """
        Main entry point - get recommendations for three stress scores.
        
        Args:
            audio_score: 0-100 (environmental/audio stress)
            digital_score: 0-100 (phone/digital stress)
            physical_score: 0-100 (activity/physical stress)
        
        Returns:
            Dict with recommendations, stress level, and details
        """
        
        # Validate scores
        for score, name in [(audio_score, "audio"), (digital_score, "digital"), (physical_score, "physical")]:
            if not 0 <= score <= 100:
                raise ValueError(f"{name}_score must be between 0 and 100")
        
        # Check cache first - avoid repeated Gemini API calls
        cache_key = self._generate_cache_key(audio_score, digital_score, physical_score)
        if cache_key in _recommendation_cache:
            cached_result = _recommendation_cache[cache_key]
            if datetime.now() - cached_result['cached_at'] < timedelta(hours=1):
                print(f"\n[*] Cache hit! Returning cached recommendations (age: {(datetime.now() - cached_result['cached_at']).total_seconds():.0f}s)")
                return cached_result['data']
            else:
                # Cache expired
                del _recommendation_cache[cache_key]
                print(f"[*] Cache expired - generating new recommendations")
        
        print("\n" + "="*70)
        print("GENERATING PERSONALIZED RECOMMENDATIONS")
        print("="*70)
        
        # Initialize state
        initial_state = RecommendationState(
            audio_score=audio_score,
            digital_score=digital_score,
            physical_score=physical_score,
            primary_stressor="",
            stress_level="",
            stress_category="",
            recommendations=[],
            generated_at=""
        )
        
        # Run the graph
        result = self.chain.invoke(initial_state)
        
        print("\n" + "="*70)
        print("RECOMMENDATIONS GENERATED")
        print("="*70 + "\n")
        
        # Format output
        response = {
            "scores": {
                "audio": audio_score,
                "digital": digital_score,
                "physical": physical_score,
                "average": (audio_score + digital_score + physical_score) / 3
            },
            "stress_analysis": {
                "level": result["stress_level"],
                "category": result["stress_category"],
                "primary_stressor": result["primary_stressor"]
            },
            "recommendations": result["recommendations"],
            "generated_at": result["generated_at"]
        }
        
        # Cache the result
        _recommendation_cache[cache_key] = {
            'data': response,
            'cached_at': datetime.now()
        }
        print(f"[*] Recommendation cached for future use (cache size: {len(_recommendation_cache)})")
        
        return response
    
    def _generate_cache_key(self, audio_score: int, digital_score: int, physical_score: int) -> str:
        """Generate a cache key based on score ranges (rounded to nearest 5)"""
        # Round scores to nearest 5 to increase cache hits for similar scores
        audio_rounded = round(audio_score / 5) * 5
        digital_rounded = round(digital_score / 5) * 5
        physical_rounded = round(physical_score / 5) * 5
        
        key_str = f"{audio_rounded}_{digital_rounded}_{physical_rounded}"
        return md5(key_str.encode()).hexdigest()[:16]


# Singleton instance
_recommendation_service = None

def get_recommendation_service() -> RecommendationService:
    """Get or initialize the Recommendation Service singleton."""
    global _recommendation_service
    if _recommendation_service is None:
        _recommendation_service = RecommendationService()
    return _recommendation_service
