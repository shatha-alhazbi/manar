# Step 4: Backend API Wrapper for Flutter App
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import asyncio
import uvicorn
import json
from datetime import datetime
import uuid

# Import our RAG system from Step 3
# from fanar_rag_integration import ManaraAI, UserProfile

# For now, we'll create simplified versions for testing
class UserProfile:
    def __init__(self, user_id: str, food_preferences: List[str] = None, 
                 budget_range: str = "$$", activity_types: List[str] = None,
                 language: str = "en", group_size: int = 1, min_rating: float = 4.0):
        self.user_id = user_id
        self.food_preferences = food_preferences or []
        self.budget_range = budget_range
        self.activity_types = activity_types or []
        self.language = language
        self.group_size = group_size
        self.min_rating = min_rating

# Pydantic models for API requests/responses
class ChatRequest(BaseModel):
    message: str
    user_id: str
    context: str = "dashboard"
    conversation_history: Optional[List[Dict]] = None

class UserPreferencesModel(BaseModel):
    food_preferences: List[str] = []
    budget_range: str = "$$"
    activity_types: List[str] = []
    language: str = "en"
    group_size: int = 1
    min_rating: float = 4.0

class RecommendationRequest(BaseModel):
    query: str
    user_id: str
    preferences: UserPreferencesModel
    limit: int = 5

class PlanningRequest(BaseModel):
    query: str
    user_id: str
    preferences: UserPreferencesModel
    date: Optional[str] = None

class BookingRequest(BaseModel):
    venue_name: str
    date: str
    time: str
    party_size: int
    user_id: str
    special_requirements: Optional[str] = None

class QuickSearchRequest(BaseModel):
    query: str
    category: Optional[str] = None
    budget: Optional[str] = None
    location: Optional[str] = None

# Response models
class RecommendationResponse(BaseModel):
    name: str
    type: str
    description: str
    location: str
    price_range: str
    rating: float
    estimated_duration: str
    why_recommended: str
    booking_available: bool
    best_time_to_visit: str
    contact: Optional[str] = None
    features: List[str] = []

class ApiResponse(BaseModel):
    success: bool
    data: Any
    message: str = ""
    request_id: str
    timestamp: str

# Initialize FastAPI app
app = FastAPI(
    title="Manara Tourism API",
    description="Backend API for Qatar Tourism App with RAG + FANAR integration",
    version="1.0.0"
)

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for demo (use proper database in production)
user_profiles = {}
conversation_history = {}

# Mock data for testing without FANAR API
MOCK_RECOMMENDATIONS = {
    "restaurants": [
        {
            "name": "Al Mourjan Restaurant",
            "type": "restaurant",
            "description": "Authentic Qatari cuisine with stunning Corniche views",
            "location": "West Bay, Corniche",
            "price_range": "$$",
            "rating": 4.6,
            "estimated_duration": "1-2 hours",
            "why_recommended": "Perfect for traditional Qatari experience with waterfront dining",
            "booking_available": True,
            "best_time_to_visit": "Sunset for best views",
            "contact": "+974 4444 0000",
            "features": ["outdoor_seating", "traditional_music", "corniche_view"]
        },
        {
            "name": "Souq Waqif Traditional Restaurant", 
            "type": "restaurant",
            "description": "Authentic Middle Eastern flavors in historic market setting",
            "location": "Souq Waqif",
            "price_range": "$",
            "rating": 4.4,
            "estimated_duration": "1 hour",
            "why_recommended": "Great budget option with authentic cultural experience",
            "booking_available": False,
            "best_time_to_visit": "Evening for market atmosphere",
            "contact": "+974 4444 0001",
            "features": ["historic_location", "budget_friendly", "cultural_experience"]
        }
    ],
    "attractions": [
        {
            "name": "Museum of Islamic Art",
            "type": "attraction",
            "description": "World-class museum with 1,400 years of Islamic art",
            "location": "Corniche, Doha",
            "price_range": "Free",
            "rating": 4.9,
            "estimated_duration": "2-3 hours",
            "why_recommended": "Must-visit cultural experience with stunning architecture",
            "booking_available": False,
            "best_time_to_visit": "Morning for fewer crowds",
            "contact": "+974 4422 4444",
            "features": ["free_entry", "educational", "photography_allowed"]
        }
    ],
    "cafes": [
        {
            "name": "Karak House",
            "type": "cafe",
            "description": "Authentic Qatari tea house with traditional karak",
            "location": "Souq Waqif",
            "price_range": "$",
            "rating": 4.5,
            "estimated_duration": "30 minutes",
            "why_recommended": "Perfect for authentic local tea experience",
            "booking_available": False,
            "best_time_to_visit": "Morning or evening",
            "contact": "+974 4444 1001",
            "features": ["authentic_experience", "budget_friendly", "quick_service"]
        }
    ]
}

# API Endpoints

@app.get("/")
async def root():
    return {"message": "Manara Tourism API", "status": "running", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/api/v1/chat", response_model=ApiResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Main chat endpoint for conversational AI
    """
    request_id = str(uuid.uuid4())
    
    try:
        # Get or create user profile
        if request.user_id not in user_profiles:
            user_profiles[request.user_id] = UserProfile(request.user_id)
        
        user_profile = user_profiles[request.user_id]
        
        # Mock response based on query intent
        response_data = await process_chat_mock(request.message, user_profile)
        
        # Store conversation history
        if request.user_id not in conversation_history:
            conversation_history[request.user_id] = []
        
        conversation_history[request.user_id].append({
            "user": request.message,
            "assistant": response_data,
            "timestamp": datetime.now().isoformat()
        })
        
        return ApiResponse(
            success=True,
            data=response_data,
            message="Chat response generated successfully",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        return ApiResponse(
            success=False,
            data={},
            message=f"Error processing chat: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/recommendations", response_model=ApiResponse)
async def get_recommendations(request: RecommendationRequest):
    """
    Get personalized recommendations
    """
    request_id = str(uuid.uuid4())
    
    try:
        # Create user profile from request
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=request.preferences.food_preferences,
            budget_range=request.preferences.budget_range,
            activity_types=request.preferences.activity_types,
            group_size=request.preferences.group_size,
            min_rating=request.preferences.min_rating
        )
        
        # Mock recommendations based on preferences
        recommendations = get_mock_recommendations(request.query, user_profile, request.limit)
        
        return ApiResponse(
            success=True,
            data={
                "recommendations": recommendations,
                "total_count": len(recommendations),
                "query": request.query,
                "user_preferences": request.preferences.dict()
            },
            message="Recommendations generated successfully",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        return ApiResponse(
            success=False,
            data={},
            message=f"Error generating recommendations: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/plan", response_model=ApiResponse)
async def create_day_plan(request: PlanningRequest):
    """
    Create a day plan/itinerary
    """
    request_id = str(uuid.uuid4())
    
    try:
        # Mock day plan
        plan = {
            "title": "Perfect Day in Qatar",
            "date": request.date or datetime.now().strftime("%Y-%m-%d"),
            "total_estimated_cost": "$60-90",
            "total_duration": "8 hours",
            "activities": [
                {
                    "time": "09:00",
                    "activity": "Breakfast at Al Mourjan Restaurant",
                    "location": "West Bay, Corniche",
                    "duration": "1 hour",
                    "estimated_cost": "$25",
                    "description": "Start with traditional Qatari breakfast with waterfront views",
                    "transportation": "Taxi from hotel",
                    "booking_required": True,
                    "tips": "Book ahead for waterfront seating"
                },
                {
                    "time": "11:00",
                    "activity": "Visit Museum of Islamic Art",
                    "location": "Corniche, Doha", 
                    "duration": "2.5 hours",
                    "estimated_cost": "Free",
                    "description": "Explore world-class Islamic art collection",
                    "transportation": "15-minute walk along Corniche",
                    "booking_required": False,
                    "tips": "Don't miss the manuscript collection"
                },
                {
                    "time": "14:00",
                    "activity": "Lunch at Souq Waqif",
                    "location": "Souq Waqif",
                    "duration": "1.5 hours",
                    "estimated_cost": "$20",
                    "description": "Traditional Middle Eastern lunch in historic market",
                    "transportation": "10-minute taxi or metro",
                    "booking_required": False,
                    "tips": "Explore the spice market after eating"
                },
                {
                    "time": "16:00",
                    "activity": "Explore Souq Waqif & Karak Tea",
                    "location": "Souq Waqif",
                    "duration": "2 hours",
                    "estimated_cost": "$10",
                    "description": "Shop for souvenirs and enjoy traditional karak tea",
                    "transportation": "Walking within souq",
                    "booking_required": False,
                    "tips": "Best time for photos as crowds thin out"
                }
            ],
            "transportation_notes": "Use Karwa taxis between major locations, metro for longer distances",
            "total_walking_distance": "2.5 km",
            "weather_tips": "Bring sunscreen and water, dress modestly for cultural sites",
            "budget_breakdown": {
                "food": "$45",
                "attractions": "$0",
                "transportation": "$25",
                "shopping": "$30"
            }
        }
        
        return ApiResponse(
            success=True,
            data={"day_plan": plan},
            message="Day plan created successfully",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        return ApiResponse(
            success=False,
            data={},
            message=f"Error creating day plan: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/book", response_model=ApiResponse)
async def process_booking(request: BookingRequest):
    """
    Process booking requests
    """
    request_id = str(uuid.uuid4())
    
    try:
        # Mock booking processing
        booking_id = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        booking_data = {
            "booking_id": booking_id,
            "status": "confirmed",
            "venue_name": request.venue_name,
            "date": request.date,
            "time": request.time,
            "party_size": request.party_size,
            "special_requirements": request.special_requirements,
            "confirmation_number": f"CONF-{booking_id}",
            "estimated_cost": "$75",
            "cancellation_policy": "Free cancellation up to 2 hours before reservation",
            "contact_info": "+974 4444 0000",
            "location": "West Bay, Corniche",
            "notes": "Please arrive 10 minutes early. Dress code: Smart casual"
        }
        
        return ApiResponse(
            success=True,
            data={"booking": booking_data},
            message="Booking processed successfully",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        return ApiResponse(
            success=False,
            data={},
            message=f"Error processing booking: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/search", response_model=ApiResponse)
async def quick_search(request: QuickSearchRequest):
    """
    Quick search functionality
    """
    request_id = str(uuid.uuid4())
    
    try:
        # Filter mock data based on search criteria
        results = []
        
        for category, items in MOCK_RECOMMENDATIONS.items():
            if request.category and category != request.category:
                continue
                
            for item in items:
                # Simple text matching
                if (request.query.lower() in item['name'].lower() or 
                    request.query.lower() in item['description'].lower()):
                    
                    # Budget filter
                    if request.budget and item['price_range'] != request.budget:
                        continue
                    
                    # Location filter
                    if request.location and request.location.lower() not in item['location'].lower():
                        continue
                    
                    results.append(item)
        
        return ApiResponse(
            success=True,
            data={
                "results": results,
                "total_count": len(results),
                "query": request.query,
                "filters": {
                    "category": request.category,
                    "budget": request.budget,
                    "location": request.location
                }
            },
            message=f"Found {len(results)} results",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        return ApiResponse(
            success=False,
            data={},
            message=f"Error performing search: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.get("/api/v1/user/{user_id}/profile")
async def get_user_profile(user_id: str):
    """
    Get user profile and preferences
    """
    if user_id not in user_profiles:
        user_profiles[user_id] = UserProfile(user_id)
    
    profile = user_profiles[user_id]
    
    return {
        "user_id": profile.user_id,
        "food_preferences": profile.food_preferences,
        "budget_range": profile.budget_range,
        "activity_types": profile.activity_types,
        "language": profile.language,
        "group_size": profile.group_size,
        "min_rating": profile.min_rating
    }

@app.post("/api/v1/user/{user_id}/profile")
async def update_user_profile(user_id: str, preferences: UserPreferencesModel):
    """
    Update user profile and preferences
    """
    user_profiles[user_id] = UserProfile(
        user_id=user_id,
        food_preferences=preferences.food_preferences,
        budget_range=preferences.budget_range,
        activity_types=preferences.activity_types,
        language=preferences.language,
        group_size=preferences.group_size,
        min_rating=preferences.min_rating
    )
    
    return {"message": "Profile updated successfully", "user_id": user_id}

@app.get("/api/v1/user/{user_id}/history")
async def get_conversation_history(user_id: str, limit: int = 10):
    """
    Get user's conversation history
    """
    history = conversation_history.get(user_id, [])
    return {
        "user_id": user_id,
        "conversation_count": len(history),
        "recent_conversations": history[-limit:] if history else []
    }

# Helper functions

async def process_chat_mock(message: str, user_profile: UserProfile) -> Dict:
    """
    Mock chat processing for testing
    """
    message_lower = message.lower()
    
    if any(word in message_lower for word in ['restaurant', 'food', 'eat', 'dinner', 'lunch']):
        return {
            "type": "recommendations",
            "intent": "food_search",
            "message": "I found some great restaurant recommendations for you!",
            "recommendations": MOCK_RECOMMENDATIONS["restaurants"][:2]
        }
    
    elif any(word in message_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
        return {
            "type": "planning",
            "intent": "day_planning",
            "message": "I'll create a perfect day plan for you in Qatar!",
            "suggestions": ["Cultural tour", "Food tour", "Modern attractions"]
        }
    
    elif any(word in message_lower for word in ['book', 'reserve', 'table']):
        return {
            "type": "booking",
            "intent": "booking_request", 
            "message": "I can help you make a reservation. Which restaurant would you like to book?",
            "booking_options": [item["name"] for item in MOCK_RECOMMENDATIONS["restaurants"]]
        }
    
    else:
        return {
            "type": "chat",
            "intent": "general_info",
            "message": "I'm here to help you explore Qatar! I can recommend restaurants, plan your day, or make bookings. What would you like to do?",
            "suggestions": ["Find restaurants", "Plan my day", "Make a booking", "Local attractions"]
        }

def get_mock_recommendations(query: str, user_profile: UserProfile, limit: int) -> List[Dict]:
    """
    Generate mock recommendations based on query and preferences
    """
    query_lower = query.lower()
    all_recommendations = []
    
    # Add all categories to recommendations
    for category, items in MOCK_RECOMMENDATIONS.items():
        all_recommendations.extend(items)
    
    # Filter by user preferences
    filtered_recommendations = []
    for item in all_recommendations:
        # Budget filter
        if user_profile.budget_range == "$" and item["price_range"] in ["$", "$$"]:
            filtered_recommendations.append(item)
        elif user_profile.budget_range == "$$" and item["price_range"] in ["$", "$$"]:
            filtered_recommendations.append(item)
        elif user_profile.budget_range == "$$$":
            filtered_recommendations.append(item)
        elif item["price_range"] == "Free":
            filtered_recommendations.append(item)
    
    # Sort by rating
    filtered_recommendations.sort(key=lambda x: x["rating"], reverse=True)
    
    return filtered_recommendations[:limit]

# Run the server
if __name__ == "__main__":
    print("Starting Manara Tourism API Server...")
    print("API Documentation: http://localhost:8000/docs")
    print("Health Check: http://localhost:8000/health")
    
    uvicorn.run(
        "backend_api_wrapper:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )