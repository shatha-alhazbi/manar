// screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import '../../services/ai_recommendation_service.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  AIRecommendationService? _aiService;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    
    // Initialize AI service and load recommendations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAIService();
    });
  }

  void _initializeAIService() {
    final userService = context.read<UserService>();
    
    // Initialize AI service (you'll need to add AuthService here when ready)
    // _aiService = AIRecommendationService(userService, authService);
    
    // For now, just simulate loading
    Future.delayed(Duration(seconds: 2), () {
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
                // Search Header
                _buildSearchHeader(),
                
                SizedBox(height: 24),
                
                // Quick Categories
                _buildQuickCategories(),
                
                SizedBox(height: 32),
                
                // Trending Now Section
                _buildTrendingSection(),
                
                SizedBox(height: 32),
                
                // Personalized Recommendations
                _buildPersonalizedSection(),
                
                SizedBox(height: 32),
                
                // Near You Section
                _buildNearbySection(),
                
                SizedBox(height: 32),
                
                // Special Collections
                _buildSpecialCollections(),
                
                SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Qatar',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Discover amazing places and experiences',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
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
              suffixIcon: IconButton(
                onPressed: () => _showFilterDialog(),
                icon: Icon(
                  Icons.tune,
                  color: Colors.white.withOpacity(0.7),
                ),
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
    );
  }

  Widget _buildQuickCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCategoryButton(Icons.restaurant_outlined, 'Restaurants')),
            SizedBox(width: 12),
            Expanded(child: _buildCategoryButton(Icons.account_balance, 'Attractions')),
            SizedBox(width: 12),
            Expanded(child: _buildCategoryButton(Icons.shopping_bag_outlined, 'Shopping')),
            SizedBox(width: 12),
            Expanded(child: _buildCategoryButton(Icons.local_cafe_outlined, 'Cafés')),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton(IconData icon, String label) {
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

  Widget _buildTrendingSection() {
    return _buildRecommendationSection(
      'Trending Now',
      [
        _buildRecommendationCard('Souq Waqif', 'Traditional Market • Old Doha', '⭐ 4.8', '• Popular this week'),
        _buildRecommendationCard('Museum of Islamic Art', 'Cultural Heritage • Corniche', '⭐ 4.9', '• Must visit'),
        _buildRecommendationCard('The Pearl-Qatar', 'Luxury Island • Shopping', '⭐ 4.7', '• Trending now'),
      ],
    );
  }

  Widget _buildPersonalizedSection() {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        String sectionTitle = 'Recommended for You';
        
        // Customize based on preferences
        if (userService.userPreferences?.interests.contains('food') == true) {
          sectionTitle = 'Perfect Dining Spots';
        } else if (userService.userPreferences?.interests.contains('culture') == true) {
          sectionTitle = 'Cultural Experiences';
        }

        return _buildRecommendationSection(
          sectionTitle,
          [
            _buildRecommendationCard('Katara Cultural Village', 'Arts & Culture • Free Entry', '⭐ 4.7', '• Matches your interests'),
            _buildRecommendationCard('Al Wakra Souq', 'Traditional Market • Authentic', '⭐ 4.5', '• Great for culture lovers'),
            _buildRecommendationCard('Doha Corniche', 'Waterfront • Walking', '⭐ 4.8', '• Perfect for your visit'),
          ],
        );
      },
    );
  }

  Widget _buildNearbySection() {
    return _buildRecommendationSection(
      'Near You',
      [
        _buildRecommendationCard('Al Mourjan Restaurant', 'Middle Eastern • Budget', '⭐ 4.6', '• 0.8km away'),
        _buildRecommendationCard('City Center Doha', 'Shopping Mall • Modern', '⭐ 4.4', '• 1.2km away'),
        _buildRecommendationCard('Aspire Park', 'Recreation • Free', '⭐ 4.5', '• 2.1km away'),
      ],
    );
  }

  Widget _buildSpecialCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Collections',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        _buildCollectionCard(
          'Hidden Gems',
          'Discover Qatar\'s best-kept secrets',
          Icons.diamond,
          AppColors.primaryBlue,
        ),
        SizedBox(height: 12),
        _buildCollectionCard(
          'Family Fun',
          'Perfect activities for the whole family',
          Icons.family_restroom,
          AppColors.mediumGray,
        ),
        SizedBox(height: 12),
        _buildCollectionCard(
          'Local Favorites',
          'Where locals love to go',
          Icons.local_fire_department,
          AppColors.darkPurple,
        ),
      ],
    );
  }

  Widget _buildCollectionCard(String title, String subtitle, IconData icon, Color backgroundColor) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCollection(title),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(String title, List<Widget> cards) {
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
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(right: 15),
                child: cards[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String subtitle, String rating, String additional) {
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
          onTap: () => _navigateToDetails(title),
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
                          title,
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
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          rating,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            additional,
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  // Navigation and action methods
  Future<void> _refreshRecommendations() async {
    // Simulate refresh
    await Future.delayed(Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  void _navigateToCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          '${category.substring(0, 1).toUpperCase()}${category.substring(1)} in Qatar',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show all $category with filtering and sorting options.',
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

  void _navigateToDetails(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show detailed information about $title including photos, reviews, booking options, etc.',
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
        title: Text(
          category,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show all items in the $category category.',
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

  void _navigateToCollection(String collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          collection,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show the $collection collection with curated recommendations.',
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
        title: Text(
          'Search Results',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Searching for: "$query"\n\nThis would show search results with AI-powered recommendations.',
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

  void _showFilterDialog() {
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Filter & Sort',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Filter options would go here
            ListTile(
              leading: Icon(Icons.star, color: AppColors.gold),
              title: Text('Rating', style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.chevron_right, color: Colors.white70),
            ),
            ListTile(
              leading: Icon(Icons.attach_money, color: AppColors.gold),
              title: Text('Price Range', style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.chevron_right, color: Colors.white70),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: AppColors.gold),
              title: Text('Distance', style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.chevron_right, color: Colors.white70),
            ),
            ListTile(
              leading: Icon(Icons.category, color: AppColors.gold),
              title: Text('Category', style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.chevron_right, color: Colors.white70),
            ),
            
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.maroon,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Apply Filters'),
            ),
            
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}