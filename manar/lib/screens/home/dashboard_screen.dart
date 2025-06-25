// screens/home/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import 'package:manara/services/auth_services.dart';
import '../../services/ai_recommendation_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  AIRecommendationService? _aiService;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Initialize AI service and load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().loadUserPreferences();
      _initializeAIService();
    });
  }

  void _initializeAIService() {
    final userService = context.read<UserService>();
    final authService = context.read<AuthService>();
    
    _aiService = AIRecommendationService(userService, authService);
    _aiService!.loadAllRecommendations();
    
    _aiService!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _aiService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue,
            AppColors.darkNavy,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header with search
              _buildHeader(),
              
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshRecommendations,
                  backgroundColor: AppColors.darkNavy,
                  color: AppColors.gold,
                  child: SingleChildScrollView(
                    padding: AppStyles.defaultPadding,
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(),
                        
                        SizedBox(height: 32),
                        
                        // Quick Actions
                        _buildQuickActions(),
                        
                        SizedBox(height: 32),
                        
                        // Day Planning Quick Access
                        _buildDayPlanningSection(),
                        
                        SizedBox(height: 32),
                        
                        // Loading indicator or recommendations
                        if (_aiService?.isLoading == true)
                          _buildLoadingSection()
                        else ...[
                          // Personalized Recommendations (Main feature)
                          if (_aiService?.personalizedRecommendations.isNotEmpty == true)
                            _buildRecommendationSection(
                              _aiService?.getPersonalizedSectionTitle() ?? 'Recommended for You',
                              _aiService!.personalizedRecommendations,
                            ),
                          
                          SizedBox(height: 32),
                          
                          // Trending Now Section
                          if (_aiService?.trendingRecommendations.isNotEmpty == true)
                            _buildRecommendationSection(
                              'Trending Now',
                              _aiService!.trendingRecommendations,
                            ),
                          
                          SizedBox(height: 32),
                          
                          // Near You Section
                          if (_aiService?.nearbyRecommendations.isNotEmpty == true)
                            _buildRecommendationSection(
                              'Near You',
                              _aiService!.nearbyRecommendations,
                            ),
                        ],
                        
                        // Error handling
                        if (_aiService?.errorMessage != null)
                          _buildErrorSection(),
                        
                        SizedBox(height: 100), // Space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Top row with logo and profile
          Row(
            children: [
              // App logo and title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مَنار',
                    style: GoogleFonts.amiri(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              
              Spacer(),
              
              // Profile button
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final user = authService.currentUser;
                  return GestureDetector(
                    onTap: () => _showProfileMenu(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroon,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search places, food, experiences...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: AppStyles.gradientContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً بك',
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Consumer<AuthService>(
                          builder: (context, authService, child) {
                            return Text(
                              'Welcome back, ${authService.currentUser?.displayName?.split(' ').first ?? 'Explorer'}!',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getWelcomeMessage(userService.userPreferences),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.emoji_people,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Qatar',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionButton(Icons.restaurant_outlined, 'Restaurants')),
            SizedBox(width: 12),
            Expanded(child: _buildActionButton(Icons.account_balance, 'Attractions')),
            SizedBox(width: 12),
            Expanded(child: _buildActionButton(Icons.shopping_bag_outlined, 'Shopping')),
            SizedBox(width: 12),
            Expanded(child: _buildActionButton(Icons.local_cafe_outlined, 'Cafés')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCategory(label.toLowerCase()),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: AppStyles.gradientContainer,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: AppColors.gold,
                  size: 28,
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayPlanningSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppStyles.goldGradientContainer,
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
                  onPressed: () => _navigateToTripPlanner(),
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

  Widget _buildRecommendationSection(String title, List<RecommendationItem> items) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToSeeAll(title),
                  child: Text(
                    'See all',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 15),
                    child: _buildRecommendationCard(items[index]),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildRecommendationCard(RecommendationItem item) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.darkPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(item),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${item.type} • ${item.location}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.whyRecommended,
                          style: TextStyle(
                            color: AppColors.gold.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '⭐ ${item.rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          item.priceRange,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        if (item.bookingAvailable)
                          Icon(
                            Icons.event_available,
                            color: AppColors.gold,
                            size: 16,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
          SizedBox(height: 16),
          Text(
            'Loading personalized recommendations...',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Unable to load recommendations',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _aiService?.errorMessage ?? 'Please check your connection and try again',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshRecommendations,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getWelcomeMessage(UserPreferences? preferences) {
    if (preferences == null) return 'Ready to explore Qatar today?';
    
    switch (preferences.visitPurpose) {
      case 'business':
        return 'Make the most of your business trip!';
      case 'vacation':
        return 'Your Qatar adventure awaits!';
      case 'family':
        return 'Enjoy your time with loved ones!';
      case 'transit':
        return 'Perfect layover activities for you!';
      case 'resident':
        return 'Discover new places in your city!';
      default:
        return 'Ready to explore Qatar today?';
    }
  }

  // Navigation and action methods
  Future<void> _refreshRecommendations() async {
    await _aiService?.refreshRecommendations();
  }

  void _navigateToCategory(String category) {
    // Show category-specific recommendations
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          '${category.substring(0, 1).toUpperCase()}${category.substring(1)} in Qatar',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show all $category with personalized recommendations based on your preferences.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _navigateToTripPlanner() {
    // This will be handled by the main navigation
    Navigator.pushNamed(context, '/day-planner');
  }

  void _navigateToDetails(RecommendationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          item.name,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.type} • ${item.location}',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                item.description,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.gold, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${item.rating}/5',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 16),
                  Text(
                    item.priceRange,
                    style: TextStyle(color: AppColors.gold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Why recommended: ${item.whyRecommended}',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          if (item.bookingAvailable)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showBookingDialog(item);
              },
              child: Text('Book Now', style: TextStyle(color: AppColors.gold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(RecommendationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Book ${item.name}', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the booking interface for ${item.name}.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _navigateToSeeAll(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(category, style: TextStyle(color: Colors.white)),
        content: Text(
          'This would show all items in the $category category with filtering options.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Search Results', style: TextStyle(color: Colors.white)),
        content: Text(
          'Searching for: "$query"\n\nThis would show personalized search results.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Consumer<AuthService>(
              builder: (context, authService, child) {
                final user = authService.currentUser;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: AppColors.maroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user?.displayName ?? 'User',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user?.email ?? 'Guest',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.white),
              title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(context);
                    await authService.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  },
                );
              },
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}