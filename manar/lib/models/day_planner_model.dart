// lib/models/day_planner_model.dart
import 'package:flutter/foundation.dart';

// Shared coordinate model
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

// Plan stop model
class PlanStop {
  final String id;
  final String name;
  final String location;
  final String type;
  final String startTime;
  final String duration;
  final String description;
  final String estimatedCost;
  final String travelToNext;
  final LatLng coordinates;
  final String tips;
  final double rating;
  final bool bookingRequired;

  PlanStop({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.startTime,
    required this.duration,
    required this.description,
    required this.estimatedCost,
    required this.travelToNext,
    required this.coordinates,
    required this.tips,
    required this.rating,
    required this.bookingRequired,
  });

  factory PlanStop.fromJson(Map<String, dynamic> json) {
    return PlanStop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      startTime: json['startTime'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
      estimatedCost: json['estimatedCost'] ?? '',
      travelToNext: json['travelToNext'] ?? '',
      coordinates: LatLng(
        json['coordinates']?['latitude'] ?? 0.0,
        json['coordinates']?['longitude'] ?? 0.0,
      ),
      tips: json['tips'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      bookingRequired: json['bookingRequired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'type': type,
      'startTime': startTime,
      'duration': duration,
      'description': description,
      'estimatedCost': estimatedCost,
      'travelToNext': travelToNext,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'tips': tips,
      'rating': rating,
      'bookingRequired': bookingRequired,
    };
  }

  // Create a copy with updated values
  PlanStop copyWith({
    String? id,
    String? name,
    String? location,
    String? type,
    String? startTime,
    String? duration,
    String? description,
    String? estimatedCost,
    String? travelToNext,
    LatLng? coordinates,
    String? tips,
    double? rating,
    bool? bookingRequired,
  }) {
    return PlanStop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      travelToNext: travelToNext ?? this.travelToNext,
      coordinates: coordinates ?? this.coordinates,
      tips: tips ?? this.tips,
      rating: rating ?? this.rating,
      bookingRequired: bookingRequired ?? this.bookingRequired,
    );
  }
}

// Booking status enum
enum BookingStatus {
  pending,
  processing,
  confirmed,
  failed,
}

// Booking step model
class BookingStep {
  final String id;
  String stopName;
  final String type;
  final String location;
  final String time;
  BookingStatus status;
  Map<String, dynamic> details;
  String? confirmationNumber;

  BookingStep({
    required this.id,
    required this.stopName,
    required this.type,
    required this.location,
    required this.time,
    required this.status,
    Map<String, dynamic>? details,
    this.confirmationNumber,
  }) : details = details ?? {};

  // Get error message from details if booking failed
  String? get errorMessage => details['error_message'];

  // Set error message in details
  set errorMessage(String? message) {
    if (message != null) {
      details['error_message'] = message;
    } else {
      details.remove('error_message');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stopName': stopName,
      'type': type,
      'location': location,
      'time': time,
      'status': status.toString(),
      'details': details,
      'confirmationNumber': confirmationNumber,
    };
  }

  factory BookingStep.fromJson(Map<String, dynamic> json) {
    return BookingStep(
      id: json['id'] ?? '',
      stopName: json['stopName'] ?? '',
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      time: json['time'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      confirmationNumber: json['confirmationNumber'],
    );
  }
}

// Chat message models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? options;
  final String? questionId;
  final bool? showGenerateButton;
  final bool? needsInput;
  final List<String>? inputFields;
  final String? stepId;
  final bool? showSummary;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.options,
    this.questionId,
    this.showGenerateButton,
    this.needsInput,
    this.inputFields,
    this.stepId,
    this.showSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'options': options,
      'questionId': questionId,
      'showGenerateButton': showGenerateButton,
      'needsInput': needsInput,
      'inputFields': inputFields,
      'stepId': stepId,
      'showSummary': showSummary,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      questionId: json['questionId'],
      showGenerateButton: json['showGenerateButton'],
      needsInput: json['needsInput'],
      inputFields: json['inputFields'] != null ? List<String>.from(json['inputFields']) : null,
      stepId: json['stepId'],
      showSummary: json['showSummary'],
    );
  }
}

// Planner question model
class PlannerQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String followUp;
  final String responseKey;

  PlannerQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.followUp,
    required this.responseKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'followUp': followUp,
      'responseKey': responseKey,
    };
  }

  factory PlannerQuestion.fromJson(Map<String, dynamic> json) {
    return PlannerQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      followUp: json['followUp'] ?? '',
      responseKey: json['responseKey'] ?? '',
    );
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'location': location,
      'price_range': priceRange,
      'rating': rating,
      'estimated_duration': estimatedDuration,
      'why_recommended': whyRecommended,
      'booking_available': bookingAvailable,
      'best_time_to_visit': bestTimeToVisit,
      'contact': contact,
      'features': features,
    };
  }

  // Convert to PlanStop for adding to day plan
  PlanStop toPlanStop({
    required String startTime,
    String? travelToNext,
    LatLng? coordinates,
  }) {
    return PlanStop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      type: type,
      startTime: startTime,
      duration: estimatedDuration,
      description: description,
      estimatedCost: priceRange,
      travelToNext: travelToNext ?? '15 min travel',
      coordinates: coordinates ?? LatLng(25.2854, 51.5310), // Default to Doha
      tips: whyRecommended,
      rating: rating,
      bookingRequired: bookingAvailable,
    );
  }
}