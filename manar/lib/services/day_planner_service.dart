// services/ai_day_planner_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manara/models/day_planner_model.dart';

class AIDayPlannerService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Generate day plan using your backend API
  Future<List<PlanStop>?> generateDayPlan({
    required String userId,
    required Map<String, dynamic> planningData,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final planningQuery = _buildPlanningQuery(planningData);
      
      final response = await http.post(
        Uri.parse('$baseUrl/plan'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'query': planningQuery,
          'user_id': userId,
          'preferences': _buildUserPreferences(planningData),
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _parsePlanFromResponse(data['data']['day_plan']);
        } else {
          _error = data['message'] ?? 'Failed to generate plan';
          return null;
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Process booking requests
  Future<Map<String, dynamic>?> processBooking({
    required String userId,
    required PlanStop stop,
    Map<String, String>? additionalDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/book'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'venue_name': stop.name,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'time': stop.startTime,
          'party_size': 2, // Default, should come from user preferences
          'user_id': userId,
          'special_requirements': additionalDetails?['Dietary restrictions'] ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['booking'];
        }
      }
      return null;
    } catch (e) {
      print('Booking error: $e');
      return null;
    }
  }

  // Chat with AI for plan modifications
  Future<String?> chatWithAI({
    required String userId,
    required String message,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          'user_id': userId,
          'context': 'day_planning',
          'conversation_history': conversationHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['message'] ?? data['data']['response'];
        }
      }
      return null;
    } catch (e) {
      print('Chat error: $e');
      return null;
    }
  }

  // Get recommendations for specific criteria
  Future<List<RecommendationItem>?> getRecommendations({
    required String userId,
    required String query,
    required Map<String, dynamic> preferences,
    int limit = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'query': query,
          'user_id': userId,
          'preferences': preferences,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final recommendations = data['data']['recommendations'] as List;
          return recommendations.map((item) => RecommendationItem.fromJson(item)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Recommendations error: $e');
      return null;
    }
  }

  // Helper methods
  String _buildPlanningQuery(Map<String, dynamic> planningData) {
    final duration = planningData['duration'] ?? 'Full day (8 hours)';
    final startTime = planningData['start_time'] ?? 'Morning (9-11 AM)';
    final interests = planningData['interests'] ?? 'Mix of everything';
    final budget = planningData['budget'] ?? 'Moderate (\$100-200)';
    final preferences = planningData['special_preferences'] ?? 'Surprise me with the best!';

    return '''
Create a detailed day plan for Qatar with the following requirements:
- Duration: $duration
- Start time: $startTime  
- Interests: $interests
- Budget: $budget
- Special preferences: $preferences

Include restaurants, attractions, and cultural experiences with proper timing and transportation between locations.
''';
  }

  Map<String, dynamic> _buildUserPreferences(Map<String, dynamic> planningData) {
    return {
      'food_preferences': _extractFoodPreferences(planningData['interests']),
      'budget_range': _extractBudgetRange(planningData['budget']),
      'activity_types': _extractActivityTypes(planningData['interests']),
      'language': 'en',
      'group_size': 2, // Default, should be customizable
      'min_rating': 4.0,
    };
  }

  List<String> _extractFoodPreferences(String? interests) {
    if (interests?.toLowerCase().contains('food') == true) {
      return ['Middle Eastern', 'Traditional', 'International'];
    }
    return ['Traditional', 'Middle Eastern'];
  }

  String _extractBudgetRange(String? budget) {
    if (budget?.contains('Budget-friendly') == true) return '\$';
    if (budget?.contains('Premium') == true) return '\$\$\$';
    return '\$\$';
  }

  List<String> _extractActivityTypes(String? interests) {
    final activities = <String>[];
    
    if (interests?.toLowerCase().contains('cultural') == true) {
      activities.addAll(['Cultural', 'Historic']);
    }
    if (interests?.toLowerCase().contains('food') == true) {
      activities.add('Food');
    }
    if (interests?.toLowerCase().contains('modern') == true) {
      activities.addAll(['Modern', 'Shopping']);
    }
    if (interests?.toLowerCase().contains('mix') == true) {
      activities.addAll(['Cultural', 'Food', 'Modern', 'Shopping']);
    }
    
    return activities.isEmpty ? ['Cultural', 'Food'] : activities;
  }

  List<PlanStop> _parsePlanFromResponse(Map<String, dynamic> planData) {
    final activities = planData['activities'] as List;
    
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;
      
      return PlanStop(
        id: (index + 1).toString(),
        name: activity['activity'] ?? 'Activity ${index + 1}',
        location: activity['location'] ?? 'Qatar',
        type: _determineStopType(activity['activity'] ?? ''),
        startTime: activity['time'] ?? '09:00',
        duration: activity['duration'] ?? '1 hour',
        description: activity['description'] ?? '',
        estimatedCost: activity['estimated_cost'] ?? '\$0',
        travelToNext: index < activities.length - 1 
            ? activities[index + 1]['transportation'] ?? '15 min'
            : 'Trip complete',
        coordinates: LatLng(25.2854 + (index * 0.01), 51.5310 + (index * 0.01)), // Mock coordinates
        tips: activity['tips'] ?? '',
        rating: 4.5, // Default rating
        bookingRequired: activity['booking_required'] ?? _requiresBooking(activity['activity'] ?? ''),
      );
    }).toList();
  }

  String _determineStopType(String activity) {
    final activityLower = activity.toLowerCase();
    
    if (activityLower.contains('restaurant') || 
        activityLower.contains('breakfast') || 
        activityLower.contains('lunch') || 
        activityLower.contains('dinner')) {
      return 'restaurant';
    }
    if (activityLower.contains('museum') || 
        activityLower.contains('visit') || 
        activityLower.contains('palace') ||
        activityLower.contains('pearl')) {
      return 'attraction';
    }
    if (activityLower.contains('cafe') || 
        activityLower.contains('coffee') ||
        activityLower.contains('tea')) {
      return 'cafe';
    }
    if (activityLower.contains('souq') || 
        activityLower.contains('shopping') ||
        activityLower.contains('market')) {
      return 'shopping';
    }
    
    return 'attraction';
  }

  bool _requiresBooking(String activity) {
    final activityLower = activity.toLowerCase();
    return activityLower.contains('restaurant') || 
           activityLower.contains('breakfast') || 
           activityLower.contains('lunch') || 
           activityLower.contains('dinner') ||
           activityLower.contains('spa') ||
           activityLower.contains('tour');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// Enhanced recommendation item model
class RecommendationItem {
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
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      priceRange: json['price_range'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      estimatedDuration: json['estimated_duration'] ?? '',
      whyRecommended: json['why_recommended'] ?? '',
      bookingAvailable: json['booking_available'] ?? false,
      bestTimeToVisit: json['best_time_to_visit'] ?? '',
      contact: json['contact'],
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

// Integration service for the dashboard
class DashboardIntegrationService {
  static void navigateToAIPlannerFromDashboard(BuildContext context) {
    Navigator.pushNamed(context, '/ai-day-planner');
  }
  
  static void setupRoutes() {
    // Add these routes to your MaterialApp
    // '/ai-day-planner': (context) => AIDayPlannerScreen(),
    // '/generated-plan': (context) => GeneratedPlanScreen(planningData: {}),
    // '/booking-agent': (context) => BookingAgentScreen(dayPlan: [], planningData: {}),
  }
}