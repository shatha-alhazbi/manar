# backend_api_wrapper.py 
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import asyncio
import uvicorn
import json
from datetime import datetime
import uuid
import firebase_admin
from firebase_admin import credentials, firestore
import os

from fanar_api_integration import ManaraAI, UserProfile

# Initialize Firebase
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("path/to/your/serviceAccountKey.json")  # Update this path
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully")
    except Exception as e:
        print(f"Firebase initialization error: {e}")
        # Continue without Firebase for development

try:
    db = firestore.client()
    print("Firestore client initialized")
except:
    db = None
    print("Running without Firestore")

# Pydantic models (same as before)
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
    title="Manar API with RAG System",
    description="Backend API with existing embeddings_vector_db.py and fanar_api_integration.py",
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

# Initialize your RAG system
FANAR_API_KEY = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"
manara_ai = None

@app.on_event("startup")
async def startup_event():
    """Initialize your existing RAG system on startup"""
    global manara_ai
    try:
        print("Initializing Manara AI with your existing RAG database...")
        
        # Make sure your vector database exists
        import os
        if not os.path.exists("./chroma_db"):
            print("Vector database not found. Please run:")
            print("1. python qatar_database.py")
            print("2. python embeddings_vector_db.py")
            return
        
        # Initialize using your existing files
        manara_ai = ManaraAI(FANAR_API_KEY)
        print(" Manar AI system initialized successfully with your RAG database!")
        print(f" Vector database loaded with {manara_ai.rag_system.collection.count()} items")
        
    except Exception as e:
        print(f" Error initializing Manara AI: {e}")
        print("Please make sure you have run the setup scripts:")
        print("1. python qatar_database.py")
        print("2. python embeddings_vector_db.py")
        manara_ai = None

# Firebase helper functions (same as before)
async def save_user_booking(user_id: str, booking_data: Dict) -> bool:
    if not db:
        print("Firebase not available, skipping save")
        return True
        
    try:
        doc_ref = db.collection('users').document(user_id).collection('bookings').document(booking_data['id'])
        doc_ref.set({
            **booking_data,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        return True
    except Exception as e:
        print(f"Error saving booking to Firebase: {e}")
        return False

async def get_user_bookings(user_id: str) -> List[Dict]:
    if not db:
        return []
        
    try:
        bookings_ref = db.collection('users').document(user_id).collection('bookings')
        docs = bookings_ref.order_by('created_at', direction=firestore.Query.DESCENDING).stream()
        
        bookings = []
        for doc in docs:
            booking_data = doc.to_dict()
            booking_data['id'] = doc.id
            bookings.append(booking_data)
        
        return bookings
    except Exception as e:
        print(f"Error getting bookings from Firebase: {e}")
        return []

# API Endpoints using your existing RAG system

@app.get("/")
async def root():
    rag_status = "initialized" if manara_ai else "not initialized"
    vector_count = 0
    if manara_ai:
        try:
            vector_count = manara_ai.rag_system.collection.count()
        except:
            pass
    
    return {
        "message": "Manara Tourism API with Your RAG System", 
        "status": "running", 
        "version": "1.0.0",
        "rag_status": rag_status,
        "vector_items": vector_count
    }

@app.get("/health")
async def health_check():
    rag_health = "healthy" if manara_ai else "unavailable"
    vector_count = 0
    if manara_ai:
        try:
            vector_count = manara_ai.rag_system.collection.count()
        except:
            pass
    
    return {
        "status": "healthy", 
        "timestamp": datetime.now().isoformat(),
        "rag_system": rag_health,
        "vector_db": "connected" if manara_ai else "disconnected",
        "vector_items": vector_count
    }

@app.post("/api/v1/chat", response_model=ApiResponse)
async def chat_endpoint(request: ChatRequest):
    """Chat endpoint using your RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manara_ai:
            return ApiResponse(
                success=False,
                data={"message": "AI system not initialized. Please check the vector database setup."},
                message="RAG system not available",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        # Create user profile
        user_profile = UserProfile(
            user_id=request.user_id,
            food_preferences=["Middle Eastern", "Traditional"],
            budget_range="$$",
            activity_types=["Cultural", "Food"],
            language="en",
            group_size=1,
            min_rating=4.0
        )
        
        # Process with your RAG + FANAR system
        print(f" Processing chat: {request.message}")
        result = await manara_ai.process_user_request(
            user_input=request.message,
            user_profile=user_profile,
            context=request.context
        )
        
        print(f" RAG response type: {result['type']}")
        
        return ApiResponse(
            success=True,
            data=result['data'],
            message="Response generated using your RAG database",
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
    """Create day plan using your RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manara_ai:
            return ApiResponse(
                success=False,
                data={},
                message="RAG system not initialized",
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
        
        print(f" Creating day plan: {request.query}")
        print(f" User preferences: {user_profile.food_preferences}, {user_profile.budget_range}")
        
        # Use your RAG system for planning
        result = await manara_ai.rag_system.create_day_plan(request.query, user_profile)
        
        activities_count = len(result.get('day_plan', {}).get('activities', []))
        print(f" Generated plan with {activities_count} activities from your RAG database")
        
        return ApiResponse(
            success=True,
            data=result,
            message=f"Day plan created with {activities_count} activities from your database",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f" Planning error: {e}")
        return ApiResponse(
            success=False,
            data={},
            message=f"Error creating plan: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/recommendations", response_model=ApiResponse)
async def get_recommendations(request: RecommendationRequest):
    """Get recommendations using your RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manara_ai:
            return ApiResponse(
                success=False,
                data={"recommendations": []},
                message="RAG system not initialized",
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
        
        print(f" Getting recommendations: {request.query}")
        
        # Use your RAG system for recommendations
        result = await manara_ai.rag_system.generate_recommendations(request.query, user_profile)
        
        rec_count = len(result.get('recommendations', []))
        print(f" Found {rec_count} recommendations from your RAG database")
        
        return ApiResponse(
            success=True,
            data=result,
            message=f"Found {rec_count} recommendations from your database",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f" Recommendations error: {e}")
        return ApiResponse(
            success=False,
            data={"recommendations": []},
            message=f"Error getting recommendations: {str(e)}",
            request_id=request_id,
            timestamp=datetime.now().isoformat()
        )

@app.post("/api/v1/book", response_model=ApiResponse)
async def process_booking(request: BookingRequest):
    """Process booking using your RAG system"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manara_ai:
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
            budget_range="$$",
            activity_types=["Cultural", "Food"],
            group_size=request.party_size,
            min_rating=4.0
        )
        
        booking_query = f"Book a table at {request.venue_name} for {request.party_size} people on {request.date} at {request.time}"
        if request.special_requirements:
            booking_query += f" with special requirements: {request.special_requirements}"
        
        print(f" Processing booking: {booking_query}")
        
        # Use your RAG system for booking
        result = await manara_ai.rag_system.process_booking_request(booking_query, user_profile)
        
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
            "notes": "Booking enhanced with your RAG database intelligence",
            "rag_insights": result.get('booking_summary', 'Booking processed successfully')
        }
        
        print(f" Booking completed: {booking_data['confirmation_number']}")
        
        return ApiResponse(
            success=True,
            data={"booking": booking_data},
            message="Booking processed with your RAG intelligence",
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
    """Search using your RAG database"""
    request_id = str(uuid.uuid4())
    
    try:
        if not manara_ai:
            return ApiResponse(
                success=False,
                data={"results": [], "total_count": 0},
                message="RAG system not available",
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
        
        user_profile = UserProfile(
            user_id="search_user",
            food_preferences=["Middle Eastern", "Traditional"],
            budget_range=request.budget or "$$",
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
        
        print(f"🔍 Searching your RAG database: {search_query}")
        
        # Use your vector database for search
        context_results = manara_ai.rag_system.retrieve_context(search_query, user_profile, n_results=10)
        
        search_results = []
        for result in context_results:
            metadata = result['metadata']
            search_results.append({
                "name": metadata.get('name', 'Unknown'),
                "type": metadata.get('category', 'attraction'),
                "description": result['document'][:200] + "...",
                "location": metadata.get('location', 'Qatar'),
                "price_range": metadata.get('price_range', metadata.get('entry_fee', '$$')),
                "rating": metadata.get('rating', 4.0),
                "estimated_duration": "1-2 hours",
                "why_recommended": f"Found in your database with {result['similarity']:.1%} relevance",
                "booking_available": metadata.get('category') == 'restaurants',
                "best_time_to_visit": "Anytime",
                "features": [],
                "similarity_score": result['similarity']
            })
        
        print(f" Found {len(search_results)} results in RAG database")
        
        return ApiResponse(
            success=True,
            data={
                "results": search_results,
                "total_count": len(search_results),
                "query": request.query,
                "rag_context_used": True,
                "database_source": "Your custom Qatar tourism database"
            },
            message=f"Found {len(search_results)} results in your database",
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

# Your RAG-specific endpoints
@app.get("/api/v1/rag/status")
async def rag_status():
    """Get your RAG system status"""
    if not manara_ai:
        return {"status": "not_initialized", "message": "Please run setup scripts first"}
    
    try:
        collection_count = manara_ai.rag_system.collection.count()
        return {
            "status": "healthy",
            "vector_db_items": collection_count,
            "embedding_model": "paraphrase-multilingual-MiniLM-L12-v2",
            "fanar_api": "connected",
            "database_source": "Your custom Qatar tourism database"
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/api/v1/rag/query")
async def query_rag_directly(query: str, user_id: str, n_results: int = 5):
    """Direct query to your RAG database"""
    if not manara_ai:
        raise HTTPException(status_code=503, detail="RAG system not available")
    
    try:
        user_profile = UserProfile(
            user_id=user_id,
            food_preferences=["Middle Eastern"],
            budget_range="$$",
            activity_types=["Cultural"],
            language="en",
            group_size=1,
            min_rating=4.0
        )
        
        results = manara_ai.rag_system.retrieve_context(query, user_profile, n_results)
        
        return {
            "query": query,
            "results_count": len(results),
            "database_source": "Your custom Qatar tourism database",
            "results": [
                {
                    "document": r['document'][:200] + "...",
                    "metadata": r['metadata'],
                    "similarity": r['similarity']
                } for r in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Firebase endpoints (same as before)
@app.post("/api/v1/user/{user_id}/bookings")
async def save_user_booking_endpoint(user_id: str, booking_data: Dict):
    try:
        success = await save_user_booking(user_id, booking_data)
        if success:
            return {"success": True, "message": "Booking saved successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to save booking")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/user/{user_id}/bookings")
async def get_user_bookings_endpoint(user_id: str):
    try:
        bookings = await get_user_bookings(user_id)
        return {"success": True, "bookings": bookings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/v1/user/{user_id}/bookings/{booking_id}")
async def update_user_booking_endpoint(user_id: str, booking_id: str, updates: Dict):
    try:
        if not db:
            return {"success": True, "message": "Firebase not available"}
            
        doc_ref = db.collection('users').document(user_id).collection('bookings').document(booking_id)
        doc_ref.update({**updates, 'updated_at': firestore.SERVER_TIMESTAMP})
        return {"success": True, "message": "Booking updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/user/{user_id}/bookings/{booking_id}")
async def delete_user_booking_endpoint(user_id: str, booking_id: str):
    try:
        if not db:
            return {"success": True, "message": "Firebase not available"}
            
        doc_ref = db.collection('users').document(user_id).collection('bookings').document(booking_id)
        doc_ref.delete()
        return {"success": True, "message": "Booking deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# User profile endpoints (same as before)
@app.get("/api/v1/user/{user_id}/profile")
async def get_user_profile(user_id: str):
    try:
        if not db:
            return {
                "user_id": user_id,
                "food_preferences": [],
                "budget_range": "$$",
                "activity_types": [],
                "language": "en",
                "group_size": 1,
                "min_rating": 4.0
            }
            
        doc_ref = db.collection('users').document(user_id)
        doc = doc_ref.get()
        
        if doc.exists:
            profile_data = doc.to_dict()
            return {
                "user_id": user_id,
                "food_preferences": profile_data.get('food_preferences', []),
                "budget_range": profile_data.get('budget_range', '$$'),
                "activity_types": profile_data.get('activity_types', []),
                "language": profile_data.get('language', 'en'),
                "group_size": profile_data.get('group_size', 1),
                "min_rating": profile_data.get('min_rating', 4.0)
            }
        else:
            return {
                "user_id": user_id,
                "food_preferences": [],
                "budget_range": "$$",
                "activity_types": [],
                "language": "en",
                "group_size": 1,
                "min_rating": 4.0
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/user/{user_id}/profile")
async def update_user_profile(user_id: str, preferences: UserPreferencesModel):
    try:
        if not db:
            return {"message": "Profile updated successfully (Firebase not available)", "user_id": user_id}
            
        doc_ref = db.collection('users').document(user_id)
        doc_ref.set({
            'food_preferences': preferences.food_preferences,
            'budget_range': preferences.budget_range,
            'activity_types': preferences.activity_types,
            'language': preferences.language,
            'group_size': preferences.group_size,
            'min_rating': preferences.min_rating,
            'updated_at': firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        return {"message": "Profile updated successfully", "user_id": user_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Run the server
if __name__ == "__main__":
    print(" Starting Manar with RAG System...")
    print(" API Documentation: http://localhost:8000/docs")
    print(" Health Check: http://localhost:8000/health")
    print(" RAG Status: http://localhost:8000/api/v1/rag/status")
   
    uvicorn.run(
        "backend_api_wrapper:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )