// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import 'package:manara/services/auth_services.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    // Load user preferences on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().loadUserPreferences();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Status Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '🔋 85%',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            // Header with gradient
            _buildHeader(),
            
            // Scrollable content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Quick Actions
                      _buildQuickActions(),
                      
                      // Trip Planner
                      _buildTripPlanner(),
                      
                      SizedBox(height: 20),
                      
                      // Trending Now Section
                      _buildSection('Trending Now', [
                        _buildCard('Souq Waqif', 'Traditional Market • Old Doha', '⭐ 4.8', '• 2.1km away'),
                        _buildCard('Museum of Islamic Art', 'Cultural Heritage • Corniche', '⭐ 4.9', '• 1.5km away'),
                      ]),
                      
                      SizedBox(height: 20),
                      
                      // Personalized Recommendations
                      Consumer<UserService>(
                        builder: (context, userService, child) {
                          if (userService.userPreferences != null) {
                            return _buildPersonalizedSection(userService);
                          }
                          return SizedBox.shrink();
                        },
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Near You Section
                      _buildSection('Near You', [
                        _buildCard('Al Mourjan Restaurant', 'Middle Eastern • Budget', '⭐ 4.6', '• Open now'),
                        _buildCard('Katara Cultural Village', 'Arts & Culture • Free', '⭐ 4.7', '• 15min drive'),
                      ]),
                      
                      SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button for Chat
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to chat screen
          _showChatDialog();
        },
        backgroundColor: AppColors.primaryBlue,
        child: Text('🤖', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.mediumGray],
        ),
      ),
      child: Stack(
        children: [
          // Background circle
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Header content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<UserService>(
                          builder: (context, userService, child) {
                            if (userService.userPreferences != null) {
                              return Text(
                                'مرحباً • Welcome',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              );
                            }
                            return Text(
                              'مرحباً • Welcome',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Discover Qatar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Profile/Settings button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _showProfileMenu(),
                        icon: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('🍽️', 'Restaurants'),
          _buildActionButton('🏛️', 'Attractions'),
          _buildActionButton('🛍️', 'Shopping'),
          _buildActionButton('☕', 'Cafés'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String icon, String label) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 7.5),
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
                  Text(
                    icon,
                    style: TextStyle(fontSize: 24),
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
      ),
    );
  }

  Widget _buildTripPlanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mediumGray, AppColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Your Perfect Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'AI-powered itinerary based on your preferences',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => _navigateToTripPlanner(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      'Create Trip Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPersonalizedSection(UserService userService) {
    final preferences = userService.userPreferences!;
    String sectionTitle = 'Recommended for You';
    
    // Customize title based on user preferences
    if (preferences.interests.contains('food')) {
      sectionTitle = 'Perfect Dining Spots';
    } else if (preferences.interests.contains('culture')) {
      sectionTitle = 'Cultural Experiences';
    } else if (preferences.visitPurpose == 'business') {
      sectionTitle = 'Business-Friendly Places';
    }

    return _buildSection(sectionTitle, [
      _buildPersonalizedCard(preferences),
      _buildPersonalizedCard(preferences, isSecondary: true),
    ]);
  }

  Widget _buildPersonalizedCard(UserPreferences preferences, {bool isSecondary = false}) {
    if (preferences.budgetRange == 'budget' && preferences.interests.contains('food')) {
      return isSecondary 
          ? _buildCard('Karak House', 'Authentic Qatari tea • Budget', '⭐ 4.5', '• Perfect for your budget')
          : _buildCard('Local Shawarma Corner', 'Street food • Budget-friendly', '⭐ 4.3', '• Matches your preferences');
    } else if (preferences.interests.contains('culture')) {
      return isSecondary
          ? _buildCard('Qatar National Library', 'Modern Architecture • Free', '⭐ 4.8', '• Cultural experience')
          : _buildCard('Falcon Souq', 'Traditional Market • Cultural', '⭐ 4.6', '• Authentic Qatar');
    } else {
      return isSecondary
          ? _buildCard('The Pearl-Qatar', 'Luxury Shopping • Premium', '⭐ 4.7', '• Upscale experience')
          : _buildCard('Aspire Park', 'Family Recreation • Free', '⭐ 4.5', '• Great for families');
    }
  }

  Widget _buildSection(String title, List<Widget> cards) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToSeeAll(title),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.mediumGray,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildCard(String title, String subtitle, String rating, String additional) {
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
                        ),
                        SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
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
                        Text(
                          additional,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPurple,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _handleNavigation(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.mediumGray,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 24)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Text('📅', style: TextStyle(fontSize: 24)),
            label: 'Day Planner',
          ),
          BottomNavigationBarItem(
            icon: Text('🤖', style: TextStyle(fontSize: 24)),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Text('👤', style: TextStyle(fontSize: 24)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        _navigateToTripPlanner();
        break;
      case 2:
        _showChatDialog();
        break;
      case 3:
        _showProfileMenu();
        break;
    }
  }

  void _navigateToCategory(String category) {
    // Navigate to category screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          'Category: ${category.capitalize()}',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would navigate to the $category screen with filtered results.',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          'Trip Planner',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would open the AI-powered trip planning interface.',
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
          'Searching for: "$query"\n\nThis would show personalized search results based on your preferences.',
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

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'AI Assistant',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'This would open the AI-powered chat interface where you can ask questions about Qatar, get recommendations, make bookings, etc.',
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
            
            // Profile header
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
            
            // Menu items
            _buildProfileMenuItem(Icons.person_outline, 'Edit Profile', () {}),
            _buildProfileMenuItem(Icons.favorite_outline, 'Favorites', () {}),
            _buildProfileMenuItem(Icons.history, 'Trip History', () {}),
            _buildProfileMenuItem(Icons.settings , 'Settings', () {}),
            _buildProfileMenuItem(Icons.help_outline, 'Help & Support', () {}),
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            // Sign out
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return _buildProfileMenuItem(
                  Icons.logout,
                  'Sign Out',
                  () async {
                    Navigator.pop(context);
                    await authService.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  },
                  isDestructive: true,
                );
              },
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}