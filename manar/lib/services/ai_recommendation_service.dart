// Updated AI Recommendation Service with better HTTP handling
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'user_services.dart';
import 'auth_services.dart';

class AIRecommendationService extends ChangeNotifier {
  // Use different URLs for different platforms
  static String get API_BASE_URL {
    if (kIsWeb) {
      // For Flutter web, use localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 instead of localhost
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // For iOS simulator, localhost should work
      return 'http://localhost:8000';
    } else {
      // Fallback
      return 'http://localhost:8000';
    }
  }
  
  final UserService _userService;
  final AuthService _authService;
  
  // HTTP client with timeout
  static final http.Client _httpClient = http.Client();
  static const Duration _timeout = Duration(seconds: 30);
  
  List<RecommendationItem> _trendingRecommendations = [];
  List<RecommendationItem> _personalizedRecommendations = [];
  List<RecommendationItem> _nearbyRecommendations = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
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

  // Test backend connection
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$API_BASE_URL/test'),
      ).timeout(_timeout);
      
      print('Test connection response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection test failed: $e');
      return false;
    }
  }

  // Make HTTP POST request with error handling
  Future<Map<String, dynamic>?> _makePostRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      print('Making request to: $API_BASE_URL$endpoint');
      print('Request body: ${jsonEncode(body)}');
      
      final response = await _httpClient.post(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      _setError('Network connection failed. Please check if the backend is running.');
      return null;
    } on HttpException catch (e) {
      print('HTTP error: $e');
      _setError('HTTP error occurred. Please try again.');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      _setError('Unexpected error: ${e.toString()}');
      return null;
    }
  }

  Future<void> loadAllRecommendations() async {
    try {
      _setLoading(true);
      _setError(null);

      // First test if backend is reachable
      bool isConnected = await testConnection();
      if (!isConnected) {
        _setError('Cannot connect to backend server. Please ensure the Python backend is running on port 8000.');
        _loadMockData(); // Load mock data as fallback
        return;
      }

      // Load user preferences first
      await _userService.loadUserPreferences();
      
      // Load all recommendation types in parallel
      await Future.wait([
        _loadTrendingRecommendations(),
        _loadPersonalizedRecommendations(),
        _loadNearbyRecommendations(),
      ]);

    } catch (e) {
      _setError('Failed to load recommendations: ${e.toString()}');
      print('Error loading recommendations: $e');
      _loadMockData(); // Load mock data as fallback
    } finally {
      _setLoading(false);
    }
  }

  // Load mock data as fallback when backend is unavailable
  void _loadMockData() {
    print('Loading mock data as fallback...');
    
    _trendingRecommendations = [
      RecommendationItem(
        id: 'mock_1',
        name: 'Souq Waqif',
        type: 'Traditional Market',
        description: 'Historic market with traditional architecture and authentic Qatari culture',
        location: 'Old Doha',
        priceRange: 'Free',
        rating: 4.8,
        estimatedDuration: '2-3 hours',
        whyRecommended: 'Perfect for cultural exploration',
        bookingAvailable: false,
        bestTimeToVisit: 'Evening',
        features: ['cultural', 'historic', 'shopping'],
      ),
      RecommendationItem(
        id: 'mock_2',
        name: 'Museum of Islamic Art',
        type: 'Museum',
        description: 'World-class museum featuring Islamic art spanning 1,400 years',
        location: 'Corniche',
        priceRange: 'Free',
        rating: 4.9,
        estimatedDuration: '2-3 hours',
        whyRecommended: 'Highly rated cultural experience',
        bookingAvailable: false,
        bestTimeToVisit: 'Morning',
        features: ['cultural', 'educational', 'free'],
      ),
    ];

    _personalizedRecommendations = _trendingRecommendations;
    _nearbyRecommendations = _trendingRecommendations;
    
    notifyListeners();
  }

  Future<void> _loadTrendingRecommendations() async {
    try {
      final data = await _makePostRequest('/api/v1/recommendations', {
        'query': 'popular trending places in Qatar',
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': _getDefaultPreferences(),
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

  Future<String> getChatResponse(String message) async {
    try {
      final data = await _makePostRequest('/api/v1/chat', {
        'message': message,
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'context': 'dashboard',
        'conversation_history': [],
      });

      if (data != null && data['success'] == true) {
        final responseData = data['data'];
        
        if (responseData['type'] == 'chat') {
          return responseData['message'] ?? 'I can help you explore Qatar!';
        } else if (responseData['type'] == 'recommendations') {
          return responseData['message'] ?? 'Here are some great recommendations!';
        } else {
          return responseData['message'] ?? 'How can I help you today?';
        }
      }
      
      return 'I\'m here to help you explore Qatar! What would you like to know?';
    } catch (e) {
      print('Error getting chat response: $e');
      return 'Sorry, I\'m having trouble connecting right now. Please try again.';
    }
  }

  Future<Map<String, dynamic>?> createDayPlan(String query) async {
    try {
      final preferences = _userService.userPreferences;
      
      final data = await _makePostRequest('/api/v1/plan', {
        'query': query,
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': preferences != null 
            ? _mapUserPreferences(preferences) 
            : _getDefaultPreferences(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (data != null && data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error creating day plan: $e');
      return null;
    }
  }

  Future<List<RecommendationItem>> searchRecommendations(String query) async {
    try {
      final preferences = _userService.userPreferences;
      
      final data = await _makePostRequest('/api/v1/recommendations', {
        'query': query,
        'user_id': _authService.currentUser?.uid ?? 'guest',
        'preferences': preferences != null 
            ? _mapUserPreferences(preferences) 
            : _getDefaultPreferences(),
        'limit': 10,
      });

      if (data != null && data['success'] == true) {
        final recommendations = data['data']['recommendations'] as List;
        return recommendations
            .map((item) => RecommendationItem.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching recommendations: $e');
      return [];
    }
  }

  // Helper methods remain the same...
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

  String getPersonalizedWelcomeMessage() {
    final preferences = _userService.userPreferences;
    final user = _authService.currentUser;
    
    String greeting = 'مرحباً • Welcome';
    if (user?.displayName != null) {
      greeting += ', ${user!.displayName!.split(' ').first}';
    }
    
    if (preferences != null) {
      switch (preferences.visitPurpose) {
        case 'business':
          return '$greeting\nYour business companion in Qatar';
        case 'vacation':
          return '$greeting\nDiscover Qatar\'s wonders';
        case 'family':
          return '$greeting\nFamily fun awaits in Qatar';
        case 'transit':
          return '$greeting\nMake the most of your time';
        case 'resident':
          return '$greeting\nExplore your home like never before';
        default:
          return '$greeting\nDiscover Qatar';
      }
    }
    
    return '$greeting\nDiscover Qatar';
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}

// RecommendationItem class remains the same...
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