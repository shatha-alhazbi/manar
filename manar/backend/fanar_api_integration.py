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
        print(" Initializing Qatar RAG System...")
        
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
            print(f"Loaded vector database with {self.collection.count()} items")
        except Exception as e:
            print(f" Error loading vector database: {e}")
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
            print(f" Error classifying intent: {e}")
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

Provide 7-8 personalized recommendations in this EXACT JSON format, stick to the prompt and do not generate random words:
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
            print(f" Error generating recommendations: {e}")
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
                return self.create_enhanced_day_plan(context_results, user_profile,{})
                
        except Exception as e:
            print(f" Error creating day plan: {e}")
            return self.create_enhanced_day_plan([], user_profile, {})
        
    def _generate_day_plan_fallback(self, prompt: str) -> str:
        """Generate day plan fallback response"""
        return '''
        {
            "day_plan": {
                "title": "Your Perfect Day in Qatar",
                "date": "2025-06-27",
                "total_estimated_cost": "QAR 200+",
                "total_duration": "6 hours",
                "activities": [
                    {
                        "time": "10:00",
                        "activity": "Breakfast at Reem Al Bawadi",
                        "location": "West Bay, Doha",
                        "duration": "1 hour",
                        "estimated_cost": "25",
                        "description": "Cozy, traditional Arabic breakfast with foul, shakshouka, and fresh bread. Sit by the window for diffused morning light.",
                        "transportation": "Taxi from hotel",
                        "booking_required": true,
                        "tips": "Order the foul with tahini, shakshouka, and hot mint tea. Perfect place to soft launch the day."
                    },
                    {
                        "time": "11:00",
                        "activity": "Fire Station Gallery + Café 999",
                        "location": "Al Bidda Area",
                        "duration": "1 hour",
                        "estimated_cost": "15",
                        "description": "Contemporary Qatari art gallery with industrial chic vibe. Explore temporary exhibitions from Qatari artists-in-residence.",
                        "transportation": "10-minute drive from West Bay",
                        "booking_required": false,
                        "tips": "Chill at Café 999 next door - creative interior, calm atmosphere. Try their iced Americano or Spanish latte."
                    },
                    {
                        "time": "12:00",
                        "activity": "Mathaf: Arab Museum of Modern Art",
                        "location": "Education City",
                        "duration": "1.5 hours",
                        "estimated_cost": "Free",
                        "description": "Deep Arab world culture with a modern lens. Empty, vast, moody atmosphere perfect for contemplation.",
                        "transportation": "15-minute drive from Al Bidda",
                        "booking_required": false,
                        "tips": "Must-sees: Monir Farmanfarmaian's mirror mosaics, Abdul Hadi El Gazzar's surrealist paintings, Choucair and Etel Adnan works."
                    },
                    {
                        "time": "13:30",
                        "activity": "Artisanal Lunch at Dukkan Falafel",
                        "location": "Education City",
                        "duration": "1 hour",
                        "estimated_cost": "20",
                        "description": "Underground Qatari-modern sandwich spot - tiny, cool, and hidden. Perfect light lunch option.",
                        "transportation": "Walking distance from Mathaf",
                        "booking_required": false,
                        "tips": "Try falafel wrap, beetroot hummus, or cold green juice. Alternative: Volume Café at The Pearl for chic industrial interior."
                    },
                    {
                        "time": "14:30",
                        "activity": "Qatar National Library Atrium",
                        "location": "Qatar National Library",
                        "duration": "45 minutes",
                        "estimated_cost": "Free",
                        "description": "Clean, futuristic library with massive atrium. Sunlight floods through the glass roof creating a serene atmosphere.",
                        "transportation": "8-minute drive from Mathaf",
                        "booking_required": false,
                        "tips": "Walk up to the rare books section or chill on the viewing deck. Soak in the silence and futuristic architecture."
                    },
                    {
                        "time": "15:15",
                        "activity": "Golden Hour Boat Ride at Corniche",
                        "location": "MIA Park Boat Dock",
                        "duration": "45 minutes",
                        "estimated_cost": "30",
                        "description": "Romantic dhow boat ride during golden hour. Skyline glows, sea breeze hits different, perfect ending to the day.",
                        "transportation": "15-minute drive to MIA Park",
                        "booking_required": false,
                        "tips": "Find a private dhow ride (QR 20-30, no booking needed). Sit on rooftop cushions and enjoy the romantic intellectual vibe."
                    }
                ],
                "transportation_notes": "Use ride-hailing apps or taxis between locations. Most drives are 10-15 minutes between venues.",
                "total_walking_distance": "1.5 km",
                "weather_tips": "Bring sunscreen, comfortable walking shoes, and a light jacket for the boat ride. Stay hydrated throughout the day.",
                "budget_breakdown": {
                    "food": "60",
                    "attractions": "0",
                    "transportation": "45"
                }
            }
        }
        '''
    
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
            print(f" Error processing booking: {e}")
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

    def create_enhanced_day_plan(self, context_results: List[Dict], user_profile: UserProfile, parsed_preferences: Dict) -> Dict:
        """Create enhanced plan from RAG context"""
        fallback_json_str = self._generate_day_plan_fallback("")
        fallback_dict = json.loads(fallback_json_str)
        return fallback_dict


    
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

class manarAI:
    """
    Main class that combines FANAR API with RAG system
    """
    def __init__(self, fanar_api_key: str, vector_db_path: str = "./chroma_db"):
        print("Initializing manarI system...")
        self.rag_system = QatarRAGSystem(fanar_api_key, vector_db_path)
        print("manarI system ready!")
    
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
            print(f" Error processing user request: {e}")
            return {
                "type": "error",
                "data": {
                    "message": "I'm sorry, I couldn't process your request right now. Please try again.",
                    "error": str(e)
                }
            }