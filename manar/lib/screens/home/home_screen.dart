// screens/home/home_screen.dart (Updated Main Navigation)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manara/constants/app_theme.dart';
import 'package:manara/screens/profile/profile_screen.dart';
import 'package:manara/screens/bookings/bookings_screen.dart';  
import 'package:manara/screens/chat/chat_screen.dart';  
import 'package:manara/screens/home/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<Widget> _screens = [
    DashboardScreen(),
    BookingsScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'Home',
    },
    {
      'icon': Icons.bookmark_outline,
      'activeIcon': Icons.bookmark,
      'label': 'Bookings',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'label': 'AI Chat',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profile',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      
      // Floating Action Button for Quick Actions (only on home screen)
      floatingActionButton: _selectedIndex == 0 ? _buildQuickActionFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildQuickActionFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.maroon,
        elevation: 8,
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPurple,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.gold.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item['activeIcon'] : item['icon'],
              color: isSelected ? AppColors.gold : AppColors.mediumGray,
              size: isSelected ? 26 : 24,
            ),
            SizedBox(height: 4),
            Text(
              item['label'],
              style: GoogleFonts.inter(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.gold : AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Restart FAB animation for home screen
      if (index == 0) {
        _fabAnimationController.reset();
        _fabAnimationController.forward();
      }
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
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
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            
            // Quick action buttons
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionButton(
                  '🗺️', 
                  'Plan Trip', 
                  'Create AI itinerary',
                  () {
                    Navigator.pop(context);
                    _navigateToPlanner();
                  },
                ),
                _buildQuickActionButton(
                  '💬', 
                  'Ask AI', 
                  'Get recommendations',
                  () {
                    Navigator.pop(context);
                    _navigateToChat();
                  },
                ),
                _buildQuickActionButton(
                  '📖', 
                  'My Bookings', 
                  'View reservations',
                  () {
                    Navigator.pop(context);
                    _navigateToBookings();
                  },
                ),
                _buildQuickActionButton(
                  '⭐', 
                  'Favorites', 
                  'Saved places',
                  () {
                    Navigator.pop(context);
                    _showFavorites();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String emoji, 
    String title, 
    String subtitle, 
    VoidCallback onTap
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji, 
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation helpers
  void _navigateToPlanner() {
    // This will trigger the day planner functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('AI Trip Planner', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the AI-powered trip planning interface where you can create personalized itineraries.',
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

  void _navigateToChat() {
    _onNavItemTapped(2);
  }

  void _navigateToBookings() {
    _onNavItemTapped(1);
  }

  void _showFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          'Your Favorites',
          style: TextStyle(color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.restaurant, color: AppColors.gold),
                title: Text('Souq Waqif', style: TextStyle(color: Colors.white)),
                subtitle: Text('Traditional Market', style: TextStyle(color: Colors.white70)),
              ),
              ListTile(
                leading: Icon(Icons.museum, color: AppColors.gold),
                title: Text('Museum of Islamic Art', style: TextStyle(color: Colors.white)),
                subtitle: Text('Cultural Heritage', style: TextStyle(color: Colors.white70)),
              ),
              ListTile(
                leading: Icon(Icons.location_city, color: AppColors.gold),
                title: Text('The Pearl-Qatar', style: TextStyle(color: Colors.white)),
                subtitle: Text('Luxury Shopping', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
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
}