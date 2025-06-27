// lib/services/day_planner_service.dart - Fixed to use FANAR API with RAG
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

  // Generate AI-powered questions using FANAR API
  Future<List<PlannerQuestion>> generateDynamicQuestions(String userId) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': 'Generate 5 personalized planning questions for a Qatar tourism day planner. Include questions about: 1) Duration and timing preferences, 2) Activity interests (cultural, food, modern, shopping), 3) Budget range, 4) Special requirements, 5) Must-visit preferences. Format as interactive questions with 3-4 option choices each.',
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
    // Try to extract structured questions from FANAR API response
    try {
      String aiMessage = aiData['message'] ?? '';
      
      // Look for structured data or parse natural language response
      if (aiMessage.contains('1)') && aiMessage.contains('2)')) {
        return _extractQuestionsFromStructuredText(aiMessage);
      } else {
        // Use default questions as fallback
        return _getDefaultQuestions();
      }
    } catch (e) {
      print('Error parsing AI questions: $e');
      return _getDefaultQuestions();
    }
  }

  List<PlannerQuestion> _extractQuestionsFromStructuredText(String aiText) {
    // Parse structured response from FANAR
    List<PlannerQuestion> questions = [];
    
    // Split by numbered questions and extract
    List<String> sections = aiText.split(RegExp(r'\d\)'));
    
    for (int i = 1; i < sections.length && questions.length < 5; i++) {
      String section = sections[i].trim();
      if (section.isNotEmpty) {
        questions.add(_createQuestionFromText(section, i));
      }
    }
    
    return questions.isNotEmpty ? questions : _getDefaultQuestions();
  }

  PlannerQuestion _createQuestionFromText(String text, int index) {
    // Extract question and create options
    String question = text.split('\n')[0].trim();
    if (question.isEmpty) {
      question = _getDefaultQuestions()[index - 1].question;
    }
    
    return PlannerQuestion(
      id: 'ai_question_$index',
      question: question,
      options: _getOptionsForQuestionType(index),
      followUp: _getFollowUpForQuestionType(index),
      responseKey: _getResponseKeyForQuestionType(index),
    );
  }

  List<String> _getOptionsForQuestionType(int questionType) {
    switch (questionType) {
      case 1: // Duration
        return ['Half day (4 hours)', 'Full day (8 hours)', 'Extended day (12 hours)'];
      case 2: // Interests
        return ['Cultural & Historic', 'Food & Dining', 'Modern & Shopping', 'Mix of everything'];
      case 3: // Budget
        return ['Budget-friendly (QAR 50-100)', 'Moderate (QAR 100-200)', 'Premium (QAR 200+)'];
      case 4: // Special requirements
        return ['No special requirements', 'Accessibility needs', 'Dietary restrictions', 'Family-friendly only'];
      case 5: // Must-visit
        return ['Surprise me with the best!', 'Include traditional souqs', 'Modern attractions only', 'Cultural sites priority'];
      default:
        return ['Option 1', 'Option 2', 'Option 3'];
    }
  }

  String _getFollowUpForQuestionType(int questionType) {
    switch (questionType) {
      case 1: return 'Perfect! What type of experiences interest you most?';
      case 2: return 'Excellent choice! What\'s your budget range?';
      case 3: return 'Great! Any special requirements or preferences?';
      case 4: return 'Noted! Any specific places you want to visit?';
      case 5: return 'Perfect! I have everything needed for your amazing plan.';
      default: return 'Thank you for your response!';
    }
  }

  String _getResponseKeyForQuestionType(int questionType) {
    switch (questionType) {
      case 1: return 'duration';
      case 2: return 'interests';
      case 3: return 'budget';
      case 4: return 'special_requirements';
      case 5: return 'must_visit';
      default: return 'custom_$questionType';
    }
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
        options: ['Budget-friendly (QAR 50-100)', 'Moderate (QAR 100-200)', 'Premium (QAR 200+)'],
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

  // Generate AI-powered day plan using FANAR API with RAG
  Future<List<PlanStop>?> generateDayPlan({
    required String userId,
    required Map<String, dynamic> planningData,
  }) async {
    _setLoading(true);
    _planningData = planningData;
    
    try {
      // Use the /plan endpoint which uses your RAG system
      final response = await http.post(
        Uri.parse('$baseUrl/plan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': _buildDetailedPlanningQuery(planningData),
          'user_id': userId,
          'preferences': {
            'food_preferences': _extractFoodPreferences(planningData),
            'budget_range': _extractBudgetRange(planningData),
            'activity_types': _extractActivityTypes(planningData),
            'language': 'en',
            'group_size': 1,
            'min_rating': 4.0,
          },
          'date': DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _currentPlan = _parseRAGPlan(data['data']);
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
      // Return fallback plan
      _currentPlan = _createFallbackPlan(planningData);
      notifyListeners();
      return _currentPlan;
    } finally {
      _setLoading(false);
    }
    
    return null;
  }

  // Parse plan from RAG + FANAR API response
  List<PlanStop> _parseRAGPlan(Map<String, dynamic> ragResponse) {
    List<PlanStop> stops = [];
    
    try {
      // The RAG system returns day_plan with activities
      Map<String, dynamic>? dayPlan = ragResponse['day_plan'];
      
      if (dayPlan != null && dayPlan['activities'] != null) {
        List<dynamic> activities = dayPlan['activities'];
        
        for (int i = 0; i < activities.length; i++) {
          var activity = activities[i];
          
          PlanStop stop = PlanStop(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: _extractVenueName(activity['activity']),
            location: activity['location'] ?? 'Qatar',
            type: _determineActivityType(activity['activity']),
            startTime: _parseTime(activity['time']),
            duration: _parseDuration(activity['duration']),
            description: activity['description'] ?? _generateDescription(activity['activity']),
            estimatedCost: _parseCost(activity['estimated_cost']),
            travelToNext: i < activities.length - 1 
                ? activity['transportation'] ?? '15 min travel'
                : 'Trip complete',
            coordinates: _getCoordinatesForLocation(activity['location']),
            tips: activity['tips'] ?? _generateTips(activity['activity']),
            rating: _parseRating(activity),
            bookingRequired: _determineBookingRequired(activity),
          );
          
          stops.add(stop);
        }
      }
      
      // If no activities found, try alternative parsing
      if (stops.isEmpty && ragResponse['message'] != null) {
        stops = _parseMessageForPlan(ragResponse['message']);
      }
      
    } catch (e) {
      print('Error parsing RAG plan: $e');
      stops = _createFallbackPlan(_planningData);
    }
    
    return stops.isNotEmpty ? stops : _createFallbackPlan(_planningData);
  }

  List<PlanStop> _parseMessageForPlan(String message) {
    // Extract plan information from AI text message
    List<PlanStop> stops = [];
    
    try {
      // Look for time patterns and activities
      RegExp timePattern = RegExp(r'(\d{1,2}:\d{2}|\d{1,2}\s*(AM|PM))', caseSensitive: false);
      List<String> lines = message.split('\n');
      
      int stopCounter = 0;
      for (String line in lines) {
        if (timePattern.hasMatch(line) && line.trim().isNotEmpty) {
          Match? timeMatch = timePattern.firstMatch(line);
          if (timeMatch != null) {
            String time = _parseTime(timeMatch.group(0) ?? '09:00');
            String activity = line.replaceAll(timePattern, '').trim();
            
            if (activity.isNotEmpty) {
              stops.add(PlanStop(
                id: '${DateTime.now().millisecondsSinceEpoch}_$stopCounter',
                name: _extractVenueName(activity),
                location: _extractLocationFromActivity(activity),
                type: _determineActivityType(activity),
                startTime: time,
                duration: '1.5 hours',
                description: activity,
                estimatedCost: '\$35',
                travelToNext: stopCounter < 3 ? '15 min travel' : 'Trip complete',
                coordinates: _getCoordinatesForLocation(_extractLocationFromActivity(activity)),
                tips: _generateTips(activity),
                rating: 4.5,
                bookingRequired: _determineBookingRequired({'activity': activity}),
              ));
              stopCounter++;
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing message for plan: $e');
    }
    
    return stops;
  }

  String _extractVenueName(String activity) {
    // Clean up activity text to extract venue name
    String cleaned = activity.trim();
    
    // Remove common prefixes
    List<String> prefixes = [
      'Visit ', 'Explore ', 'Enjoy ', 'Experience ', 'Tour ', 'See ',
      'Breakfast at ', 'Lunch at ', 'Dinner at ', 'Coffee at ',
      'Stop at ', 'Go to ', 'Head to '
    ];
    
    for (String prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }
    
    // Extract venue name before location indicators
    if (cleaned.contains(' in ')) {
      cleaned = cleaned.split(' in ')[0].trim();
    }
    if (cleaned.contains(' at ')) {
      cleaned = cleaned.split(' at ')[0].trim();
    }
    if (cleaned.contains(' (')) {
      cleaned = cleaned.split(' (')[0].trim();
    }
    
    return cleaned.isNotEmpty ? cleaned : 'Qatar Experience';
  }

  String _extractLocationFromActivity(String activity) {
    // Extract location from activity description
    List<String> qatarLocations = [
      'Souq Waqif', 'West Bay', 'The Pearl', 'Katara', 'Corniche',
      'Museum District', 'Doha', 'Education City', 'Aspire Zone'
    ];
    
    String activityLower = activity.toLowerCase();
    for (String location in qatarLocations) {
      if (activityLower.contains(location.toLowerCase())) {
        return location;
      }
    }
    
    return 'Doha, Qatar';
  }

  String _buildDetailedPlanningQuery(Map<String, dynamic> data) {
    List<String> queryParts = [];
    
    // Build comprehensive query for RAG system
    queryParts.add('Create a detailed Qatar day plan');
    
    if (data['duration'] != null) {
      queryParts.add('for ${data['duration'].toLowerCase()}');
    }
    
    if (data['start_time'] != null) {
      queryParts.add('starting ${data['start_time'].toLowerCase()}');
    }
    
    if (data['interests'] != null) {
      queryParts.add('focusing on ${data['interests'].toLowerCase()} experiences');
    }
    
    if (data['budget'] != null) {
      queryParts.add('with ${data['budget'].toLowerCase()} budget');
    }
    
    if (data['special_preferences'] != null) {
      queryParts.add('including ${data['special_preferences']}');
    }
    
    // Add specific requirements for good planning
    queryParts.add('Include restaurants, attractions, and cultural sites');
    queryParts.add('Optimize travel time and create a logical route');
    queryParts.add('Provide specific venue names and locations in Qatar');
    
    return queryParts.join(', ');
  }

  List<PlanStop> _createFallbackPlan(Map<String, dynamic> planningData) {
    // Create a basic plan based on user preferences when AI fails
    List<PlanStop> fallbackStops = [];
    
    String budget = _extractBudgetRange(planningData);
    List<String> interests = _extractActivityTypes(planningData);
    String startTime = _extractStartTime(planningData);
    
    // Morning activity
    if (interests.contains('Cultural') || interests.contains('Cultural & Historic')) {
      fallbackStops.add(_createCulturalStop(startTime, budget));
    } else if (interests.contains('Food')) {
      fallbackStops.add(_createFoodStop(startTime, budget));
    } else {
      fallbackStops.add(_createGeneralStop(startTime, budget));
    }
    
    // Afternoon activity
    String afternoonTime = _addHoursToTime(startTime, 3);
    if (interests.contains('Shopping') || interests.contains('Modern')) {
      fallbackStops.add(_createShoppingStop(afternoonTime, budget));
    } else {
      fallbackStops.add(_createAttractionStop(afternoonTime, budget));
    }
    
    // Evening activity
    String eveningTime = _addHoursToTime(afternoonTime, 2);
    fallbackStops.add(_createDinnerStop(eveningTime, budget));
    
    return fallbackStops;
  }

  PlanStop _createCulturalStop(String time, String budget) {
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_cultural',
      name: 'Museum of Islamic Art',
      location: 'Corniche, Doha',
      type: 'attraction',
      startTime: time,
      duration: '2 hours',
      description: 'Explore 1,400 years of Islamic art and culture in this architectural masterpiece',
      estimatedCost: 'Free',
      travelToNext: '10 min travel',
      coordinates: LatLng(25.2948, 51.5397),
      tips: 'Visit during morning hours for fewer crowds and better photo opportunities',
      rating: 4.8,
      bookingRequired: false,
    );
  }

  PlanStop _createFoodStop(String time, String budget) {
    String restaurant = budget == '\$' ? 'Al Mourjan Restaurant' : 'Nobu Doha';
    String cost = budget == '\$' ? '\$25' : '\$80';
    
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_food',
      name: restaurant,
      location: budget == '\$' ? 'Corniche' : 'West Bay',
      type: 'restaurant',
      startTime: time,
      duration: '1.5 hours',
      description: 'Experience authentic flavors at this highly-rated restaurant',
      estimatedCost: cost,
      travelToNext: '15 min travel',
      coordinates: budget == '\$' ? LatLng(25.2854, 51.5310) : LatLng(25.3656, 51.5310),
      tips: 'Try the signature dishes and local specialties',
      rating: 4.6,
      bookingRequired: true,
    );
  }

  PlanStop _createGeneralStop(String time, String budget) {
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_general',
      name: 'Souq Waqif',
      location: 'Old Doha',
      type: 'attraction',
      startTime: time,
      duration: '2 hours',
      description: 'Traditional marketplace with authentic Qatari architecture and cultural experiences',
      estimatedCost: '\$20',
      travelToNext: '20 min travel',
      coordinates: LatLng(25.2867, 51.5333),
      tips: 'Perfect for shopping and experiencing local culture. Evening visits offer great atmosphere',
      rating: 4.7,
      bookingRequired: false,
    );
  }

  PlanStop _createShoppingStop(String time, String budget) {
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_shopping',
      name: 'The Pearl Qatar',
      location: 'The Pearl',
      type: 'shopping',
      startTime: time,
      duration: '2 hours',
      description: 'Luxury shopping and dining destination with marina views',
      estimatedCost: '\$50',
      travelToNext: '25 min travel',
      coordinates: LatLng(25.3780, 51.5540),
      tips: 'Great for luxury shopping and waterfront dining experiences',
      rating: 4.5,
      bookingRequired: false,
    );
  }

  PlanStop _createAttractionStop(String time, String budget) {
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_attraction',
      name: 'Katara Cultural Village',
      location: 'Katara',
      type: 'attraction',
      startTime: time,
      duration: '2.5 hours',
      description: 'Cultural district featuring galleries, theaters, restaurants, and beaches',
      estimatedCost: 'Free',
      travelToNext: '20 min travel',
      coordinates: LatLng(25.3792, 51.5310),
      tips: 'Visit the Blue Mosque and enjoy the beach area. Late afternoon is ideal',
      rating: 4.6,
      bookingRequired: false,
    );
  }

  PlanStop _createDinnerStop(String time, String budget) {
    String restaurant = budget == '\$' ? 'Souq Waqif Traditional Restaurant' : 'IDAM by Alain Ducasse';
    String cost = budget == '\$' ? '\$30' : '\$120';
    
    return PlanStop(
      id: '${DateTime.now().millisecondsSinceEpoch}_dinner',
      name: restaurant,
      location: budget == '\$' ? 'Souq Waqif' : 'Museum of Islamic Art',
      type: 'restaurant',
      startTime: time,
      duration: '2 hours',
      description: 'End your day with a memorable dining experience',
      estimatedCost: cost,
      travelToNext: 'Trip complete',
      coordinates: budget == '\$' ? LatLng(25.2867, 51.5333) : LatLng(25.2948, 51.5397),
      tips: 'Perfect location for dinner with great ambiance',
      rating: 4.7,
      bookingRequired: true,
    );
  }

  String _extractStartTime(Map<String, dynamic> data) {
    String startTimeData = data['start_time']?.toString() ?? '';
    if (startTimeData.contains('Early morning')) return '08:00';
    if (startTimeData.contains('Morning')) return '10:00';
    if (startTimeData.contains('Afternoon')) return '13:00';
    return '09:00';
  }

  String _addHoursToTime(String time, int hours) {
    try {
      List<String> parts = time.split(':');
      int hour = int.parse(parts[0]) + hours;
      int minute = int.parse(parts[1]);
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '15:00';
    }
  }

  // Utility methods (keeping existing implementations)
  String _parseTime(dynamic timeValue) {
    if (timeValue == null) return '09:00';
    
    String timeStr = timeValue.toString();
    
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeStr)) {
      return timeStr;
    }
    
    if (timeStr.contains('AM') || timeStr.contains('PM')) {
      return _convertTo24Hour(timeStr);
    }
    
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
    
    return '09:00';
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
    
    if (duration.contains('hour') || duration.contains('min')) {
      return duration;
    }
    
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
    
    if (cost.contains('\$') || cost.toLowerCase() == 'free') {
      return cost;
    }
    
    RegExp numberRegex = RegExp(r'(\d+)');
    Match? match = numberRegex.firstMatch(cost);
    
    if (match != null) {
      return '\$${match.group(1)}';
    }
    
    return '\$30';
  }

  double _parseRating(Map<String, dynamic> activity) {
    if (activity['rating'] != null) {
      return (activity['rating'] as num).toDouble();
    }
    
    String activityStr = activity['activity']?.toString().toLowerCase() ?? '';
    
    if (activityStr.contains('museum') || activityStr.contains('cultural')) {
      return 4.7 + (DateTime.now().millisecond % 30) / 100;
    } else if (activityStr.contains('restaurant') || activityStr.contains('food')) {
      return 4.3 + (DateTime.now().millisecond % 40) / 100;
    } else {
      return 4.0 + (DateTime.now().millisecond % 50) / 100;
    }
  }

  String _generateDescription(String activity) {
    return 'Experience the best of $activity in Qatar. A perfect addition to your adventure.';
  }

  LatLng _getCoordinatesForLocation(String? location) {
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
    
    return LatLng(25.2854, 51.5310);
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

  String _generateTips(String activity) {
    Map<String, String> tips = {
      'museum': 'Visit during morning hours for fewer crowds and better photo opportunities.',
      'restaurant': 'Try the local specialties and don\'t miss the traditional dishes.',
      'souq': 'Perfect for shopping and experiencing local culture. Bargaining is expected.',
      'corniche': 'Best visited during sunset for spectacular views and photo opportunities.',
      'pearl': 'Ideal for luxury shopping and waterfront dining experiences.',
      'katara': 'Explore the cultural village and enjoy the beach area.',
      'cultural': 'Learn about Qatar\'s rich heritage and traditions.',
      'mall': 'Great for shopping, dining, and escaping the heat.',
    };
    
    String lowerActivity = activity.toLowerCase();
    for (String key in tips.keys) {
      if (lowerActivity.contains(key)) {
        return tips[key]!;
      }
    }
    
    return 'Enjoy this amazing experience during your Qatar adventure!';
  }

  List<String> _extractFoodPreferences(Map<String, dynamic> data) {
    List<String> prefs = [];
    String interests = data['interests']?.toString() ?? '';
    
    if (interests.toLowerCase().contains('food')) {
      prefs.addAll(['Middle Eastern', 'Traditional', 'International']);
    } else {
      prefs.addAll(['Middle Eastern', 'Traditional']);
    }
    return prefs;
  }

  String _extractBudgetRange(Map<String, dynamic> data) {
    String budget = data['budget']?.toString() ?? '';
    if (budget.contains('Budget-friendly')) return '\$';
    if (budget.contains('Moderate')) return '\$\$';
    if (budget.contains('Premium')) return '\$\$\$';
    return '\$';
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

  // AI-powered booking agent using your RAG + FANAR system
  Future<List<BookingStep>> processBookingsWithAI({
    required List<PlanStop> dayPlan,
    required String userId,
  }) async {
    _setLoading(true);
    List<BookingStep> bookingSteps = [];
    
    try {
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
        
        // Process booking with your RAG + FANAR system
        await _processIndividualBookingWithRAG(bookingStep, userId);
      }
      
    } catch (e) {
      _setError('Booking error: $e');
      print('Booking processing error: $e');
    } finally {
      _setLoading(false);
    }
    
    return bookingSteps;
  }

  Future<void> _processIndividualBookingWithRAG(BookingStep booking, String userId) async {
    try {
      // Use your backend's booking endpoint which uses RAG + FANAR
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
          
          // Parse booking details from your RAG-enhanced response
          Map<String, dynamic> bookingDetails = data['data']['booking'];
          booking.details = {
            'confirmation_number': bookingDetails['confirmation_number'],
            'estimated_cost': bookingDetails['estimated_cost'],
            'contact_info': bookingDetails['contact_info'],
            'location': bookingDetails['location'],
            'cancellation_policy': bookingDetails['cancellation_policy'] ?? 'Standard cancellation policy',
            'special_instructions': bookingDetails['notes'] ?? bookingDetails['rag_insights'],
            'party_size': bookingDetails['party_size'],
            'booking_time': DateTime.now().toIso8601String(),
            'rag_insights': bookingDetails['rag_insights'], // AI insights from your RAG system
          };
          
        } else {
          booking.status = BookingStatus.failed;
          booking.details['error_message'] = data['message'];
          print('Booking failed: ${data['message']}');
        }
      } else {
        booking.status = BookingStatus.failed;
        booking.details['error_message'] = 'Server error: ${response.statusCode}';
        print('Booking API error: ${response.statusCode}');
      }
    } catch (e) {
      booking.status = BookingStatus.failed;
      booking.details['error_message'] = 'Network error: $e';
      print('Booking failed: $e');
    }
    
    notifyListeners();
  }

  // AI Chat for planning assistance using your FANAR + RAG system
  Future<String> chatWithPlanningAI({
    required String message,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      // Use your chat endpoint which has RAG integration
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
            'timestamp': msg.timestamp.toIso8601String(),
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return _parseRAGChatResponse(data['data']);
        } else {
          return 'I understand your request. Let me help you with that!';
        }
      }
    } catch (e) {
      print('Chat error: $e');
    }
    
    return 'I\'m having trouble connecting right now. Please try again.';
  }

  String _parseRAGChatResponse(Map<String, dynamic> ragData) {
    // Parse different types of responses from your RAG system
    if (ragData['message'] != null) {
      return ragData['message'];
    } else if (ragData['recommendations'] != null) {
      return 'I found some great recommendations for you! Let me show you the options.';
    } else if (ragData['day_plan'] != null) {
      return 'I can help you plan that! Let me work on creating the perfect itinerary.';
    }
    
    return 'I\'m here to help with your Qatar adventure planning!';
  }

  // Get real-time recommendations from your RAG system
  Future<List<RecommendationItem>> getAIRecommendations({
    required String query,
    required String userId,
  }) async {
    try {
      // Use your recommendations endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'user_id': userId,
          'preferences': {
            'food_preferences': ['Middle Eastern', 'Traditional'],
            'budget_range': '\$',
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
          return _parseRAGRecommendations(data['data']);
        }
      }
    } catch (e) {
      print('Recommendations error: $e');
    }
    
    return [];
  }

  List<RecommendationItem> _parseRAGRecommendations(Map<String, dynamic> ragData) {
    List<RecommendationItem> items = [];
    
    try {
      if (ragData['recommendations'] != null) {
        for (var item in ragData['recommendations']) {
          items.add(RecommendationItem(
            name: item['name'] ?? 'Qatar Experience',
            type: item['type'] ?? 'attraction',
            description: item['description'] ?? 'Amazing Qatar experience',
            location: item['location'] ?? 'Qatar',
            priceRange: item['price_range'] ?? '\$30',
            rating: (item['rating'] ?? 4.5).toDouble(),
            estimatedDuration: item['estimated_duration'] ?? '2 hours',
            whyRecommended: item['why_recommended'] ?? 'Perfect for your preferences',
            bookingAvailable: item['booking_available'] ?? false,
            bestTimeToVisit: item['best_time_to_visit'] ?? 'Anytime',
            features: List<String>.from(item['features'] ?? []),
          ));
        }
      }
    } catch (e) {
      print('Error parsing RAG recommendations: $e');
    }
    
    return items;
  }

  // Plan management methods
  void updatePlanStop(String stopId, PlanStop updatedStop) {
    int index = _currentPlan.indexWhere((stop) => stop.id == stopId);
    if (index != -1) {
      _currentPlan[index] = updatedStop;
      notifyListeners();
    }
  }

  void removePlanStop(String stopId) {
    _currentPlan.removeWhere((stop) => stop.id == stopId);
    notifyListeners();
  }

  void addPlanStop(PlanStop newStop) {
    _currentPlan.add(newStop);
    notifyListeners();
  }

  // Save/Load plans (optional - can integrate with local storage or backend)
  Future<void> savePlan(String planName) async {
    try {
      // Save plan to backend or local storage
      Map<String, dynamic> planData = {
        'name': planName,
        'created_at': DateTime.now().toIso8601String(),
        'planning_data': _planningData,
        'stops': _currentPlan.map((stop) => {
          'id': stop.id,
          'name': stop.name,
          'location': stop.location,
          'type': stop.type,
          'startTime': stop.startTime,
          'duration': stop.duration,
          'description': stop.description,
          'estimatedCost': stop.estimatedCost,
          'travelToNext': stop.travelToNext,
          'coordinates': {
            'latitude': stop.coordinates.latitude,
            'longitude': stop.coordinates.longitude,
          },
          'tips': stop.tips,
          'rating': stop.rating,
          'bookingRequired': stop.bookingRequired,
        }).toList(),
      };
      
      // Save logic here - could be local storage, Firebase, or your backend
      print('Plan saved: $planName');
      
    } catch (e) {
      _setError('Failed to save plan: $e');
    }
  }

  // Clear current state
  void clearCurrentPlan() {
    _currentPlan.clear();
    _currentBookings.clear();
    _planningData.clear();
    _error = '';
    notifyListeners();
  }

  // Get plan statistics
  Map<String, dynamic> getPlanStatistics() {
    if (_currentPlan.isEmpty) return {};
    
    int totalCost = 0;
    int totalDuration = 0;
    Map<String, int> activityTypes = {};
    int bookableStops = 0;
    
    for (PlanStop stop in _currentPlan) {
      // Calculate cost
      String costStr = stop.estimatedCost.replaceAll(RegExp(r'[^\d]'), '');
      int cost = int.tryParse(costStr) ?? 0;
      totalCost += cost;
      
      // Calculate duration (simplified)
      if (stop.duration.contains('hour')) {
        int hours = int.tryParse(stop.duration.split(' ')[0]) ?? 1;
        totalDuration += hours * 60;
      } else if (stop.duration.contains('min')) {
        int minutes = int.tryParse(stop.duration.split(' ')[0]) ?? 60;
        totalDuration += minutes;
      }
      
      // Count activity types
      activityTypes[stop.type] = (activityTypes[stop.type] ?? 0) + 1;
      
      // Count bookable stops
      if (stop.bookingRequired) bookableStops++;
    }
    
    return {
      'total_cost': totalCost,
      'total_duration_minutes': totalDuration,
      'total_stops': _currentPlan.length,
      'activity_breakdown': activityTypes,
      'bookable_stops': bookableStops,
      'average_rating': _currentPlan.fold(0.0, (sum, stop) => sum + stop.rating) / _currentPlan.length,
    };
  }
}
