# Step 2: Create Embeddings & Vector Database for RAG
import json
import chromadb
import numpy as np
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Any, Optional
import os
from datetime import datetime

class QatarVectorDatabase:
    def __init__(self, model_name: str = "paraphrase-multilingual-MiniLM-L12-v2"):
        """
        Initialize the vector database with embeddings model
        Using multilingual model to support Arabic/English queries
        """
        print(" Initializing Qatar Vector Database...")
        
        # Initialize embedding model
        self.embedding_model = SentenceTransformer(model_name)
        print(f" Loaded embedding model: {model_name}")
        
        # Initialize ChromaDB with cosine similarity
        self.client = chromadb.PersistentClient(path="./chroma_db")
        
        # Create or get collection with cosine similarity
        try:
            # Try to get existing collection
            self.collection = self.client.get_collection("qatar_tourism")
            print(" Loaded existing Qatar tourism collection")
        except:
            # Create new collection with cosine similarity
            self.collection = self.client.create_collection(
                name="qatar_tourism",
                metadata={"description": "Qatar tourism data for RAG", "hnsw:space": "cosine"}
            )
            print(" Created new Qatar tourism collection with cosine similarity")
    
    def load_and_process_data(self, embeddings_file: str = "qatar_embeddings_data.json"):
        """
        Load the prepared embeddings data and create vector embeddings
        """
        print(f" Loading data from {embeddings_file}...")
        
        try:
            with open(embeddings_file, 'r', encoding='utf-8') as f:
                self.data = json.load(f)
            print(f" Loaded {len(self.data)} items")
        except FileNotFoundError:
            print(f" Error: {embeddings_file} not found. Run Step 1 first!")
            return False
        
        return True
    
    def create_embeddings(self):
        """
        Create embeddings for all text data
        """
        print(" Creating embeddings...")
        
        # Extract texts for embedding
        texts = [item['text'] for item in self.data]
        
        # Create embeddings in batches for efficiency
        print(" Processing embeddings (this may take a moment)...")
        embeddings = self.embedding_model.encode(
            texts, 
            batch_size=32,
            show_progress_bar=True,
            convert_to_numpy=True
        )
        
        print(f" Created {len(embeddings)} embeddings")
        return embeddings
    
    def populate_vector_database(self):
        """
        Populate ChromaDB with embeddings and metadata
        """
        print(" Populating vector database...")
        
        # Check if collection already has data
        existing_count = self.collection.count()
        if existing_count > 0:
            print(f" Collection already has {existing_count} items. Clearing...")
            # Clear existing data
            self.collection.delete(where={})
        
        # Create embeddings
        embeddings = self.create_embeddings()
        
        # Prepare data for ChromaDB
        ids = []
        documents = []
        metadatas = []
        embeddings_list = []
        
        for i, item in enumerate(self.data):
            ids.append(item['id'])
            documents.append(item['text'])
            
            # Create metadata (ChromaDB doesn't support nested objects)
            metadata = {
                'category': item['category'],
                'name': item['name'],
                'location': item['metadata'].get('location', ''),
                'rating': item['metadata'].get('rating', 0),
                'price_range': item['metadata'].get('price_range', ''),
                'cuisine_type': item['metadata'].get('cuisine_type', ''),
                'entry_fee': item['metadata'].get('entry_fee', ''),
                'opening_hours': item['metadata'].get('opening_hours', ''),
                'best_time_to_visit': item['metadata'].get('best_time_to_visit', ''),
            }
            
            # Add features as comma-separated string
            if 'features' in item['metadata']:
                metadata['features'] = ','.join(item['metadata']['features'])
            
            metadatas.append(metadata)
            embeddings_list.append(embeddings[i].tolist())
        
        # Add to ChromaDB
        self.collection.add(
            ids=ids,
            documents=documents,
            metadatas=metadatas,
            embeddings=embeddings_list
        )
        
        print(f" Added {len(ids)} items to vector database")
        print(f" Database stats: {self.collection.count()} total items")
    
    def search_similar(self, query: str, n_results: int = 5, category_filter: Optional[str] = None) -> List[Dict]:
        """
        Search for similar items using semantic similarity
        """
        # Create query embedding
        query_embedding = self.embedding_model.encode([query])
        
        # Prepare where clause for filtering
        where_clause = {}
        if category_filter:
            where_clause["category"] = category_filter
        
        # Search in ChromaDB
        results = self.collection.query(
            query_embeddings=query_embedding.tolist(),
            n_results=n_results,
            where=where_clause if where_clause else None
        )
        
        # Format results
        formatted_results = []
        for i in range(len(results['ids'][0])):
            # ChromaDB returns squared euclidean distance, convert to cosine similarity
            distance = results['distances'][0][i]
            # For cosine similarity: similarity = 1 - (distance / 2)
            # Clamp between 0 and 1
            similarity_score = max(0, min(1, 1 - (distance / 2)))
            
            formatted_results.append({
                'id': results['ids'][0][i],
                'document': results['documents'][0][i],
                'metadata': results['metadatas'][0][i],
                'distance': distance,
                'similarity_score': similarity_score
            })
        
        return formatted_results
    
    def search_with_filters(self, 
                          query: str, 
                          category: Optional[str] = None,
                          price_range: Optional[str] = None,
                          min_rating: Optional[float] = None,
                          n_results: int = 5) -> List[Dict]:
        """
        Enhanced search with multiple filters and smart price logic
        """
        # Define price logic
        price_order = {"$": 1, "$": 2, "$$": 3}
        
        # Handle budget-related queries with smart filtering
        is_budget_query = any(word in query.lower() for word in ['budget', 'cheap', 'affordable', 'inexpensive'])
        
        # Build where clause
        where_clause = {}
        if category:
            where_clause["category"] = category
        if price_range and not is_budget_query:  # Don't use price_range filter for budget queries
            where_clause["price_range"] = price_range
        
        # Create query embedding
        query_embedding = self.embedding_model.encode([query])
        
        # Search with more results to allow for filtering
        search_results = n_results * 3 if is_budget_query else n_results * 2
        
        results = self.collection.query(
            query_embeddings=query_embedding.tolist(),
            n_results=search_results,
            where=where_clause if where_clause else None
        )
        
        # Post-process for additional filters
        filtered_results = []
        for i in range(len(results['ids'][0])):
            metadata = results['metadatas'][0][i]
            
            # Apply rating filter
            if min_rating and metadata.get('rating', 0) < min_rating:
                continue
            
            # Smart budget filtering
            if is_budget_query:
                item_price = metadata.get('price_range', '')
                # For budget queries, only include $ and $ options
                if item_price in price_order and price_order[item_price] > 2:
                    continue  # Skip expensive ($$) options for budget queries
            
            # Apply explicit price range filter
            if price_range and metadata.get('price_range', '') != price_range:
                continue
            
            # Fix similarity calculation
            distance = results['distances'][0][i]
            similarity_score = max(0, min(1, 1 - (distance / 2)))
            
            filtered_results.append({
                'id': results['ids'][0][i],
                'document': results['documents'][0][i],
                'metadata': metadata,
                'distance': distance,
                'similarity_score': similarity_score
            })
            
            if len(filtered_results) >= n_results:
                break
        
        return filtered_results
    
    def get_recommendations_for_user(self, 
                                   user_preferences: Dict,
                                   query: str = "",
                                   n_results: int = 5) -> List[Dict]:
        """
        Get personalized recommendations based on user preferences
        """
        # Build enhanced query based on user preferences
        enhanced_query_parts = []
        
        if query:
            enhanced_query_parts.append(query)
        
        # Add user preferences to query
        if user_preferences.get('food_preferences'):
            enhanced_query_parts.append(f"cuisine: {', '.join(user_preferences['food_preferences'])}")
        
        if user_preferences.get('activity_types'):
            enhanced_query_parts.append(f"activities: {', '.join(user_preferences['activity_types'])}")
        
        if user_preferences.get('budget_range'):
            enhanced_query_parts.append(f"budget: {user_preferences['budget_range']}")
        
        enhanced_query = ". ".join(enhanced_query_parts)
        
        # Search with preferences
        return self.search_with_filters(
            query=enhanced_query,
            price_range=user_preferences.get('budget_range'),
            min_rating=user_preferences.get('min_rating', 4.0),
            n_results=n_results
        )
    
    def test_search_functionality(self):
        """
        Test the search functionality with various queries
        """
        print("\n Testing Search Functionality...")
        print("=" * 50)
        
        test_queries = [
            {"query": "traditional Qatari food", "description": "Traditional cuisine search"},
            {"query": "museum and art", "description": "Cultural attractions"},
            {"query": "budget friendly restaurants", "description": "Budget dining"},
            {"query": "expensive fine dining", "description": "Luxury dining"},
            {"query": "family activities", "description": "Family-friendly options"},
            {"query": "coffee and relaxation", "description": "Cafe search"}
        ]
        
        for test in test_queries:
            print(f"\n {test['description']}: '{test['query']}'")
            results = self.search_with_filters(test['query'], n_results=3)
            
            for i, result in enumerate(results, 1):
                metadata = result['metadata']
                price_info = metadata.get('price_range', metadata.get('entry_fee', 'N/A'))
                print(f"  {i}. {metadata['name']} ({metadata['category']})")
                print(f"     Similarity: {result['similarity_score']:.3f} | Price: {price_info}")
                print(f"     Location: {metadata['location']}")
    
    def get_database_stats(self):
        """
        Get comprehensive database statistics
        """
        print("\n Vector Database Statistics")
        print("=" * 50)
        
        total_count = self.collection.count()
        print(f"Total items: {total_count}")
        
        # Get sample of data to analyze categories
        sample_results = self.collection.get(limit=total_count)
        
        # Count by category
        categories = {}
        ratings = []
        
        for metadata in sample_results['metadatas']:
            category = metadata['category']
            categories[category] = categories.get(category, 0) + 1
            
            if metadata.get('rating'):
                ratings.append(metadata['rating'])
        
        print("\nItems by category:")
        for category, count in categories.items():
            print(f"  {category}: {count}")
        
        if ratings:
            avg_rating = sum(ratings) / len(ratings)
            print(f"\nAverage rating: {avg_rating:.2f}")
        
        print("=" * 50)

def setup_qatar_rag_system():
    """
    Main function to set up the complete RAG system
    """
    print(" Setting up Qatar Tourism RAG System")
    print("=" * 60)
    
    # Initialize vector database
    vector_db = QatarVectorDatabase()
    
    # Load and process data
    if not vector_db.load_and_process_data():
        return None
    
    # Create embeddings and populate database
    vector_db.populate_vector_database()
    
    # Show statistics
    vector_db.get_database_stats()
    
    # Test functionality
    vector_db.test_search_functionality()
    
    print("\n Qatar Tourism RAG System Ready!")
    print(" Ready for Step 3: FANAR API Integration")
    
    return vector_db

# Example usage and testing
if __name__ == "__main__":
    # Set up the system
    vector_db = setup_qatar_rag_system()
    
    if vector_db:
        print("\n" + "="*60)
        print(" INTERACTIVE TESTING")
        print("="*60)
        
        # Example user preferences
        user_preferences = {
            'food_preferences': ['Middle Eastern', 'Traditional'],
            'budget_range': '$$',
            'activity_types': ['Cultural', 'Shopping'],
            'min_rating': 4.0
        }
        
        # Test personalized recommendations
        print("\n Testing Personalized Recommendations:")
        print(f"User preferences: {user_preferences}")
        
        recommendations = vector_db.get_recommendations_for_user(
            user_preferences=user_preferences,
            query="best places to visit in Qatar",
            n_results=5
        )
        
        print(f"\n Top {len(recommendations)} Personalized Recommendations:")
        for i, rec in enumerate(recommendations, 1):
            metadata = rec['metadata']
            print(f"\n{i}. {metadata['name']}")
            print(f"   Category: {metadata['category']}")
            print(f"   Location: {metadata['location']}")
            print(f"   Rating: {metadata.get('rating', 'N/A')}")
            print(f"   Price: {metadata.get('price_range', metadata.get('entry_fee', 'N/A'))}")
            print(f"   Similarity Score: {rec['similarity_score']:.3f}")
        
        print(f"\n Vector database saved to: ./chroma_db/")
        print(" You can now use this database with FANAR API in Step 3!")

# Utility function for quick testing
def quick_search(query: str, category: str = None):
    """Quick search function for testing"""
    client = chromadb.PersistentClient(path="./chroma_db")
    collection = client.get_collection("qatar_tourism")
    model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
    
    query_embedding = model.encode([query])
    
    where_clause = {"category": category} if category else None
    
    results = collection.query(
        query_embeddings=query_embedding.tolist(),
        n_results=3,
        where=where_clause
    )
    
    for i, (name, doc) in enumerate(zip(results['metadatas'][0], results['documents'][0])):
        distance = results['distances'][0][i]
        similarity = max(0, min(1, 1 - (distance / 2)))
        print(f"{i+1}. {name['name']} ({name['category']})")
        print(f"   Similarity: {similarity:.3f}")
        print()