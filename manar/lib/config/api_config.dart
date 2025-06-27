// lib/config/api_config.dart
class ApiConfig {
  // Replace these with your actual backend URLs
  static const String LOCAL_BASE_URL = 'http://localhost:8000';
  static const String STAGING_BASE_URL = 'https://your-staging-api.com';
  static const String PRODUCTION_BASE_URL = 'https://your-production-api.com';
  
  // Current environment
  static const Environment CURRENT_ENV = Environment.LOCAL;
  
  // Get base URL based on current environment
  static String get baseUrl {
    switch (CURRENT_ENV) {
      case Environment.LOCAL:
        return LOCAL_BASE_URL;
      case Environment.STAGING:
        return STAGING_BASE_URL;
      case Environment.PRODUCTION:
        return PRODUCTION_BASE_URL;
    }
  }
  
  // API Endpoints
  static const String RECOMMENDATIONS_ENDPOINT = '/api/v1/recommendations';
  static const String CHAT_ENDPOINT = '/api/v1/chat';
  static const String PLAN_ENDPOINT = '/api/v1/plan';
  static const String SEARCH_ENDPOINT = '/api/v1/search';
  static const String BOOKING_ENDPOINT = '/api/v1/book';
  
  // API Keys (these should be stored securely in production)
  static const String FANAR_API_KEY = 'fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz';
  
  // Request timeouts
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 60);
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 60);
  
  // Retry configuration
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 2);
}

enum Environment {
  LOCAL,
  STAGING,
  PRODUCTION,
}