// lib/services/booking_service.dart - Updated with Firebase integration
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/day_planner_model.dart';

class BookingService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get upcomingBookings => _upcomingBookings;
  List<Map<String, dynamic>> get pastBookings => _pastBookings;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Initialize and load bookings
  Future<void> initialize(String userId) async {
    await loadBookings(userId);
  }

  // Load bookings from Firebase
  Future<void> loadBookings(String userId) async {
    _setLoading(true);
    try {
      await _loadFromFirebase(userId);
    } catch (e) {
      _setError('Failed to load bookings: $e');
      print('Error loading bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadFromFirebase(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .orderBy('created_at', descending: true)
          .get();
      
      List<Map<String, dynamic>> allBookings = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        bookingData['id'] = doc.id;
        
        // Convert Firestore timestamps
        if (bookingData['created_at'] is Timestamp) {
          bookingData['created_at'] = (bookingData['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (bookingData['updated_at'] is Timestamp) {
          bookingData['updated_at'] = (bookingData['updated_at'] as Timestamp).toDate().toIso8601String();
        }
        
        allBookings.add(bookingData);
      }
      
      _organizeBookingsByDate(allBookings);
      notifyListeners();
    } catch (e) {
      print('Error loading from Firebase: $e');
      throw e;
    }
  }

  void _organizeBookingsByDate(List<Map<String, dynamic>> allBookings) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    _upcomingBookings.clear();
    _pastBookings.clear();
    
    for (var booking in allBookings) {
      DateTime bookingDate = _parseBookingDate(booking['date']);
      
      if (bookingDate.isAfter(today) || bookingDate.isAtSameMomentAs(today)) {
        if (booking['status'] != 'cancelled') {
          _upcomingBookings.add(booking);
        }
      } else {
        _pastBookings.add(booking);
      }
    }
    
    // Sort upcoming by date (closest first)
    _upcomingBookings.sort((a, b) {
      DateTime dateA = _parseBookingDate(a['date']);
      DateTime dateB = _parseBookingDate(b['date']);
      return dateA.compareTo(dateB);
    });
    
    // Sort past by date (most recent first)
    _pastBookings.sort((a, b) {
      DateTime dateA = _parseBookingDate(a['date']);
      DateTime dateB = _parseBookingDate(b['date']);
      return dateB.compareTo(dateA);
    });
  }

  DateTime _parseBookingDate(String dateString) {
    try {
      if (dateString.toLowerCase() == 'today') {
        return DateTime.now();
      } else if (dateString.toLowerCase() == 'tomorrow') {
        return DateTime.now().add(Duration(days: 1));
      } else if (dateString.contains('Dec') || dateString.contains('Jan')) {
        // Parse formats like "Dec 28", "Jan 5"
        DateTime now = DateTime.now();
        int day = int.parse(dateString.split(' ')[1]);
        int month = dateString.contains('Dec') ? 12 : 1;
        int year = month == 12 ? now.year : now.year + 1;
        return DateTime(year, month, day);
      } else {
        // Try to parse ISO format
        return DateTime.parse(dateString);
      }
    } catch (e) {
      // Default to today if parsing fails
      return DateTime.now();
    }
  }

  // Add new booking from AI planner
  Future<void> addBookingFromAI({
    required BookingStep bookingStep,
    required String userId,
    String? planTitle,
  }) async {
    try {
      Map<String, dynamic> bookingData = {
        'id': bookingStep.id,
        'type': bookingStep.type,
        'name': bookingStep.stopName,
        'location': bookingStep.location,
        'date': _formatBookingDate(DateTime.now()),
        'time': bookingStep.time,
        'guests': bookingStep.details['party_size'] ?? 2,
        'status': _mapBookingStatus(bookingStep.status),
        'image': _getEmojiForType(bookingStep.type),
        'bookingRef': bookingStep.confirmationNumber ?? 'AI${bookingStep.id.substring(0, 6)}',
        'confirmation_details': bookingStep.details,
        'created_by_ai': true,
        'plan_title': planTitle,
        'created_at': DateTime.now().toIso8601String(),
        'estimated_cost': bookingStep.details['estimated_cost'] ?? '\$30',
        'contact_info': bookingStep.details['contact_info'] ?? '+974 4444 0000',
        'cancellation_policy': bookingStep.details['cancellation_policy'] ?? 'Standard cancellation policy',
        'special_instructions': bookingStep.details['special_instructions'] ?? 'Please arrive on time',
      };

      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingStep.id)
          .set(bookingData);

      // Also send to backend for processing
      await _sendToBackend(bookingData, userId);
      
      // Reload bookings to reflect changes
      await loadBookings(userId);
      
    } catch (e) {
      _setError('Failed to add booking: $e');
      print('Error adding booking: $e');
    }
  }

  String _formatBookingDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));
    DateTime bookingDay = DateTime(date.year, date.month, date.day);
    
    if (bookingDay.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (bookingDay.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return '${_getMonthName(date.month)} ${date.day}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _mapBookingStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.failed:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _getEmojiForType(String type) {
    switch (type) {
      case 'restaurant':
        return '🍽️';
      case 'cafe':
        return '☕';
      case 'attraction':
        return '🏛️';
      case 'shopping':
        return '🛍️';
      case 'tour':
        return '🏜️';
      case 'museum':
        return '🏛️';
      default:
        return '📍';
    }
  }

  Future<void> _sendToBackend(Map<String, dynamic> booking, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(booking),
      );
      
      if (response.statusCode == 200) {
        print('Booking synced with backend');
      } else {
        print('Backend sync failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to sync booking with backend: $e');
    }
  }

  // Modify existing booking
  Future<bool> modifyBooking({
    required String bookingId,
    required Map<String, dynamic> updates,
    required String userId,
  }) async {
    try {
      // Update in Firebase
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId)
          .update({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update in backend
      await _sendModificationToBackend(bookingId, updates, userId);
      
      // Reload bookings
      await loadBookings(userId);
      
      return true;
    } catch (e) {
      _setError('Failed to modify booking: $e');
      return false;
    }
  }

  Future<void> _sendModificationToBackend(String bookingId, Map<String, dynamic> updates, String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        print('Booking modification synced with backend');
      }
    } catch (e) {
      print('Failed to sync modification with backend: $e');
    }
  }

  // Cancel booking
  Future<bool> cancelBooking({
    required String bookingId,
    required String userId,
    String? reason,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (reason != null) {
        updates['cancellation_reason'] = reason;
      }

      // Update in Firebase
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId)
          .update(updates);

      // Update in backend
      await _sendCancellationToBackend(bookingId, userId, reason);
      
      // Reload bookings
      await loadBookings(userId);
      
      return true;
    } catch (e) {
      _setError('Failed to cancel booking: $e');
      return false;
    }
  }

  Future<void> _sendCancellationToBackend(String bookingId, String userId, String? reason) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reason': reason,
          'cancelled_at': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        print('Booking cancellation synced with backend');
      }
    } catch (e) {
      print('Failed to sync cancellation with backend: $e');
    }
  }

  // Rate completed booking
  Future<bool> rateBooking({
    required String bookingId,
    required double rating,
    String? review,
    required String userId,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'rating': rating,
        'review': review,
        'rated_at': DateTime.now().toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Update in Firebase
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId)
          .update(updates);

      // Send to backend
      await _sendRatingToBackend(bookingId, rating, review, userId);
      
      // Reload bookings
      await loadBookings(userId);
      
      return true;
    } catch (e) {
      _setError('Failed to rate booking: $e');
      return false;
    }
  }

  Future<void> _sendRatingToBackend(String bookingId, double rating, String? review, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/bookings/$bookingId/rating'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rating': rating,
          'review': review,
          'rated_at': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        print('Rating synced with backend');
      }
    } catch (e) {
      print('Failed to sync rating with backend: $e');
    }
  }

  // Get booking details
  Map<String, dynamic>? getBookingById(String bookingId) {
    // Check upcoming bookings
    for (var booking in _upcomingBookings) {
      if (booking['id'] == bookingId) {
        return booking;
      }
    }
    
    // Check past bookings
    for (var booking in _pastBookings) {
      if (booking['id'] == bookingId) {
        return booking;
      }
    }
    
    return null;
  }

  // Refresh bookings
  Future<void> refreshBookings(String userId) async {
    await loadBookings(userId);
  }

  // Clear all bookings (for logout)
  Future<void> clearBookings() async {
    _upcomingBookings.clear();
    _pastBookings.clear();
    notifyListeners();
  }

  // Get bookings for a specific date
  List<Map<String, dynamic>> getBookingsForDate(DateTime date) {
    String dateString = _formatBookingDate(date);
    return _upcomingBookings.where((booking) => booking['date'] == dateString).toList();
  }

  // Get booking statistics
  Map<String, dynamic> getBookingStatistics() {
    int totalBookings = _upcomingBookings.length + _pastBookings.length;
    int completedBookings = _pastBookings.where((b) => b['status'] == 'completed').length;
    int cancelledBookings = _pastBookings.where((b) => b['status'] == 'cancelled').length;
    int aiGeneratedBookings = [..._upcomingBookings, ..._pastBookings]
        .where((b) => b['created_by_ai'] == true).length;
    
    double averageRating = 0.0;
    List<double> ratings = _pastBookings
        .where((b) => b['rating'] != null)
        .map((b) => (b['rating'] as num).toDouble())
        .toList();
    
    if (ratings.isNotEmpty) {
      averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
    }
    
    return {
      'total_bookings': totalBookings,
      'upcoming_bookings': _upcomingBookings.length,
      'completed_bookings': completedBookings,
      'cancelled_bookings': cancelledBookings,
      'ai_generated_bookings': aiGeneratedBookings,
      'average_rating': averageRating,
      'total_rated': ratings.length,
    };
  }

  // Listen to real-time updates from Firebase
  void startListeningToBookings(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> allBookings = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        bookingData['id'] = doc.id;
        
        // Convert Firestore timestamps
        if (bookingData['created_at'] is Timestamp) {
          bookingData['created_at'] = (bookingData['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (bookingData['updated_at'] is Timestamp) {
          bookingData['updated_at'] = (bookingData['updated_at'] as Timestamp).toDate().toIso8601String();
        }
        
        allBookings.add(bookingData);
      }
      
      _organizeBookingsByDate(allBookings);
      notifyListeners();
    });
  }
}