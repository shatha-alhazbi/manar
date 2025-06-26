// lib/models/day_planner_models.dart
import 'package:flutter/foundation.dart';

// Shared coordinate model
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
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
}

// Booking step model
class BookingStep {
  final String id;
  final String stopName;
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
    required this.details,
    this.confirmationNumber,
  });
}

enum BookingStatus {
  pending,
  processing,
  confirmed,
  failed,
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
}

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
}