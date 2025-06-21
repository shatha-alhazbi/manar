import requests 
import json
import asyncio
import aiohttp
import chromadb
from sentence_transformers import SentenceTransformer
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import time

# FANAR API Configuration
FANAR_API_BASE = "https://api.fanar.qa"
FANAR_API_KEY = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"  

@dataclass
class UserProfile:
    user_id: str
    food_preferences: List[str]
    budget_range: str
    activity_types: List[str]
    language: str = "en"
    accessibility_needs: List[str] = None
    group_size: int = 1
    min_rating: float = 4.0

class FanarAPIClient:
    def __init__(self, api_key: str, base_url: str = FANAR_API_BASE):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
    
    async def generate_completion(self, prompt: str, max_tokens: int = 1000, temperature: float = 0.7) -> str:
        """
        Generate text completion using FANAR API
        """
        # Use chat completion format as recommended by FANAR API
        messages = [
            {"role": "user", "content": prompt}
        ]
        
        payload = {
            "model": "Fanar",  # Use main FANAR model
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature
        }
        
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as session:
                async with session.post(
                    f"{self.base_url}/v1/chat/completions",
                    headers=self.headers,
                    json=payload
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
                    else:
                        error_text = await response.text()
                        print(f"FANAR API Error {response.status}: {error_text}")
                        return ""
        except Exception as e:
            print(f"FANAR API Request Failed: {e}")
            return ""
    
    async def chat_completion(self, messages: List[Dict], max_tokens: int = 1000, temperature: float = 0.7) -> str:
        """
        Generate chat completion using FANAR API
        """
        payload = {
            "model": "Fanar",  # Use main FANAR model
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature
        }
        
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as session:
                async with session.post(
                    f"{self.base_url}/v1/chat/completions", 
                    headers=self.headers,
                    json=payload
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
                    else:
                        error_text = await response.text()
                        print(f"FANAR Chat API Error {response.status}: {error_text}")
                        return ""
        except Exception as e:
            print(f"FANAR Chat API Request Failed: {e}")
            return ""

class QatarRAGSystem:
    def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
        """
        Initialize the complete RAG system with FANAR API and vector database
        """
        print("Initializing Qatar RAG System...")
        
        # Initialize FANAR client
        self.fanar_client = FanarAPIClient(fanar_api_key)
        
        # Initialize vector database
        self.embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
        self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        
        try:
            self.collection = self.chroma_client.get_collection("qatar_tourism")
            print(f"Loaded vector database with {self.collection.count()} items")
        except Exception as e:
            print(f"Error loading vector database: {e}")
            print("Please run Step 2 first to create the vector database")
            raise
    
    def retrieve_context(self, query: str, user_profile: UserProfile, n_results: int = 5) -> List[Dict]:
        """
        Retrieve relevant context from vector database based on query and user preferences
        """
        # Enhance query with user preferences
        enhanced_query_parts = [query]
        
        if user_profile.food_preferences:
            enhanced_query_parts.append(f"cuisine preferences: {', '.join(user_profile.food_preferences)}")
        
        if user_profile.activity_types:
            enhanced_query_parts.append(f"activity interests: {', '.join(user_profile.activity_types)}")
        
        if user_profile.budget_range:
            enhanced_query_parts.append(f"budget: {user_profile.budget_range}")
        
        enhanced_query = ". ".join(enhanced_query_parts)
        
        # Create query embedding
        query_embedding = self.embedding_model.encode([enhanced_query])
        
        # Search vector database
        results = self.collection.query(
            query_embeddings=query_embedding.tolist(),
            n_results=n_results * 2,  # Get more results for filtering
            include=['documents', 'metadatas', 'distances']
        )
        
        # Filter and format results
        filtered_results = []
        for i in range(len(results['ids'][0])):
            metadata = results['metadatas'][0][i]
            
            # Apply user preference filters
            if user_profile.budget_range:
                item_price = metadata.get('price_range', '')
                if item_price and item_price != user_profile.budget_range:
                    # Allow some flexibility in budget
                    budget_order = {'$': 1, '$$': 2, '$$$': 3}
                    if (user_profile.budget_range in budget_order and 
                        item_price in budget_order and 
                        budget_order[item_price] > budget_order[user_profile.budget_range] + 1):
                        continue
            
            # Apply rating filter
            if metadata.get('rating', 0) < user_profile.min_rating:
                continue
            
            # Calculate similarity
            distance = results['distances'][0][i]
            similarity = max(0, min(1, 1 - (distance / 2)))
            
            filtered_results.append({
                'document': results['documents'][0][i],
                'metadata': metadata,
                'similarity': similarity
            })
            
            if len(filtered_results) >= n_results:
                break
        
        return filtered_results
    
    async def classify_intent(self, user_input: str, user_profile: UserProfile) -> str:
        """
        Use FANAR to classify user intent
        """
        intent_prompt = f"""You are an AI assistant for a Qatar tourism app. Classify the user's request into one of these categories:

1. "recommendation" - User wants suggestions for restaurants, attractions, cafes, or activities
2. "planning" - User wants to plan a day trip, itinerary, or schedule  
3. "booking" - User wants to make reservations, buy tickets, or order something
4. "chat" - General questions about Qatar, conversation, or information requests

Examples:
- "Show me good restaurants" → recommendation
- "Plan my day in Doha" → planning  
- "Book a table for tonight" → booking
- "What's the weather like?" → chat

User input: "{user_input}"
User preferences: Food - {user_profile.food_preferences}, Budget - {user_profile.budget_range}

Respond with ONLY the category name (recommendation/planning/booking/chat)."""

        intent = await self.fanar_client.generate_completion(intent_prompt, max_tokens=10)
        return intent.lower().strip()
    
    async def generate_recommendations(self, user_input: str, user_profile: UserProfile) -> Dict:
        """
        Generate personalized recommendations using RAG + FANAR
        """
        # Retrieve relevant context
        context_results = self.retrieve_context(user_input, user_profile, n_results=5)
        
        # Format context for FANAR
        context_text = "\n".join([
            f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
            f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
            f"Rating: {result['metadata'].get('rating', 'N/A')}"
            for result in context_results
        ])
        
        recommendation_prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

User Profile:
- Food preferences: {user_profile.food_preferences}
- Budget range: {user_profile.budget_range}  
- Preferred activities: {user_profile.activity_types}
- Group size: {user_profile.group_size}
- Minimum rating: {user_profile.min_rating}

Available places in Qatar:
{context_text}

User request: "{user_input}"

Provide 3-4 personalized recommendations in this EXACT JSON format:
{{
    "recommendations": [
        {{
            "name": "Place Name",
            "type": "restaurant/attraction/cafe/activity",
            "description": "Brief description why this is perfect for the user",
            "location": "Area name", 
            "price_range": "$/$$/$$$ or specific price",
            "rating": 4.5,
            "estimated_duration": "1-2 hours",
            "why_recommended": "Specific reason based on user preferences",
            "booking_available": true,
            "best_time_to_visit": "Morning/Afternoon/Evening"
        }}
    ],
    "summary": "Brief explanation of why these recommendations fit the user's profile"
}}

Ensure all recommendations match the user's budget and preferences. Respond with valid JSON only."""

        response = await self.fanar_client.generate_completion(recommendation_prompt, max_tokens=1500)
        
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            # Fallback response
            return {
                "recommendations": [
                    {
                        "name": result['metadata']['name'],
                        "type": result['metadata']['category'],
                        "description": f"Recommended based on your preferences",
                        "location": result['metadata'].get('location', ''),
                        "price_range": result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A')),
                        "rating": result['metadata'].get('rating', 0),
                        "estimated_duration": "2 hours",
                        "why_recommended": "Matches your preferences and budget",
                        "booking_available": False,
                        "best_time_to_visit": "Anytime"
                    }
                    for result in context_results[:3]
                ],
                "summary": "Recommendations based on your preferences"
            }
    
    async def create_day_plan(self, user_input: str, user_profile: UserProfile) -> Dict:
        """
        Create a structured day plan using RAG + FANAR
        """
        # Get diverse context (restaurants, attractions, cafes)
        context_results = self.retrieve_context(user_input, user_profile, n_results=8)
        
        # Organize by category
        restaurants = [r for r in context_results if r['metadata']['category'] == 'restaurants']
        attractions = [r for r in context_results if r['metadata']['category'] == 'attractions']
        cafes = [r for r in context_results if r['metadata']['category'] == 'cafes']
        
        context_text = f"""Available options:

RESTAURANTS:
{chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in restaurants[:3]])}

ATTRACTIONS:
{chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('entry_fee', 'Free')}" for r in attractions[:3]])}

CAFES:
{chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in cafes[:2]])}"""

        planning_prompt = f"""Create a detailed day itinerary for Qatar based on the user's request and preferences.

User Profile:
- Food preferences: {user_profile.food_preferences}
- Budget: {user_profile.budget_range}
- Preferred activities: {user_profile.activity_types}
- Group size: {user_profile.group_size}

{context_text}

User request: "{user_input}"

Create a realistic day plan in this EXACT JSON format:
{{
    "day_plan": {{
        "title": "Your Perfect Day in Qatar",
        "date": "{datetime.now().strftime('%Y-%m-%d')}",
        "total_estimated_cost": "$50-80",
        "total_duration": "8 hours",
        "activities": [
            {{
                "time": "09:00",
                "activity": "Breakfast at [Restaurant Name]",
                "location": "Specific area",
                "duration": "1 hour", 
                "estimated_cost": "$15",
                "description": "Why this fits the plan and user preferences",
                "transportation": "10-minute walk from previous location",
                "booking_required": false,
                "tips": "Arrive early to avoid crowds"
            }}
        ],
        "transportation_notes": "Best ways to get around for this itinerary",
        "total_walking_distance": "3 km",
        "weather_tips": "Bring sunscreen and water",
        "budget_breakdown": {{
            "food": "$40",
            "attractions": "$30",
            "transportation": "$20"
        }}
    }}
}}

Include 4-5 activities covering breakfast, main attractions, lunch/cafe, and dinner. Make sure activities are in chronological order and transportation between locations is realistic."""

        response = await self.fanar_client.generate_completion(planning_prompt, max_tokens=2000)
        
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            # Fallback plan using retrieved context
            activities = []
            if restaurants:
                activities.append({
                    "time": "09:00",
                    "activity": f"Breakfast at {restaurants[0]['metadata']['name']}",
                    "location": restaurants[0]['metadata'].get('location', ''),
                    "duration": "1 hour",
                    "estimated_cost": "$20",
                    "description": "Start your day with a traditional breakfast",
                    "transportation": "Taxi from hotel",
                    "booking_required": True,
                    "tips": "Try the local specialties"
                })
            
            if attractions:
                activities.append({
                    "time": "11:00", 
                    "activity": f"Visit {attractions[0]['metadata']['name']}",
                    "location": attractions[0]['metadata'].get('location', ''),
                    "duration": "2.5 hours",
                    "estimated_cost": attractions[0]['metadata'].get('entry_fee', 'Free'),
                    "description": "Explore this cultural attraction",
                    "transportation": "15-minute walk or short taxi",
                    "booking_required": False,
                    "tips": "Best time for photos"
                })
            
            return {
                "day_plan": {
                    "title": "Your Perfect Day in Qatar",
                    "date": datetime.now().strftime("%Y-%m-%d"),
                    "total_estimated_cost": "$60-90",
                    "total_duration": "8 hours",
                    "activities": activities,
                    "transportation_notes": "Use Karwa taxis or metro when available",
                    "total_walking_distance": "2 km",
                    "weather_tips": "Stay hydrated and wear comfortable shoes"
                }
            }
    
    async def handle_general_chat(self, user_input: str, user_profile: UserProfile, conversation_history: List[Dict] = None) -> str:
        """
        Handle general conversation about Qatar using RAG + FANAR
        """
        # Get relevant context
        context_results = self.retrieve_context(user_input, user_profile, n_results=3)
        
        context_text = "\n".join([
            f"- {result['metadata']['name']}: {result['document'][:200]}..."
            for result in context_results
        ]) if context_results else "No specific information found."

        # Prepare chat messages
        messages = [
            {
                "role": "system",
                "content": f"""You are a friendly Qatar tourism assistant. Help users with information about Qatar's culture, attractions, food, and travel tips.

Relevant information about Qatar:
{context_text}

User preferences: {user_profile.food_preferences}, Budget: {user_profile.budget_range}, Activities: {user_profile.activity_types}

Keep responses helpful, friendly, and focused on Qatar tourism. Provide specific recommendations when appropriate."""
            }
        ]
        
        # Add conversation history
        if conversation_history:
            messages.extend(conversation_history)
        
        messages.append({
            "role": "user",
            "content": user_input
        })
        
        response = await self.fanar_client.chat_completion(messages, max_tokens=500)
        return response or "I'm sorry, I couldn't process your request right now. Please try again."
    
    async def process_booking_request(self, user_input: str, user_profile: UserProfile) -> Dict:
        """
        Process booking requests using FANAR to extract details
        """
        booking_prompt = f"""Extract booking information from the user's request and format it properly.

User request: "{user_input}"
User profile: Group size: {user_profile.group_size}, Budget: {user_profile.budget_range}

Extract and format the booking details in this EXACT JSON format:
{{
    "booking_details": {{
        "type": "restaurant/attraction/transportation/activity",
        "venue_name": "Specific place name or 'not specified'",
        "date": "2024-03-15 or 'not specified'",
        "time": "19:00 or 'not specified'",
        "party_size": {user_profile.group_size},
        "special_requirements": "Any dietary restrictions or accessibility needs",
        "estimated_cost": "$50 or 'not specified'",
        "confirmation_needed": true
    }},
    "booking_summary": "Clear summary of what will be booked",
    "next_steps": "What the user needs to do to complete the booking",
    "missing_info": ["List of any missing required information"]
}}

If the request is not clear, indicate what information is missing."""

        response = await self.fanar_client.generate_completion(booking_prompt, max_tokens=800)
        
        try:
            booking_data = json.loads(response)
            booking_data["booking_status"] = "pending_confirmation"
            booking_data["booking_id"] = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
            return booking_data
        except json.JSONDecodeError:
            return {
                "booking_details": {
                    "type": "unknown",
                    "venue_name": "not specified",
                    "status": "needs_clarification"
                },
                "booking_summary": "Could not understand booking request",
                "next_steps": "Please provide more specific details for your booking",
                "missing_info": ["venue name", "date", "time"]
            }

# Main Application Class
class ManaraAI:
    def __init__(self, fanar_api_key: str):
        self.rag_system = QatarRAGSystem(fanar_api_key)
        print("Manara AI System Ready!")
    
    async def process_user_request(self, user_input: str, user_profile: UserProfile, context: str = "dashboard") -> Dict:
        """
        Main entry point for processing user requests
        """
        try:
            # Classify intent using FANAR
            intent = await self.rag_system.classify_intent(user_input, user_profile)
            print(f"Classified intent: {intent}")
            
            if intent == "recommendation":
                result = await self.rag_system.generate_recommendations(user_input, user_profile)
                return {"type": "recommendations", "data": result}
            
            elif intent == "planning":
                result = await self.rag_system.create_day_plan(user_input, user_profile)
                return {"type": "day_plan", "data": result}
            
            elif intent == "booking":
                result = await self.rag_system.process_booking_request(user_input, user_profile)
                return {"type": "booking", "data": result}
            
            else:  # chat
                result = await self.rag_system.handle_general_chat(user_input, user_profile)
                return {"type": "chat", "data": {"message": result}}
        
        except Exception as e:
            print(f"Error processing request: {e}")
            return {
                "type": "error",
                "data": {"message": f"Sorry, I encountered an error. Please try again."}
            }

# Test the system
async def test_manara_system():
    """
    Test the complete system with various queries
    """
    print("Testing Manara AI System with FANAR API")
    print("=" * 60)
    
    # Initialize system (replace with your actual FANAR API key)
    manara_ai = ManaraAI(FANAR_API_KEY)
    
    # Test user profile
    user_profile = UserProfile(
        user_id="test_user",
        food_preferences=["Middle Eastern", "Traditional"],
        budget_range="$$",
        activity_types=["Cultural", "Food"],
        group_size=2,
        min_rating=4.0
    )
    
    # Test queries
    test_queries = [
        "I want to try authentic Qatari restaurants",
        "Plan a perfect cultural day for me in Doha", 
        "Book a table for 2 at a traditional restaurant tonight",
        "What's the best time to visit Souq Waqif?"
    ]
    
    for i, query in enumerate(test_queries, 1):
        print(f"\nTest {i}: {query}")
        print("-" * 40)
        
        result = await manara_ai.process_user_request(query, user_profile)
        
        print(f"Response Type: {result['type']}")
        if result['type'] == 'recommendations':
            recs = result['data'].get('recommendations', [])
            print(f"Found {len(recs)} recommendations:")
            for rec in recs[:2]:  # Show first 2
                print(f"  - {rec['name']} ({rec['type']}) - {rec['price_range']}")
        
        elif result['type'] == 'day_plan':
            plan = result['data'].get('day_plan', {})
            activities = plan.get('activities', [])
            print(f"Day plan with {len(activities)} activities:")
            for activity in activities[:2]:  # Show first 2
                print(f"  - {activity['time']}: {activity['activity']}")
        
        elif result['type'] == 'booking':
            booking = result['data'].get('booking_details', {})
            print(f"Booking: {booking.get('type', 'unknown')} at {booking.get('venue_name', 'TBD')}")
        
        else:
            message = result['data'].get('message', '')
            print(f"Chat response: {message[:100]}...")
        
        # Small delay between requests
        await asyncio.sleep(1)

if __name__ == "__main__":
    # Run the test
    asyncio.run(test_manara_system())