// lib/main.dart - Updated with full AI integration
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

// Import the AI planner screens
import 'screens/planner/booking_agent_screen.dart';
import 'screens/planner/day_planner_screen.dart';
import 'screens/planner/generated_plan_screen.dart';

// Import services
import 'services/auth_services.dart';
import 'services/user_services.dart';
import 'services/ai_recommendation_service.dart';
import 'services/day_planner_service.dart';
import 'services/booking_service.dart';

// Import models
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
        // Core services
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        
        // AI and planning services
        ChangeNotifierProvider(create: (_) => AIDayPlannerService()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        
        // Dependent services
        ChangeNotifierProxyProvider2<UserService, AuthService, AIRecommendationService>(
          create: (context) => AIRecommendationService(
            Provider.of<UserService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, userService, authService, previous) =>
              previous ?? AIRecommendationService(userService, authService),
        ),
      ],
      child: MaterialApp(
        title: 'Manar - AI-Powered Qatar Tourism',
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
                  planningData: args?['planningData'] ?? {},
                  generatedStops: args?['generatedStops'],
                ),
              );
            
            case '/booking-agent':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => BookingAgentScreen(
                  dayPlan: List<PlanStop>.from(args?['dayPlan'] ?? []),
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
                // Initialize all AI services when navigating to home
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _initializeAIServices(context, snapshot.data!.uid);
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

  void _initializeAIServices(BuildContext context, String userId) async {
    try {
      // Initialize AI recommendation service
      final aiService = context.read<AIRecommendationService>();
      aiService.loadAllRecommendations();
      
      // Initialize booking service
      final bookingService = context.read<BookingService>();
      await bookingService.initialize(userId);
      
      print('AI services initialized successfully for user: $userId');
    } catch (e) {
      print('Error initializing AI services: $e');
    }
  }
}

// Navigation helpers for AI day planner
class AIPlannerRoutes {
  static const String aiDayPlanner = '/ai-day-planner';
  static const String generatedPlan = '/generated-plan';
  static const String bookingAgent = '/booking-agent';
  
  static void navigateToAIDayPlanner(BuildContext context) {
    Navigator.pushNamed(context, aiDayPlanner);
  }
  
  static void navigateToGeneratedPlan(
    BuildContext context, 
    Map<String, dynamic> planningData,
    {List<PlanStop>? generatedStops}
  ) {
    Navigator.pushNamed(
      context, 
      generatedPlan,
      arguments: {
        'planningData': planningData,
        'generatedStops': generatedStops,
      },
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

// Updated dashboard integration example
class DashboardAIIntegration {
  // How to integrate the AI Day Planner button in your dashboard
  static Widget buildAIDayPlannerCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.1),
            AppColors.primaryBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.maroon,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Day Planner',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Powered by FANAR AI',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Let our advanced AI create a personalized Qatar itinerary, handle all bookings, and optimize your perfect day automatically.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AIPlannerRoutes.navigateToAIDayPlanner(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.maroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start AI Planning',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI will handle everything: planning, booking, and optimization',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Example integration in dashboard screen
  static Widget buildDashboardWithAI(BuildContext context) {
    return Column(
      children: [
        // Existing dashboard content
        // ...
        
        // AI Day Planner Section
        buildAIDayPlannerCard(context),
        
        // Recent AI Activities
        Consumer2<AIDayPlannerService, BookingService>(
          builder: (context, plannerService, bookingService, child) {
            return Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent AI Activity',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Show recent AI bookings
                  if (bookingService.upcomingBookings.any((b) => b['created_by_ai'] == true)) ...[
                    ...bookingService.upcomingBookings
                        .where((b) => b['created_by_ai'] == true)
                        .take(2)
                        .map((booking) => Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.psychology, color: AppColors.gold, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI booked: ${booking['name']}',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              Text(
                                booking['date'],
                                style: TextStyle(color: AppColors.gold, fontSize: 12),
                              ),
                            ],
                          ),
                        )).toList(),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.white60, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No AI activity yet. Start planning your first AI-powered adventure!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        
        // More dashboard content
        // ...
      ],
    );
  }
}

// Error handling and fallback systems
class AIServiceErrorHandler {
  static void handleAIError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Service Error',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(error, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Retry logic here
          },
        ),
      ),
    );
  }

  static Widget buildOfflineMode(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: AppColors.warning),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Services Offline',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Using cached recommendations. Connect to internet for full AI features.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Performance monitoring for AI services
class AIPerformanceMonitor {
  static void trackAIResponse(String endpoint, Duration responseTime) {
    print('AI Endpoint: $endpoint - Response Time: ${responseTime.inMilliseconds}ms');
    
    if (responseTime.inSeconds > 10) {
      print('WARNING: Slow AI response detected for $endpoint');
    }
  }

  static void trackUserSatisfaction(String feature, double rating) {
    print('User Satisfaction - $feature: $rating/5.0');
  }
}
