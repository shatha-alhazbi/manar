// services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final String visitPurpose;
  final String budgetRange;
  final List<String> interests;
  final List<String> cuisinePreferences;
  final String transportMode;
  final String language;
  final int groupSize;
  final double minRating;

  UserPreferences({
    required this.visitPurpose,
    required this.budgetRange,
    required this.interests,
    required this.cuisinePreferences,
    required this.transportMode,
    this.language = 'en',
    this.groupSize = 1,
    this.minRating = 4.0,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      visitPurpose: map['visitPurpose'] ?? '',
      budgetRange: map['budgetRange'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      cuisinePreferences: List<String>.from(map['cuisinePreferences'] ?? []),
      transportMode: map['transportMode'] ?? '',
      language: map['language'] ?? 'en',
      groupSize: map['groupSize'] ?? 1,
      minRating: (map['minRating'] ?? 4.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitPurpose': visitPurpose,
      'budgetRange': budgetRange,
      'interests': interests,
      'cuisinePreferences': cuisinePreferences,
      'transportMode': transportMode,
      'language': language,
      'groupSize': groupSize,
      'minRating': minRating,
    };
  }
}

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserPreferences? _userPreferences;
  UserPreferences? get userPreferences => _userPreferences;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  String? get currentUserId => _auth.currentUser?.uid;
  
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['profileComplete'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }
  
  Future<bool> saveUserPreferences(UserPreferences preferences) async {
    try {
      _setLoading(true);
      _setError(null);
      
      String? userId = currentUserId;
      if (userId == null) {
        _setError('User not logged in');
        return false;
      }
      
      Map<String, dynamic> data = preferences.toMap();
      data['profileComplete'] = true;
      data['onboardingCompletedAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(userId).update(data);
      
      _userPreferences = preferences;
      
      return true;
    } catch (e) {
      _setError('Failed to save preferences. Please try again.');
      print('Error saving user preferences: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<UserPreferences?> loadUserPreferences([String? userId]) async {
    try {
      _setLoading(true);
      _setError(null);
      
      String? uid = userId ?? currentUserId;
      if (uid == null) {
        _setError('User not logged in');
        return null;
      }
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _userPreferences = UserPreferences.fromMap(data);
        return _userPreferences;
      }
      
      return null;
    } catch (e) {
      _setError('Failed to load preferences.');
      print('Error loading user preferences: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateUserPreference(String key, dynamic value) async {
    try {
      String? userId = currentUserId;
      if (userId == null) {
        _setError('User not logged in');
        return false;
      }
      
      await _firestore.collection('users').doc(userId).update({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await loadUserPreferences();
      
      return true;
    } catch (e) {
      _setError('Failed to update preference.');
      print('Error updating user preference: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      String? uid = userId ?? currentUserId;
      if (uid == null) return null;
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      String? userId = currentUserId;
      if (userId == null) {
        _setError('User not logged in');
        return false;
      }
      
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(userId).update(data);
      
      return true;
    } catch (e) {
      _setError('Failed to update profile.');
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  Future<List<String>> getRecommendationTags() async {
    if (_userPreferences == null) {
      await loadUserPreferences();
    }
    
    if (_userPreferences == null) return [];
    
    List<String> tags = [];
    
    switch (_userPreferences!.visitPurpose) {
      case 'business':
        tags.addAll(['quick_service', 'wifi', 'business_friendly']);
        break;
      case 'vacation':
        tags.addAll(['tourist_friendly', 'photo_worthy', 'cultural']);
        break;
      case 'family':
        tags.addAll(['family_friendly', 'group_seating', 'kid_options']);
        break;
      case 'transit':
        tags.addAll(['quick_access', 'near_airport', 'fast_service']);
        break;
      case 'resident':
        tags.addAll(['local_favorite', 'authentic', 'hidden_gem']);
        break;
    }
    
    tags.add('budget_${_userPreferences!.budgetRange}');
    tags.addAll(_userPreferences!.interests);
    tags.addAll(_userPreferences!.cuisinePreferences);
    
    switch (_userPreferences!.transportMode) {
      case 'public':
        tags.addAll(['metro_accessible', 'walkable']);
        break;
      case 'taxi':
        tags.addAll(['easy_pickup', 'central_location']);
        break;
      case 'car':
        tags.addAll(['parking_available', 'drive_friendly']);
        break;
      case 'tour':
        tags.addAll(['tour_included', 'group_friendly']);
        break;
    }
    
    return tags;
  }
  
  String generateWelcomeMessage() {
    if (_userPreferences == null) return 'Welcome to Qatar!';
    
    String purpose = '';
    switch (_userPreferences!.visitPurpose) {
      case 'business':
        purpose = 'business trip';
        break;
      case 'vacation':
        purpose = 'vacation';
        break;
      case 'family':
        purpose = 'family visit';
        break;
      case 'transit':
        purpose = 'transit stay';
        break;
      case 'resident':
        purpose = 'local exploration';
        break;
    }
    
    return 'Welcome to Qatar! I\'ve personalized your experience for your $purpose with ${_userPreferences!.budgetRange} budget. Let\'s discover amazing places that match your interests!';
  }
  
  Future<bool> addToFavorites(String venueId, String venueName, String venueType) async {
    try {
      String? userId = currentUserId;
      if (userId == null) {
        _setError('User not logged in');
        return false;
      }
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(venueId)
          .set({
        'venueId': venueId,
        'venueName': venueName,
        'venueType': venueType,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _setError('Failed to add to favorites.');
      print('Error adding to favorites: $e');
      return false;
    }
  }
  
  Future<bool> removeFromFavorites(String venueId) async {
    try {
      String? userId = currentUserId;
      if (userId == null) {
        _setError('User not logged in');
        return false;
      }
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(venueId)
          .delete();
      
      return true;
    } catch (e) {
      _setError('Failed to remove from favorites.');
      print('Error removing from favorites: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      String? userId = currentUserId;
      if (userId == null) return [];
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
  
  Future<bool> isFavorite(String venueId) async {
    try {
      String? userId = currentUserId;
      if (userId == null) return false;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(venueId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }
  
  Future<void> trackRecommendationInteraction(String query, List<String> results) async {
    try {
      String? userId = currentUserId;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'recommendationHistory': FieldValue.arrayUnion([
          {
            'query': query,
            'timestamp': FieldValue.serverTimestamp(),
            'results': results,
          }
        ]),
      });
    } catch (e) {
      print('Error tracking recommendation interaction: $e');
    }
  }
  
  Stream<DocumentSnapshot> getUserProfileStream() {
    String? userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    
    return _firestore.collection('users').doc(userId).snapshots();
  }
}