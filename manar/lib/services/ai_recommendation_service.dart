// Updated AI Recommendation Service with better error handling and mock personalization
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'user_services.dart';
import 'auth_services.dart';
import 'package:logger/logger.dart';

var logger = Logger();
final allMockData = [
      //       RecommendationItem(
      //     id: "101",
      //     name: "La Spiga by Paper Moon",
      //     type: "Restaurant",
      //     description: "Italian restaurant offering a luxurious dining experience.",
      //     location: "W Doha Hotel",
      //     priceRange: r"$$$",
      //     rating: 4.8,
      //     estimatedDuration: "2 hours",
      //     whyRecommended: "Perfect for a romantic dinner with authentic Italian cuisine.",
      //     bookingAvailable: true,
      //     bestTimeToVisit: "Evening",
      //     features: ["Outdoor seating", "Valet parking"]
      // ),
      // RecommendationItem(
      //     id: "102",
      //     name: "Museum of Islamic Art",
      //     type: "Attraction",
      //     description: "A stunning museum showcasing Islamic art and architecture.",
      //     location: "Corniche",
      //     priceRange: r"$",
      //     rating: 4.9,
      //     estimatedDuration: "4 hours",
      //     whyRecommended: "A must-visit for art and history enthusiasts.",
      //     bookingAvailable: false,
      //     bestTimeToVisit: "Afternoon",
      //     features: ["Guided tours", "Cafe"]
      // ),
      // RecommendationItem(
      //     id: "103",
      //     name: "Katara Cultural Village",
      //     type: "Attraction",
      //     description: "A cultural hub with theaters, galleries, and restaurants.",
      //     location: "Katara",
      //     priceRange: r"$",
      //     rating: 4.7,
      //     estimatedDuration: "5 hours",
      //     whyRecommended: "Ideal for exploring Qatar's rich cultural heritage.",
      //     bookingAvailable: false,
      //     bestTimeToVisit: "Evening",
      //     features: ["Live performances", "Beach access"]
      // ),
      // RecommendationItem(
      //     id: "104",
      //     name: "The Pearl-Qatar",
      //     type: "Shopping",
      //     description: "An upscale shopping and dining destination on an artificial island.",
      //     location: "The Pearl",
      //     priceRange: r"$$$",
      //     rating: 4.6,
      //     estimatedDuration: "3 hours",
      //     whyRecommended: "Great for luxury shopping and waterfront dining.",
      //     bookingAvailable: false,
      //     bestTimeToVisit: "Afternoon",
      //     features: ["Waterfront views", "Luxury brands"]
      // ),
      RecommendationItem(
          id: "105",
          name: "Arwa",
          type: "Shopping",
          description: "A traditional market offering local goods and souvenirs.",
          location: "Downtown Doha",
          priceRange: r"$",
          rating: 4.8,
          estimatedDuration: "3 hours",
          whyRecommended: "Experience authentic Qatari culture and shop for unique items.",
          bookingAvailable: false,
          bestTimeToVisit: "Morning",
          features: ["Street food", "Handicrafts"]
      )
    ];
    
class AIRecommendationService extends ChangeNotifier {
  // Use different URLs for different platforms
  static String get API_BASE_URL {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }
  
  final UserService _userService;
  final AuthService _authService;
  
  static final http.Client _httpClient = http.Client();
  static const Duration _timeout = Duration(seconds: 60); // Reduced timeout
  
  List<RecommendationItem> _trendingRecommendations = [];
  List<RecommendationItem> _personalizedRecommendations = [];
  List<RecommendationItem> _nearbyRecommendations = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _useBackend = true; // Flag to control backend usage
  
  List<RecommendationItem> get trendingRecommendations => _trendingRecommendations;
  List<RecommendationItem> get personalizedRecommendations => _personalizedRecommendations;
  List<RecommendationItem> get nearbyRecommendations => _nearbyRecommendations;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AIRecommendationService(this._userService, this._authService);

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Test backend connection with shorter timeout
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$API_BASE_URL/health'),
      ).timeout(Duration(seconds: 3)); // Very short timeout for testing
      
      print('Backend connection test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _makePostRequest(String endpoint, Map<String, dynamic> body) async {
    if (!_useBackend) return null;
    
    try {
      print('Making request to: $API_BASE_URL$endpoint');
      
      final response = await _httpClient.post(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Request failed: $e');
      _useBackend = false; // Disable backend for this session
      return null;
    }
  }

  Future<void> loadAllRecommendations() async {
    try {
      _setLoading(true);
      _setError(null);

      // Load user preferences first
      await _userService.loadUserPreferences();
      
      // Quick backend test
      bool isConnected = await testConnection();
      
      if (isConnected && _useBackend) {
        print('Using backend API for recommendations');
        await _loadBackendRecommendations();
      } else {
        print('Using personalized mock data');
        _useBackend = false;
        _loadPersonalizedMockData();
      }

    } catch (e) {
      _setError('Failed to load recommendations: ${e.toString()}');
      print('Error loading recommendations: $e');
      _loadPersonalizedMockData(); // Load personalized mock data as fallback
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadBackendRecommendations() async {
    // _loadPersonalizedMockData();
    try {
      // Load all recommendation types in parallel
      await Future.wait([
        _loadTrendingRecommendations(),
        _loadPersonalizedRecommendations(),
        _loadNearbyRecommendations(),
      ]);
    } catch (e) {
      print('Backend loading failed, falling back to mock data');
      _useBackend = false;
      _loadPersonalizedMockData();
    }
  }

  // IMPROVED: Load personalized mock data based on user preferences
  void _loadPersonalizedMockData() {
    print('Loading personalized mock data...');
    
    final preferences = _userService.userPreferences;
    
    // PERSONALIZE based on user preferences
    _personalizedRecommendations = _filterAndPersonalize(allMockData, preferences);
    _trendingRecommendations = _getTrendingRecommendations(allMockData);
    _nearbyRecommendations = _getNearbyRecommendations(allMockData, preferences);
    
    print('Loaded personalized recommendations: ${_personalizedRecommendations.length}');
    notifyListeners();
  }

  List<RecommendationItem> _filterAndPersonalize(List<RecommendationItem> allData, UserPreferences? preferences) {
    if (preferences == null) return allData.take(3).toList();
    
    List<RecommendationItem> filtered = [];
    
    // Filter by budget
    for (var item in allData) {
      bool matchesBudget = false;
      
      switch (preferences.budgetRange) {
        case 'budget':
          matchesBudget = item.priceRange == '\$' || item.priceRange == 'Free';
          break;
        case 'mid_range':
          matchesBudget = item.priceRange == '\$' || item.priceRange == '\$\$' || item.priceRange == 'Free';
          break;
        case 'premium':
          matchesBudget = true; // Premium users can afford anything
          break;
        default:
          matchesBudget = item.priceRange != '\$\$\$'; // Default to mid-range
      }
      
      if (matchesBudget) {
        // Create personalized why_recommended based on user preferences
        String personalizedWhy = _generatePersonalizedRecommendation(item, preferences);
        
        filtered.add(RecommendationItem(
          id: item.id,
          name: item.name,
          type: item.type,
          description: item.description,
          location: item.location,
          priceRange: item.priceRange,
          rating: item.rating,
          estimatedDuration: item.estimatedDuration,
          whyRecommended: personalizedWhy,
          bookingAvailable: item.bookingAvailable,
          bestTimeToVisit: item.bestTimeToVisit,
          features: item.features,
        ));
      }
    }
    
    // Sort by relevance to user interests
    filtered.sort((a, b) => _calculateRelevanceScore(b, preferences).compareTo(_calculateRelevanceScore(a, preferences)));
    
    return filtered.take(5).toList();
  }

  String _generatePersonalizedRecommendation(RecommendationItem item, UserPreferences preferences) {
    List<String> reasons = [];
    
    // Budget-based reasons
    if (preferences.budgetRange == 'budget' && (item.priceRange == '\$' || item.priceRange == 'Free')) {
      reasons.add('fits your budget perfectly');
    }
    if (preferences.budgetRange == 'premium' && item.priceRange == '\$\$\$') {
      reasons.add('premium experience as you prefer');
    }
    
    // Interest-based reasons
    if (preferences.interests.contains('culture') && item.features.contains('cultural')) {
      reasons.add('matches your cultural interests');
    }
    if (preferences.interests.contains('food') && item.type == 'restaurant') {
      reasons.add('perfect for your food interests');
    }
    if (preferences.interests.contains('shopping') && item.features.contains('shopping')) {
      reasons.add('great for shopping as you like');
    }
    if (preferences.interests.contains('nature') && item.features.contains('outdoor')) {
      reasons.add('offers the outdoor experience you enjoy');
    }
    
    // Visit purpose reasons
    switch (preferences.visitPurpose) {
      case 'business':
        if (item.features.contains('wifi') || item.features.contains('business-friendly')) {
          reasons.add('ideal for business travelers');
        }
        break;
      case 'family':
        if (item.features.contains('family-friendly')) {
          reasons.add('perfect for family visits');
        }
        break;
      case 'vacation':
        if (item.features.contains('tourist-friendly') || item.rating >= 4.5) {
          reasons.add('top-rated vacation spot');
        }
        break;
      case 'resident':
        if (item.features.contains('local') || item.features.contains('authentic')) {
          reasons.add('authentic local experience');
        }
        break;
    }
    
    // Cuisine preferences
    if (item.type == 'restaurant') {
      if (preferences.cuisinePreferences.contains('Middle Eastern') && item.features.contains('traditional')) {
        reasons.add('authentic Middle Eastern cuisine you love');
      }
      if (preferences.cuisinePreferences.contains('International') && item.features.contains('fusion')) {
        reasons.add('international flavors you enjoy');
      }
    }
    
    // Default reason if no specific matches
    if (reasons.isEmpty) {
      if (item.rating >= 4.5) {
        reasons.add('highly rated by visitors');
      } else {
        reasons.add('recommended based on your profile');
      }
    }
    
    return reasons.isNotEmpty ? reasons.first : 'recommended for you';
  }

  double _calculateRelevanceScore(RecommendationItem item, UserPreferences preferences) {
    double score = item.rating; // Base score from rating
    
    // Boost score based on interests
    for (String interest in preferences.interests) {
      if (interest == 'culture' && item.features.contains('cultural')) score += 2.0;
      if (interest == 'food' && item.type == 'restaurant') score += 2.0;
      if (interest == 'shopping' && item.features.contains('shopping')) score += 2.0;
      if (interest == 'nature' && item.features.contains('outdoor')) score += 2.0;
    }
    
    // Budget compatibility
    bool budgetMatch = false;
    switch (preferences.budgetRange) {
      case 'budget':
        budgetMatch = item.priceRange == '\$' || item.priceRange == 'Free';
        break;
      case 'mid_range':
        budgetMatch = item.priceRange != '\$\$\$';
        break;
      case 'premium':
        budgetMatch = true;
        break;
    }
    if (budgetMatch) score += 1.0;
    
    return score;
  }

  List<RecommendationItem> _getTrendingRecommendations(List<RecommendationItem> allData) {
    // Sort by rating for trending
    List<RecommendationItem> trending = List.from(allData);
    trending.sort((a, b) => b.rating.compareTo(a.rating));
    return trending.take(5).toList();
  }

  List<RecommendationItem> _getNearbyRecommendations(List<RecommendationItem> allData, UserPreferences? preferences) {
    // For mock data, just return variety based on preferences or default
    if (preferences != null) {
      return _filterAndPersonalize(allData, preferences).take(3).toList();
    }
    return allData.take(3).toList();
  }

  // Backend recommendation methods (keep existing)
  Future<void> _loadTrendingRecommendations() async {
    try {
      final preferences = _userService.userPreferences;
      final data = await _makePostRequest('/api/v1/recommendations', {
        'query': 'popular trending places in Qatar',
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': preferences != null 
            ? _mapUserPreferences(preferences) 
            : _getDefaultPreferences(),
        'limit': 5,
      });

      if (data != null && data['success'] == true) {
        final recommendations = data['data']['recommendations'] as List;
        _trendingRecommendations = recommendations
            .map((item) => RecommendationItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error loading trending recommendations: $e');
    }
  }

  Future<void> _loadPersonalizedRecommendations() async {
    try {
      if (_userService.userPreferences == null) {
        _personalizedRecommendations = _trendingRecommendations;
        return;
      }

      final preferences = _userService.userPreferences!;
      String query = _buildPersonalizedQuery(preferences);

      final data = await _makePostRequest('/api/v1/recommendations', {
        'query': query,
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': _mapUserPreferences(preferences),
        'limit': 5,
      });

      if (data != null && data['success'] == true) {
        final recommendations = data['data']['recommendations'] as List;
        _personalizedRecommendations = recommendations
            .map((item) => RecommendationItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error loading personalized recommendations: $e');
      _personalizedRecommendations = _trendingRecommendations;
    }
  }

  Future<void> _loadNearbyRecommendations() async {
    try {
      final preferences = _userService.userPreferences;
      String query = 'places near me in Qatar';
      
      if (preferences != null) {
        query += ' ${preferences.budgetRange} budget';
      }

      final data = await _makePostRequest('/api/v1/recommendations', {
        'query': query,
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': preferences != null 
            ? _mapUserPreferences(preferences) 
            : _getDefaultPreferences(),
        'limit': 5,
      });

      if (data != null && data['success'] == true) {
        final recommendations = data['data']['recommendations'] as List;
        _nearbyRecommendations = recommendations
            .map((item) => RecommendationItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error loading nearby recommendations: $e');
    }
  }

  // Keep all other existing methods unchanged...
  String _buildPersonalizedQuery(UserPreferences preferences) {
    List<String> queryParts = [];
    
    switch (preferences.visitPurpose) {
      case 'business':
        queryParts.add('business-friendly places');
        break;
      case 'vacation':
        queryParts.add('tourist attractions and experiences');
        break;
      case 'family':
        queryParts.add('family-friendly activities');
        break;
      case 'transit':
        queryParts.add('quick accessible places near airport');
        break;
      case 'resident':
        queryParts.add('local hidden gems and authentic experiences');
        break;
    }

    switch (preferences.budgetRange) {
      case 'budget':
        queryParts.add('affordable budget-friendly');
        break;
      case 'mid_range':
        queryParts.add('mid-range value');
        break;
      case 'premium':
        queryParts.add('luxury premium');
        break;
    }

    if (preferences.interests.isNotEmpty) {
      String interests = preferences.interests.join(' ');
      queryParts.add(interests);
    }

    if (preferences.cuisinePreferences.isNotEmpty) {
      String cuisines = preferences.cuisinePreferences.join(' ');
      queryParts.add('$cuisines cuisine');
    }

    return queryParts.join(' ') + ' in Qatar';
  }

  Map<String, dynamic> _mapUserPreferences(UserPreferences preferences) {
    return {
      'food_preferences': preferences.cuisinePreferences,
      'budget_range': _mapBudgetRange(preferences.budgetRange),
      'activity_types': preferences.interests,
      'language': preferences.language,
      'group_size': preferences.groupSize,
      'min_rating': preferences.minRating,
    };
  }

  String _mapBudgetRange(String budgetRange) {
    switch (budgetRange) {
      case 'budget':
        return '\$';
      case 'mid_range':
        return '\$\$';
      case 'premium':
        return '\$\$\$';
      default:
        return '\$\$';
    }
  }

  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'food_preferences': ['Middle Eastern'],
      'budget_range': '\$\$',
      'activity_types': ['culture'],
      'language': 'en',
      'group_size': 1,
      'min_rating': 4.0,
    };
  }

  Future<void> refreshRecommendations() async {
    await loadAllRecommendations();
  }

  String getPersonalizedSectionTitle() {
    final preferences = _userService.userPreferences;
    if (preferences == null) return 'Recommended for You';
    
    if (preferences.interests.contains('food')) {
      return 'Perfect Dining Spots';
    } else if (preferences.interests.contains('culture')) {
      return 'Cultural Experiences';
    } else if (preferences.visitPurpose == 'business') {
      return 'Business-Friendly Places';
    } else if (preferences.visitPurpose == 'family') {
      return 'Family Activities';
    } else {
      return 'Personalized for You';
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}

// Keep the existing RecommendationItem class unchanged
class RecommendationItem {
  final String id;
  final String name;
  final String type;
  final String description;
  final String location;
  final String priceRange;
  final double rating;
  final String estimatedDuration;
  final String whyRecommended;
  final bool bookingAvailable;
  final String bestTimeToVisit;
  final String? contact;
  final List<String> features;

  RecommendationItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.location,
    required this.priceRange,
    required this.rating,
    required this.estimatedDuration,
    required this.whyRecommended,
    required this.bookingAvailable,
    required this.bestTimeToVisit,
    this.contact,
    required this.features,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      priceRange: json['price_range'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      estimatedDuration: json['estimated_duration'] ?? '',
      whyRecommended: json['why_recommended'] ?? '',
      bookingAvailable: json['booking_available'] ?? false,
      bestTimeToVisit: json['best_time_to_visit'] ?? '',
      contact: json['contact'],
      features: List<String>.from(json['features'] ?? []),
    );
  }
}