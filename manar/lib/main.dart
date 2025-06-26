// main.dart - Updated with new routes
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Firebase options
import 'firebase_options.dart';

// Import existing screens
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

// Import the new day planner screens
import 'screens/planner/booking_agent_screen.dart';
import 'screens/planner/day_planner_screen.dart';
import 'screens/planner/generated_plan_screen.dart';
// Import services
import 'services/auth_services.dart';
import 'services/user_services.dart';
import 'services/ai_recommendation_service.dart';
import 'services/day_planner_service.dart';
import 'models/day_planner_model.dart';
// Import constants
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with proper options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(ManaraApp());
}

class ManaraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProxyProvider2<UserService, AuthService, AIRecommendationService>(
          create: (context) => AIRecommendationService(
            Provider.of<UserService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, userService, authService, previous) =>
              previous ?? AIRecommendationService(userService, authService),
        ),
        ChangeNotifierProvider(create: (_) => AIDayPlannerService()),
      ],
      child: MaterialApp(
        title: 'Manar - Qatar Tourism',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        
        // Initial route based on auth state
        home: AuthStateWrapper(),
        
        // Define all routes
        routes: {
          '/welcome': (context) => WelcomeScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/onboarding': (context) => OnboardingFlow(),
          '/home': (context) => HomeScreen(),
          '/ai-day-planner': (context) => AIDayPlannerScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle routes that need parameters
          switch (settings.name) {
            case '/generated-plan':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => GeneratedPlanScreen(
                  planningData: args ?? {},
                ),
              );
            
            case '/booking-agent':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => BookingAgentScreen(
                  dayPlan: args?['dayPlan'] ?? [],
                  planningData: args?['planningData'] ?? {},
                ),
              );
            
            default:
              return null;
          }
        },
      ),
    );
  }
}

class AuthStateWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        
        // User is logged in
        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: UserService().hasCompletedOnboarding(snapshot.data!.uid),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }
              
              // Check if user completed onboarding
              if (onboardingSnapshot.data == true) {
                // Initialize AI service when navigating to home
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final aiService = context.read<AIRecommendationService>();
                  aiService.loadAllRecommendations();
                });
                return HomeScreen();
              } else {
                return OnboardingFlow();
              }
            },
          );
        }
        
        // User is not logged in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
        });
        return SplashScreen(); 
      },
    );
  }
}

// Updated dashboard_screen.dart - Add navigation method
// Add this method to your existing DashboardScreen class:

/*
  void _navigateToTripPlanner() {
    Navigator.pushNamed(context, '/ai-day-planner');
  }
*/

// constants/app_routes.dart - Route management
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String aiDayPlanner = '/ai-day-planner';
  static const String generatedPlan = '/generated-plan';
  static const String bookingAgent = '/booking-agent';
  
  static void navigateToAIDayPlanner(BuildContext context) {
    Navigator.pushNamed(context, aiDayPlanner);
  }
  
  static void navigateToGeneratedPlan(BuildContext context, Map<String, dynamic> planningData) {
    Navigator.pushNamed(
      context, 
      generatedPlan,
      arguments: planningData,
    );
  }
  
  static void navigateToBookingAgent(
    BuildContext context, 
    List<PlanStop> dayPlan, 
    Map<String, dynamic> planningData
  ) {
    Navigator.pushNamed(
      context, 
      bookingAgent,
      arguments: {
        'dayPlan': dayPlan,
        'planningData': planningData,
      },
    );
  }
}

// Updated ai_day_planner_screen.dart - Navigation method
// Add this method to your AIDayPlannerScreen class:

/*
  void _generatePlan() {
    // Use the service to generate plan, then navigate
    final plannerService = context.read<AIDayPlannerService>();
    final authService = context.read<AuthService>();
    
    plannerService.generateDayPlan(
      userId: authService.currentUser?.uid ?? 'guest',
      planningData: userResponses,
    ).then((generatedPlan) {
      if (generatedPlan != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GeneratedPlanScreen(
              planningData: userResponses,
              generatedStops: generatedPlan, // Pass generated stops
            ),
          ),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate plan. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }
*/

// pubspec.yaml dependencies - Add these if not already present
/*
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  google_fonts: ^4.0.4
  http: ^0.13.5
  shared_preferences: ^2.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
*/

// Example usage in your existing code:

class ExampleIntegration {
  // How to integrate the AI Day Planner button in your dashboard
  Widget buildAIDayPlannerButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.maroon,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plan Your Perfect Day',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroon,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Let our AI create a personalized itinerary based on your preferences and available time.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.maroon.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AppRoutes.navigateToAIDayPlanner(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create AI Plan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // How to integrate with your backend API
  void setupBackendIntegration() {
    /*
    1. Update your backend_api_wrapper.py to handle the new planning endpoints
    2. Make sure your FANAR API integration is working
    3. Test the endpoints with the provided mock data
    4. Update the baseUrl in AIDayPlannerService to your server
    
    Backend endpoints needed:
    - POST /api/v1/plan (day planning)
    - POST /api/v1/book (booking)  
    - POST /api/v1/chat (AI chat)
    - POST /api/v1/recommendations (recommendations)
    */
  }
  
  // How to add map integration (Google Maps example)
  Widget buildMapIntegration() {
    /*
    For real map integration, add google_maps_flutter to pubspec.yaml:
    
    dependencies:
      google_maps_flutter: ^2.2.8
    
    Then replace the mock map in GeneratedPlanScreen with:
    
    GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(25.2854, 51.5310), // Doha center
        zoom: 12,
      ),
      markers: Set<Marker>.from(
        dayPlan.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          return Marker(
            markerId: MarkerId(stop.id),
            position: stop.coordinates,
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: stop.location,
            ),
          );
        }),
      ),
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: dayPlan.map((stop) => stop.coordinates).toList(),
          color: AppColors.gold,
          width: 4,
        ),
      },
    )
    */
    
    return Container(
      child: Text('Map integration placeholder'),
    );
  }
}