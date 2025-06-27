# import requests 
# import json
# import asyncio
# import aiohttp
# import chromadb
# from sentence_transformers import SentenceTransformer
# from typing import Dict, List, Optional, Any
# from dataclasses import dataclass
# from datetime import datetime
# import time
# import ssl

# # FANAR API Configuration
# FANAR_API_BASE = "https://api.fanar.qa"
# FANAR_API_KEY = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"  

# @dataclass
# class UserProfile:
#     user_id: str
#     food_preferences: List[str]
#     budget_range: str
#     activity_types: List[str]
#     language: str = "en"
#     accessibility_needs: List[str] = None
#     group_size: int = 1
#     min_rating: float = 4.0

# class FanarAPIClient:
#     def __init__(self, api_key: str, base_url: str = FANAR_API_BASE):
#         self.api_key = api_key
#         self.base_url = base_url
#         self.headers = {
#             "Authorization": f"Bearer {api_key}",
#             "Content-Type": "application/json",
#             "Accept": "application/json"
#         }
#         self.is_available = True
#         self.last_check = 0
#         self.check_interval = 300  # Check every 5 minutes
    
#     async def _check_api_availability(self) -> bool:
#         """Check if FANAR API is available"""
#         current_time = time.time()
#         if current_time - self.last_check < self.check_interval:
#             return self.is_available
        
#         try:
#             # Create SSL context that's more permissive
#             ssl_context = ssl.create_default_context()
#             ssl_context.check_hostname = False
#             ssl_context.verify_mode = ssl.CERT_NONE
            
#             connector = aiohttp.TCPConnector(ssl=ssl_context)
#             timeout = aiohttp.ClientTimeout(total=30)
            
#             async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
#                 async with session.get(f"{self.base_url}/v1/models", headers=self.headers) as response:
#                     self.is_available = response.status < 500
#         except Exception as e:
#             print(f"FANAR API availability check failed: {e}")
#             self.is_available = False
        
#         self.last_check = current_time
#         return self.is_available
    
#     async def generate_completion(self, prompt: str, max_tokens: int = 1000, temperature: float = 0.7) -> str:
#         """
#         Generate text completion using FANAR API with robust error handling
#         """
#         # Check API availability first
#         if not await self._check_api_availability():
#             print("FANAR API not available, using local fallback")
#             return self._local_fallback_completion(prompt)
        
#         messages = [
#             {"role": "user", "content": prompt}
#         ]

#         # print(f"ARWA prompt: {prompt}")

#         payload = {
#             "model": "Fanar",
#             "messages": messages,
#             "max_tokens": max_tokens,
#             "temperature": temperature
#         }
        
#         try:
#             # Create SSL context
#             ssl_context = ssl.create_default_context()
#             ssl_context.check_hostname = False
#             ssl_context.verify_mode = ssl.CERT_NONE
            
#             connector = aiohttp.TCPConnector(ssl=ssl_context)
#             timeout = aiohttp.ClientTimeout(total=30)
            
#             async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
#                 async with session.post(
#                     f"{self.base_url}/v1/chat/completions",
#                     headers=self.headers,
#                     json=payload
#                 ) as response:
#                     if response.status == 200:
#                         result = await response.json()
#                         return result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
#                     else:
#                         error_text = await response.text()
#                         print(f"FANAR API Error {response.status}: {error_text}")
#                         self.is_available = False
#                         return self._local_fallback_completion(prompt)
                        
#         except aiohttp.ClientError as e:
#             print(f"FANAR API Connection Error: {e}")
#             self.is_available = False
#             return self._local_fallback_completion(prompt)
#         except asyncio.TimeoutError:
#             print("FANAR API Timeout - using fallback")
#             return self._local_fallback_completion(prompt)
#         except Exception as e:
#             print(f"FANAR API Request Failed: {e}")
#             self.is_available = False
#             return self._local_fallback_completion(prompt)
    
#     def _local_fallback_completion(self, prompt: str) -> str:
#         """
#         Local fallback when FANAR API is not available
#         """
#         prompt_lower = prompt.lower()
        
#         # Analyze prompt to provide relevant fallback response
#         if "day plan" in prompt_lower or "itinerary" in prompt_lower:
#             return self._generate_day_plan_fallback(prompt)
#         elif "recommendation" in prompt_lower:
#             return self._generate_recommendations_fallback(prompt)
#         elif "booking" in prompt_lower:
#             return self._generate_booking_fallback(prompt)
#         elif "question" in prompt_lower:
#             return self._generate_questions_fallback(prompt)
#         else:
#             return self._generate_general_fallback(prompt)
    
#     def _generate_day_plan_fallback(self, prompt: str) -> str:
#         """Generate day plan fallback response"""
#         return '''
#         {
#             "day_plan": {
#                 "title": "Your Perfect Day in Qatar",
#                 "date": "2025-06-27",
#                 "total_estimated_cost": "$150-200",
#                 "total_duration": "10 hours",
#                 "activities": [
#                     {
#                         "time": "09:00",
#                         "activity": "Breakfast at Al Mourjan Restaurant",
#                         "location": "Corniche, Doha",
#                         "duration": "1 hour",
#                         "estimated_cost": "$25",
#                         "description": "Start your day with traditional Qatari breakfast overlooking the beautiful Corniche",
#                         "transportation": "Taxi from hotel",
#                         "booking_required": true,
#                         "tips": "Try the traditional dishes and enjoy the waterfront view"
#                     },
#                     {
#                         "time": "11:00",
#                         "activity": "Visit Museum of Islamic Art",
#                         "location": "Corniche, Doha", 
#                         "duration": "2.5 hours",
#                         "estimated_cost": "Free",
#                         "description": "Explore world-class Islamic art spanning 1,400 years from three continents",
#                         "transportation": "10-minute walk",
#                         "booking_required": false,
#                         "tips": "Visit during morning hours for fewer crowds and better photography"
#                     },
#                     {
#                         "time": "14:30",
#                         "activity": "Lunch at Souq Waqif Traditional Restaurant",
#                         "location": "Souq Waqif, Old Doha",
#                         "duration": "1.5 hours",
#                         "estimated_cost": "$35",
#                         "description": "Experience authentic Middle Eastern flavors in Qatar's most famous traditional market",
#                         "transportation": "15-minute taxi ride",
#                         "booking_required": false,
#                         "tips": "Perfect for experiencing local culture and traditional atmosphere"
#                     },
#                     {
#                         "time": "17:00",
#                         "activity": "Explore Katara Cultural Village",
#                         "location": "Katara, Doha",
#                         "duration": "2.5 hours",
#                         "estimated_cost": "Free",
#                         "description": "Cultural district featuring galleries, theaters, and beautiful beaches",
#                         "transportation": "20-minute taxi ride",
#                         "booking_required": false,
#                         "tips": "Visit the Blue Mosque and enjoy the beach area during sunset"
#                     },
#                     {
#                         "time": "20:00",
#                         "activity": "Dinner at The Pearl Qatar",
#                         "location": "The Pearl Qatar",
#                         "duration": "2 hours",
#                         "estimated_cost": "$80",
#                         "description": "End your day with fine dining at this luxury waterfront destination",
#                         "transportation": "15-minute drive",
#                         "booking_required": true,
#                         "tips": "Perfect location for dinner with marina views and luxury shopping"
#                     }
#                 ],
#                 "transportation_notes": "Use Karwa taxis or ride-hailing apps for convenient travel between locations",
#                 "total_walking_distance": "2 km",
#                 "weather_tips": "Stay hydrated, wear comfortable shoes, and bring sunscreen",
#                 "budget_breakdown": {
#                     "food": "$140",
#                     "attractions": "$0", 
#                     "transportation": "$30"
#                 }
#             }
#         }
#         '''
    
#     def _generate_recommendations_fallback(self, prompt: str) -> str:
#         """Generate recommendations fallback response"""
#         return '''
#         {
#             "recommendations": [
#                 {
#                     "name": "Arwa",
#                     "type": "attraction",
#                     "description": "World-class museum showcasing Islamic art spanning 1,400 years",
#                     "location": "Corniche, Doha",
#                     "price_range": "Free",
#                     "rating": 4.8,
#                     "estimated_duration": "2-3 hours",
#                     "why_recommended": "Perfect for cultural enthusiasts and art lovers",
#                     "booking_available": false,
#                     "best_time_to_visit": "Morning for fewer crowds"
#                 },
#             ],
#             "summary": "These recommendations offer a perfect mix of culture, dining, and authentic Qatari experiences"
#         }
#         '''
    
#     def _generate_booking_fallback(self, prompt: str) -> str:
#         """Generate booking fallback response"""
#         return '''
#         {
#             "booking_details": {
#                 "type": "restaurant",
#                 "venue_name": "Restaurant booking request",
#                 "date": "2025-06-27",
#                 "time": "19:00",
#                 "party_size": 2,
#                 "estimated_cost": "$75",
#                 "confirmation_needed": true
#             },
#             "booking_summary": "Booking request processed for restaurant reservation",
#             "next_steps": "Please confirm the booking details and we'll proceed with the reservation",
#             "missing_info": []
#         }
#         '''
    
#     def _generate_questions_fallback(self, prompt: str) -> str:
#         """Generate planning questions fallback"""
#         return '''
#         Here are some personalized questions to help plan your Qatar experience:
        
#         1. How much time do you have available for your Qatar adventure?
#         2. What type of experiences interest you most - cultural sites, food, modern attractions, or a mix?
#         3. What's your preferred budget range for the day?
#         4. Are there any specific places in Qatar you definitely want to visit?
#         5. What time would you prefer to start your day?
#         '''
    
#     def _generate_general_fallback(self, prompt: str) -> str:
#         """Generate general fallback response"""
#         return "I'm here to help you explore Qatar! I can assist with planning your day, finding great restaurants, recommending attractions, and helping with bookings. What would you like to know about Qatar?"

# class QatarRAGSystem:
#     def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
#         """
#         Initialize the complete RAG system with FANAR API and vector database
#         """
#         print("🚀 Initializing Qatar RAG System...")
        
#         # Initialize FANAR client with improved error handling
#         self.fanar_client = FanarAPIClient(fanar_api_key)
        
#         # Initialize vector database
#         self.embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
#         self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        
#         try:
#             self.collection = self.chroma_client.get_collection("qatar_tourism")
#             print(f"✅ Loaded vector database with {self.collection.count()} items")
#         except Exception as e:
#             print(f"❌ Error loading vector database: {e}")
#             print("Please run Step 2 first to create the vector database")
#             raise
    
#     def retrieve_context(self, query: str, user_profile: UserProfile, n_results: int = 5) -> List[Dict]:
#         """
#         Retrieve relevant context from vector database based on query and user preferences
#         """
#         try:
#             # Enhance query with user preferences
#             enhanced_query_parts = [query]
#             # print(f"ARWA enhanced_query_parts: {enhanced_query_parts}")
#             if user_profile.food_preferences:
#                 enhanced_query_parts.append(f"cuisine preferences: {', '.join(user_profile.food_preferences)}")

#             # print(f"ARWA enhanced_query_parts 2: {enhanced_query_parts}")
#             if user_profile.activity_types:
#                 enhanced_query_parts.append(f"activity interests: {', '.join(user_profile.activity_types)}")
            
#             # print(f"ARWA enhanced_query_parts 3: {enhanced_query_parts}")
#             if user_profile.budget_range:
#                 enhanced_query_parts.append(f"budget: {user_profile.budget_range}")

#             # print(f"ARWA enhanced_query_parts 4: {enhanced_query_parts}")
#             enhanced_query = ". ".join(enhanced_query_parts)

#             # Create query embedding
#             query_embedding = self.embedding_model.encode([enhanced_query])
            
#             # Search vector database
#             results = self.collection.query(
#                 query_embeddings=query_embedding.tolist(),
#                 n_results=n_results * 2,  # Get more results for filtering
#                 include=['documents', 'metadatas', 'distances']
#             )
            
#             # Filter and format results
#             filtered_results = []
#             for i in range(len(results['ids'][0])):
#                 metadata = results['metadatas'][0][i]
                
#                 # Apply user preference filters
#                 if user_profile.budget_range:
#                     item_price = metadata.get('price_range', '')
#                     if item_price and item_price != user_profile.budget_range:
#                         # Allow some flexibility in budget
#                         budget_order = {'$': 1, '$$': 2, '$$$': 3}
#                         if (user_profile.budget_range in budget_order and 
#                             item_price in budget_order and 
#                             budget_order[item_price] > budget_order[user_profile.budget_range] + 1):
#                             continue
                
#                 # Apply rating filter
#                 if metadata.get('rating', 0) < user_profile.min_rating:
#                     continue
                
#                 # Calculate similarity
#                 distance = results['distances'][0][i]
#                 similarity = max(0, min(1, 1 - (distance / 2)))
                
#                 filtered_results.append({
#                     'document': results['documents'][0][i],
#                     'metadata': metadata,
#                     'similarity': similarity
#                 })
                
#                 if len(filtered_results) >= n_results:
#                     break

#             return filtered_results
            
#         except Exception as e:
#             print(f" Error retrieving context: {e}")
#             return []
    
#     async def classify_intent(self, user_input: str, user_profile: UserProfile) -> str:
#         """
#         Use FANAR to classify user intent with fallback
#         """
#         intent_prompt = f"""You are an AI assistant for a Qatar tourism app. Classify the user's request into one of these categories:

# 1. "recommendation" - User wants suggestions for restaurants, attractions, cafes, or activities
# 2. "planning" - User wants to plan a day trip, itinerary, or schedule  
# 3. "booking" - User wants to make reservations, buy tickets, or order something
# 4. "chat" - General questions about Qatar, conversation, or information requests

# Examples:
# - "Show me good restaurants" → recommendation
# - "Plan my day in Doha" → planning  
# - "Book a table for tonight" → booking
# - "What's the weather like?" → chat

# User input: "{user_input}"
# User preferences: Food - {user_profile.food_preferences}, Budget - {user_profile.budget_range}

# Respond with ONLY the category name (recommendation/planning/booking/chat)."""

#         try:
#             intent = await self.fanar_client.generate_completion(intent_prompt, max_tokens=10)
#             intent = intent.lower().strip()
            
#             # Validate intent
#             valid_intents = ['recommendation', 'planning', 'booking', 'chat']
#             if intent not in valid_intents:
#                 # Fallback intent classification
#                 user_input_lower = user_input.lower()
#                 if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
#                     return 'recommendation'
#                 elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
#                     return 'planning'
#                 elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
#                     return 'booking'
#                 else:
#                     return 'chat'
            
#             return intent
            
#         except Exception as e:
#             print(f"❌ Error classifying intent: {e}")
#             # Simple fallback classification
#             user_input_lower = user_input.lower()
#             if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
#                 return 'recommendation'
#             elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
#                 return 'planning'
#             elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
#                 return 'booking'
#             else:
#                 return 'chat'
    
#     async def generate_recommendations(self, user_input: str, user_profile: UserProfile) -> Dict:
#         """
#         Generate personalized recommendations using RAG + FANAR with robust fallbacks
#         """
#         try:
#             # Retrieve relevant context
#             context_results = self.retrieve_context(user_input, user_profile, n_results=5)
#             # print(f"ARWA context: {context_results}")
#             # Format context for FANAR
#             context_text = "\n".join([
#                 f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
#                 f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
#                 f"Rating: {result['metadata'].get('rating', 'N/A')}"
#                 for result in context_results
#             ])

#             # print(f"ARWA user preferences: {user_profile.food_preferences}, {user_profile.budget_range}, {user_profile.activity_types}, {user_profile.group_size}, {user_profile.min_rating}")

#             # recommendation_prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

#             # User Profile:
#             # - Food preferences: {user_profile.food_preferences}
#             # - Budget range: {user_profile.budget_range}  
#             # - Preferred activities: {user_profile.activity_types}
#             # - Group size: {user_profile.group_size}
#             # - Minimum rating: {user_profile.min_rating}

#             # Available places in Qatar:
#             # {context_text}

#             # User request: "{user_input}"

#             # Provide 3-4 personalized recommendations in this EXACT JSON format:
#             # {{
#             #     "recommendations": [
#             #         {{
#             #             "name": "Place Name",
#             #             "type": "restaurant/attraction/cafe/activity",
#             #             "description": "Brief description why this is perfect for the user",
#             #             "location": "Area name", 
#             #             "price_range": "$/$$/$$$ or specific price",
#             #             "rating": 4.5,
#             #             "estimated_duration": "1-2 hours",
#             #             "why_recommended": "Specific reason based on user preferences",
#             #             "booking_available": true,
#             #             "best_time_to_visit": "Morning/Afternoon/Evening"
#             #         }}
#             #     ],
#             #     "summary": "Brief explanation of why these recommendations fit the user's profile"
#             # }}

#             # Ensure all recommendations match the user's budget and preferences. Respond with valid JSON only."""
#             recommendation_prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

#             User Profile:
#             - Food preferences: {user_profile.food_preferences}
#             - Budget range: {user_profile.budget_range}  
#             - Preferred activities: {user_profile.activity_types}
#             - Group size: {user_profile.group_size}
#             - Minimum rating: {user_profile.min_rating}

#             Available places in Qatar:
#             {context_text}

#             User request: "{user_input}"

#             Provide 3-4 personalized recommendations in this EXACT JSON format:
#             {{
#                 "recommendations": [
#                     {{
#                         "name": "Place Name",
#                         "type": "restaurant/attraction/cafe/activity",
#                         "description": "Brief description why this is perfect for the user",
#                         "location": "Area name", 
#                         "price_range": "$/$$/$$$ or specific price",
#                         "rating": 4.5,
#                         "estimated_duration": "1-2 hours",
#                         "why_recommended": "Specific reason based on user preferences",
#                         "booking_available": true,
#                         "best_time_to_visit": "Morning/Afternoon/Evening"
#                     }}
#                 ],
#                 "summary": "Brief explanation of why these recommendations fit the user's profile"
#             }}

#             Respond with valid JSON only. Do not include any comments, explanations, or extra text outside the JSON object.
#             """

#             print(f"ARWA recommendation prompt: {recommendation_prompt}")

#             response = await self.fanar_client.generate_completion(recommendation_prompt, max_tokens=1500)

#             # print(f"ARWA response: {response}")
#             try:
#                 # Try to parse FANAR response
#                 return json.loads(response)
#             except json.JSONDecodeError:
#                 # Fallback: Create recommendations from RAG context
#                 print("⚠️ FANAR response not parseable, using RAG fallback")
#                 return self._create_rag_recommendations(context_results, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error generating recommendations: {e}")
#             # Ultimate fallback
#             return {
#                 "recommendations": [
#                     {
#                         "name": "Museum of Islamic Art",
#                         "type": "attraction",
#                         "description": "World-class Islamic art museum perfect for cultural exploration",
#                         "location": "Corniche, Doha",
#                         "price_range": "Free",
#                         "rating": 4.8,
#                         "estimated_duration": "2-3 hours",
#                         "why_recommended": "Matches your cultural interests and budget",
#                         "booking_available": False,
#                         "best_time_to_visit": "Morning"
#                     }
#                 ],
#                 "summary": "Curated recommendations based on your preferences"
#             }
    
#     def _create_rag_recommendations(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
#         """Create recommendations from RAG context when FANAR fails"""
#         recommendations = []
        
#         for result in context_results[:4]:
#             metadata = result['metadata']
#             recommendations.append({
#                 "name": metadata.get('name', 'Qatar Experience'),
#                 "type": metadata.get('category', 'attraction'),
#                 "description": f"Recommended based on your preferences with {result['similarity']:.1%} relevance",
#                 "location": metadata.get('location', 'Qatar'),
#                 "price_range": metadata.get('price_range', metadata.get('entry_fee', 'N/A')),
#                 "rating": metadata.get('rating', 4.0),
#                 "estimated_duration": "2 hours",
#                 "why_recommended": "Found in our database as highly relevant to your interests",
#                 "booking_available": metadata.get('category') == 'restaurants',
#                 "best_time_to_visit": "Anytime"
#             })
        
#         return {
#             "recommendations": recommendations,
#             "summary": f"Personalized recommendations based on your {user_profile.budget_range} budget and {', '.join(user_profile.activity_types)} interests"
#         }
    
#     async def create_day_plan(self, user_input: str, user_profile: UserProfile) -> Dict:
#         """
#         Create a structured day plan using RAG + FANAR with robust fallbacks
#         """
#         try:
#             # Get diverse context (restaurants, attractions, cafes)
#             context_results = self.retrieve_context(user_input, user_profile, n_results=8)
            
#             # Organize by category
#             restaurants = [r for r in context_results if r['metadata']['category'] == 'restaurants']
#             attractions = [r for r in context_results if r['metadata']['category'] == 'attractions']
#             cafes = [r for r in context_results if r['metadata']['category'] == 'cafes']
            
#             context_text = f"""Available options:

# RESTAURANTS:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in restaurants[:3]])}

# ATTRACTIONS:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('entry_fee', 'Free')}" for r in attractions[:3]])}

# CAFES:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in cafes[:2]])}"""

#             planning_prompt = f"""Create a detailed day itinerary for Qatar based on the user's request and preferences.

# User Profile:
# - Food preferences: {user_profile.food_preferences}
# - Budget: {user_profile.budget_range}
# - Preferred activities: {user_profile.activity_types}
# - Group size: {user_profile.group_size}

# {context_text}

# User request: "{user_input}"

# Create a realistic day plan in this EXACT JSON format:
# {{
#     "day_plan": {{
#         "title": "Your Perfect Day in Qatar",
#         "date": "{datetime.now().strftime('%Y-%m-%d')}",
#         "total_estimated_cost": "$50-80",
#         "total_duration": "8 hours",
#         "activities": [
#             {{
#                 "time": "09:00",
#                 "activity": "Breakfast at [Restaurant Name]",
#                 "location": "Specific area",
#                 "duration": "1 hour", 
#                 "estimated_cost": "$15",
#                 "description": "Why this fits the plan and user preferences",
#                 "transportation": "10-minute walk from previous location",
#                 "booking_required": false,
#                 "tips": "Arrive early to avoid crowds"
#             }}
#         ],
#         "transportation_notes": "Best ways to get around for this itinerary",
#         "total_walking_distance": "3 km",
#         "weather_tips": "Bring sunscreen and water",
#         "budget_breakdown": {{
#             "food": "$40",
#             "attractions": "$30",
#             "transportation": "$20"
#         }}
#     }}
# }}

# Include 4-5 activities covering breakfast, main attractions, lunch/cafe, and dinner. Make sure activities are in chronological order and transportation between locations is realistic."""

#             response = await self.fanar_client.generate_completion(planning_prompt, max_tokens=2000)
            
#             try:
#                 # Try to parse FANAR response
#                 return json.loads(response)
#             except json.JSONDecodeError:
#                 # Fallback: Create plan from RAG context
#                 print("⚠️ FANAR response not parseable, using RAG fallback")
#                 return self._create_rag_day_plan(context_results, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error creating day plan: {e}")
#             return self._create_rag_day_plan([], user_profile)
    
#     def _create_rag_day_plan(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
#         """Create day plan from RAG context when FANAR fails"""
#         activities = []
        
#         # Morning activity (9 AM)
#         if context_results:
#             # Find a restaurant or cafe for breakfast
#             breakfast_spot = next((r for r in context_results if r['metadata']['category'] in ['restaurants', 'cafes']), context_results[0])
#             activities.append({
#                 "time": "09:00",
#                 "activity": f"Breakfast at {breakfast_spot['metadata']['name']}",
#                 "location": breakfast_spot['metadata'].get('location', 'Doha'),
#                 "duration": "1 hour",
#                 "estimated_cost": "$25",
#                 "description": "Start your day with a delicious meal",
#                 "transportation": "Taxi from hotel",
#                 "booking_required": True,
#                 "tips": "Try the local specialties"
#             })
        
#         # Mid-morning activity (11 AM)
#         if len(context_results) > 1:
#             attraction = next((r for r in context_results if r['metadata']['category'] == 'attractions'), context_results[1])
#             activities.append({
#                 "time": "11:00",
#                 "activity": f"Visit {attraction['metadata']['name']}",
#                 "location": attraction['metadata'].get('location', 'Doha'),
#                 "duration": "2 hours",
#                 "estimated_cost": attraction['metadata'].get('entry_fee', 'Free'),
#                 "description": "Explore this amazing attraction",
#                 "transportation": "15-minute taxi ride",
#                 "booking_required": False,
#                 "tips": "Best time for photos and exploration"
#             })
        
#         # If no context available, use defaults
#         if not activities:
#             activities = [
#                 {
#                     "time": "09:00",
#                     "activity": "Breakfast at Local Café",
#                     "location": "Doha",
#                     "duration": "1 hour",
#                     "estimated_cost": "$20",
#                     "description": "Start your day with traditional breakfast",
#                     "transportation": "Taxi from hotel",
#                     "booking_required": False,
#                     "tips": "Try local specialties"
#                 },
#                 {
#                     "time": "11:00",
#                     "activity": "Explore Doha Attractions",
#                     "location": "Central Doha",
#                     "duration": "2 hours",
#                     "estimated_cost": "Free",
#                     "description": "Discover the beauty of Qatar",
#                     "transportation": "Walking or short taxi",
#                     "booking_required": False,
#                     "tips": "Bring water and comfortable shoes"
#                 }
#             ]
        
#         return {
#             "day_plan": {
#                 "title": "Your Perfect Day in Qatar",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": "$80-120",
#                 "total_duration": "8 hours",
#                 "activities": activities,
#                 "transportation_notes": "Use Karwa taxis or ride-hailing apps for convenient transportation",
#                 "total_walking_distance": "2 km",
#                 "weather_tips": "Bring sunscreen and water",
#                 "budget_breakdown": {
#                     "food": "$50",
#                     "attractions": "$30",
#                     "transportation": "$25"
#                 }
#             }
#         }
    
#     async def process_booking_request(self, booking_query: str, user_profile: UserProfile) -> Dict:
#         """
#         Process booking requests using FANAR API
#         """
#         try:
#             booking_prompt = f"""You are a Qatar tourism booking assistant. Process this booking request and provide booking details.

# User Profile:
# - Budget: {user_profile.budget_range}
# - Group size: {user_profile.group_size}
# - Food preferences: {user_profile.food_preferences}

# Booking request: "{booking_query}"

# Analyze the booking request and provide details in this EXACT JSON format:
# {{
#     "booking_details": {{
#         "type": "restaurant/activity/accommodation",
#         "venue_name": "Venue name from request",
#         "date": "YYYY-MM-DD",
#         "time": "HH:MM",
#         "party_size": {user_profile.group_size},
#         "estimated_cost": "$XX",
#         "confirmation_needed": true
#     }},
#     "booking_summary": "Brief summary of what's being booked",
#     "next_steps": "What needs to be done to complete the booking",
#     "missing_info": ["Any missing information needed"]
# }}

# Respond with valid JSON only."""

#             response = await self.fanar_client.generate_completion(booking_prompt, max_tokens=800)
            
#             try:
#                 return json.loads(response)
#             except json.JSONDecodeError:
#                 print("⚠️ FANAR booking response not parseable, using fallback")
#                 return self._create_booking_fallback(booking_query, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error processing booking: {e}")
#             return self._create_booking_fallback(booking_query, user_profile)
    
#     def _create_booking_fallback(self, booking_query: str, user_profile: UserProfile) -> Dict:
#         """Create booking response when FANAR fails"""
#         return {
#             "booking_details": {
#                 "type": "restaurant",
#                 "venue_name": "Qatar Restaurant",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "time": "19:00",
#                 "party_size": user_profile.group_size,
#                 "estimated_cost": "$75",
#                 "confirmation_needed": True
#             },
#             "booking_summary": "Restaurant booking request processed",
#             "next_steps": "Please confirm the booking details and we'll proceed with the reservation",
#             "missing_info": []
#         }

#     # Enhanced day planning methods
#     def _parse_cost(self, cost_str: str) -> int:
#         """Parse cost string to integer"""
#         if not cost_str or cost_str.lower() == 'free':
#             return 0
        
#         # Extract numbers from string
#         import re
#         numbers = re.findall(r'\d+', str(cost_str))
#         if numbers:
#             return int(numbers[0])
        
#         # Default based on $ symbols
#         if '$' in cost_str:
#             return 100
#         elif '$' in cost_str:
#             return 50
#         elif '€' in cost_str:
#             return 25
#         else:
#             return 0

#     def _add_time_precise(self, time_str: str, hours_to_add: float) -> str:
#         """Add precise time including fractions of hours"""
#         try:
#             hour, minute = map(int, time_str.split(':'))
            
#             # Convert hours to minutes
#             total_minutes = hour * 60 + minute + (hours_to_add * 60)
            
#             # Convert back to hours and minutes
#             new_hour = int(total_minutes // 60) % 24
#             new_minute = int(total_minutes % 60)
            
#             return f"{new_hour:02d}:{new_minute:02d}"
#         except:
#             return "12:00"

#     async def create_enhanced_day_plan(self, query: str, user_profile: UserProfile, parsed_preferences: Dict = None) -> Dict:
#         """
#         Enhanced day plan creation that uses parsed preferences from the query
#         """
#         if parsed_preferences is None:
#             parsed_preferences = {}
        
#         duration_hours = parsed_preferences.get('duration', 8)
#         start_time = parsed_preferences.get('start_time', '09:00')
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         print(f"📊 Creating enhanced plan: {duration_hours}h, starts {start_time}, ${budget_amount} budget")
        
#         try:
#             # Get diverse context based on activity types
#             context_results = self.retrieve_context(query, user_profile, n_results=15)
            
#             # Try FANAR-enhanced plan first
#             if await self.fanar_client._check_api_availability():
#                 fanar_result = await self._generate_fanar_enhanced_plan(
#                     query, user_profile, parsed_preferences, context_results
#                 )
#                 if fanar_result:
#                     return fanar_result
            
#             # Fallback to enhanced RAG-based plan
#             print("🔄 Using enhanced RAG fallback plan generation")
#             return self._create_enhanced_rag_plan(context_results, user_profile, parsed_preferences)
                
#         except Exception as e:
#             print(f"❌ Enhanced day plan error: {e}")
#             return self._create_emergency_fallback_plan(duration_hours, budget_amount, start_time)

#     async def _generate_fanar_enhanced_plan(self, query: str, user_profile: UserProfile, parsed_preferences: Dict, context_results: List[Dict]) -> Dict:
#         """Generate plan using FANAR API with enhanced context"""
#         try:
#             # Format context for FANAR
#             context_text = "\n".join([
#                 f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
#                 f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
#                 f"Rating: {result['metadata'].get('rating', 'N/A')}"
#                 for result in context_results[:8]
#             ])
            
#             duration_hours = parsed_preferences.get('duration', 8)
#             budget_amount = parsed_preferences.get('budget_amount', 150)
#             start_time = parsed_preferences.get('start_time', '09:00')
            
#             enhanced_prompt = f"""Create a detailed {duration_hours}-hour Qatar day plan starting at {start_time} with ${budget_amount} budget.

# User Profile:
# - Food preferences: {user_profile.food_preferences}
# - Budget range: {user_profile.budget_range} (${budget_amount} total)
# - Preferred activities: {user_profile.activity_types}
# - Group size: {user_profile.group_size}

# Available venues in Qatar:
# {context_text}

# Requirements:
# - Start at {start_time}
# - Total duration: {duration_hours} hours
# - Total budget: ${budget_amount}
# - Include proper meal timing
# - Optimize travel routes
# - Match budget level expectations

# Create plan in this EXACT JSON format:
# {{
#     "day_plan": {{
#         "title": "Your {duration_hours}-Hour Qatar Experience",
#         "date": "{datetime.now().strftime('%Y-%m-%d')}",
#         "total_estimated_cost": "${budget_amount}",
#         "total_duration": "{duration_hours} hours",
#         "activities": [
#             {{
#                 "time": "HH:MM",
#                 "activity": "Activity name with venue",
#                 "location": "Specific location",
#                 "duration": "X hours",
#                 "estimated_cost": "$XX",
#                 "description": "Why this fits the plan",
#                 "transportation": "How to get there",
#                 "booking_required": true/false,
#                 "tips": "Helpful advice"
#             }}
#         ],
#         "transportation_notes": "Best transportation for this itinerary",
#         "total_walking_distance": "X km",
#         "weather_tips": "Dress and preparation advice",
#         "budget_breakdown": {{
#             "food": "$XX",
#             "attractions": "$XX",
#             "transportation": "$XX"
#         }}
#     }}
# }}

# Ensure activities fit the time duration and budget exactly."""

#             response = await self.fanar_client.generate_completion(enhanced_prompt, max_tokens=2500)
            
#             try:
#                 parsed_response = json.loads(response)
#                 # Validate the response has the right structure
#                 if 'day_plan' in parsed_response and 'activities' in parsed_response['day_plan']:
#                     print("✅ FANAR generated valid plan")
#                     return parsed_response
#             except json.JSONDecodeError:
#                 print("⚠️ FANAR response not valid JSON")
            
#         except Exception as e:
#             print(f"❌ FANAR enhanced plan error: {e}")
        
#         return None

#     def _create_enhanced_rag_plan(self, context_results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> Dict:
#         """Create enhanced plan from RAG context"""
#         duration_hours = parsed_preferences.get('duration', 8)
#         start_time = parsed_preferences.get('start_time', '09:00')
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         # Filter results by user preferences
#         filtered_results = self._filter_by_enhanced_preferences(context_results, user_profile, parsed_preferences)
        
#         # Generate activities based on duration and preferences
#         activities = self._create_enhanced_activities(filtered_results, duration_hours, start_time, budget_amount, parsed_preferences)
        
#         total_cost = sum(self._parse_cost(activity.get('estimated_cost', '$0')) for activity in activities)
        
#         return {
#             "day_plan": {
#                 "title": f"Your {parsed_preferences.get('duration_text', 'Perfect')} Qatar Experience",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": f"${total_cost}",
#                 "total_duration": f"{duration_hours} hours",
#                 "activities": activities,
#                 "transportation_notes": f"Recommended transportation for this {duration_hours}-hour itinerary",
#                 "total_walking_distance": f"{len(activities) * 0.5:.1f} km",
#                 "weather_tips": "Dress comfortably, bring sunscreen and water for extended touring",
#                 "budget_breakdown": self._calculate_enhanced_budget_breakdown(activities, budget_amount)
#             }
#         }

#     def _filter_by_enhanced_preferences(self, results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> List[Dict]:
#         """Enhanced filtering based on parsed preferences"""
#         filtered = []
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         # Score results based on preferences
#         scored_results = []
#         for result in results:
#             metadata = result['metadata']
#             score = 0
            
#             # Budget compatibility score
#             item_cost = self._parse_cost(metadata.get('price_range', metadata.get('entry_fee', '$0')))
#             if budget_amount >= 200:  # Premium budget
#                 if item_cost >= 50:
#                     score += 3  # Prefer higher-end options
#                 else:
#                     score += 1
#             elif budget_amount >= 100:  # Moderate budget
#                 if 20 <= item_cost <= 80:
#                     score += 3  # Perfect range
#                 elif item_cost < 20:
#                     score += 2
#                 else:
#                     score += 0  # Too expensive
#             else:  # Budget-friendly
#                 if item_cost <= 30:
#                     score += 3
#                 elif item_cost <= 50:
#                     score += 1
#                 else:
#                     continue  # Skip expensive items
            
#             # Activity type preference score
#             category = metadata.get('category', '')
#             activity_types = parsed_preferences.get('activity_types', user_profile.activity_types)
            
#             if 'Cultural' in activity_types and category in ['attractions', 'museums']:
#                 score += 2
#             if 'Food' in activity_types and category in ['restaurants', 'cafes']:
#                 score += 2
#             if 'Modern' in activity_types and category in ['shopping', 'malls']:
#                 score += 2
#             if 'Shopping' in activity_types and 'souq' in metadata.get('name', '').lower():
#                 score += 2
            
#             # Special preference bonuses
#             if parsed_preferences.get('include_souqs') and 'souq' in metadata.get('name', '').lower():
#                 score += 3
#             if parsed_preferences.get('prioritize_culture') and category in ['attractions', 'museums']:
#                 score += 3
            
#             # Rating bonus
#             rating = metadata.get('rating', 0)
#             if rating >= 4.5:
#                 score += 2
#             elif rating >= 4.0:
#                 score += 1
            
#             scored_results.append((result, score))
        
#         # Sort by score and return top results
#         scored_results.sort(key=lambda x: x[1], reverse=True)
#         return [result for result, score in scored_results[:12]]

#     def _create_enhanced_activities(self, filtered_results: List[Dict], duration_hours: int, start_time: str, budget_amount: int, parsed_preferences: Dict) -> List[Dict]:
#         """Create activities with proper timing and budget distribution"""
#         activities = []
#         current_time = start_time
        
#         # Calculate activity distribution based on duration
#         if duration_hours >= 12:
#             # Extended day: Breakfast, Activity, Lunch, Activity, Snack, Activity, Dinner
#             activity_schedule = [
#                 ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), 
#                 ('activity', 2.0), ('coffee', 1.0), ('activity', 2.5), ('dinner', 2.0)
#             ]
#         elif duration_hours >= 8:
#             # Full day: Breakfast, Activity, Lunch, Activity, Dinner
#             activity_schedule = [
#                 ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), ('activity', 2.5), ('dinner', 1.5)
#             ]
#         else:
#             # Half day: Light meal, Activity, Activity
#             activity_schedule = [
#                 ('coffee', 0.5), ('activity', 2.0), ('lunch', 1.0), ('activity', 1.5)
#             ]
        
#         # Separate venues by type for selection
#         restaurants = [r for r in filtered_results if r['metadata']['category'] == 'restaurants']
#         attractions = [r for r in filtered_results if r['metadata']['category'] == 'attractions']
#         cafes = [r for r in filtered_results if r['metadata']['category'] == 'cafes']
        
#         # Ensure we have enough venues
#         if not restaurants:
#             restaurants = [{'metadata': {'name': 'Local Restaurant', 'category': 'restaurants', 'location': 'Doha'}}]
#         if not attractions:
#             attractions = [{'metadata': {'name': 'Qatar Attraction', 'category': 'attractions', 'location': 'Doha'}}]
        
#         restaurant_index = 0
#         attraction_index = 0
#         cafe_index = 0
        
#         for i, (activity_type, duration_hours_float) in enumerate(activity_schedule):
#             if activity_type == 'breakfast':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'breakfast', budget_amount, duration_hours_float
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'lunch':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'lunch', budget_amount, duration_hours_float
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'dinner':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'dinner', budget_amount * 1.5, duration_hours_float  # Dinner costs more
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'coffee':
#                 venue = cafes[cafe_index % len(cafes)] if cafes else restaurants[0]
#                 activity = self._create_enhanced_cafe_activity(
#                     venue, current_time, budget_amount, duration_hours_float
#                 )
#                 cafe_index += 1
                
#             else:  # activity
#                 venue = attractions[attraction_index % len(attractions)]
#                 activity = self._create_enhanced_attraction_activity(
#                     venue, current_time, budget_amount, duration_hours_float
#                 )
#                 attraction_index += 1
            
#             activities.append(activity)
#             current_time = self._add_time_precise(current_time, duration_hours_float)
        
#         return activities

#     def _create_enhanced_meal_activity(self, venue: Dict, time: str, meal_type: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced meal activity with proper pricing"""
#         metadata = venue.get('metadata', {})
        
#         # Calculate cost based on budget and meal type
#         if budget_amount >= 200:  # Premium
#             base_cost = {'breakfast': 40, 'lunch': 60, 'dinner': 120}
#         elif budget_amount >= 100:  # Moderate
#             base_cost = {'breakfast': 25, 'lunch': 40, 'dinner': 70}
#         else:  # Budget
#             base_cost = {'breakfast': 15, 'lunch': 25, 'dinner': 45}
        
#         cost = base_cost.get(meal_type, 30)
        
#         # Use venue cost if available and reasonable
#         venue_cost = self._parse_cost(metadata.get('price_range', '$0'))
#         if venue_cost > 0 and abs(venue_cost - cost) < cost * 0.5:
#             cost = venue_cost
        
#         return {
#             "time": time,
#             "activity": f"{meal_type.title()} at {metadata.get('name', 'Premium Restaurant')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": f"${cost}",
#             "description": self._get_venue_description(venue, f"Enjoy an excellent {meal_type} experience"),
#             "transportation": "Private transport or taxi",
#             "booking_required": True,
#             "tips": f"Perfect {meal_type} spot with {metadata.get('rating', 4.5)}/5 rating"
#         }

#     def _create_enhanced_attraction_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced attraction activity"""
#         metadata = venue.get('metadata', {})
        
#         # Calculate cost based on budget level
#         base_cost = self._parse_cost(metadata.get('entry_fee', metadata.get('price_range', '$0')))
        
#         if base_cost == 0:
#             cost_str = "Free"
#         elif budget_amount >= 200:
#             cost_str = f"${max(base_cost, 20)}"  # Premium experiences
#         else:
#             cost_str = f"${base_cost}" if base_cost > 0 else "Free"
        
#         return {
#             "time": time,
#             "activity": f"Visit {metadata.get('name', 'Qatar Cultural Site')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": cost_str,
#             "description": self._get_venue_description(venue, "Explore this remarkable attraction"),
#             "transportation": "Private transport recommended",
#             "booking_required": False,
#             "tips": f"Rated {metadata.get('rating', 4.5)}/5 - don't miss this experience"
#         }

#     def _create_enhanced_cafe_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced cafe/coffee break activity"""
#         metadata = venue.get('metadata', {})
        
#         cost = 20 if budget_amount >= 200 else 15 if budget_amount >= 100 else 10
        
#         return {
#             "time": time,
#             "activity": f"Coffee break at {metadata.get('name', 'Local Café')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": f"${cost}",
#             "description": self._get_venue_description(venue, "Relaxing coffee break and light refreshments"),
#             "transportation": "Walking distance or short taxi",
#             "booking_required": False,
#             "tips": "Perfect spot to recharge and enjoy local atmosphere"
#         }

#     def _get_venue_description(self, venue: Dict, fallback: str) -> str:
#         """Get venue description from RAG data or use fallback"""
#         if venue and 'document' in venue:
#             return venue['document'][:150] + "..."
#         return fallback

#     def _calculate_enhanced_budget_breakdown(self, activities: List[Dict], total_budget: int) -> Dict:
#         """Calculate realistic budget breakdown"""
#         food_cost = 0
#         attraction_cost = 0
        
#         for activity in activities:
#             cost = self._parse_cost(activity.get('estimated_cost', '$0'))
#             activity_name = activity.get('activity', '').lower()
            
#             if any(word in activity_name for word in ['breakfast', 'lunch', 'dinner', 'coffee']):
#                 food_cost += cost
#             else:
#                 attraction_cost += cost
        
#         transportation_cost = max(int(total_budget * 0.15), 30)  # 15% of budget or minimum $30
        
#         return {
#             "food": f"${food_cost}",
#             "attractions": f"${attraction_cost}",
#             "transportation": f"${transportation_cost}"
#         }

#     def _create_emergency_fallback_plan(self, duration_hours: int, budget_amount: int, start_time: str) -> Dict:
#         """Emergency fallback when everything fails"""
#         activities = []
        
#         # Create basic premium Qatar experience based on budget
#         if budget_amount >= 200:
#             activities = [
#                 {
#                     "time": start_time,
#                     "activity": "Breakfast at Al Mourjan Restaurant",
#                     "location": "West Bay, Corniche",
#                     "duration": "1 hour",
#                     "estimated_cost": "$45",
#                     "description": "Premium waterfront breakfast with traditional Qatari cuisine",
#                     "transportation": "Private car from hotel",
#                     "booking_required": True,
#                     "tips": "Request table with Corniche view"
#                 },
#                 {
#                     "time": self._add_time_precise(start_time, 2),
#                     "activity": "Visit Museum of Islamic Art",
#                     "location": "Corniche, Doha",
#                     "duration": "2.5 hours",
#                     "estimated_cost": "Free",
#                     "description": "World-class Islamic art collection in stunning I.M. Pei building",
#                     "transportation": "10-minute private car ride",
#                     "booking_required": False,
#                     "tips": "Don't miss the manuscript collection"
#                 }
#             ]
#         else:
#             # Budget-friendly fallback
#             activities = [
#                 {
#                     "time": start_time,
#                     "activity": "Breakfast at Local Café",
#                     "location": "Souq Waqif",
#                     "duration": "1 hour",
#                     "estimated_cost": "$15",
#                     "description": "Traditional breakfast in authentic market setting",
#                     "transportation": "Taxi from hotel",
#                     "booking_required": False,
#                     "tips": "Try the local bread and honey"
#                 },
#                 {
#                     "time": self._add_time_precise(start_time, 1.5),
#                     "activity": "Explore Souq Waqif",
#                     "location": "Old Doha",
#                     "duration": "3 hours",
#                     "estimated_cost": "$20",
#                     "description": "Traditional marketplace with authentic architecture",
#                     "transportation": "Walking within souq",
#                     "booking_required": False,
#                     "tips": "Perfect for shopping and cultural immersion"
#                 }
#             ]
        
#         total_cost = sum(self._parse_cost(activity['estimated_cost']) for activity in activities)
        
#         return {
#             "day_plan": {
#                 "title": f"Your {duration_hours}-Hour Qatar Experience",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": f"${total_cost}",
#                 "total_duration": f"{duration_hours} hours",
#                 "activities": activities,
#                 "transportation_notes": "Taxi and walking recommended for budget plan" if budget_amount < 200 else "Private car recommended for premium experience",
#                 "total_walking_distance": "3 km" if budget_amount < 200 else "1 km",
#                 "weather_tips": "Dress comfortably, bring sunscreen and water",
#                 "budget_breakdown": {
#                     "food": f"${int(total_cost * 0.6)}",
#                     "attractions": f"${int(total_cost * 0.3)}",
#                     "transportation": f"${int(total_cost * 0.1) + 20}"
#                 }
#             }
#         }


# class ManarAI:
#     """
#     Main class that combines FANAR API with RAG system
#     """
#     def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
#         print("🚀 Initializing ManarAI system...")
#         self.rag_system = QatarRAGSystem(fanar_api_key, vector_db_path)
#         print("✅ ManarAI system ready!")
    
#     async def process_user_request(self, user_input: str, user_profile: UserProfile, context: str = "dashboard") -> Dict:
#         """
#         Main entry point for processing user requests
#         """
#         try:
#             # Classify intent using FANAR
#             intent = await self.rag_system.classify_intent(user_input, user_profile)
#             print(f"🎯 Classified intent: {intent}")
            
#             # Route to appropriate handler
#             if intent == "recommendation":
#                 result = await self.rag_system.generate_recommendations(user_input, user_profile)
#                 return {"type": "recommendations", "data": result}
                
#             elif intent == "planning":
#                 result = await self.rag_system.create_day_plan(user_input, user_profile)
#                 return {"type": "day_plan", "data": result}
                
#             elif intent == "booking":
#                 result = await self.rag_system.process_booking_request(user_input, user_profile)
#                 return {"type": "booking", "data": result}
                
#             else:  # chat
#                 # For general chat, use FANAR directly with some context
#                 context_results = self.rag_system.retrieve_context(user_input, user_profile, n_results=3)
#                 context_text = "\n".join([f"- {r['metadata']['name']}: {r['document'][:100]}..." for r in context_results[:2]])
                
#                 chat_prompt = f"""You are a friendly Qatar tourism assistant. Answer the user's question using your knowledge and the context provided.

# Context from Qatar database:
# {context_text}

# User question: "{user_input}"

# Provide a helpful, conversational response about Qatar tourism."""

#                 response = await self.rag_system.fanar_client.generate_completion(chat_prompt, max_tokens=500)
                
#                 return {
#                     "type": "chat", 
#                     "data": {
#                         "message": response,
#                         "context_used": len(context_results) > 0
#                     }
#                 }
                
#         except Exception as e:
#             print(f"❌ Error processing user request: {e}")
#             return {
#                 "type": "error",
#                 "data": {
#                     "message": "I'm sorry, I couldn't process your request right now. Please try again.",
#                     "error": str(e)
#                 }
#             }

# import requests 
# import json
# import asyncio
# import aiohttp
# import chromadb
# from sentence_transformers import SentenceTransformer
# from typing import Dict, List, Optional, Any
# from dataclasses import dataclass
# from datetime import datetime
# import time
# import ssl
# from openai import OpenAI

# model_name = "Fanar"

# @dataclass
# class UserProfile:
#     user_id: str
#     food_preferences: List[str]
#     budget_range: str
#     activity_types: List[str]
#     language: str = "en"
#     accessibility_needs: List[str] = None
#     group_size: int = 1
#     min_rating: float = 4.0


# class QatarRAGSystem:
#     def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
#         """
#         Initialize the complete RAG system with FANAR API and vector database
#         """
#         print("🚀 Initializing Qatar RAG System...")
        
#         # Initialize FANAR client with improved error handling
#         self.fanar_client = OpenAI(
#             base_url="https://api.fanar.qa/v1",
#             api_key=fanar_api_key,
#         )
        
#         # Initialize vector database
#         self.embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
#         self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        
#         try:
#             self.collection = self.chroma_client.get_collection("qatar_tourism")
#             print(f"✅ Loaded vector database with {self.collection.count()} items")
#         except Exception as e:
#             print(f"❌ Error loading vector database: {e}")
#             print("Please run Step 2 first to create the vector database")
#             raise
    
#     def retrieve_context(self, query: str, user_profile: UserProfile, n_results: int = 10) -> List[Dict]:
#         """
#         Retrieve relevant context from vector database based on query and user preferences
#         """
#         try:
#             # Enhance query with user preferences
#             enhanced_query_parts = [query]
#             # print(f"ARWA enhanced_query_parts: {enhanced_query_parts}")
#             if user_profile.food_preferences:
#                 # enhanced_query_parts.append(f"cuisine preferences: {', '.join(user_profile.food_preferences)}")
#                 enhanced_query_parts.append(f"{'. '.join(user_profile.food_preferences)}")

#             # print(f"ARWA enhanced_query_parts 2: {enhanced_query_parts}")
#             if user_profile.activity_types:
#                 # enhanced_query_parts.append(f"activity interests: {', '.join(user_profile.activity_types)}")
#                 enhanced_query_parts.append(f"{'. '.join(user_profile.activity_types)}")
            
#             # print(f"ARWA enhanced_query_parts 3: {enhanced_query_parts}")
#             if user_profile.budget_range:
#                 # enhanced_query_parts.append(f"budget: {user_profile.budget_range}")
#                 enhanced_query_parts.append(f"{user_profile.budget_range}")

#             # print(f"ARWA enhanced_query_parts 4: {enhanced_query_parts}")
#             enhanced_query = ". ".join(enhanced_query_parts)

#             # Create query embedding

#             query_embedding = self.embedding_model.encode([enhanced_query])
#             print(f"ARWA query: {enhanced_query}")
#             # Search vector database
#             results = self.collection.query(
#                 query_embeddings=query_embedding.tolist(),
#                 n_results=n_results * 4,  # Get more results for filtering
#                 include=['documents', 'metadatas', 'distances']
#             )
#             print(f"ARWA results: {len(results)}")
            
#             # Filter and format results
#             filtered_results = []
#             for i in range(len(results['ids'][0])):
#                 metadata = results['metadatas'][0][i]
#                 # Apply user preference filters
#                 # if user_profile.budget_range:
#                 #     item_price = metadata.get('price_range', '')
#                 #     if item_price and item_price != user_profile.budget_range:
#                 #         # Allow some flexibility in budget
#                 #         budget_order = {'$': 1, '$$': 2, '$$$': 3}
#                 #         if (user_profile.budget_range in budget_order and 
#                 #             item_price in budget_order and 
#                 #             budget_order[item_price] > budget_order[user_profile.budget_range] + 1):
#                 #             continue
#                 # Apply user preference filters - RELAXED budget filtering
#                 if user_profile.budget_range:
#                     item_price = metadata.get('price_range', '')
#                     # Only filter out items that are 2+ budget levels higher (allow more flexibility)
#                     if item_price:
#                         budget_order = {'$': 1, '$$': 2, '$$$': 3, '$$$$': 4}
#                         user_budget_level = budget_order.get(user_profile.budget_range, 2)
#                         item_budget_level = budget_order.get(item_price, 2)
#                         # Skip only if item is more than 2 levels above user's budget
#                         if item_budget_level > user_budget_level:
#                             continue
                
#                 # Apply rating filter
#                 if metadata.get('rating', 0) < user_profile.min_rating:
#                     continue
                
#                 # Calculate similarity
#                 distance = results['distances'][0][i]
#                 similarity = max(0, min(1, 1 - (distance / 2)))
                
#                 filtered_results.append({
#                     'document': results['documents'][0][i],
#                     'metadata': metadata,
#                     'similarity': similarity
#                 })
                
#                 if len(filtered_results) >= n_results:
#                     break
#             return filtered_results
            
#         except Exception as e:
#             print(f" Error retrieving context: {e}")
#             return []
    
#     async def classify_intent(self, user_input: str, user_profile: UserProfile) -> str:
#         """
#         Use FANAR to classify user intent with fallback
#         """
#         intent_prompt = f"""You are an AI assistant for a Qatar tourism app. Classify the user's request into one of these categories:

# 1. "recommendation" - User wants suggestions for restaurants, attractions, cafes, or activities
# 2. "planning" - User wants to plan a day trip, itinerary, or schedule  
# 3. "booking" - User wants to make reservations, buy tickets, or order something
# 4. "chat" - General questions about Qatar, conversation, or information requests

# Examples:
# - "Show me good restaurants" → recommendation
# - "Plan my day in Doha" → planning  
# - "Book a table for tonight" → booking
# - "What's the weather like?" → chat

# User input: "{user_input}"
# User preferences: Food - {user_profile.food_preferences}, Budget - {user_profile.budget_range}

# Respond with ONLY the category name (recommendation/planning/booking/chat)."""

#         try:
#             intent = await self.fanar_client.generate_completion(intent_prompt, max_tokens=10)
#             intent = intent.lower().strip()
            
#             # Validate intent
#             valid_intents = ['recommendation', 'planning', 'booking', 'chat']
#             if intent not in valid_intents:
#                 # Fallback intent classification
#                 user_input_lower = user_input.lower()
#                 if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
#                     return 'recommendation'
#                 elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
#                     return 'planning'
#                 elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
#                     return 'booking'
#                 else:
#                     return 'chat'
            
#             return intent
            
#         except Exception as e:
#             print(f"❌ Error classifying intent: {e}")
#             # Simple fallback classification
#             user_input_lower = user_input.lower()
#             if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
#                 return 'recommendation'
#             elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
#                 return 'planning'
#             elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
#                 return 'booking'
#             else:
#                 return 'chat'
    
#     async def generate_recommendations(self, user_input: str, user_profile: UserProfile) -> Dict:
#         """
#         Generate personalized recommendations using RAG + FANAR with robust fallbacks
#         """
#         try:
#             # Retrieve relevant context
#             context_results = self.retrieve_context(user_input, user_profile, n_results=5)
#             # print(f"ARWA context: {context_results}")
#             # Format context for FANAR
#             context_text = "\n".join([
#                 f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
#                 f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
#                 f"Rating: {result['metadata'].get('rating', 'N/A')}"
#                 for result in context_results
#             ])

#             # print(f"ARWA user preferences: {user_profile.food_preferences}, {user_profile.budget_range}, {user_profile.activity_types}, {user_profile.group_size}, {user_profile.min_rating}")

#             # recommendation_prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

#             # User Profile:
#             # - Food preferences: {user_profile.food_preferences}
#             # - Budget range: {user_profile.budget_range}  
#             # - Preferred activities: {user_profile.activity_types}
#             # - Group size: {user_profile.group_size}
#             # - Minimum rating: {user_profile.min_rating}

#             # Available places in Qatar:
#             # {context_text}

#             # User request: "{user_input}"

#             # Provide 3-4 personalized recommendations in this EXACT JSON format:
#             # {{
#             #     "recommendations": [
#             #         {{
#             #             "name": "Place Name",
#             #             "type": "restaurant/attraction/cafe/activity",
#             #             "description": "Brief description why this is perfect for the user",
#             #             "location": "Area name", 
#             #             "price_range": "$/$$/$$$ or specific price",
#             #             "rating": 4.5,
#             #             "estimated_duration": "1-2 hours",
#             #             "why_recommended": "Specific reason based on user preferences",
#             #             "booking_available": true,
#             #             "best_time_to_visit": "Morning/Afternoon/Evening"
#             #         }}
#             #     ],
#             #     "summary": "Brief explanation of why these recommendations fit the user's profile"
#             # }}

#             # Ensure all recommendations match the user's budget and preferences. Respond with valid JSON only."""
#             prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

#             User Profile:
#             - Food preferences: {user_profile.food_preferences}
#             - Budget range: {user_profile.budget_range}  
#             - Preferred activities: {user_profile.activity_types}
#             - Group size: {user_profile.group_size}
#             - Minimum rating: {user_profile.min_rating}

#             Available places in Qatar:
#             {context_text}

#             User request: "{user_input}"

#             Provide 3-4 personalized recommendations in this EXACT JSON format, if anything does not have data just keep an empty string or null value, do not explain why it is empty:
#             {{
#                 "recommendations": [
#                     {
#                         "name": "Place Name",
#                         "type": "restaurant/attraction/cafe/activity",
#                         "description": "Brief description why this is perfect for the user",
#                         "location": "Area name", 
#                         "price_range": "$/$$/$$$ or specific price", "(if there is no price just say ""Free"" do not comment here)"
#                         "rating": "number",
#                         "estimated_duration": "1-2 hours",
#                         "why_recommended": "Specific reason based on user preferences",
#                         "booking_available": "true", "(if there is no booking needed just say false do not comment here),"
#                         "best_time_to_visit": "Morning/Afternoon/Evening"
#                     }
#                 ],
#                 "summary": "Brief explanation of why these recommendations fit the user's profile"
#             }}

#             Respond with valid JSON only. Do not include any comments, explanations, or extra text outside the JSON object.
#                 """
#             print(f"ARWA recommendation_prompt: {prompt}")
#             messages =     {"role": "user", "content": prompt}
#             # print(f"ARWA recommendation_prompt: {recommendation_prompt}")
#             response = self.fanar_client.chat.completions.create(model = model_name, messages=[messages])
#             # response = await self.fanar_client.generate_completion(recommendation_prompt, max_tokens=1500)
#             print(f"ARWA response: {response.choices[0].message.content}")
#             # print(f"ARWA response: {response}")
#             try:
#                 # Try to parse FANAR response
#                 # return json.loads(response)
#                 return json.loads(response.choices[0].message.content)
#             except json.JSONDecodeError:
#                 # Fallback: Create recommendations from RAG context
#                 print("⚠️ FANAR response not parseable, using RAG fallback")
#                 return self._create_rag_recommendations(context_results, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error generating recommendations: {e}")
#             # Ultimate fallback
#             return {
#                 "recommendations": [
#                     {
#                         "name": "Museum of Islamic Art",
#                         "type": "attraction",
#                         "description": "World-class Islamic art museum perfect for cultural exploration",
#                         "location": "Corniche, Doha",
#                         "price_range": "Free",
#                         "rating": 4.8,
#                         "estimated_duration": "2-3 hours",
#                         "why_recommended": "Matches your cultural interests and budget",
#                         "booking_available": False,
#                         "best_time_to_visit": "Morning"
#                     }
#                 ],
#                 "summary": "Curated recommendations based on your preferences"
#             }
    
#     def _create_rag_recommendations(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
#         """Create recommendations from RAG context when FANAR fails"""
#         recommendations = []
        
#         for result in context_results[:4]:
#             metadata = result['metadata']
#             recommendations.append({
#                 "name": metadata.get('name', 'Qatar Experience'),
#                 "type": metadata.get('category', 'attraction'),
#                 "description": f"Recommended based on your preferences with {result['similarity']:.1%} relevance",
#                 "location": metadata.get('location', 'Qatar'),
#                 "price_range": metadata.get('price_range', metadata.get('entry_fee', 'N/A')),
#                 "rating": metadata.get('rating', 4.0),
#                 "estimated_duration": "2 hours",
#                 "why_recommended": "Found in our database as highly relevant to your interests",
#                 "booking_available": metadata.get('category') == 'restaurants',
#                 "best_time_to_visit": "Anytime"
#             })
        
#         return {
#             "recommendations": recommendations,
#             "summary": f"Personalized recommendations based on your {user_profile.budget_range} budget and {', '.join(user_profile.activity_types)} interests"
#         }
    
#     async def create_day_plan(self, user_input: str, user_profile: UserProfile) -> Dict:
#         """
#         Create a structured day plan using RAG + FANAR with robust fallbacks
#         """
#         try:
#             # Get diverse context (restaurants, attractions, cafes)
#             context_results = self.retrieve_context(user_input, user_profile, n_results=8)
            
#             # Organize by category
#             restaurants = [r for r in context_results if r['metadata']['category'] == 'restaurants']
#             attractions = [r for r in context_results if r['metadata']['category'] == 'attractions']
#             cafes = [r for r in context_results if r['metadata']['category'] == 'cafes']
            
#             context_text = f"""Available options:

# RESTAURANTS:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in restaurants[:3]])}

# ATTRACTIONS:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('entry_fee', 'Free')}" for r in attractions[:3]])}

# CAFES:
# {chr(10).join([f"- {r['metadata']['name']}: {r['metadata'].get('location', '')}, {r['metadata'].get('price_range', 'N/A')}" for r in cafes[:2]])}"""

#             planning_prompt = f"""Create a detailed day itinerary for Qatar based on the user's request and preferences.

# User Profile:
# - Food preferences: {user_profile.food_preferences}
# - Budget: {user_profile.budget_range}
# - Preferred activities: {user_profile.activity_types}
# - Group size: {user_profile.group_size}

# {context_text}

# User request: "{user_input}"

# Create a realistic day plan in this EXACT JSON format:
# {{
#     "day_plan": {{
#         "title": "Your Perfect Day in Qatar",
#         "date": "{datetime.now().strftime('%Y-%m-%d')}",
#         "total_estimated_cost": "$50-80",
#         "total_duration": "8 hours",
#         "activities": [
#             {{
#                 "time": "09:00",
#                 "activity": "Breakfast at [Restaurant Name]",
#                 "location": "Specific area",
#                 "duration": "1 hour", 
#                 "estimated_cost": "$15",
#                 "description": "Why this fits the plan and user preferences",
#                 "transportation": "10-minute walk from previous location",
#                 "booking_required": false,
#                 "tips": "Arrive early to avoid crowds"
#             }}
#         ],
#         "transportation_notes": "Best ways to get around for this itinerary",
#         "total_walking_distance": "3 km",
#         "weather_tips": "Bring sunscreen and water",
#         "budget_breakdown": {{
#             "food": "$40",
#             "attractions": "$30",
#             "transportation": "$20"
#         }}
#     }}
# }}

# Include 4-5 activities covering breakfast, main attractions, lunch/cafe, and dinner. Make sure activities are in chronological order and transportation between locations is realistic."""

#             response = await self.fanar_client.generate_completion(planning_prompt, max_tokens=2000)
            
#             try:
#                 # Try to parse FANAR response
#                 return json.loads(response)
#             except json.JSONDecodeError:
#                 # Fallback: Create plan from RAG context
#                 print("⚠️ FANAR response not parseable, using RAG fallback")
#                 return self._create_rag_day_plan(context_results, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error creating day plan: {e}")
#             return self._create_rag_day_plan([], user_profile)
    
#     def _create_rag_day_plan(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
#         """Create day plan from RAG context when FANAR fails"""
#         activities = []
        
#         # Morning activity (9 AM)
#         if context_results:
#             # Find a restaurant or cafe for breakfast
#             breakfast_spot = next((r for r in context_results if r['metadata']['category'] in ['restaurants', 'cafes']), context_results[0])
#             activities.append({
#                 "time": "09:00",
#                 "activity": f"Breakfast at {breakfast_spot['metadata']['name']}",
#                 "location": breakfast_spot['metadata'].get('location', 'Doha'),
#                 "duration": "1 hour",
#                 "estimated_cost": "$25",
#                 "description": "Start your day with a delicious meal",
#                 "transportation": "Taxi from hotel",
#                 "booking_required": True,
#                 "tips": "Try the local specialties"
#             })
        
#         # Mid-morning activity (11 AM)
#         if len(context_results) > 1:
#             attraction = next((r for r in context_results if r['metadata']['category'] == 'attractions'), context_results[1])
#             activities.append({
#                 "time": "11:00",
#                 "activity": f"Visit {attraction['metadata']['name']}",
#                 "location": attraction['metadata'].get('location', 'Doha'),
#                 "duration": "2 hours",
#                 "estimated_cost": attraction['metadata'].get('entry_fee', 'Free'),
#                 "description": "Explore this amazing attraction",
#                 "transportation": "15-minute taxi ride",
#                 "booking_required": False,
#                 "tips": "Best time for photos and exploration"
#             })
        
#         # If no context available, use defaults
#         if not activities:
#             activities = [
#                 {
#                     "time": "09:00",
#                     "activity": "Breakfast at Local Café",
#                     "location": "Doha",
#                     "duration": "1 hour",
#                     "estimated_cost": "$20",
#                     "description": "Start your day with traditional breakfast",
#                     "transportation": "Taxi from hotel",
#                     "booking_required": False,
#                     "tips": "Try local specialties"
#                 },
#                 {
#                     "time": "11:00",
#                     "activity": "Explore Doha Attractions",
#                     "location": "Central Doha",
#                     "duration": "2 hours",
#                     "estimated_cost": "Free",
#                     "description": "Discover the beauty of Qatar",
#                     "transportation": "Walking or short taxi",
#                     "booking_required": False,
#                     "tips": "Bring water and comfortable shoes"
#                 }
#             ]
        
#         return {
#             "day_plan": {
#                 "title": "Your Perfect Day in Qatar",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": "$80-120",
#                 "total_duration": "8 hours",
#                 "activities": activities,
#                 "transportation_notes": "Use Karwa taxis or ride-hailing apps for convenient transportation",
#                 "total_walking_distance": "2 km",
#                 "weather_tips": "Bring sunscreen and water",
#                 "budget_breakdown": {
#                     "food": "$50",
#                     "attractions": "$30",
#                     "transportation": "$25"
#                 }
#             }
#         }
    
#     async def process_booking_request(self, booking_query: str, user_profile: UserProfile) -> Dict:
#         """
#         Process booking requests using FANAR API
#         """
#         try:
#             booking_prompt = f"""You are a Qatar tourism booking assistant. Process this booking request and provide booking details.

# User Profile:
# - Budget: {user_profile.budget_range}
# - Group size: {user_profile.group_size}
# - Food preferences: {user_profile.food_preferences}

# Booking request: "{booking_query}"

# Analyze the booking request and provide details in this EXACT JSON format:
# {{
#     "booking_details": {{
#         "type": "restaurant/activity/accommodation",
#         "venue_name": "Venue name from request",
#         "date": "YYYY-MM-DD",
#         "time": "HH:MM",
#         "party_size": {user_profile.group_size},
#         "estimated_cost": "$XX",
#         "confirmation_needed": true
#     }},
#     "booking_summary": "Brief summary of what's being booked",
#     "next_steps": "What needs to be done to complete the booking",
#     "missing_info": ["Any missing information needed"]
# }}

# Respond with valid JSON only."""

#             response = await self.fanar_client.generate_completion(booking_prompt, max_tokens=800)
            
#             try:
#                 return json.loads(response)
#             except json.JSONDecodeError:
#                 print("⚠️ FANAR booking response not parseable, using fallback")
#                 return self._create_booking_fallback(booking_query, user_profile)
                
#         except Exception as e:
#             print(f"❌ Error processing booking: {e}")
#             return self._create_booking_fallback(booking_query, user_profile)
    
#     def _create_booking_fallback(self, booking_query: str, user_profile: UserProfile) -> Dict:
#         """Create booking response when FANAR fails"""
#         return {
#             "booking_details": {
#                 "type": "restaurant",
#                 "venue_name": "Qatar Restaurant",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "time": "19:00",
#                 "party_size": user_profile.group_size,
#                 "estimated_cost": "$75",
#                 "confirmation_needed": True
#             },
#             "booking_summary": "Restaurant booking request processed",
#             "next_steps": "Please confirm the booking details and we'll proceed with the reservation",
#             "missing_info": []
#         }

#     # Enhanced day planning methods
#     def _parse_cost(self, cost_str: str) -> int:
#         """Parse cost string to integer"""
#         if not cost_str or cost_str.lower() == 'free':
#             return 0
        
#         # Extract numbers from string
#         import re
#         numbers = re.findall(r'\d+', str(cost_str))
#         if numbers:
#             return int(numbers[0])
        
#         # Default based on $ symbols
#         if '$' in cost_str:
#             return 100
#         elif '$' in cost_str:
#             return 50
#         elif '€' in cost_str:
#             return 25
#         else:
#             return 0

#     def _add_time_precise(self, time_str: str, hours_to_add: float) -> str:
#         """Add precise time including fractions of hours"""
#         try:
#             hour, minute = map(int, time_str.split(':'))
            
#             # Convert hours to minutes
#             total_minutes = hour * 60 + minute + (hours_to_add * 60)
            
#             # Convert back to hours and minutes
#             new_hour = int(total_minutes // 60) % 24
#             new_minute = int(total_minutes % 60)
            
#             return f"{new_hour:02d}:{new_minute:02d}"
#         except:
#             return "12:00"

#     async def create_enhanced_day_plan(self, query: str, user_profile: UserProfile, parsed_preferences: Dict = None) -> Dict:
#         """
#         Enhanced day plan creation that uses parsed preferences from the query
#         """
#         if parsed_preferences is None:
#             parsed_preferences = {}
        
#         duration_hours = parsed_preferences.get('duration', 8)
#         start_time = parsed_preferences.get('start_time', '09:00')
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         print(f"📊 Creating enhanced plan: {duration_hours}h, starts {start_time}, ${budget_amount} budget")
        
#         try:
#             # Get diverse context based on activity types
#             context_results = self.retrieve_context(query, user_profile, n_results=15)
            
#             # Try FANAR-enhanced plan first
#             if await self.fanar_client._check_api_availability():
#                 fanar_result = await self._generate_fanar_enhanced_plan(
#                     query, user_profile, parsed_preferences, context_results
#                 )
#                 if fanar_result:
#                     return fanar_result
            
#             # Fallback to enhanced RAG-based plan
#             print("🔄 Using enhanced RAG fallback plan generation")
#             return self._create_enhanced_rag_plan(context_results, user_profile, parsed_preferences)
                
#         except Exception as e:
#             print(f"❌ Enhanced day plan error: {e}")
#             return self._create_emergency_fallback_plan(duration_hours, budget_amount, start_time)

#     async def _generate_fanar_enhanced_plan(self, query: str, user_profile: UserProfile, parsed_preferences: Dict, context_results: List[Dict]) -> Dict:
#         """Generate plan using FANAR API with enhanced context"""
#         try:
#             # Format context for FANAR
#             context_text = "\n".join([
#                 f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
#                 f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
#                 f"Rating: {result['metadata'].get('rating', 'N/A')}"
#                 for result in context_results[:8]
#             ])
            
#             duration_hours = parsed_preferences.get('duration', 8)
#             budget_amount = parsed_preferences.get('budget_amount', 150)
#             start_time = parsed_preferences.get('start_time', '09:00')
            
#             enhanced_prompt = f"""Create a detailed {duration_hours}-hour Qatar day plan starting at {start_time} with ${budget_amount} budget.

# User Profile:
# - Food preferences: {user_profile.food_preferences}
# - Budget range: {user_profile.budget_range} (${budget_amount} total)
# - Preferred activities: {user_profile.activity_types}
# - Group size: {user_profile.group_size}

# Available venues in Qatar:
# {context_text}

# Requirements:
# - Start at {start_time}
# - Total duration: {duration_hours} hours
# - Total budget: ${budget_amount}
# - Include proper meal timing
# - Optimize travel routes
# - Match budget level expectations

# Create plan in this EXACT JSON format:
# {{
#     "day_plan": {{
#         "title": "Your {duration_hours}-Hour Qatar Experience",
#         "date": "{datetime.now().strftime('%Y-%m-%d')}",
#         "total_estimated_cost": "${budget_amount}",
#         "total_duration": "{duration_hours} hours",
#         "activities": [
#             {{
#                 "time": "HH:MM",
#                 "activity": "Activity name with venue",
#                 "location": "Specific location",
#                 "duration": "X hours",
#                 "estimated_cost": "$XX",
#                 "description": "Why this fits the plan",
#                 "transportation": "How to get there",
#                 "booking_required": true/false,
#                 "tips": "Helpful advice"
#             }}
#         ],
#         "transportation_notes": "Best transportation for this itinerary",
#         "total_walking_distance": "X km",
#         "weather_tips": "Dress and preparation advice",
#         "budget_breakdown": {{
#             "food": "$XX",
#             "attractions": "$XX",
#             "transportation": "$XX"
#         }}
#     }}
# }}

# Ensure activities fit the time duration and budget exactly."""

#             response = await self.fanar_client.generate_completion(enhanced_prompt, max_tokens=2500)
            
#             try:
#                 parsed_response = json.loads(response)
#                 # Validate the response has the right structure
#                 if 'day_plan' in parsed_response and 'activities' in parsed_response['day_plan']:
#                     print("✅ FANAR generated valid plan")
#                     return parsed_response
#             except json.JSONDecodeError:
#                 print("⚠️ FANAR response not valid JSON")
            
#         except Exception as e:
#             print(f"❌ FANAR enhanced plan error: {e}")
        
#         return None

#     def _create_enhanced_rag_plan(self, context_results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> Dict:
#         """Create enhanced plan from RAG context"""
#         duration_hours = parsed_preferences.get('duration', 8)
#         start_time = parsed_preferences.get('start_time', '09:00')
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         # Filter results by user preferences
#         filtered_results = self._filter_by_enhanced_preferences(context_results, user_profile, parsed_preferences)
        
#         # Generate activities based on duration and preferences
#         activities = self._create_enhanced_activities(filtered_results, duration_hours, start_time, budget_amount, parsed_preferences)
        
#         total_cost = sum(self._parse_cost(activity.get('estimated_cost', '$0')) for activity in activities)
        
#         return {
#             "day_plan": {
#                 "title": f"Your {parsed_preferences.get('duration_text', 'Perfect')} Qatar Experience",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": f"${total_cost}",
#                 "total_duration": f"{duration_hours} hours",
#                 "activities": activities,
#                 "transportation_notes": f"Recommended transportation for this {duration_hours}-hour itinerary",
#                 "total_walking_distance": f"{len(activities) * 0.5:.1f} km",
#                 "weather_tips": "Dress comfortably, bring sunscreen and water for extended touring",
#                 "budget_breakdown": self._calculate_enhanced_budget_breakdown(activities, budget_amount)
#             }
#         }

#     def _filter_by_enhanced_preferences(self, results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> List[Dict]:
#         """Enhanced filtering based on parsed preferences"""
#         filtered = []
#         budget_amount = parsed_preferences.get('budget_amount', 150)
        
#         # Score results based on preferences
#         scored_results = []
#         for result in results:
#             metadata = result['metadata']
#             score = 0
            
#             # Budget compatibility score
#             item_cost = self._parse_cost(metadata.get('price_range', metadata.get('entry_fee', '$0')))
#             if budget_amount >= 200:  # Premium budget
#                 if item_cost >= 50:
#                     score += 3  # Prefer higher-end options
#                 else:
#                     score += 1
#             elif budget_amount >= 100:  # Moderate budget
#                 if 20 <= item_cost <= 80:
#                     score += 3  # Perfect range
#                 elif item_cost < 20:
#                     score += 2
#                 else:
#                     score += 0  # Too expensive
#             else:  # Budget-friendly
#                 if item_cost <= 30:
#                     score += 3
#                 elif item_cost <= 50:
#                     score += 1
#                 else:
#                     continue  # Skip expensive items
            
#             # Activity type preference score
#             category = metadata.get('category', '')
#             activity_types = parsed_preferences.get('activity_types', user_profile.activity_types)
            
#             if 'Cultural' in activity_types and category in ['attractions', 'museums']:
#                 score += 2
#             if 'Food' in activity_types and category in ['restaurants', 'cafes']:
#                 score += 2
#             if 'Modern' in activity_types and category in ['shopping', 'malls']:
#                 score += 2
#             if 'Shopping' in activity_types and 'souq' in metadata.get('name', '').lower():
#                 score += 2
            
#             # Special preference bonuses
#             if parsed_preferences.get('include_souqs') and 'souq' in metadata.get('name', '').lower():
#                 score += 3
#             if parsed_preferences.get('prioritize_culture') and category in ['attractions', 'museums']:
#                 score += 3
            
#             # Rating bonus
#             rating = metadata.get('rating', 0)
#             if rating >= 4.5:
#                 score += 2
#             elif rating >= 4.0:
#                 score += 1
            
#             scored_results.append((result, score))
        
#         # Sort by score and return top results
#         scored_results.sort(key=lambda x: x[1], reverse=True)
#         return [result for result, score in scored_results[:12]]

#     def _create_enhanced_activities(self, filtered_results: List[Dict], duration_hours: int, start_time: str, budget_amount: int, parsed_preferences: Dict) -> List[Dict]:
#         """Create activities with proper timing and budget distribution"""
#         activities = []
#         current_time = start_time
        
#         # Calculate activity distribution based on duration
#         if duration_hours >= 12:
#             # Extended day: Breakfast, Activity, Lunch, Activity, Snack, Activity, Dinner
#             activity_schedule = [
#                 ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), 
#                 ('activity', 2.0), ('coffee', 1.0), ('activity', 2.5), ('dinner', 2.0)
#             ]
#         elif duration_hours >= 8:
#             # Full day: Breakfast, Activity, Lunch, Activity, Dinner
#             activity_schedule = [
#                 ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), ('activity', 2.5), ('dinner', 1.5)
#             ]
#         else:
#             # Half day: Light meal, Activity, Activity
#             activity_schedule = [
#                 ('coffee', 0.5), ('activity', 2.0), ('lunch', 1.0), ('activity', 1.5)
#             ]
        
#         # Separate venues by type for selection
#         restaurants = [r for r in filtered_results if r['metadata']['category'] == 'restaurants']
#         attractions = [r for r in filtered_results if r['metadata']['category'] == 'attractions']
#         cafes = [r for r in filtered_results if r['metadata']['category'] == 'cafes']
        
#         # Ensure we have enough venues
#         if not restaurants:
#             restaurants = [{'metadata': {'name': 'Local Restaurant', 'category': 'restaurants', 'location': 'Doha'}}]
#         if not attractions:
#             attractions = [{'metadata': {'name': 'Qatar Attraction', 'category': 'attractions', 'location': 'Doha'}}]
        
#         restaurant_index = 0
#         attraction_index = 0
#         cafe_index = 0
        
#         for i, (activity_type, duration_hours_float) in enumerate(activity_schedule):
#             if activity_type == 'breakfast':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'breakfast', budget_amount, duration_hours_float
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'lunch':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'lunch', budget_amount, duration_hours_float
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'dinner':
#                 venue = restaurants[restaurant_index % len(restaurants)]
#                 activity = self._create_enhanced_meal_activity(
#                     venue, current_time, 'dinner', budget_amount * 1.5, duration_hours_float  # Dinner costs more
#                 )
#                 restaurant_index += 1
                
#             elif activity_type == 'coffee':
#                 venue = cafes[cafe_index % len(cafes)] if cafes else restaurants[0]
#                 activity = self._create_enhanced_cafe_activity(
#                     venue, current_time, budget_amount, duration_hours_float
#                 )
#                 cafe_index += 1
                
#             else:  # activity
#                 venue = attractions[attraction_index % len(attractions)]
#                 activity = self._create_enhanced_attraction_activity(
#                     venue, current_time, budget_amount, duration_hours_float
#                 )
#                 attraction_index += 1
            
#             activities.append(activity)
#             current_time = self._add_time_precise(current_time, duration_hours_float)
        
#         return activities

#     def _create_enhanced_meal_activity(self, venue: Dict, time: str, meal_type: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced meal activity with proper pricing"""
#         metadata = venue.get('metadata', {})
        
#         # Calculate cost based on budget and meal type
#         if budget_amount >= 200:  # Premium
#             base_cost = {'breakfast': 40, 'lunch': 60, 'dinner': 120}
#         elif budget_amount >= 100:  # Moderate
#             base_cost = {'breakfast': 25, 'lunch': 40, 'dinner': 70}
#         else:  # Budget
#             base_cost = {'breakfast': 15, 'lunch': 25, 'dinner': 45}
        
#         cost = base_cost.get(meal_type, 30)
        
#         # Use venue cost if available and reasonable
#         venue_cost = self._parse_cost(metadata.get('price_range', '$0'))
#         if venue_cost > 0 and abs(venue_cost - cost) < cost * 0.5:
#             cost = venue_cost
        
#         return {
#             "time": time,
#             "activity": f"{meal_type.title()} at {metadata.get('name', 'Premium Restaurant')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": f"${cost}",
#             "description": self._get_venue_description(venue, f"Enjoy an excellent {meal_type} experience"),
#             "transportation": "Private transport or taxi",
#             "booking_required": True,
#             "tips": f"Perfect {meal_type} spot with {metadata.get('rating', 4.5)}/5 rating"
#         }

#     def _create_enhanced_attraction_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced attraction activity"""
#         metadata = venue.get('metadata', {})
        
#         # Calculate cost based on budget level
#         base_cost = self._parse_cost(metadata.get('entry_fee', metadata.get('price_range', '$0')))
        
#         if base_cost == 0:
#             cost_str = "Free"
#         elif budget_amount >= 200:
#             cost_str = f"${max(base_cost, 20)}"  # Premium experiences
#         else:
#             cost_str = f"${base_cost}" if base_cost > 0 else "Free"
        
#         return {
#             "time": time,
#             "activity": f"Visit {metadata.get('name', 'Qatar Cultural Site')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": cost_str,
#             "description": self._get_venue_description(venue, "Explore this remarkable attraction"),
#             "transportation": "Private transport recommended",
#             "booking_required": False,
#             "tips": f"Rated {metadata.get('rating', 4.5)}/5 - don't miss this experience"
#         }

#     def _create_enhanced_cafe_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
#         """Create enhanced cafe/coffee break activity"""
#         metadata = venue.get('metadata', {})
        
#         cost = 20 if budget_amount >= 200 else 15 if budget_amount >= 100 else 10
        
#         return {
#             "time": time,
#             "activity": f"Coffee break at {metadata.get('name', 'Local Café')}",
#             "location": metadata.get('location', 'Doha, Qatar'),
#             "duration": f"{duration} hours",
#             "estimated_cost": f"${cost}",
#             "description": self._get_venue_description(venue, "Relaxing coffee break and light refreshments"),
#             "transportation": "Walking distance or short taxi",
#             "booking_required": False,
#             "tips": "Perfect spot to recharge and enjoy local atmosphere"
#         }

#     def _get_venue_description(self, venue: Dict, fallback: str) -> str:
#         """Get venue description from RAG data or use fallback"""
#         if venue and 'document' in venue:
#             return venue['document'][:150] + "..."
#         return fallback

#     def _calculate_enhanced_budget_breakdown(self, activities: List[Dict], total_budget: int) -> Dict:
#         """Calculate realistic budget breakdown"""
#         food_cost = 0
#         attraction_cost = 0
        
#         for activity in activities:
#             cost = self._parse_cost(activity.get('estimated_cost', '$0'))
#             activity_name = activity.get('activity', '').lower()
            
#             if any(word in activity_name for word in ['breakfast', 'lunch', 'dinner', 'coffee']):
#                 food_cost += cost
#             else:
#                 attraction_cost += cost
        
#         transportation_cost = max(int(total_budget * 0.15), 30)  # 15% of budget or minimum $30
        
#         return {
#             "food": f"${food_cost}",
#             "attractions": f"${attraction_cost}",
#             "transportation": f"${transportation_cost}"
#         }

#     def _create_emergency_fallback_plan(self, duration_hours: int, budget_amount: int, start_time: str) -> Dict:
#         """Emergency fallback when everything fails"""
#         activities = []
        
#         # Create basic premium Qatar experience based on budget
#         if budget_amount >= 200:
#             activities = [
#                 {
#                     "time": start_time,
#                     "activity": "Breakfast at Al Mourjan Restaurant",
#                     "location": "West Bay, Corniche",
#                     "duration": "1 hour",
#                     "estimated_cost": "$45",
#                     "description": "Premium waterfront breakfast with traditional Qatari cuisine",
#                     "transportation": "Private car from hotel",
#                     "booking_required": True,
#                     "tips": "Request table with Corniche view"
#                 },
#                 {
#                     "time": self._add_time_precise(start_time, 2),
#                     "activity": "Visit Museum of Islamic Art",
#                     "location": "Corniche, Doha",
#                     "duration": "2.5 hours",
#                     "estimated_cost": "Free",
#                     "description": "World-class Islamic art collection in stunning I.M. Pei building",
#                     "transportation": "10-minute private car ride",
#                     "booking_required": False,
#                     "tips": "Don't miss the manuscript collection"
#                 }
#             ]
#         else:
#             # Budget-friendly fallback
#             activities = [
#                 {
#                     "time": start_time,
#                     "activity": "Breakfast at Local Café",
#                     "location": "Souq Waqif",
#                     "duration": "1 hour",
#                     "estimated_cost": "$15",
#                     "description": "Traditional breakfast in authentic market setting",
#                     "transportation": "Taxi from hotel",
#                     "booking_required": False,
#                     "tips": "Try the local bread and honey"
#                 },
#                 {
#                     "time": self._add_time_precise(start_time, 1.5),
#                     "activity": "Explore Souq Waqif",
#                     "location": "Old Doha",
#                     "duration": "3 hours",
#                     "estimated_cost": "$20",
#                     "description": "Traditional marketplace with authentic architecture",
#                     "transportation": "Walking within souq",
#                     "booking_required": False,
#                     "tips": "Perfect for shopping and cultural immersion"
#                 }
#             ]
        
#         total_cost = sum(self._parse_cost(activity['estimated_cost']) for activity in activities)
        
#         return {
#             "day_plan": {
#                 "title": f"Your {duration_hours}-Hour Qatar Experience",
#                 "date": datetime.now().strftime("%Y-%m-%d"),
#                 "total_estimated_cost": f"${total_cost}",
#                 "total_duration": f"{duration_hours} hours",
#                 "activities": activities,
#                 "transportation_notes": "Taxi and walking recommended for budget plan" if budget_amount < 200 else "Private car recommended for premium experience",
#                 "total_walking_distance": "3 km" if budget_amount < 200 else "1 km",
#                 "weather_tips": "Dress comfortably, bring sunscreen and water",
#                 "budget_breakdown": {
#                     "food": f"${int(total_cost * 0.6)}",
#                     "attractions": f"${int(total_cost * 0.3)}",
#                     "transportation": f"${int(total_cost * 0.1) + 20}"
#                 }
#             }
#         }


# class ManarAI:
#     """
#     Main class that combines FANAR API with RAG system
#     """
#     def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
#         print("🚀 Initializing ManarAI system...")
#         self.rag_system = QatarRAGSystem(fanar_api_key, vector_db_path)
#         print("✅ ManarAI system ready!")
    
#     async def process_user_request(self, user_input: str, user_profile: UserProfile, context: str = "dashboard") -> Dict:
#         """
#         Main entry point for processing user requests
#         """
#         try:
#             # Classify intent using FANAR
#             intent = await self.rag_system.classify_intent(user_input, user_profile)
#             print(f"🎯 Classified intent: {intent}")
            
#             # Route to appropriate handler
#             if intent == "recommendation":
#                 result = await self.rag_system.generate_recommendations(user_input, user_profile)
#                 return {"type": "recommendations", "data": result}
                
#             elif intent == "planning":
#                 result = await self.rag_system.create_day_plan(user_input, user_profile)
#                 return {"type": "day_plan", "data": result}
                
#             elif intent == "booking":
#                 result = await self.rag_system.process_booking_request(user_input, user_profile)
#                 return {"type": "booking", "data": result}
                
#             else:  # chat
#                 # For general chat, use FANAR directly with some context
#                 context_results = self.rag_system.retrieve_context(user_input, user_profile, n_results=3)
#                 context_text = "\n".join([f"- {r['metadata']['name']}: {r['document'][:100]}..." for r in context_results[:2]])
                
#                 chat_prompt = f"""You are a friendly Qatar tourism assistant. Answer the user's question using your knowledge and the context provided.

# Context from Qatar database:
# {context_text}

# User question: "{user_input}"

# Provide a helpful, conversational response about Qatar tourism."""

#                 response = await self.rag_system.fanar_client.generate_completion(chat_prompt, max_tokens=500)
                
#                 return {
#                     "type": "chat", 
#                     "data": {
#                         "message": response,
#                         "context_used": len(context_results) > 0
#                     }
#                 }
                
#         except Exception as e:
#             print(f"❌ Error processing user request: {e}")
#             return {
#                 "type": "error",
#                 "data": {
#                     "message": "I'm sorry, I couldn't process your request right now. Please try again.",
#                     "error": str(e)
#                 }
#             }

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
import ssl
from openai import OpenAI

model_name = "Fanar"

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


class QatarRAGSystem:
    def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
        """
        Initialize the complete RAG system with FANAR API and vector database
        """
        print("🚀 Initializing Qatar RAG System...")
        
        # Initialize FANAR client with improved error handling
        self.fanar_client = OpenAI(
            base_url="https://api.fanar.qa/v1",
            api_key=fanar_api_key,
        )
        
        # Initialize vector database
        self.embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
        self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        
        try:
            self.collection = self.chroma_client.get_collection("qatar_tourism")
            print(f"✅ Loaded vector database with {self.collection.count()} items")
        except Exception as e:
            print(f"❌ Error loading vector database: {e}")
            print("Please run Step 2 first to create the vector database")
            raise
    
    def retrieve_context(self, query: str, user_profile: UserProfile, n_results: int = 10) -> List[Dict]:
        """
        Retrieve relevant context from vector database based on query and user preferences
        """
        try:
            # Enhance query with user preferences
            enhanced_query_parts = [query]
            
            if user_profile.food_preferences:
                enhanced_query_parts.append(f"{'. '.join(user_profile.food_preferences)}")

            if user_profile.activity_types:
                enhanced_query_parts.append(f"{'. '.join(user_profile.activity_types)}")
            
            if user_profile.budget_range:
                enhanced_query_parts.append(f"{user_profile.budget_range}")

            enhanced_query = ". ".join(enhanced_query_parts)

            # Create query embedding
            query_embedding = self.embedding_model.encode([enhanced_query])
            print(f"Enhanced query: {enhanced_query}")
            
            # Search vector database
            results = self.collection.query(
                query_embeddings=query_embedding.tolist(),
                n_results=n_results * 4,  # Get more results for filtering
                include=['documents', 'metadatas', 'distances']
            )
            
            # Filter and format results
            filtered_results = []
            for i in range(len(results['ids'][0])):
                metadata = results['metadatas'][0][i]
                
                # Apply user preference filters - RELAXED budget filtering
                if user_profile.budget_range:
                    item_price = metadata.get('price_range', '')
                    # Only filter out items that are 2+ budget levels higher (allow more flexibility)
                    if item_price:
                        budget_order = {'$': 1, '$$': 2, '$$$': 3, '$$$$': 4}
                        user_budget_level = budget_order.get(user_profile.budget_range, 2)
                        item_budget_level = budget_order.get(item_price, 2)
                        # Skip only if item is more than 2 levels above user's budget
                        if item_budget_level > user_budget_level:
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
            
        except Exception as e:
            print(f"Error retrieving context: {e}")
            return []
    
    async def classify_intent(self, user_input: str, user_profile: UserProfile) -> str:
        """
        Use FANAR to classify user intent with fallback
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

        try:
            messages = {"role": "user", "content": intent_prompt}
            response = self.fanar_client.chat.completions.create(
                model=model_name, 
                messages=[messages],
                max_tokens=10
            )
            intent = response.choices[0].message.content.lower().strip()
            
            # Validate intent
            valid_intents = ['recommendation', 'planning', 'booking', 'chat']
            if intent not in valid_intents:
                # Fallback intent classification
                user_input_lower = user_input.lower()
                if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
                    return 'recommendation'
                elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
                    return 'planning'
                elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
                    return 'booking'
                else:
                    return 'chat'
            
            return intent
            
        except Exception as e:
            print(f"❌ Error classifying intent: {e}")
            # Simple fallback classification
            user_input_lower = user_input.lower()
            if any(word in user_input_lower for word in ['recommend', 'suggest', 'show me', 'find me']):
                return 'recommendation'
            elif any(word in user_input_lower for word in ['plan', 'itinerary', 'day', 'schedule']):
                return 'planning'
            elif any(word in user_input_lower for word in ['book', 'reserve', 'table', 'ticket']):
                return 'booking'
            else:
                return 'chat'
    
    async def generate_recommendations(self, user_input: str, user_profile: UserProfile) -> Dict:
        """
        Generate personalized recommendations using RAG + FANAR with robust fallbacks
        """
        try:
            # Retrieve relevant context
            context_results = self.retrieve_context(user_input, user_profile, n_results=5)
            
            # Format context for FANAR
            context_text = "\n".join([
                f"- {result['metadata']['name']} ({result['metadata']['category']}): {result['metadata'].get('location', '')}, "
                f"Price: {result['metadata'].get('price_range', result['metadata'].get('entry_fee', 'N/A'))}, "
                f"Rating: {result['metadata'].get('rating', 'N/A')}"
                for result in context_results
            ])

            # Fixed prompt with proper JSON formatting
            prompt = f"""You are a Qatar tourism expert. Based on the user's preferences and available places, provide personalized recommendations.

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
            "price_range": "Free or $ or $$ or $$$", (if there is no price just say free do not comment here)
            "rating": 4.5,
            "estimated_duration": "n hours",
            "why_recommended": "Specific reason based on user preferences",
            "booking_available": true, (if there is no booking needed just say false do not comment here)
            "best_time_to_visit": "Morning/Afternoon/Evening"
        }}
    ],
    "summary": "Brief explanation of why these recommendations fit the user's profile"
}}

Respond with valid JSON only. Do not include any comments or explanations outside the JSON."""

            print(f"Sending recommendation prompt to FANAR...")
            messages = {"role": "user", "content": prompt}
            response = self.fanar_client.chat.completions.create(
                model=model_name, 
                messages=[messages],
                max_tokens=1500
            )
            
            response_content = response.choices[0].message.content
            print(f"FANAR response: {response_content}")
            
            try:
                # Try to parse FANAR response
                return json.loads(response_content)
            except json.JSONDecodeError as e:
                print(f"⚠️ FANAR response not parseable: {e}")
                print(f"Response content: {response_content}")
                # Fallback: Create recommendations from RAG context
                return self._create_rag_recommendations(context_results, user_profile)
                
        except Exception as e:
            print(f"❌ Error generating recommendations: {e}")
            # Ultimate fallback
            return {
                "recommendations": [
                    {
                        "name": "Museum of Islamic Art",
                        "type": "attraction",
                        "description": "World-class Islamic art museum perfect for cultural exploration",
                        "location": "Corniche, Doha",
                        "price_range": "Free",
                        "rating": 4.8,
                        "estimated_duration": "2-3 hours",
                        "why_recommended": "Matches your cultural interests and budget",
                        "booking_available": False,
                        "best_time_to_visit": "Morning"
                    }
                ],
                "summary": "Curated recommendations based on your preferences"
            }
    
    def _create_rag_recommendations(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
        """Create recommendations from RAG context when FANAR fails"""
        recommendations = []
        
        for result in context_results[:4]:
            metadata = result['metadata']
            recommendations.append({
                "name": metadata.get('name', 'Qatar Experience'),
                "type": metadata.get('category', 'attraction'),
                "description": f"Recommended based on your preferences with {result['similarity']:.1%} relevance",
                "location": metadata.get('location', 'Qatar'),
                "price_range": metadata.get('price_range', metadata.get('entry_fee', 'N/A')),
                "rating": metadata.get('rating', 4.0),
                "estimated_duration": "2 hours",
                "why_recommended": "Found in our database as highly relevant to your interests",
                "booking_available": metadata.get('category') == 'restaurants',
                "best_time_to_visit": "Anytime"
            })
        
        return {
            "recommendations": recommendations,
            "summary": f"Personalized recommendations based on your {user_profile.budget_range} budget and {', '.join(user_profile.activity_types)} interests"
        }
    
    async def create_day_plan(self, user_input: str, user_profile: UserProfile) -> Dict:
        """
        Create a structured day plan using RAG + FANAR with robust fallbacks
        """
        try:
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
                "activity": "Breakfast at Restaurant Name",
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

            messages = {"role": "user", "content": planning_prompt}
            response = self.fanar_client.chat.completions.create(
                model=model_name, 
                messages=[messages],
                max_tokens=2000
            )
            
            try:
                # Try to parse FANAR response
                return json.loads(response.choices[0].message.content)
            except json.JSONDecodeError:
                # Fallback: Create plan from RAG context
                print("⚠️ FANAR response not parseable, using RAG fallback")
                return self._create_rag_day_plan(context_results, user_profile)
                
        except Exception as e:
            print(f"❌ Error creating day plan: {e}")
            return self._create_rag_day_plan([], user_profile)
    
    def _create_rag_day_plan(self, context_results: List[Dict], user_profile: UserProfile) -> Dict:
        """Create day plan from RAG context when FANAR fails"""
        activities = []
        
        # Morning activity (9 AM)
        if context_results:
            # Find a restaurant or cafe for breakfast
            breakfast_spot = next((r for r in context_results if r['metadata']['category'] in ['restaurants', 'cafes']), context_results[0])
            activities.append({
                "time": "09:00",
                "activity": f"Breakfast at {breakfast_spot['metadata']['name']}",
                "location": breakfast_spot['metadata'].get('location', 'Doha'),
                "duration": "1 hour",
                "estimated_cost": "$25",
                "description": "Start your day with a delicious meal",
                "transportation": "Taxi from hotel",
                "booking_required": True,
                "tips": "Try the local specialties"
            })
        
        # Mid-morning activity (11 AM)
        if len(context_results) > 1:
            attraction = next((r for r in context_results if r['metadata']['category'] == 'attractions'), context_results[1])
            activities.append({
                "time": "11:00",
                "activity": f"Visit {attraction['metadata']['name']}",
                "location": attraction['metadata'].get('location', 'Doha'),
                "duration": "2 hours",
                "estimated_cost": attraction['metadata'].get('entry_fee', 'Free'),
                "description": "Explore this amazing attraction",
                "transportation": "15-minute taxi ride",
                "booking_required": False,
                "tips": "Best time for photos and exploration"
            })
        
        # If no context available, use defaults
        if not activities:
            activities = [
                {
                    "time": "09:00",
                    "activity": "Breakfast at Local Café",
                    "location": "Doha",
                    "duration": "1 hour",
                    "estimated_cost": "$20",
                    "description": "Start your day with traditional breakfast",
                    "transportation": "Taxi from hotel",
                    "booking_required": False,
                    "tips": "Try local specialties"
                },
                {
                    "time": "11:00",
                    "activity": "Explore Doha Attractions",
                    "location": "Central Doha",
                    "duration": "2 hours",
                    "estimated_cost": "Free",
                    "description": "Discover the beauty of Qatar",
                    "transportation": "Walking or short taxi",
                    "booking_required": False,
                    "tips": "Bring water and comfortable shoes"
                }
            ]
        
        return {
            "day_plan": {
                "title": "Your Perfect Day in Qatar",
                "date": datetime.now().strftime("%Y-%m-%d"),
                "total_estimated_cost": "$80-120",
                "total_duration": "8 hours",
                "activities": activities,
                "transportation_notes": "Use Karwa taxis or ride-hailing apps for convenient transportation",
                "total_walking_distance": "2 km",
                "weather_tips": "Bring sunscreen and water",
                "budget_breakdown": {
                    "food": "$50",
                    "attractions": "$30",
                    "transportation": "$25"
                }
            }
        }
    
    async def process_booking_request(self, booking_query: str, user_profile: UserProfile) -> Dict:
        """
        Process booking requests using FANAR API
        """
        try:
            booking_prompt = f"""You are a Qatar tourism booking assistant. Process this booking request and provide booking details.

User Profile:
- Budget: {user_profile.budget_range}
- Group size: {user_profile.group_size}
- Food preferences: {user_profile.food_preferences}

Booking request: "{booking_query}"

Analyze the booking request and provide details in this EXACT JSON format:
{{
    "booking_details": {{
        "type": "restaurant/activity/accommodation",
        "venue_name": "Venue name from request",
        "date": "YYYY-MM-DD",
        "time": "HH:MM",
        "party_size": {user_profile.group_size},
        "estimated_cost": "$XX",
        "confirmation_needed": true
    }},
    "booking_summary": "Brief summary of what's being booked",
    "next_steps": "What needs to be done to complete the booking",
    "missing_info": ["Any missing information needed"]
}}

Respond with valid JSON only."""

            messages = {"role": "user", "content": booking_prompt}
            response = self.fanar_client.chat.completions.create(
                model=model_name, 
                messages=[messages],
                max_tokens=800
            )
            
            try:
                return json.loads(response.choices[0].message.content)
            except json.JSONDecodeError:
                print("⚠️ FANAR booking response not parseable, using fallback")
                return self._create_booking_fallback(booking_query, user_profile)
                
        except Exception as e:
            print(f"❌ Error processing booking: {e}")
            return self._create_booking_fallback(booking_query, user_profile)
    
    def _create_booking_fallback(self, booking_query: str, user_profile: UserProfile) -> Dict:
        """Create booking response when FANAR fails"""
        return {
            "booking_details": {
                "type": "restaurant",
                "venue_name": "Qatar Restaurant",
                "date": datetime.now().strftime("%Y-%m-%d"),
                "time": "19:00",
                "party_size": user_profile.group_size,
                "estimated_cost": "$75",
                "confirmation_needed": True
            },
            "booking_summary": "Restaurant booking request processed",
            "next_steps": "Please confirm the booking details and we'll proceed with the reservation",
            "missing_info": []
        }

    # Enhanced day planning methods (keeping the existing ones as they are working)
    def _parse_cost(self, cost_str: str) -> int:
        """Parse cost string to integer"""
        if not cost_str or cost_str.lower() == 'free':
            return 0
        
        # Extract numbers from string
        import re
        numbers = re.findall(r'\d+', str(cost_str))
        if numbers:
            return int(numbers[0])
        
        # Default based on $ symbols
        if '$$$' in cost_str:
            return 100
        elif '$$' in cost_str:
            return 50
        elif '$' in cost_str:
            return 25
        else:
            return 0

    def _add_time_precise(self, time_str: str, hours_to_add: float) -> str:
        """Add precise time including fractions of hours"""
        try:
            hour, minute = map(int, time_str.split(':'))
            
            # Convert hours to minutes
            total_minutes = hour * 60 + minute + (hours_to_add * 60)
            
            # Convert back to hours and minutes
            new_hour = int(total_minutes // 60) % 24
            new_minute = int(total_minutes % 60)
            
            return f"{new_hour:02d}:{new_minute:02d}"
        except:
            return "12:00"

    async def create_enhanced_day_plan(self, query: str, user_profile: UserProfile, parsed_preferences: Dict = None) -> Dict:
        """
        Enhanced day plan creation that uses parsed preferences from the query
        """
        if parsed_preferences is None:
            parsed_preferences = {}
        
        duration_hours = parsed_preferences.get('duration', 8)
        start_time = parsed_preferences.get('start_time', '09:00')
        budget_amount = parsed_preferences.get('budget_amount', 150)
        
        print(f"📊 Creating enhanced plan: {duration_hours}h, starts {start_time}, ${budget_amount} budget")
        
        try:
            # Get diverse context based on activity types
            context_results = self.retrieve_context(query, user_profile, n_results=15)
            
            # Fallback to enhanced RAG-based plan
            print("🔄 Using enhanced RAG fallback plan generation")
            return self._create_enhanced_rag_plan(context_results, user_profile, parsed_preferences)
                
        except Exception as e:
            print(f"❌ Enhanced day plan error: {e}")
            return self._create_emergency_fallback_plan(duration_hours, budget_amount, start_time)

    def _create_enhanced_rag_plan(self, context_results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> Dict:
        """Create enhanced plan from RAG context"""
        duration_hours = parsed_preferences.get('duration', 8)
        start_time = parsed_preferences.get('start_time', '09:00')
        budget_amount = parsed_preferences.get('budget_amount', 150)
        
        # Filter results by user preferences
        filtered_results = self._filter_by_enhanced_preferences(context_results, user_profile, parsed_preferences)
        
        # Generate activities based on duration and preferences
        activities = self._create_enhanced_activities(filtered_results, duration_hours, start_time, budget_amount, parsed_preferences)
        
        total_cost = sum(self._parse_cost(activity.get('estimated_cost', '$0')) for activity in activities)
        
        return {
            "day_plan": {
                "title": f"Your {parsed_preferences.get('duration_text', 'Perfect')} Qatar Experience",
                "date": datetime.now().strftime("%Y-%m-%d"),
                "total_estimated_cost": f"${total_cost}",
                "total_duration": f"{duration_hours} hours",
                "activities": activities,
                "transportation_notes": f"Recommended transportation for this {duration_hours}-hour itinerary",
                "total_walking_distance": f"{len(activities) * 0.5:.1f} km",
                "weather_tips": "Dress comfortably, bring sunscreen and water for extended touring",
                "budget_breakdown": self._calculate_enhanced_budget_breakdown(activities, budget_amount)
            }
        }

    def _filter_by_enhanced_preferences(self, results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> List[Dict]:
        """Enhanced filtering based on parsed preferences"""
        filtered = []
        budget_amount = parsed_preferences.get('budget_amount', 150)
        
        # Score results based on preferences
        scored_results = []
        for result in results:
            metadata = result['metadata']
            score = 0
            
            # Budget compatibility score
            item_cost = self._parse_cost(metadata.get('price_range', metadata.get('entry_fee', '$0')))
            if budget_amount >= 200:  # Premium budget
                if item_cost >= 50:
                    score += 3  # Prefer higher-end options
                else:
                    score += 1
            elif budget_amount >= 100:  # Moderate budget
                if 20 <= item_cost <= 80:
                    score += 3  # Perfect range
                elif item_cost < 20:
                    score += 2
                else:
                    score += 0  # Too expensive
            else:  # Budget-friendly
                if item_cost <= 30:
                    score += 3
                elif item_cost <= 50:
                    score += 1
                else:
                    continue  # Skip expensive items
            
            # Activity type preference score
            category = metadata.get('category', '')
            activity_types = parsed_preferences.get('activity_types', user_profile.activity_types)
            
            if 'Cultural' in activity_types and category in ['attractions', 'museums']:
                score += 2
            if 'Food' in activity_types and category in ['restaurants', 'cafes']:
                score += 2
            if 'Modern' in activity_types and category in ['shopping', 'malls']:
                score += 2
            if 'Shopping' in activity_types and 'souq' in metadata.get('name', '').lower():
                score += 2
            
            # Special preference bonuses
            if parsed_preferences.get('include_souqs') and 'souq' in metadata.get('name', '').lower():
                score += 3
            if parsed_preferences.get('prioritize_culture') and category in ['attractions', 'museums']:
                score += 3
            
            # Rating bonus
            rating = metadata.get('rating', 0)
            if rating >= 4.5:
                score += 2
            elif rating >= 4.0:
                score += 1
            
            scored_results.append((result, score))
        
        # Sort by score and return top results
        scored_results.sort(key=lambda x: x[1], reverse=True)
        return [result for result, score in scored_results[:12]]

    def _create_enhanced_activities(self, filtered_results: List[Dict], duration_hours: int, start_time: str, budget_amount: int, parsed_preferences: Dict) -> List[Dict]:
        """Create activities with proper timing and budget distribution"""
        activities = []
        current_time = start_time
        
        # Calculate activity distribution based on duration
        if duration_hours >= 12:
            # Extended day: Breakfast, Activity, Lunch, Activity, Snack, Activity, Dinner
            activity_schedule = [
                ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), 
                ('activity', 2.0), ('coffee', 1.0), ('activity', 2.5), ('dinner', 2.0)
            ]
        elif duration_hours >= 8:
            # Full day: Breakfast, Activity, Lunch, Activity, Dinner
            activity_schedule = [
                ('breakfast', 1.0), ('activity', 2.5), ('lunch', 1.5), ('activity', 2.5), ('dinner', 1.5)
            ]
        else:
            # Half day: Light meal, Activity, Activity
            activity_schedule = [
                ('coffee', 0.5), ('activity', 2.0), ('lunch', 1.0), ('activity', 1.5)
            ]
        
        # Separate venues by type for selection
        restaurants = [r for r in filtered_results if r['metadata']['category'] == 'restaurants']
        attractions = [r for r in filtered_results if r['metadata']['category'] == 'attractions']
        cafes = [r for r in filtered_results if r['metadata']['category'] == 'cafes']
        
        # Ensure we have enough venues
        if not restaurants:
            restaurants = [{'metadata': {'name': 'Local Restaurant', 'category': 'restaurants', 'location': 'Doha'}}]
        if not attractions:
            attractions = [{'metadata': {'name': 'Qatar Attraction', 'category': 'attractions', 'location': 'Doha'}}]
        
        restaurant_index = 0
        attraction_index = 0
        cafe_index = 0
        
        for i, (activity_type, duration_hours_float) in enumerate(activity_schedule):
            if activity_type == 'breakfast':
                venue = restaurants[restaurant_index % len(restaurants)]
                activity = self._create_enhanced_meal_activity(
                    venue, current_time, 'breakfast', budget_amount, duration_hours_float
                )
                restaurant_index += 1
                
            elif activity_type == 'lunch':
                venue = restaurants[restaurant_index % len(restaurants)]
                activity = self._create_enhanced_meal_activity(
                    venue, current_time, 'lunch', budget_amount, duration_hours_float
                )
                restaurant_index += 1
                
            elif activity_type == 'dinner':
                venue = restaurants[restaurant_index % len(restaurants)]
                activity = self._create_enhanced_meal_activity(
                    venue, current_time, 'dinner', budget_amount * 1.5, duration_hours_float  # Dinner costs more
                )
                restaurant_index += 1
                
            elif activity_type == 'coffee':
                venue = cafes[cafe_index % len(cafes)] if cafes else restaurants[0]
                activity = self._create_enhanced_cafe_activity(
                    venue, current_time, budget_amount, duration_hours_float
                )
                cafe_index += 1
                
            else:  # activity
                venue = attractions[attraction_index % len(attractions)]
                activity = self._create_enhanced_attraction_activity(
                    venue, current_time, budget_amount, duration_hours_float
                )
                attraction_index += 1
            
            activities.append(activity)
            current_time = self._add_time_precise(current_time, duration_hours_float)
        
        return activities

    def _create_enhanced_meal_activity(self, venue: Dict, time: str, meal_type: str, budget_amount: int, duration: float) -> Dict:
        """Create enhanced meal activity with proper pricing"""
        metadata = venue.get('metadata', {})
        
        # Calculate cost based on budget and meal type
        if budget_amount >= 200:  # Premium
            base_cost = {'breakfast': 40, 'lunch': 60, 'dinner': 120}
        elif budget_amount >= 100:  # Moderate
            base_cost = {'breakfast': 25, 'lunch': 40, 'dinner': 70}
        else:  # Budget
            base_cost = {'breakfast': 15, 'lunch': 25, 'dinner': 45}
        
        cost = base_cost.get(meal_type, 30)
        
        # Use venue cost if available and reasonable
        venue_cost = self._parse_cost(metadata.get('price_range', '$0'))
        if venue_cost > 0 and abs(venue_cost - cost) < cost * 0.5:
            cost = venue_cost
        
        return {
            "time": time,
            "activity": f"{meal_type.title()} at {metadata.get('name', 'Premium Restaurant')}",
            "location": metadata.get('location', 'Doha, Qatar'),
            "duration": f"{duration} hours",
            "estimated_cost": f"${cost}",
            "description": self._get_venue_description(venue, f"Enjoy an excellent {meal_type} experience"),
            "transportation": "Private transport or taxi",
            "booking_required": True,
            "tips": f"Perfect {meal_type} spot with {metadata.get('rating', 4.5)}/5 rating"
        }

    def _create_enhanced_attraction_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
        """Create enhanced attraction activity"""
        metadata = venue.get('metadata', {})
        
        # Calculate cost based on budget level
        base_cost = self._parse_cost(metadata.get('entry_fee', metadata.get('price_range', '$0')))
        
        if base_cost == 0:
            cost_str = "Free"
        elif budget_amount >= 200:
            cost_str = f"${max(base_cost, 20)}"  # Premium experiences
        else:
            cost_str = f"${base_cost}" if base_cost > 0 else "Free"
        
        return {
            "time": time,
            "activity": f"Visit {metadata.get('name', 'Qatar Cultural Site')}",
            "location": metadata.get('location', 'Doha, Qatar'),
            "duration": f"{duration} hours",
            "estimated_cost": cost_str,
            "description": self._get_venue_description(venue, "Explore this remarkable attraction"),
            "transportation": "Private transport recommended",
            "booking_required": False,
            "tips": f"Rated {metadata.get('rating', 4.5)}/5 - don't miss this experience"
        }

    def _create_enhanced_cafe_activity(self, venue: Dict, time: str, budget_amount: int, duration: float) -> Dict:
        """Create enhanced cafe/coffee break activity"""
        metadata = venue.get('metadata', {})
        
        cost = 20 if budget_amount >= 200 else 15 if budget_amount >= 100 else 10
        
        return {
            "time": time,
            "activity": f"Coffee break at {metadata.get('name', 'Local Café')}",
            "location": metadata.get('location', 'Doha, Qatar'),
            "duration": f"{duration} hours",
            "estimated_cost": f"${cost}",
            "description": self._get_venue_description(venue, "Relaxing coffee break and light refreshments"),
            "transportation": "Walking distance or short taxi",
            "booking_required": False,
            "tips": "Perfect spot to recharge and enjoy local atmosphere"
        }

    def _get_venue_description(self, venue: Dict, fallback: str) -> str:
        """Get venue description from RAG data or use fallback"""
        if venue and 'document' in venue:
            return venue['document'][:150] + "..."
        return fallback

    def _calculate_enhanced_budget_breakdown(self, activities: List[Dict], total_budget: int) -> Dict:
        """Calculate realistic budget breakdown"""
        food_cost = 0
        attraction_cost = 0
        
        for activity in activities:
            cost = self._parse_cost(activity.get('estimated_cost', '$0'))
            activity_name = activity.get('activity', '').lower()
            
            if any(word in activity_name for word in ['breakfast', 'lunch', 'dinner', 'coffee']):
                food_cost += cost
            else:
                attraction_cost += cost
        
        transportation_cost = max(int(total_budget * 0.15), 30)  # 15% of budget or minimum $30
        
        return {
            "food": f"${food_cost}",
            "attractions": f"${attraction_cost}",
            "transportation": f"${transportation_cost}"
        }

    def _create_emergency_fallback_plan(self, duration_hours: int, budget_amount: int, start_time: str) -> Dict:
        """Emergency fallback when everything fails"""
        activities = []
        
        # Create basic premium Qatar experience based on budget
        if budget_amount >= 200:
            activities = [
                {
                    "time": start_time,
                    "activity": "Breakfast at Al Mourjan Restaurant",
                    "location": "West Bay, Corniche",
                    "duration": "1 hour",
                    "estimated_cost": "$45",
                    "description": "Premium waterfront breakfast with traditional Qatari cuisine",
                    "transportation": "Private car from hotel",
                    "booking_required": True,
                    "tips": "Request table with Corniche view"
                },
                {
                    "time": self._add_time_precise(start_time, 2),
                    "activity": "Visit Museum of Islamic Art",
                    "location": "Corniche, Doha",
                    "duration": "2.5 hours",
                    "estimated_cost": "Free",
                    "description": "World-class Islamic art collection in stunning I.M. Pei building",
                    "transportation": "10-minute private car ride",
                    "booking_required": False,
                    "tips": "Don't miss the manuscript collection"
                }
            ]
        else:
            # Budget-friendly fallback
            activities = [
                {
                    "time": start_time,
                    "activity": "Breakfast at Local Café",
                    "location": "Souq Waqif",
                    "duration": "1 hour",
                    "estimated_cost": "$15",
                    "description": "Traditional breakfast in authentic market setting",
                    "transportation": "Taxi from hotel",
                    "booking_required": False,
                    "tips": "Try the local bread and honey"
                },
                {
                    "time": self._add_time_precise(start_time, 1.5),
                    "activity": "Explore Souq Waqif",
                    "location": "Old Doha",
                    "duration": "3 hours",
                    "estimated_cost": "$20",
                    "description": "Traditional marketplace with authentic architecture",
                    "transportation": "Walking within souq",
                    "booking_required": False,
                    "tips": "Perfect for shopping and cultural immersion"
                }
            ]
        
        total_cost = sum(self._parse_cost(activity['estimated_cost']) for activity in activities)
        
        return {
            "day_plan": {
                "title": f"Your {duration_hours}-Hour Qatar Experience",
                "date": datetime.now().strftime("%Y-%m-%d"),
                "total_estimated_cost": f"${total_cost}",
                "total_duration": f"{duration_hours} hours",
                "activities": activities,
                "transportation_notes": "Taxi and walking recommended for budget plan" if budget_amount < 200 else "Private car recommended for premium experience",
                "total_walking_distance": "3 km" if budget_amount < 200 else "1 km",
                "weather_tips": "Dress comfortably, bring sunscreen and water",
                "budget_breakdown": {
                    "food": f"${int(total_cost * 0.6)}",
                    "attractions": f"${int(total_cost * 0.3)}",
                    "transportation": f"${int(total_cost * 0.1) + 20}"
                }
            }
        }


class ManarAI:
    """
    Main class that combines FANAR API with RAG system
    """
    def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
        print("🚀 Initializing ManarAI system...")
        self.rag_system = QatarRAGSystem(fanar_api_key, vector_db_path)
        print("✅ ManarAI system ready!")
    
    async def process_user_request(self, user_input: str, user_profile: UserProfile, context: str = "dashboard") -> Dict:
        """
        Main entry point for processing user requests
        """
        try:
            # Classify intent using FANAR
            intent = await self.rag_system.classify_intent(user_input, user_profile)
            print(f"🎯 Classified intent: {intent}")
            
            # Route to appropriate handler
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
                # For general chat, use FANAR directly with some context
                context_results = self.rag_system.retrieve_context(user_input, user_profile, n_results=3)
                context_text = "\n".join([f"- {r['metadata']['name']}: {r['document'][:100]}..." for r in context_results[:2]])
                
                chat_prompt = f"""You are a friendly Qatar tourism assistant. Answer the user's question using your knowledge and the context provided.

Context from Qatar database:
{context_text}

User question: "{user_input}"

Provide a helpful, conversational response about Qatar tourism."""

                try:
                    messages = {"role": "user", "content": chat_prompt}
                    response = self.rag_system.fanar_client.chat.completions.create(
                        model=model_name, 
                        messages=[messages],
                        max_tokens=500
                    )
                    
                    return {
                        "type": "chat", 
                        "data": {
                            "message": response.choices[0].message.content,
                            "context_used": len(context_results) > 0
                        }
                    }
                except Exception as e:
                    print(f"Chat error: {e}")
                    return {
                        "type": "chat", 
                        "data": {
                            "message": "I'm here to help you explore Qatar! What would you like to know?",
                            "context_used": len(context_results) > 0
                        }
                    }
                
        except Exception as e:
            print(f"❌ Error processing user request: {e}")
            return {
                "type": "error",
                "data": {
                    "message": "I'm sorry, I couldn't process your request right now. Please try again.",
                    "error": str(e)
                }
            }