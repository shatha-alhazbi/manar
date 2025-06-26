// lib/services/day_planner_service.dart - Fixed Flutter syntax errors
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/day_planner_model.dart';
import 'auth_services.dart';
import 'user_services.dart';

class AIDayPlannerService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api/v1'; 
  
  bool _isLoading = false;
  String _error = '';
  List<PlanStop> _currentPlan = [];
  List<BookingStep> _currentBookings = [];
  Map<String, dynamic> _planningData = {};
  
  bool get isLoading => _isLoading;
  String get error => _error;
  List<PlanStop> get currentPlan => _currentPlan;
  List<BookingStep> get currentBookings => _currentBookings;
  Map<String, dynamic> get planningData => _planningData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Generate AI-powered questions based on user profile
  Future<List<PlannerQuestion>> generateDynamicQuestions(String userId) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': 'Generate personalized planning questions for a Qatar tourism day planner. Create 5 interactive questions about duration, timing, interests, budget, and preferences.',
          'user_id': userId,
          'context': 'planning_questions',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return _parseAIQuestions(data['data']);
        }
      }
      
      return _getDefaultQuestions();
    } catch (e) {
      _setError('Failed to generate questions: $e');
      return _getDefaultQuestions();
    } finally {
      _setLoading(false);
    }
  }

  List<PlannerQuestion> _parseAIQuestions(Map<String, dynamic> aiData) {
    List<PlannerQuestion> questions = [];
    
    // Parse AI response - adapt based on actual FANAR output format
    if (aiData['message'] != null) {
      // If AI returns structured data, parse it
      if (aiData['questions'] != null) {
        for (var q in aiData['questions']) {
          questions.add(PlannerQuestion(
            id: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            question: q['question'] ?? '',
            options: List<String>.from(q['options'] ?? []),
            followUp: q['followUp'] ?? 'Thank you for your response!',
            responseKey: q['responseKey'] ?? 'custom_${questions.length}',
          ));
        }
      } else {
        // If AI returns text, extract questions manually
        String aiText = aiData['message'];
        questions = _extractQuestionsFromText(aiText);
      }
    }
    
    return questions.isNotEmpty ? questions : _getDefaultQuestions();
  }

  List<PlannerQuestion> _extractQuestionsFromText(String aiText) {
    // Extract questions from AI text response
    List<PlannerQuestion> questions = [];
    
    // This would parse natural language from FANAR
    // For now, return default but this can be enhanced with NLP
    return _getDefaultQuestions();
  }

  List<PlannerQuestion> _getDefaultQuestions() {
    return [
      PlannerQuestion(
        id: 'time_available',
        question: 'How much time do you have for your Qatar adventure today?',
        options: ['Half day (4 hours)', 'Full day (8 hours)', 'Extended day (12 hours)'],
        followUp: 'Perfect! What time would you like to start?',
        responseKey: 'duration',
      ),
      PlannerQuestion(
        id: 'start_time',
        question: 'What time would you like to start your day?',
        options: ['Early morning (7-9 AM)', 'Morning (9-11 AM)', 'Afternoon (12-2 PM)'],
        followUp: 'Got it! What type of experiences are you most interested in?',
        responseKey: 'start_time',
      ),
      PlannerQuestion(
        id: 'interests',
        question: 'What type of experiences excite you most?',
        options: ['Cultural & Historic', 'Food & Dining', 'Modern & Shopping', 'Mix of everything'],
        followUp: 'Excellent choice! What\'s your budget range for today?',
        responseKey: 'interests',
      ),
      PlannerQuestion(
        id: 'budget',
        question: 'What\'s your budget range for today\'s adventure?',
        options: ['Budget-friendly (\$50-100)', 'Moderate (\$100-200)', 'Premium (\$200+)'],
        followUp: 'Great! Any specific places you definitely want to visit?',
        responseKey: 'budget',
      ),
      PlannerQuestion(
        id: 'preferences',
        question: 'Any specific preferences or must-visit places?',
        options: ['Surprise me with the best!', 'Include traditional souqs', 'Modern attractions only'],
        followUp: 'Perfect! I have everything I need to create your amazing day plan.',
        responseKey: 'special_preferences',
      ),
    ];
  }

  // Generate AI-powered day plan
  Future<List<PlanStop>?> generateDayPlan({
    required String userId,
    required Map<String, dynamic> planningData,
  }) async {
    _setLoading(true);
    _planningData = planningData;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': _buildPlanningQuery(planningData),
          'user_id': userId,
          'preferences': {
            'food_preferences': _extractFoodPreferences(planningData),
            'budget_range': _extractBudgetRange(planningData),
            'activity_types': _extractActivityTypes(planningData),
            'language': 'en',
            'group_size': 1,
            'min_rating': 4.0,
          },
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _currentPlan = _parseRealAIPlan(data['data']);
          notifyListeners();
          return _currentPlan;
        } else {
          _setError(data['message'] ?? 'Failed to generate plan');
        }
      } else {
        _setError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Network error: $e');
      print('Day plan generation error: $e');
    } finally {
      _setLoading(false);
    }
    
    return null;
  }

  // Parse real AI plan from FANAR output
  List<PlanStop> _parseRealAIPlan(Map<String, dynamic> aiResponse) {
    List<PlanStop> stops = [];
    
    try {
      // Handle different AI response formats
      Map<String, dynamic>? dayPlan;
      
      if (aiResponse['day_plan'] != null) {
        dayPlan = aiResponse['day_plan'];
      } else if (aiResponse['message'] != null) {
        // Try to extract JSON from message
        dayPlan = _extractPlanFromMessage(aiResponse['message']);
      }
      
      if (dayPlan != null && dayPlan['activities'] != null) {
        List<dynamic> activities = dayPlan['activities'];
        
        for (int i = 0; i < activities.length; i++) {
          var activity = activities[i];
          
          // Extract location coordinates if available
          LatLng coordinates = _extractCoordinates(activity);
          
          // Parse time properly
          String startTime = _parseTime(activity['time']);
          
          // Extract duration
          String duration = _parseDuration(activity['duration']);
          
          // Extract cost
          String estimatedCost = _parseCost(activity['estimated_cost']);
          
          // Determine if booking is required
          bool bookingRequired = _determineBookingRequired(activity);
          
          // Extract description
          String description = _parseDescription(activity);
          
          // Extract activity name
          String activityName = _parseActivityName(activity['activity']);
          
          // Determine activity type
          String activityType = _determineActivityType(activity['activity']);
          
          // Calculate travel to next
          String travelToNext = i < activities.length - 1 
              ? _calculateTravel(activity, activities[i + 1])
              : 'Trip complete';
          
          stops.add(PlanStop(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: activityName,
            location: activity['location'] ?? 'Qatar',
            type: activityType,
            startTime: startTime,
            duration: duration,
            description: description,
            estimatedCost: estimatedCost,
            travelToNext: travelToNext,
            coordinates: coordinates,
            tips: activity['tips'] ?? _generateTips(activityName),
            rating: _parseRating(activity),
            bookingRequired: bookingRequired,
          ));
        }
      }
      
    } catch (e) {
      print('Error parsing AI plan: $e');
      // Return a single default stop if parsing fails
      stops = [_createDefaultStop()];
    }
    
    return stops.isNotEmpty ? stops : [_createDefaultStop()];
  }

  Map<String, dynamic>? _extractPlanFromMessage(String message) {
    try {
      // Look for JSON in the message
      int jsonStart = message.indexOf('{');
      int jsonEnd = message.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        String jsonStr = message.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
    } catch (e) {
      print('Failed to extract JSON from message: $e');
    }
    return null;
  }

  String _parseActivityName(String activity) {
    // Remove prefixes like "Breakfast at", "Visit", etc.
    String name = activity;
    
    // Common prefixes to remove
    List<String> prefixes = [
      'breakfast at ', 'lunch at ', 'dinner at ', 'visit ', 'explore ', 
      'enjoy ', 'experience ', 'tour ', 'see ', 'discover '
    ];
    
    String lowerActivity = activity.toLowerCase();
    for (String prefix in prefixes) {
      if (lowerActivity.startsWith(prefix)) {
        name = activity.substring(prefix.length);
        break;
      }
    }
    
    return name.trim();
  }

  String _parseTime(dynamic timeValue) {
    if (timeValue == null) return '09:00';
    
    String timeStr = timeValue.toString();
    
    // If already in HH:MM format
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeStr)) {
      return timeStr;
    }
    
    // Parse from different formats
    if (timeStr.contains('AM') || timeStr.contains('PM')) {
      return _convertTo24Hour(timeStr);
    }
    
    // Extract time from text like "at 9:00" or "9:00 AM"
    RegExp timeRegex = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?', caseSensitive: false);
    Match? match = timeRegex.firstMatch(timeStr);
    
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      String? period = match.group(3)?.toUpperCase();
      
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    
    return '09:00'; // Default
  }

  String _convertTo24Hour(String time12) {
    try {
      RegExp regex = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)', caseSensitive: false);
      Match? match = regex.firstMatch(time12);
      
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
        String period = match.group(3)!.toUpperCase();
        
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error converting time: $e');
    }
    
    return '09:00';
  }

  String _parseDuration(dynamic durationValue) {
    if (durationValue == null) return '1 hour';
    
    String duration = durationValue.toString().toLowerCase();
    
    // Already in good format
    if (duration.contains('hour') || duration.contains('min')) {
      return duration;
    }
    
    // Extract numbers and convert
    RegExp numberRegex = RegExp(r'(\d+\.?\d*)');
    Match? match = numberRegex.firstMatch(duration);
    
    if (match != null) {
      double value = double.parse(match.group(1)!);
      
      if (duration.contains('h')) {
        int hours = value.floor();
        int minutes = ((value - hours) * 60).round();
        
        if (hours > 0 && minutes > 0) {
          return '${hours}h ${minutes}min';
        } else if (hours > 0) {
          return '$hours hour${hours > 1 ? 's' : ''}';
        } else {
          return '$minutes minutes';
        }
      } else {
        return '${value.toInt()} minutes';
      }
    }
    
    return '1 hour';
  }

  String _parseCost(dynamic costValue) {
    if (costValue == null) return '\$30';
    
    String cost = costValue.toString();
    
    // Already has currency symbol
    if (cost.contains('\$') || cost.toLowerCase() == 'free') {
      return cost;
    }
    
    // Extract number and add currency
    RegExp numberRegex = RegExp(r'(\d+)');
    Match? match = numberRegex.firstMatch(cost);
    
    if (match != null) {
      return '\$${match.group(1)}';
    }
    
    return '\$30'; // Default
  }

  double _parseRating(Map<String, dynamic> activity) {
    if (activity['rating'] != null) {
      return (activity['rating'] as num).toDouble();
    }
    
    // Generate realistic rating based on activity type
    String activityStr = activity['activity']?.toString().toLowerCase() ?? '';
    
    if (activityStr.contains('museum') || activityStr.contains('cultural')) {
      return 4.7 + (DateTime.now().millisecond % 30) / 100;
    } else if (activityStr.contains('restaurant') || activityStr.contains('food')) {
      return 4.3 + (DateTime.now().millisecond % 40) / 100;
    } else {
      return 4.0 + (DateTime.now().millisecond % 50) / 100;
    }
  }

  String _parseDescription(Map<String, dynamic> activity) {
    if (activity['description'] != null) {
      return activity['description'];
    }
    
    // Generate description based on activity
    String activityName = activity['activity']?.toString() ?? '';
    String location = activity['location']?.toString() ?? '';
    
    return 'Experience the best of $activityName in $location. A perfect addition to your Qatar adventure.';
  }

  LatLng _extractCoordinates(Map<String, dynamic> activity) {
    // Check if coordinates are provided
    if (activity['coordinates'] != null) {
      var coords = activity['coordinates'];
      if (coords is Map) {
        return LatLng(
          (coords['latitude'] ?? 25.2854).toDouble(),
          (coords['longitude'] ?? 51.5310).toDouble(),
        );
      }
    }
    
    // Get coordinates based on location name
    return _getCoordinatesForLocation(activity['location']);
  }

  bool _determineBookingRequired(Map<String, dynamic> activity) {
    if (activity['booking_required'] != null) {
      return activity['booking_required'] as bool;
    }
    
    String activityStr = activity['activity']?.toString().toLowerCase() ?? '';
    
    return activityStr.contains('restaurant') || 
           activityStr.contains('dinner') || 
           activityStr.contains('lunch') ||
           activityStr.contains('fine dining') ||
           activityStr.contains('reservation');
  }

  String _calculateTravel(Map<String, dynamic> current, Map<String, dynamic> next) {
    if (current['transportation'] != null) {
      return current['transportation'];
    }
    
    // Default travel calculation
    return '15 min travel';
  }

  String _generateTips(String activityName) {
    Map<String, String> tips = {
      'museum': 'Visit during morning hours for fewer crowds and better photo opportunities.',
      'restaurant': 'Try the local specialties and don\'t miss the traditional dishes.',
      'souq': 'Perfect for shopping and experiencing local culture. Bargaining is expected.',
      'corniche': 'Best visited during sunset for spectacular views and photo opportunities.',
      'pearl': 'Ideal for luxury shopping and waterfront dining experiences.',
    };
    
    String lowerName = activityName.toLowerCase();
    for (String key in tips.keys) {
      if (lowerName.contains(key)) {
        return tips[key]!;
      }
    }
    
    return 'Enjoy this amazing experience during your Qatar adventure!';
  }

  PlanStop _createDefaultStop() {
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: 'Explore Qatar',
      location: 'Doha, Qatar',
      type: 'attraction',
      startTime: '09:00',
      duration: '2 hours',
      description: 'Discover the beauty and culture of Qatar',
      estimatedCost: '\$30',
      travelToNext: 'Trip complete',
      coordinates: LatLng(25.2854, 51.5310),
      tips: 'Enjoy your Qatar adventure!',
      rating: 4.5,
      bookingRequired: false,
    );
  }

  String _buildPlanningQuery(Map<String, dynamic> data) {
    List<String> queryParts = [];
    
    if (data['duration'] != null) {
      queryParts.add('Plan a ${data['duration'].toLowerCase()} in Qatar');
    }
    
    if (data['start_time'] != null) {
      queryParts.add('starting ${data['start_time'].toLowerCase()}');
    }
    
    if (data['interests'] != null) {
      queryParts.add('focusing on ${data['interests'].toLowerCase()}');
    }
    
    if (data['budget'] != null) {
      queryParts.add('with ${data['budget'].toLowerCase()} budget');
    }
    
    if (data['special_preferences'] != null) {
      queryParts.add('considering: ${data['special_preferences']}');
    }
    
    return queryParts.join(', ');
  }

  List<String> _extractFoodPreferences(Map<String, dynamic> data) {
    List<String> prefs = [];
    if (data['interests']?.toString().toLowerCase().contains('food') == true) {
      prefs.addAll(['Middle Eastern', 'Traditional', 'International']);
    }
    return prefs;
  }

  String _extractBudgetRange(Map<String, dynamic> data) {
    String budget = data['budget']?.toString() ?? '';
    if (budget.contains('Budget-friendly')) return '\$';
    if (budget.contains('Moderate')) return '\$\$';
    if (budget.contains('Premium')) return '\$\$\$';
    return '\$\$';
  }

  List<String> _extractActivityTypes(Map<String, dynamic> data) {
    List<String> activities = [];
    String interests = data['interests']?.toString() ?? '';
    
    if (interests.contains('Cultural')) activities.add('Cultural');
    if (interests.contains('Food')) activities.add('Food');
    if (interests.contains('Modern')) activities.add('Modern');
    if (interests.contains('Shopping')) activities.add('Shopping');
    if (interests.contains('Mix')) activities.addAll(['Cultural', 'Food', 'Modern']);
    
    return activities.isNotEmpty ? activities : ['Cultural', 'Food'];
  }

  String _determineActivityType(String activity) {
    String activityLower = activity.toLowerCase();
    if (activityLower.contains('restaurant') || activityLower.contains('lunch') || 
        activityLower.contains('dinner') || activityLower.contains('breakfast')) {
      return 'restaurant';
    }
    if (activityLower.contains('museum') || activityLower.contains('cultural') || 
        activityLower.contains('historic')) {
      return 'attraction';
    }
    if (activityLower.contains('cafe') || activityLower.contains('coffee') || 
        activityLower.contains('tea')) {
      return 'cafe';
    }
    if (activityLower.contains('shop') || activityLower.contains('souq') || 
        activityLower.contains('market')) {
      return 'shopping';
    }
    return 'attraction';
  }

  LatLng _getCoordinatesForLocation(String? location) {
    // Real-world coordinates for Qatar locations
    Map<String, LatLng> locationMap = {
      'corniche': LatLng(25.2854, 51.5310),
      'souq waqif': LatLng(25.2867, 51.5329),
      'west bay': LatLng(25.3548, 51.5326),
      'the pearl': LatLng(25.3780, 51.5540),
      'katara': LatLng(25.3548, 51.5326),
      'museum of islamic art': LatLng(25.2760, 51.5390),
      'al mourjan': LatLng(25.2854, 51.5310),
      'doha': LatLng(25.2854, 51.5310),
      'education city': LatLng(25.3069, 51.4539),
      'aspire zone': LatLng(25.2572, 51.4444),
      'villaggio mall': LatLng(25.2606, 51.4414),
      'city center doha': LatLng(25.3548, 51.5326),
      'national museum': LatLng(25.2906, 51.5391),
      'al zubarah': LatLng(25.9792, 51.0186),
    };
    
    String locationKey = location?.toLowerCase() ?? '';
    for (String key in locationMap.keys) {
      if (locationKey.contains(key)) {
        return locationMap[key]!;
      }
    }
    
    // Default to Doha center
    return LatLng(25.2854, 51.5310);
  }

  // AI-powered booking agent - now processes real AI responses
  Future<List<BookingStep>> processBookingsWithAI({
    required List<PlanStop> dayPlan,
    required String userId,
  }) async {
    _setLoading(true);
    List<BookingStep> bookingSteps = [];
    
    try {
      // Filter stops that need booking
      List<PlanStop> bookableStops = dayPlan.where((stop) => stop.bookingRequired).toList();
      
      for (PlanStop stop in bookableStops) {
        BookingStep bookingStep = BookingStep(
          id: stop.id,
          stopName: stop.name,
          type: stop.type,
          location: stop.location,
          time: stop.startTime,
          status: BookingStatus.processing,
          details: {},
        );
        
        bookingSteps.add(bookingStep);
        _currentBookings = bookingSteps;
        notifyListeners();
        
        // Process booking with real AI
        await _processIndividualBookingWithAI(bookingStep, userId);
      }
      
    } catch (e) {
      _setError('Booking error: $e');
      print('Booking processing error: $e');
    } finally {
      _setLoading(false);
    }
    
    return bookingSteps;
  }

  Future<void> _processIndividualBookingWithAI(BookingStep booking, String userId) async {
    try {
      // Call real AI booking API
      final response = await http.post(
        Uri.parse('$baseUrl/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'venue_name': booking.stopName,
          'date': DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0],
          'time': booking.time,
          'party_size': 2,
          'user_id': userId,
          'special_requirements': null,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          booking.status = BookingStatus.confirmed;
          booking.confirmationNumber = data['data']['booking']['confirmation_number'];
          
          // Parse real booking details from AI
          Map<String, dynamic> bookingDetails = data['data']['booking'];
          booking.details = {
            'confirmation_number': bookingDetails['confirmation_number'],
            'estimated_cost': bookingDetails['estimated_cost'],
            'contact_info': bookingDetails['contact_info'],
            'location': bookingDetails['location'],
            'cancellation_policy': bookingDetails['cancellation_policy'],
            'special_instructions': bookingDetails['notes'],
            'party_size': bookingDetails['party_size'],
            'booking_time': DateTime.now().toIso8601String(),
          };
          
        } else {
          booking.status = BookingStatus.failed;
          print('Booking failed: ${data['message']}');
        }
      } else {
        booking.status = BookingStatus.failed;
        print('Booking API error: ${response.statusCode}');
      }
    } catch (e) {
      booking.status = BookingStatus.failed;
      print('Booking failed: $e');
    }
    
    notifyListeners();
  }

  // AI Chat for planning assistance - now uses real FANAR responses
  Future<String> chatWithPlanningAI({
    required String message,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'user_id': userId,
          'context': 'day_planning',
          'conversation_history': conversationHistory?.map((msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Parse AI response
          return _parseAIChatResponse(data['data']);
        }
      }
    } catch (e) {
      print('Chat error: $e');
    }
    
    return 'I\'m having trouble connecting right now. Please try again.';
  }

  String _parseAIChatResponse(Map<String, dynamic> aiData) {
    // Parse different types of AI responses
    if (aiData['message'] != null) {
      return aiData['message'];
    } else if (aiData['recommendations'] != null) {
      return 'I found some great recommendations for you! Let me show you the options.';
    } else if (aiData['planning'] != null) {
      return 'I can help you plan that! Let me work on creating the perfect itinerary.';
    }
    
    return 'I\'m here to help with your Qatar adventure!';
  }

  // Get real-time recommendations from AI
  Future<List<RecommendationItem>> getAIRecommendations({
    required String query,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'user_id': userId,
          'preferences': {
            'food_preferences': ['Middle Eastern', 'Traditional'],
            'budget_range': '$$',
            'activity_types': ['Cultural', 'Food'],
            'language': 'en',
            'group_size': 1,
            'min_rating': 4.0,
          },
          'limit': 5,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return _parseAIRecommendations(data['data']);
        }
      }
    } catch (e) {
      print('Recommendations error: $e');
    }
    
    return [];
  }

  List<RecommendationItem> _parseAIRecommendations(Map<String, dynamic> aiData) {
    List<RecommendationItem> items = [];
    
    try {
      // Parse recommendations from AI response
      if (aiData['recommendations'] != null) {
        for (var item in ai