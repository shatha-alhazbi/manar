# Step 1: Create Qatar Tourism Database
# This will be our knowledge base for RAG implementation

import json
import pandas as pd
from datetime import datetime
from typing import List, Dict, Any

class QatarTourismDatabase:
    def __init__(self):
        self.data = {
            "restaurants": [],
            "attractions": [],
            "cafes": [],
            "shopping": [],
            "hotels": [],
            "transportation": [],
            "cultural_sites": [],
            "events": []
        }
        self._populate_sample_data()
    
    def _populate_sample_data(self):
        """
        Populate with curated Qatar tourism data
        This data is structured to work well with embeddings later
        """
        
        # RESTAURANTS DATA
        self.data["restaurants"] = [
            {
                "id": "rest_001",
                "name": "Al Mourjan Restaurant",
                "cuisine_type": "Traditional Qatari",
                "location": "West Bay, Corniche",
                "coordinates": {"lat": 25.3548, "lng": 51.5310},
                "price_range": "$$",
                "avg_cost_per_person": 80,
                "rating": 4.6,
                "description": "Authentic Qatari cuisine with stunning views of the Corniche waterfront. Famous for traditional dishes like machboos and harees.",
                "specialties": ["Machboos", "Harees", "Luqaimat", "Fresh Seafood"],
                "ambiance": "Traditional, Family-friendly, Waterfront views",
                "opening_hours": "12:00-15:00, 19:00-23:00",
                "contact": "+974 4444 0000",
                "features": ["outdoor_seating", "family_friendly", "traditional_music", "corniche_view", "valet_parking"],
                "dietary_options": ["halal", "vegetarian_options"],
                "languages_spoken": ["Arabic", "English"],
                "dress_code": "Smart casual",
                "best_time_to_visit": "Sunset for best views",
                "booking_required": True,
                "payment_methods": ["cash", "card", "digital_wallet"]
            },
            {
                "id": "rest_002",
                "name": "Souq Waqif Traditional Restaurant",
                "cuisine_type": "Middle Eastern",
                "location": "Souq Waqif, Old Doha",
                "coordinates": {"lat": 25.2867, "lng": 51.5333},
                "price_range": "$",
                "avg_cost_per_person": 45,
                "rating": 4.4,
                "description": "Experience authentic Middle Eastern flavors in the heart of Qatar's most famous traditional market.",
                "specialties": ["Mixed Grill", "Hummus", "Fattoush", "Kunafa"],
                "ambiance": "Traditional market setting, Cultural experience",
                "opening_hours": "11:00-24:00",
                "contact": "+974 4444 0001",
                "features": ["historic_location", "budget_friendly", "local_experience", "shisha", "live_entertainment"],
                "dietary_options": ["halal", "vegetarian", "vegan_options"],
                "languages_spoken": ["Arabic", "English", "Urdu"],
                "dress_code": "Casual",
                "best_time_to_visit": "Evening for cultural atmosphere",
                "booking_required": False,
                "payment_methods": ["cash", "card"]
            },
            {
                "id": "rest_003",
                "name": "Nobu Doha",
                "cuisine_type": "Japanese-Peruvian Fusion",
                "location": "Four Seasons Hotel, West Bay",
                "coordinates": {"lat": 25.3656, "lng": 51.5310},
                "price_range": "$$$",
                "avg_cost_per_person": 350,
                "rating": 4.8,
                "description": "World-renowned Japanese-Peruvian fusion cuisine with innovative dishes and premium ingredients.",
                "specialties": ["Black Cod Miso", "Yellowtail Jalapeño", "Wagyu Beef", "Premium Sushi"],
                "ambiance": "Upscale, Modern, Fine dining",
                "opening_hours": "18:00-24:00",
                "contact": "+974 4494 8888",
                "features": ["fine_dining", "city_views", "premium_ingredients", "wine_pairing", "private_dining"],
                "dietary_options": ["halal_available", "vegetarian", "gluten_free"],
                "languages_spoken": ["English", "Japanese", "Arabic"],
                "dress_code": "Formal",
                "best_time_to_visit": "Dinner for full experience",
                "booking_required": True,
                "payment_methods": ["card", "digital_wallet"]
            }
        ]
        
        # ATTRACTIONS DATA
        self.data["attractions"] = [
            {
                "id": "attr_001",
                "name": "Museum of Islamic Art",
                "category": "Museum",
                "location": "Corniche, Doha",
                "coordinates": {"lat": 25.2948, "lng": 51.5397},
                "entry_fee": "Free",
                "rating": 4.9,
                "description": "World-class museum showcasing Islamic art spanning 1,400 years from three continents. Designed by I.M. Pei.",
                "highlights": ["14th-century manuscripts", "Ceramic collection", "Textiles", "Architecture by I.M. Pei"],
                "opening_hours": "09:00-19:00 (Closed Mondays)",
                "estimated_duration": "2-3 hours",
                "contact": "+974 4422 4444",
                "features": ["family_friendly", "educational", "photography_allowed", "guided_tours", "café", "gift_shop"],
                "accessibility": ["wheelchair_accessible", "audio_guides"],
                "languages_available": ["Arabic", "English", "French"],
                "best_time_to_visit": "Morning for fewer crowds",
                "nearby_attractions": ["Corniche", "Souq Waqif"],
                "transportation": ["metro_nearby", "parking_available", "taxi_accessible"]
            },
            {
                "id": "attr_002",
                "name": "Souq Waqif",
                "category": "Traditional Market",
                "location": "Al Souq, Doha",
                "coordinates": {"lat": 25.2867, "lng": 51.5333},
                "entry_fee": "Free",
                "rating": 4.8,
                "description": "Traditional marketplace rebuilt to retain its original Qatari architectural style. Hub for shopping, dining, and cultural experiences.",
                "highlights": ["Traditional architecture", "Spice market", "Falcon Souq", "Cultural performances"],
                "opening_hours": "10:00-22:00 (Shops vary)",
                "estimated_duration": "2-4 hours",
                "contact": "+974 4433 3333",
                "features": ["shopping", "dining", "cultural_experience", "evening_entertainment", "traditional_crafts"],
                "accessibility": ["wheelchair_accessible", "family_friendly"],
                "languages_available": ["Arabic", "English", "Multiple"],
                "best_time_to_visit": "Evening for atmosphere and cooler weather",
                "nearby_attractions": ["Museum of Islamic Art", "Corniche"],
                "transportation": ["metro_station", "taxi_accessible", "walking_distance_corniche"]
            },
            {
                "id": "attr_003",
                "name": "Katara Cultural Village",
                "category": "Cultural Complex",
                "location": "Katara, Doha",
                "coordinates": {"lat": 25.3792, "lng": 51.5310},
                "entry_fee": "Free (Individual attractions may charge)",
                "rating": 4.7,
                "description": "Cultural district featuring galleries, theaters, restaurants, and beaches. Qatar's premier destination for arts and culture.",
                "highlights": ["Blue Mosque", "Pigeon Towers", "Beach", "Amphitheater", "Art galleries"],
                "opening_hours": "24/7 (Individual venues vary)",
                "estimated_duration": "3-5 hours",
                "contact": "+974 4408 0000",
                "features": ["cultural_events", "art_galleries", "beach_access", "restaurants", "festivals", "family_friendly"],
                "accessibility": ["wheelchair_accessible", "parking_available"],
                "languages_available": ["Arabic", "English"],
                "best_time_to_visit": "Late afternoon and evening",
                "nearby_attractions": ["The Pearl Qatar", "West Bay"],
                "transportation": ["taxi_accessible", "parking_available", "bus_routes"]
            }
        ]
        
        # CAFES DATA
        self.data["cafes"] = [
            {
                "id": "cafe_001",
                "name": "Karak House",
                "specialty": "Traditional Karak Tea",
                "location": "Souq Waqif",
                "coordinates": {"lat": 25.2867, "lng": 51.5330},
                "price_range": "$",
                "avg_cost_per_person": 15,
                "rating": 4.5,
                "description": "Authentic Qatari tea house serving the perfect blend of karak tea with traditional snacks.",
                "specialties": ["Karak Tea", "Arabic Coffee", "Traditional Sweets", "Sambosas"],
                "ambiance": "Traditional, Local experience, Casual",
                "opening_hours": "06:00-24:00",
                "features": ["authentic_experience", "budget_friendly", "outdoor_seating", "quick_service"],
                "best_time_to_visit": "Early morning or evening"
            },
            {
                "id": "cafe_002",
                "name": "Café Ceramic",
                "specialty": "Artisan Coffee & Pottery",
                "location": "Katara Cultural Village",
                "coordinates": {"lat": 25.3792, "lng": 51.5315},
                "price_range": "$$",
                "avg_cost_per_person": 35,
                "rating": 4.6,
                "description": "Unique café combining specialty coffee with pottery workshops in a cultural setting.",
                "specialties": ["Specialty Coffee", "Pottery Classes", "Artisan Pastries"],
                "ambiance": "Artistic, Cultural, Creative",
                "opening_hours": "08:00-22:00",
                "features": ["art_workshops", "cultural_location", "instagram_worthy", "creative_experience"],
                "best_time_to_visit": "Morning for workshops"
            }
        ]
        
        # SHOPPING DATA
        self.data["shopping"] = [
            {
                "id": "shop_001",
                "name": "Villaggio Mall",
                "category": "Shopping Mall",
                "location": "Aspire Zone",
                "coordinates": {"lat": 25.2613, "lng": 51.4436},
                "description": "Venice-themed luxury shopping mall with gondola rides and high-end international brands.",
                "highlights": ["Gondola rides", "Sky ceiling", "Luxury brands", "Family entertainment"],
                "opening_hours": "10:00-22:00",
                "features": ["luxury_shopping", "family_entertainment", "dining", "unique_experience"],
                "brands": ["International luxury", "Fashion", "Electronics", "Home goods"],
                "best_time_to_visit": "Weekday afternoons"
            },
            {
                "id": "shop_002",
                "name": "Gold Souq",
                "category": "Traditional Market",
                "location": "Souq Waqif",
                "coordinates": {"lat": 25.2867, "lng": 51.5335},
                "description": "Traditional gold and jewelry market with competitive prices and custom designs.",
                "highlights": ["Gold jewelry", "Custom designs", "Competitive prices", "Traditional craftsmanship"],
                "opening_hours": "09:00-22:00",
                "features": ["traditional_shopping", "negotiable_prices", "custom_jewelry", "authentic_experience"],
                "best_time_to_visit": "Evening when less crowded"
            }
        ]
        
        # TRANSPORTATION DATA
        self.data["transportation"] = [
            {
                "id": "trans_001",
                "type": "Doha Metro",
                "description": "Modern, efficient metro system connecting major attractions and districts",
                "lines": ["Red Line", "Green Line", "Gold Line"],
                "operating_hours": "05:30-24:00",
                "cost": "2-8 QAR depending on zones",
                "features": ["air_conditioned", "wifi", "accessibility", "contactless_payment"],
                "coverage": ["Airport", "City Center", "West Bay", "Cultural Village"]
            },
            {
                "id": "trans_002",
                "type": "Karwa Taxi",
                "description": "Official Qatar taxi service with fixed meters and trained drivers",
                "cost": "Starting 10 QAR + per km",
                "features": ["metered_fare", "trained_drivers", "credit_card_accepted", "app_booking"],
                "availability": "24/7"
            }
        ]

    def get_all_data(self) -> Dict[str, List[Dict]]:
        """Return all data"""
        return self.data
    
    def get_category_data(self, category: str) -> List[Dict]:
        """Get data for specific category"""
        return self.data.get(category, [])
    
    def search_by_name(self, name: str) -> List[Dict]:
        """Search across all categories by name"""
        results = []
        for category, items in self.data.items():
            for item in items:
                if name.lower() in item.get('name', '').lower():
                    results.append({**item, 'category': category})
        return results
    
    def search_by_location(self, location: str) -> List[Dict]:
        """Search by location"""
        results = []
        for category, items in self.data.items():
            for item in items:
                if location.lower() in item.get('location', '').lower():
                    results.append({**item, 'category': category})
        return results
    
    def get_by_price_range(self, price_range: str) -> List[Dict]:
        """Filter by price range"""
        results = []
        for category, items in self.data.items():
            for item in items:
                if item.get('price_range') == price_range:
                    results.append({**item, 'category': category})
        return results
    
    def export_to_json(self, filename: str = "qatar_tourism_data.json"):
        """Export data to JSON file"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.data, f, indent=2, ensure_ascii=False)
        print(f"Data exported to {filename}")
    
    def export_to_csv(self, category: str, filename: str = None):
        """Export specific category to CSV"""
        if category not in self.data:
            print(f"Category {category} not found")
            return
        
        if filename is None:
            filename = f"qatar_{category}.csv"
        
        df = pd.DataFrame(self.data[category])
        df.to_csv(filename, index=False)
        print(f"{category} data exported to {filename}")
    
    def create_embeddings_text(self) -> List[Dict]:
        """
        Create rich text descriptions for each item that will work well with embeddings
        This prepares the data for RAG implementation
        """
        embeddings_data = []
        
        for category, items in self.data.items():
            for item in items:
                # Create comprehensive text description
                text_parts = []
                
                # Basic info
                text_parts.append(f"Name: {item.get('name', '')}")
                text_parts.append(f"Category: {category}")
                text_parts.append(f"Location: {item.get('location', '')}")
                
                # Description
                if item.get('description'):
                    text_parts.append(f"Description: {item['description']}")
                
                # Specific fields based on category
                if category == "restaurants":
                    text_parts.append(f"Cuisine: {item.get('cuisine_type', '')}")
                    text_parts.append(f"Price range: {item.get('price_range', '')}")
                    text_parts.append(f"Specialties: {', '.join(item.get('specialties', []))}")
                    text_parts.append(f"Ambiance: {item.get('ambiance', '')}")
                    
                elif category == "attractions":
                    text_parts.append(f"Type: {item.get('category', '')}")
                    text_parts.append(f"Entry fee: {item.get('entry_fee', '')}")
                    text_parts.append(f"Duration: {item.get('estimated_duration', '')}")
                    text_parts.append(f"Highlights: {', '.join(item.get('highlights', []))}")
                
                elif category == "cafes":
                    text_parts.append(f"Specialty: {item.get('specialty', '')}")
                    text_parts.append(f"Specialties: {', '.join(item.get('specialties', []))}")
                    text_parts.append(f"Ambiance: {item.get('ambiance', '')}")
                
                # Common fields
                if item.get('features'):
                    text_parts.append(f"Features: {', '.join(item['features'])}")
                
                if item.get('opening_hours'):
                    text_parts.append(f"Hours: {item['opening_hours']}")
                
                if item.get('rating'):
                    text_parts.append(f"Rating: {item['rating']}/5")
                
                if item.get('best_time_to_visit'):
                    text_parts.append(f"Best time to visit: {item['best_time_to_visit']}")
                
                # Create final text
                full_text = ". ".join(text_parts)
                
                embeddings_data.append({
                    'id': item.get('id', f"{category}_{len(embeddings_data)}"),
                    'category': category,
                    'name': item.get('name', ''),
                    'text': full_text,
                    'metadata': item
                })
        
        return embeddings_data
    
    def print_summary(self):
        """Print database summary"""
        print(" Qatar Tourism Database Summary")
        print("=" * 50)
        total_items = 0
        for category, items in self.data.items():
            count = len(items)
            total_items += count
            print(f"{category.title()}: {count} items")
        print(f"\nTotal items: {total_items}")
        print("=" * 50)

# Usage Example
if __name__ == "__main__":
    # Create the database
    db = QatarTourismDatabase()
    
    # Print summary
    db.print_summary()
    
    # Export data for later use
    db.export_to_json("qatar_tourism_data.json")
    
    # Create embeddings-ready text
    embeddings_data = db.create_embeddings_text()
    
    # Save embeddings data
    with open("qatar_embeddings_data.json", 'w', encoding='utf-8') as f:
        json.dump(embeddings_data, f, indent=2, ensure_ascii=False)
    
    print("\n Database created successfully!")
    print(" Files created:")
    print("  - qatar_tourism_data.json (raw data)")
    print("  - qatar_embeddings_data.json (prepared for embeddings)")
    print("\n Ready for Step 2: Creating embeddings and implementing RAG!")