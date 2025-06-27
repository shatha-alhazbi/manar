# # backend_api_wrapper.py - Fixed Version with Proper FANAR Integration
# from fastapi import FastAPI, HTTPException, BackgroundTasks
# from fastapi.middleware.cors import CORSMiddleware
# from pydantic import BaseModel
# from typing import List, Dict, Optional, Any
# import asyncio
# import uvicorn
# import json
# from datetime import datetime
# import uuid

# # Import your fixed FANAR integration
# from fanar_api_integration import ManarAI, UserProfile

# # Pydantic models
# class ChatRequest(BaseModel):
#     message: str
#     user_id: str
#     context: str = "dashboard"
#     conversation_history: Optional[List[Dict]] = None

# class UserPreferencesModel(BaseModel):
#     food_preferences: List[str] = []
#     budget_range: str = "$$"
#     activity_types: List[str] = []
#     language: str = "en"
#     group_size: int = 1
#     min_rating: float = 4.0

# class RecommendationRequest(BaseModel):
#     query: str
#     user_id: str
#     preferences: UserPreferencesModel
#     limit: int = 5

# class PlanningRequest(BaseModel):
#     query: str
#     user_id: str
#     preferences: UserPreferencesModel
#     date: Optional[str] = None

# class BookingRequest(BaseModel):
#     venue_name: str
#     date: str
#     time: str
#     party_size: int
#     user_id: str
#     special_requirements: Optional[str] = None

# class QuickSearchRequest(BaseModel):
#     query: str
#     category: Optional[str] = None
#     budget: Optional[str] = None
#     location: Optional[str] = None

# class ApiResponse(BaseModel):
#     success: bool
#     data: Any
#     message: str = ""
#     request_id: str
#     timestamp: str

# # Initialize FastAPI app
# app = FastAPI(
#     title="Manara API with FANAR Integration",
#     description="Backend API with FANAR API integration and RAG system",
#     version="1.0.0"
# )

# # Add CORS middleware
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # Initialize your system
# FANAR_API_KEY = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"
# manar_ai = None

# # In-memory storage for demonstration
# user_bookings = {}
# user_profiles = {}

# @app.on_event("startup")
# async def startup_event():
#     """Initialize ManarAI system on startup"""
#     global manar_ai
#     try:
#         print(" Initializing ManarAI with FANAR API integration...")
        
#         # Make sure your vector database exists
#         import os
#         if not os.path.exists("./chroma_db"):
#             print(" Vector database not found. Please run:")
#             print("1. python qatar_database.py")
#             print("2. python embeddings_vector_db.py")
#             return
        
#         # Initialize using your existing files
#         manar_ai = ManarAI(FANAR_API_KEY)
#         print(" ManarAI system initialized successfully!")
#         print(f" Vector database loaded with {manar_ai.rag_system.collection.count()} items")
#         print(f" FANAR API status: {'Available' if manar_ai.rag_system.fanar_client.is_available else 'Fallback mode'}")
        
#     except Exception as e:
#         print(f" Error initializing ManarAI: {e}")
#         print("Please make sure you have run the setup scripts:")
#         print("1. python qatar_database.py")
#         print("2. python embeddings_vector_db.py")
#         manar_ai = None

# # Helper functions for in-memory storage
# async def save_user_booking(user_id: str, booking_data: Dict) -> bool:
#     """Save booking to in-memory storage"""
#     if user_id not in user_bookings:
#         user_bookings[user_id] = []
    
#     booking_data['created_at'] = datetime.now().isoformat()
#     booking_data['updated_at'] = datetime.now().isoformat()
#     user_bookings[user_id].append(booking_data)
    
#     print(f" Booking saved for user {user_id}")
#     return True

# async def get_user_bookings(user_id: str) -> List[Dict]:
#     """Get user bookings from in-memory storage"""
#     return user_bookings.get(user_id, [])

# def _parse_planning_query(query: str) -> Dict:
#     """Parse planning query to extract user preferences"""
#     parsed = {}
#     query_lower = query.lower()
    
#     # Extract duration
#     if 'extended day' in query_lower or '12 hour' in query_lower:
#         parsed['duration'] = 12
#         parsed['duration_text'] = 'extended day (12 hours)'
#     elif 'full day' in query_lower or '8 hour' in query_lower:
#         parsed['duration'] = 8
#         parsed['duration_text'] = 'full day (8 hours)'
#     elif 'half day' in query_lower or '4 hour' in query_lower:
#         parsed['duration'] = 4
#         parsed['duration_text'] = 'half day (4 hours)'
    
#     # Extract start time
#     if 'early morning' in query_lower or '7-9 am' in query_lower:
#         parsed['start_time'] = '07:00'
#         parsed['start_time_text'] = 'early morning'
#     elif 'morning' in query_lower or '9-11 am' in query_lower:
#         parsed['start_time'] = '09:00'
#         parsed['start_time_text'] = 'morning'
#     elif 'afternoon' in query_lower or '12-2 pm' in query_lower:
#         parsed['start_time'] = '13:00'
#         parsed['start_time_text'] = 'afternoon'
    
#     # Extract budget
#     if 'premium' in query_lower or '$200+' in query_lower:
#         parsed['budget_range'] = '$$$'
#         parsed['budget_amount'] = 250
#         parsed['budget_text'] = 'premium ($200+)'
#     elif 'moderate' in query_lower or '$100-200' in query_lower:
#         parsed['budget_range'] = '$$'
#         parsed['budget_amount'] = 150
#         parsed['budget_text'] = 'moderate ($100-200)'
#     elif 'budget' in query_lower or '$50-100' in query_lower:
#         parsed['budget_range'] = '$'
#         parsed['budget_amount'] = 75
#         parsed['budget_text'] = 'budget-friendly ($50-100)'
    
#     # Extract activity preferences
#     activity_types = []
#     if 'cultural' in query_lower or 'historic' in query_lower:
#         activity_types.append('Cultural')
#     if 'food' in query_lower or 'dining' in query_lower:
#         activity_types.append('Food')
#     if 'modern' in query_lower or 'shopping' in query_lower:
#         activity_types.append('Modern')
#     if 'mix of everything' in query_lower or 'surprise me' in query_lower:
#         activity_types = ['Cultural', 'Food', 'Modern', 'Shopping']
#         parsed['surprise_mode'] = True
    
#     if activity_types:
#         parsed['activity_types'] = activity_types
    
#     # Extract special preferences
#     if 'traditional souqs' in query_lower:
#         parsed['include_souqs'] = True
#     if 'cultural sites' in query_lower:
#         parsed['prioritize_culture'] = True
#     if 'restaurants' in query_lower:
#         parsed['include_restaurants'] = True
#         if not parsed.get('activity_types'):
#             parsed['activity_types'] = ['Food']
    
#     return parsed

# # API Endpoints
# @app.get("/")
# async def root():
#     fanar_status = "connected" if manar_ai and manar_ai.rag_system.fanar_client.is_available else "fallback mode"
#     rag_status = "initialized" if manar_ai else "not initialized"
#     vector_count = 0
#     if manar_ai:
#         try:
#             vector_count = manar_ai.rag_system.collection.count()
#         except:
#             pass
    
#     return {
#         "message": "🇶🇦 Manara Tourism API with FANAR Integration", 
#         "status": "running", 
#         "version": "1.0.0",
#         "fanar_api_status": fanar_status,
#         "rag_status": rag_status,
#         "vector_items": vector_count,
#         "features": ["FANAR API", "RAG System", "Qatar Tourism Database"]
#     }

# @app.get("/health")
# async def health_check():
#     fanar_health = "connected" if manar_ai and manar_ai.rag_system.fanar_client.is_available else "fallback"
#     rag_health = "healthy" if manar_ai else "unavailable"
#     vector_count = 0
#     if manar_ai:
#         try:
#             vector_count = manar_ai.rag_system.collection.count()
#         except:
#             pass
    
#     return {
#         "status": "healthy", 
#         "timestamp": datetime.now().isoformat(),
#         "fanar_api": fanar_health,
#         "rag_system": rag_health,
#         "vector_db": "connected" if manar_ai else "disconnected",
#         "vector_items": vector_count
#     }

# @app.post("/api/v1/chat", response_model=ApiResponse)
# async def chat_endpoint(request: ChatRequest):
#     """Chat endpoint using FANAR API and RAG system"""
#     request_id = str(uuid.uuid4())
    
#     try:
#         if not manar_ai:
#             return ApiResponse(
#                 success=False,
#                 data={"message": "ManarAI system not initialized. Please check the vector database setup."},
#                 message="System not available",
#                 request_id=request_id,
#                 timestamp=datetime.now().isoformat()
#             )
        
#         # Create user profile
#         user_profile = UserProfile(
#             user_id=request.user_id,
#             food_preferences=["Middle Eastern", "Traditional"],
#             budget_range="$",
#             activity_types=["Cultural", "Food"],
#             language="en",
#             group_size=1,
#             min_rating=4.0
#         )
        
#         # Process with FANAR + RAG system
#         print(f" Processing chat: {request.message}")
#         result = await manar_ai.process_user_request(
#             user_input=request.message,
#             user_profile=user_profile,
#             context=request.context
#         )
        
#         print(f" Response type: {result['type']}")
        
#         return ApiResponse(
#             success=True,
#             data=result['data'],
#             message=f"Response generated using FANAR API and RAG database ({result['type']})",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )
        
#     except Exception as e:
#         print(f" Chat endpoint error: {e}")
#         return ApiResponse(
#             success=False,
#             data={"message": "Sorry, I couldn't process your request right now."},
#             message=f"Error: {str(e)}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )

# @app.post("/api/v1/plan", response_model=ApiResponse)
# async def create_day_plan(request: PlanningRequest):
#     """Create day plan using FANAR API and RAG system with preference parsing"""
#     request_id = str(uuid.uuid4())
    
#     try:
#         if not manar_ai:
#             return ApiResponse(
#                 success=False,
#                 data={},
#                 message="ManarAI system not initialized",
#                 request_id=request_id,
#                 timestamp=datetime.now().isoformat()
#             )
        
#         # Extract and parse user preferences from the query
#         parsed_preferences = _parse_planning_query(request.query)
        
#         # Merge with request preferences, giving priority to parsed preferences
#         user_profile = UserProfile(
#             user_id=request.user_id,
#             food_preferences=parsed_preferences.get('food_preferences', request.preferences.food_preferences),
#             budget_range=parsed_preferences.get('budget_range', request.preferences.budget_range),
#             activity_types=parsed_preferences.get('activity_types', request.preferences.activity_types),
#             group_size=parsed_preferences.get('group_size', request.preferences.group_size),
#             min_rating=request.preferences.min_rating
#         )
        
#         print(f"📅 Creating day plan: {request.query}")
#         print(f"👤 Parsed preferences: Duration={parsed_preferences.get('duration', 'not specified')}, "
#               f"Budget={user_profile.budget_range}, Start={parsed_preferences.get('start_time', 'not specified')}")
#         print(f"🎯 Activity types: {user_profile.activity_types}")
        
#         # Use enhanced day planning with FANAR API
#         result = await manar_ai.rag_system.create_enhanced_day_plan(request.query, user_profile, parsed_preferences)
        
#         activities_count = len(result.get('day_plan', {}).get('activities', []))
#         total_cost = result.get('day_plan', {}).get('total_estimated_cost', 'Not calculated')
#         duration = result.get('day_plan', {}).get('total_duration', 'Not specified')
        
#         print(f"✅ Generated plan: {activities_count} activities, {duration}, {total_cost}")
        
#         return ApiResponse(
#             success=True,
#             data=result,
#             message=f"Day plan created using FANAR API: {activities_count} activities, {duration}, cost {total_cost}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )
        
#     except Exception as e:
#         print(f"❌ Planning error: {e}")
#         return ApiResponse(
#             success=False,
#             data={},
#             message=f"Error creating plan: {str(e)}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )

# @app.post("/api/v1/recommendations", response_model=ApiResponse)
# async def get_recommendations(request: RecommendationRequest):
#     """Get recommendations using FANAR API and RAG system"""
#     request_id = str(uuid.uuid4())
    
#     try:
#         if not manar_ai:
#             return ApiResponse(
#                 success=False,
#                 data={"recommendations": []},
#                 message="ManarAI system not initialized",
#                 request_id=request_id,
#                 timestamp=datetime.now().isoformat()
#             )
        
#         user_profile = UserProfile(
#             user_id=request.user_id,
#             food_preferences=request.preferences.food_preferences,
#             budget_range=request.preferences.budget_range,
#             activity_types=request.preferences.activity_types,
#             group_size=request.preferences.group_size,
#             min_rating=request.preferences.min_rating
#         )
        
#         print(f"🔍 Getting recommendations: {request.query}")
        
#         # Use FANAR API + RAG system for recommendations
#         result = await manar_ai.rag_system.generate_recommendations(request.query, user_profile)
        
#         rec_count = len(result.get('recommendations', []))
#         print(f"✅ Found {rec_count} recommendations using FANAR API")
        
#         return ApiResponse(
#             success=True,
#             data=result,
#             message=f"Found {rec_count} recommendations using FANAR API and RAG database",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )
        
#     except Exception as e:
#         print(f"❌ Recommendations error: {e}")
#         return ApiResponse(
#             success=False,
#             data={"recommendations": []},
#             message=f"Error getting recommendations: {str(e)}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )

# @app.post("/api/v1/book", response_model=ApiResponse)
# async def process_booking(request: BookingRequest):
#     """Process booking using FANAR API and RAG system"""
#     request_id = str(uuid.uuid4())
    
#     try:
#         if not manar_ai:
#             # Fallback booking
#             booking_id = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
#             booking_data = {
#                 "booking_id": booking_id,
#                 "status": "confirmed",
#                 "venue_name": request.venue_name,
#                 "date": request.date,
#                 "time": request.time,
#                 "party_size": request.party_size,
#                 "confirmation_number": f"CONF-{booking_id}",
#                 "estimated_cost": "$75",
#                 "contact_info": "+974 4444 0000",
#                 "location": f"Qatar - {request.venue_name}",
#                 "notes": "Booking confirmed (fallback mode)"
#             }
            
#             return ApiResponse(
#                 success=True,
#                 data={"booking": booking_data},
#                 message="Booking processed (fallback mode)",
#                 request_id=request_id,
#                 timestamp=datetime.now().isoformat()
#             )
        
#         user_profile = UserProfile(
#             user_id=request.user_id,
#             food_preferences=["Middle Eastern", "Traditional"],
#             budget_range="$",
#             activity_types=["Cultural", "Food"],
#             group_size=request.party_size,
#             min_rating=4.0
#         )
        
#         booking_query = f"Book a table at {request.venue_name} for {request.party_size} people on {request.date} at {request.time}"
#         if request.special_requirements:
#             booking_query += f" with special requirements: {request.special_requirements}"
        
#         print(f"📝 Processing booking: {booking_query}")
        
#         # Use FANAR API + RAG system for booking
#         result = await manar_ai.rag_system.process_booking_request(booking_query, user_profile)
        
#         booking_id = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
#         booking_details = result.get('booking_details', {})
        
#         booking_data = {
#             "booking_id": booking_id,
#             "status": "confirmed",
#             "venue_name": request.venue_name,
#             "date": request.date,
#             "time": request.time,
#             "party_size": request.party_size,
#             "special_requirements": request.special_requirements,
#             "confirmation_number": f"CONF-{booking_id}",
#             "estimated_cost": booking_details.get('estimated_cost', '$75'),
#             "cancellation_policy": "Free cancellation up to 2 hours before reservation",
#             "contact_info": f"+974 4444 {datetime.now().microsecond // 1000:04d}",
#             "location": f"Qatar - {request.venue_name}",
#             "notes": "Booking processed using FANAR API intelligence",
#             "fanar_insights": result.get('booking_summary', 'Booking processed successfully')
#         }
        
#         # Save booking to in-memory storage
#         await save_user_booking(request.user_id, booking_data)
        
#         print(f" Booking completed: {booking_data['confirmation_number']}")
        
#         return ApiResponse(
#             success=True,
#             data={"booking": booking_data},
#             message="Booking processed using FANAR API",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )
        
#     except Exception as e:
#         print(f" Booking error: {e}")
#         return ApiResponse(
#             success=False,
#             data={},
#             message=f"Error processing booking: {str(e)}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )

# @app.post("/api/v1/search", response_model=ApiResponse)
# async def quick_search(request: QuickSearchRequest):
#     """Search using RAG database and FANAR API"""
#     request_id = str(uuid.uuid4())
    
#     try:
#         if not manar_ai:
#             return ApiResponse(
#                 success=False,
#                 data={"results": [], "total_count": 0},
#                 message="ManarAI system not available",
#                 request_id=request_id,
#                 timestamp=datetime.now().isoformat()
#             )
        
#         user_profile = UserProfile(
#             user_id="search_user",
#             food_preferences=["Middle Eastern", "Traditional"],
#             budget_range=request.budget or "$",
#             activity_types=["Cultural", "Food"],
#             language="en",
#             group_size=1,
#             min_rating=4.0
#         )
        
#         search_query = request.query
#         if request.category:
#             search_query += f" in {request.category} category"
#         if request.location:
#             search_query += f" near {request.location}"
        
#         print(f"🔍 Searching database: {search_query}")
        
#         # Use vector database for search
#         context_results = manar_ai.rag_system.retrieve_context(search_query, user_profile, n_results=10)
        
#         search_results = []
#         for result in context_results:
#             metadata = result['metadata']
#             search_results.append({
#                 "name": metadata.get('name', 'Unknown'),
#                 "type": metadata.get('category', 'attraction'),
#                 "description": result['document'][:200] + "...",
#                 "location": metadata.get('location', 'Qatar'),
#                 "price_range": metadata.get('price_range', metadata.get('entry_fee', '')),
#                 "rating": metadata.get('rating', 4.0),
#                 "estimated_duration": "1-2 hours",
#                 "why_recommended": f"Found in database with {result['similarity']:.1%} relevance",
#                 "booking_available": metadata.get('category') == 'restaurants',
#                 "best_time_to_visit": "Anytime",
#                 "features": [],
#                 "similarity_score": result['similarity']
#             })
        
#         print(f" Found {len(search_results)} results in database")
        
#         return ApiResponse(
#             success=True,
#             data={
#                 "results": search_results,
#                 "total_count": len(search_results),
#                 "query": request.query,
#                 "rag_context_used": True,
#                 "database_source": "Qatar tourism database with FANAR API enhancement"
#             },
#             message=f"Found {len(search_results)} results using enhanced search",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )
        
#     except Exception as e:
#         print(f" Search error: {e}")
#         return ApiResponse(
#             success=False,
#             data={"results": [], "total_count": 0},
#             message=f"Search error: {str(e)}",
#             request_id=request_id,
#             timestamp=datetime.now().isoformat()
#         )

# # System status endpoints
# @app.get("/api/v1/fanar/status")
# async def fanar_status():
#     """Get FANAR API status"""
#     if not manar_ai:
#         return {"status": "not_initialized", "message": "ManarAI system not initialized"}
    
#     try:
#         # Check FANAR API availability
#         fanar_available = await manar_ai.rag_system.fanar_client._check_api_availability()
        
#         return {
#             "status": "healthy" if fanar_available else "fallback_mode",
#             "fanar_api_available": fanar_available,
#             "last_check": manar_ai.rag_system.fanar_client.last_check,
#             "api_base": manar_ai.rag_system.fanar_client.base_url,
#             "fallback_enabled": True
#         }
#     except Exception as e:
#         return {"status": "error", "message": str(e)}

# @app.get("/api/v1/rag/status")
# async def rag_status():
#     """Get RAG system status"""
#     if not manar_ai:
#         return {"status": "not_initialized", "message": "Please run setup scripts first"}
    
#     try:
#         collection_count = manar_ai.rag_system.collection.count()
#         return {
#             "status": "healthy",
#             "vector_db_items": collection_count,
#             "embedding_model": "paraphrase-multilingual-MiniLM-L12-v2",
#             "database_source": "Qatar tourism database"
#         }
#     except Exception as e:
#         return {"status": "error", "message": str(e)}


# # User management endpoints
# @app.get("/api/v1/user/{user_id}/bookings")
# async def get_user_bookings_endpoint(user_id: str):
#     try:
#         bookings = await get_user_bookings(user_id)
#         return {"success": True, "bookings": bookings}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# @app.post("/api/v1/user/{user_id}/profile")
# async def update_user_profile(user_id: str, preferences: UserPreferencesModel):
#     try:
#         # Save to in-memory storage
#         user_profiles[user_id] = {
#             'food_preferences': preferences.food_preferences,
#             'budget_range': preferences.budget_range,
#             'activity_types': preferences.activity_types,
#             'language': preferences.language,
#             'group_size': preferences.group_size,
#             'min_rating': preferences.min_rating,
#             'updated_at': datetime.now().isoformat()
#         }
        
#         return {"message": "Profile updated successfully", "user_id": user_id}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# @app.get("/api/v1/user/{user_id}/profile")
# async def get_user_profile(user_id: str):
#     try:
#         profile = user_profiles.get(user_id, {
#             "user_id": user_id,
#             "food_preferences": [],
#             "budget_range": "$",
#             "activity_types": [],
#             "language": "en",
#             "group_size": 1,
#             "min_rating": 4.0
#         })
        
#         return profile
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# # Run the server
# if __name__ == "__main__":
#     print("🚀 Starting Manara with FANAR API Integration...")
#     print("📚 API Documentation: http://localhost:8000/docs")
#     print("💚 Health Check: http://localhost:8000/health")
#     print("🤖 FANAR API Status: http://localhost:8000/api/v1/fanar/status")
#     print("🧠 RAG Status: http://localhost:8000/api/v1/rag/status")
   
#     uvicorn.run(
#         "backend_api_wrapper:app",
#         host="0.0.0.0",
#         port=8000,
#         reload=True,
#         log_level="info"
#     )

# backend_api_wrapper.py - Fixed Version with Proper FANAR Integration
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import asyncio
import uvicorn
import json
from datetime import datetime
import uuid
import logging


# Import your fixed FANAR integration
from fanar_api_integration import ManarAI, UserProfile
logger = logging.getLogger(__name__)

# Pydantic models
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

class ApiResponse(BaseModel):
    success: bool
    data: Any
    message: str = ""
    request_id: str
    timestamp: str

# Initialize FastAPI app
app = FastAPI(
    title="Manara API with FANAR Integration",
    description="Backend API with FANAR API integration and RAG system",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize your system
FANAR_API_KEY = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"
manar_ai = None

# In-memory storage for demonstration
user_bookings = {}
user_profiles = {}

@app.on_event("startup")
async def startup_event():
    """Initialize ManarAI system on startup"""
    global manar_ai
    try:
        print(" Initializing ManarAI with FANAR API integration...")
        
        # Make sure your vector database exists
        import os
        if not os.path.exists("./chroma_db"):
            print(" Vector database not found. Please run:")
            print("1. python qatar_database.py")
            print("2. python embeddings_vector_db.py")
            return
        
        # Initialize using your existing files
        manar_ai = ManarAI(FANAR_API_KEY)
        print(" ManarAI system initialized successfully!")
        print(f" Vector database loaded with {manar_ai.rag_system.collection.count()} items")
        # print(f" FANAR API status: {'Available' if manar_ai.rag_system.fanar_client.is_available else 'Fallback mode'}")
        
    except Exception as e:
        print(f" Error initializing ManarAI: {e}")
        print("Please make sure you have run the setup scripts:")
        print("1. python qatar_database.py")
        print("2. python embeddings_vector_db.py")
        manar_ai = None

# Helper functions for in-memory storage
async def save_user_booking(user_id: str, booking_data: Dict) -> bool:
    """Save booking to in-memory storage"""
    if user_id not in user_bookings:
        user_bookings[user_id] = []
    
    booking_data['created_at'] = datetime.now().isoformat()
    booking_data['updated_at'] = datetime.now().isoformat()
    user_bookings[user_id].append(booking_data)
    
    print(f" Booking saved for user {user_id}")
    return True

async def get_user_bookings(user_id: str) -> List[Dict]:
    """Get user bookings from in-memory storage"""
    return user_bookings.get(user_id, [])

def _parse_planning_query(query: str) -> Dict:
    """Parse planning query to extract user preferences"""
    parsed = {}
    query_lower = query.lower()
    
    # Extract duration
    if 'extended day' in query_lower or '12 hour' in query_lower:
        parsed['duration'] = 12
        parsed['duration_text'] = 'extended day (12 hours)'
    elif 'full day' in query_lower or '8 hour' in query_lower:
        parsed['duration'] = 8
        parsed['duration_text'] = 'full day (8 hours)'
    elif 'half day' in query_lower or '4 hour' in query_lower:
        parsed['duration'] = 4
        parsed['duration_text'] = 'half day (4 hours)'
    
    # Extract start time
    if 'early morning' in query_lower or '7-9 am' in query_lower:
        parsed['start_time'] = '07:00'
        parsed['start_time_text'] = 'early morning'
    elif 'morning' in query_lower or '9-11 am' in query_lower:
        parsed['start_time'] = '09:00'
        parsed['start_time_text'] = 'morning'
    elif 'afternoon' in query_lower or '12-2 pm' in query_lower:
        parsed['start_time'] = '13:00'
        parsed['start_time_text'] = 'afternoon'
    
    # Extract budget
    if 'premium' in query_lower or '$200+' in query_lower:
        parsed['budget_range'] = '$$$'
        parsed['budget_amount'] = 250
        parsed['budget_text'] = 'premium ($200+)'
    elif 'moderate' in query_lower or '$100-200' in query_lower:
        parsed['budget_range'] = '$$'
        parsed['budget_amount'] = 150
        parsed['budget_text'] = 'moderate ($100-200)'
    elif 'budget' in query_lower or '$50-100' in query_lower:
        parsed['budget_range'] = '$'
        parsed['budget_amount'] = 75
        parsed['budget_text'] = 'budget-friendly ($50-100)'
    
    # Extract activity preferences
    activity_types = []
    if 'cultural' in query_lower or 'historic' in query_lower:
        activity_types.append('Cultural')
    if 'food' in query_lower or 'dining' in query_lower:
        activity_types.append('Food')
    if 'modern' in query_lower or 'shopping' in query_lower:
        activity_types.append('Modern')
    if 'mix of everything' in query_lower or 'surprise me' in query_lower:
        activity_types = ['Cultural', 'Food', 'Modern', 'Shopping']
        parsed['surprise_mode'] = True
    
    if activity_types:
        parsed['activity_types'] = activity_types
    
    # Extract special preferences
    if 'traditional souqs' in query_lower:
        parsed['include_souqs'] = True
    if 'cultural sites' in query_lower:
        parsed['prioritize_culture'] = True
    if 'restaurants' in query_lower:
        parsed['include_restaurants'] = True
        if not parsed.get('activity_types'):
            parsed['activity_types'] = ['Food']
    
    return parsed

# API Endpoints
@app.get("/")
async def root():
    fanar_status = "connected" if manar_ai and manar_ai.rag_system.fanar_client.is_available else "fallback mode"
    rag_status = "initialized" if manar_ai else "not initialized"
    vector_count = 0
    if manar_ai:
        try:
            vector_count = manar_ai.rag_system.collection.count()
        except:
            pass
    
    return {
        "message": "🇶🇦 Manara Tourism API with FANAR Integration", 
        "status": "running", 
        "version": "1.0.0",
        "fanar_api_status": fanar_status,
        "rag_status": rag_status,
        "vector_items": vector_count,
        "features": ["FANAR API", "RAG System", "Qatar Tourism Database"]
    }

@app.get("/health")
async def health_check():
    # fanar_health = "connected" if manar_ai and manar_ai.rag_system.fanar_client.is_available else "fallback"
    fanar_health = "connected" if manar_ai else "fallback"
    rag_health = "healthy" if manar_ai else "unavailable"
    vector_count = 0
    if manar_ai:
        try:
            vector_count = manar_ai.rag_system.collection.count()
        except:
            pass
    
    return {
        "status": "healthy", 
        "timestamp": datetime.now().isoformat(),
        "fanar_api": fanar_health,
        "rag_system": rag_health,
        "vector_db": "connected" if manar_ai else "disconnected",
        "vector_items": vector_count
    }

@app.post("/api/v1/chat", response_model=ApiResponse)
async def chat_endpoint(request: ChatRequest):
    """Chat endpoint using FANAR API and RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manar_ai:
            return ApiResponse(
                success=False,
                data={"message": "ManarAI system not initialized. Please check the vector database setup."},
                message="System not available",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        # Create user profile
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=["Middle Eastern", "Traditional"],
            budget_range="$",
            activity_types=["Cultural", "Food"],
            language="en",
            group_size=1,
            min_rating=4.0
        )
        
        # Process with FANAR + RAG system
        print(f" Processing chat: {request.message}")
        result = await manar_ai.process_user_request(
            user_input=request.message,
            user_profile=user_profile,
            context=request.context
        )
        
        print(f" Response type: {result['type']}")
        
        return ApiResponse(
            success=True,
            data=result['data'],
            message=f"Response generated using FANAR API and RAG database ({result['type']})",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f" Chat endpoint error: {e}")
        return ApiResponse(
            success=False,
            data={"message": "Sorry, I couldn't process your request right now."},
            message=f"Error: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/plan", response_model=ApiResponse)
async def create_day_plan(request: PlanningRequest):
    """Create day plan using FANAR API and RAG system with preference parsing"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manar_ai:
            return ApiResponse(
                success=False,
                data={},
                message="ManarAI system not initialized",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        # Extract and parse user preferences from the query
        parsed_preferences = _parse_planning_query(request.query)
        
        # Merge with request preferences, giving priority to parsed preferences
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=parsed_preferences.get('food_preferences', request.preferences.food_preferences),
            budget_range=parsed_preferences.get('budget_range', request.preferences.budget_range),
            activity_types=parsed_preferences.get('activity_types', request.preferences.activity_types),
            group_size=parsed_preferences.get('group_size', request.preferences.group_size),
            min_rating=request.preferences.min_rating
        )
        
        print(f"📅 Creating day plan: {request.query}")
        print(f"👤 Parsed preferences: Duration={parsed_preferences.get('duration', 'not specified')}, "
              f"Budget={user_profile.budget_range}, Start={parsed_preferences.get('start_time', 'not specified')}")
        print(f"🎯 Activity types: {user_profile.activity_types}")
        
        # Use enhanced day planning with FANAR API
        result = await manar_ai.rag_system.create_enhanced_day_plan(request.query, user_profile, parsed_preferences)
        
        activities_count = len(result.get('day_plan', {}).get('activities', []))
        total_cost = result.get('day_plan', {}).get('total_estimated_cost', 'Not calculated')
        duration = result.get('day_plan', {}).get('total_duration', 'Not specified')
        
        print(f"✅ Generated plan: {activities_count} activities, {duration}, {total_cost}")
        
        return ApiResponse(
            success=True,
            data=result,
            message=f"Day plan created using FANAR API: {activities_count} activities, {duration}, cost {total_cost}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f"❌ Planning error: {e}")
        return ApiResponse(
            success=False,
            data={},
            message=f"Error creating plan: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/recommendations", response_model=ApiResponse)
async def get_recommendations(request: RecommendationRequest):
    """Get recommendations using FANAR API and RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manar_ai:
            return ApiResponse(
                success=False,
                data={"recommendations": []},
                message="ManarAI system not initialized",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=request.preferences.food_preferences,
            budget_range=request.preferences.budget_range,
            activity_types=request.preferences.activity_types,
            group_size=request.preferences.group_size,
            min_rating=request.preferences.min_rating
        )
        
        print(f"🔍 Getting recommendations: {request.query}")
        
        # Use FANAR API + RAG system for recommendations
        result = await manar_ai.rag_system.generate_recommendations(request.query, user_profile)
        
        rec_count = len(result.get('recommendations', []))
        print(f"✅ Found {rec_count} recommendations using FANAR API")
        
        return ApiResponse(
            success=True,
            data=result,
            message=f"Found {rec_count} recommendations using FANAR API and RAG database",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f"❌ Recommendations error: {e}")
        return ApiResponse(
            success=False,
            data={"recommendations": []},
            message=f"Error getting recommendations: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/book", response_model=ApiResponse)
async def process_booking(request: BookingRequest):
    """Process booking using FANAR API and RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manar_ai:
            # Fallback booking
            booking_id = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
            booking_data = {
                "booking_id": booking_id,
                "status": "confirmed",
                "venue_name": request.venue_name,
                "date": request.date,
                "time": request.time,
                "party_size": request.party_size,
                "confirmation_number": f"CONF-{booking_id}",
                "estimated_cost": "$75",
                "contact_info": "+974 4444 0000",
                "location": f"Qatar - {request.venue_name}",
                "notes": "Booking confirmed (fallback mode)"
            }
            
            return ApiResponse(
                success=True,
                data={"booking": booking_data},
                message="Booking processed (fallback mode)",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=["Middle Eastern", "Traditional"],
            budget_range="$",
            activity_types=["Cultural", "Food"],
            group_size=request.party_size,
            min_rating=4.0
        )
        
        booking_query = f"Book a table at {request.venue_name} for {request.party_size} people on {request.date} at {request.time}"
        if request.special_requirements:
            booking_query += f" with special requirements: {request.special_requirements}"
        
        print(f"📝 Processing booking: {booking_query}")
        
        # Use FANAR API + RAG system for booking
        result = await manar_ai.rag_system.process_booking_request(booking_query, user_profile)
        
        booking_id = f"MNR{datetime.now().strftime('%Y%m%d%H%M%S')}"
        booking_details = result.get('booking_details', {})
        
        booking_data = {
            "booking_id": booking_id,
            "status": "confirmed",
            "venue_name": request.venue_name,
            "date": request.date,
            "time": request.time,
            "party_size": request.party_size,
            "special_requirements": request.special_requirements,
            "confirmation_number": f"CONF-{booking_id}",
            "estimated_cost": booking_details.get('estimated_cost', '$75'),
            "cancellation_policy": "Free cancellation up to 2 hours before reservation",
            "contact_info": f"+974 4444 {datetime.now().microsecond // 1000:04d}",
            "location": f"Qatar - {request.venue_name}",
            "notes": "Booking processed using FANAR API intelligence",
            "fanar_insights": result.get('booking_summary', 'Booking processed successfully')
        }
        
        # Save booking to in-memory storage
        await save_user_booking(request.user_id, booking_data)
        
        print(f" Booking completed: {booking_data['confirmation_number']}")
        
        return ApiResponse(
            success=True,
            data={"booking": booking_data},
            message="Booking processed using FANAR API",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f" Booking error: {e}")
        return ApiResponse(
            success=False,
            data={},
            message=f"Error processing booking: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/search", response_model=ApiResponse)
async def quick_search(request: QuickSearchRequest):
    """Search using RAG database and FANAR API"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manar_ai:
            return ApiResponse(
                success=False,
                data={"results": [], "total_count": 0},
                message="ManarAI system not available",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        user_profile = UserProfile(
            user_id="search_user",
            food_preferences=["Middle Eastern", "Traditional"],
            budget_range=request.budget or "$",
            activity_types=["Cultural", "Food"],
            language="en",
            group_size=1,
            min_rating=4.0
        )
        
        search_query = request.query
        if request.category:
            search_query += f" in {request.category} category"
        if request.location:
            search_query += f" near {request.location}"
        
        print(f"🔍 Searching database: {search_query}")
        
        # Use vector database for search
        context_results = manar_ai.rag_system.retrieve_context(search_query, user_profile, n_results=10)
        
        search_results = []
        for result in context_results:
            metadata = result['metadata']
            search_results.append({
                "name": metadata.get('name', 'Unknown'),
                "type": metadata.get('category', 'attraction'),
                "description": result['document'][:200] + "...",
                "location": metadata.get('location', 'Qatar'),
                "price_range": metadata.get('price_range', metadata.get('entry_fee', '')),
                "rating": metadata.get('rating', 4.0),
                "estimated_duration": "1-2 hours",
                "why_recommended": f"Found in database with {result['similarity']:.1%} relevance",
                "booking_available": metadata.get('category') == 'restaurants',
                "best_time_to_visit": "Anytime",
                "features": [],
                "similarity_score": result['similarity']
            })
        
        print(f" Found {len(search_results)} results in database")
        
        return ApiResponse(
            success=True,
            data={
                "results": search_results,
                "total_count": len(search_results),
                "query": request.query,
                "rag_context_used": True,
                "database_source": "Qatar tourism database with FANAR API enhancement"
            },
            message=f"Found {len(search_results)} results using enhanced search",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f" Search error: {e}")
        return ApiResponse(
            success=False,
            data={"results": [], "total_count": 0},
            message=f"Search error: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

# System status endpoints
@app.get("/api/v1/fanar/status")
async def fanar_status():
    """Get FANAR API status"""
    if not manar_ai:
        return {"status": "not_initialized", "message": "ManarAI system not initialized"}
    
    try:
        # Check FANAR API availability
        fanar_available = await manar_ai.rag_system.fanar_client._check_api_availability()
        
        return {
            "status": "healthy" if fanar_available else "fallback_mode",
            "fanar_api_available": fanar_available,
            "last_check": manar_ai.rag_system.fanar_client.last_check,
            "api_base": manar_ai.rag_system.fanar_client.base_url,
            "fallback_enabled": True
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/api/v1/rag/status")
async def rag_status():
    """Get RAG system status"""
    if not manar_ai:
        return {"status": "not_initialized", "message": "Please run setup scripts first"}
    
    try:
        collection_count = manar_ai.rag_system.collection.count()
        return {
            "status": "healthy",
            "vector_db_items": collection_count,
            "embedding_model": "paraphrase-multilingual-MiniLM-L12-v2",
            "database_source": "Qatar tourism database"
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


# User management endpoints
@app.get("/api/v1/user/{user_id}/bookings")
async def get_user_bookings_endpoint(user_id: str):
    try:
        bookings = await get_user_bookings(user_id)
        return {"success": True, "bookings": bookings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/user/{user_id}/profile")
async def update_user_profile(user_id: str, preferences: UserPreferencesModel):
    try:
        # Save to in-memory storage
        user_profiles[user_id] = {
            'food_preferences': preferences.food_preferences,
            'budget_range': preferences.budget_range,
            'activity_types': preferences.activity_types,
            'language': preferences.language,
            'group_size': preferences.group_size,
            'min_rating': preferences.min_rating,
            'updated_at': datetime.now().isoformat()
        }
        
        return {"message": "Profile updated successfully", "user_id": user_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/user/{user_id}/profile")
async def get_user_profile(user_id: str):
    try:
        profile = user_profiles.get(user_id, {
            "user_id": user_id,
            "food_preferences": [],
            "budget_range": "$",
            "activity_types": [],
            "language": "en",
            "group_size": 1,
            "min_rating": 4.0
        })
        
        return profile
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
# chatbot part
class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = "default"

class ChatResponse(BaseModel):
    success: bool
    response: Optional[str] = None
    error: Optional[str] = None
    timestamp: str
    conversation_id: Optional[str] = None

class ClearChatRequest(BaseModel):
    conversation_id: Optional[str] = "default"

class QatarChatbot:
    def __init__(self):
        self.model_name = "Fanar"
        self.conversation_history = {}
        
    def get_system_prompt(self):
        return """You are a helpful AI assistant specialized in Qatar tourism, culture, and local information. 
        You help visitors and residents discover the best of Qatar including:
        - Restaurants and local cuisine
        - Cultural attractions and museums
        - Shopping destinations
        - Family-friendly activities
        - Budget-friendly options
        - Traditional experiences
        - Transportation guidance
        - Weather and seasonal information
        
        Provide helpful, accurate, and engaging responses about Qatar. 
        Use emojis appropriately and format responses in a clear, readable way.
        Always be respectful of Qatari culture and Islamic values.
        If you don't know something specific about Qatar, suggest reliable local sources or official websites."""

    def generate_response(self, user_message: str, conversation_id: str = "default"):
        try:
            # Get or create conversation history
            if conversation_id not in self.conversation_history:
                self.conversation_history[conversation_id] = [
                    {"role": "system", "content": self.get_system_prompt()}
                ]
            
            # Add user message to history
            self.conversation_history[conversation_id].append({
                "role": "user", 
                "content": user_message
            })
            
            # Generate response using Fanar API
            response = manar_ai.rag_system.fanar_client.chat.completions.create(
                model=self.model_name,
                messages=self.conversation_history[conversation_id],
                max_tokens=800,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content
            
            # Add AI response to history
            self.conversation_history[conversation_id].append({
                "role": "assistant",
                "content": ai_response
            })
            
            # Limit conversation history to last 20 messages to prevent token overflow
            if len(self.conversation_history[conversation_id]) > 21:  # 1 system + 20 messages
                self.conversation_history[conversation_id] = (
                    [self.conversation_history[conversation_id][0]] +  # Keep system message
                    self.conversation_history[conversation_id][-20:]   # Keep last 20
                )
            
            return ChatResponse(
                success=True,
                response=ai_response,
                timestamp=datetime.now().isoformat(),
                conversation_id=conversation_id
            )
            
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            return ChatResponse(
                success=False,
                error="Failed to generate response. Please try again.",
                timestamp=datetime.now().isoformat()
            )

    def clear_conversation(self, conversation_id: str):
        """Clear conversation history for a specific user"""
        if conversation_id in self.conversation_history:
            del self.conversation_history[conversation_id]

# Initialize chatbot
chatbot = QatarChatbot()

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Main chat endpoint"""
    try:
        if not request.message or not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        user_message = request.message.strip()
        conversation_id = request.conversation_id or "default"
        
        # Generate response
        result = chatbot.generate_response(user_message, conversation_id)
        
        if not result.success:
            raise HTTPException(status_code=500, detail=result.error)
            
        return result
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/clear_chat")
async def clear_chat(request: ClearChatRequest):
    """Clear conversation history"""
    try:
        conversation_id = request.conversation_id or "default"
        chatbot.clear_conversation(conversation_id)
        
        return {
            "success": True,
            "message": "Conversation history cleared"
        }
        
    except Exception as e:
        logger.error(f"Error clearing chat: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to clear conversation")

@app.get("/conversation_status")
async def conversation_status(conversation_id: str = "default"):
    """Get conversation status and message count"""
    message_count = 0
    if conversation_id in chatbot.conversation_history:
        # Subtract 1 for system message
        message_count = len(chatbot.conversation_history[conversation_id]) - 1
    
    return {
        "conversation_id": conversation_id,
        "message_count": message_count,
        "has_history": message_count > 0
    }


# Run the server
if __name__ == "__main__":
    print("🚀 Starting Manara with FANAR API Integration...")
    print("📚 API Documentation: http://localhost:8000/docs")
    print("💚 Health Check: http://localhost:8000/health")
    print("🤖 FANAR API Status: http://localhost:8000/api/v1/fanar/status")
    print("🧠 RAG Status: http://localhost:8000/api/v1/rag/status")
   
    uvicorn.run(
        "backend_api_wrapper:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )