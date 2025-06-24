// // screens/home/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../constants/app_theme.dart';
// import 'package:manara/services/user_services.dart';
// import 'package:manara/services/auth_services.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   int _selectedIndex = 0;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//     _animationController.forward();
    
//     // Load user preferences on screen init
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<UserService>().loadUserPreferences();
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.darkNavy,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Custom Status Bar
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '9:41',
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                   ),
//                   Text(
//                     '🔋 85%',
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Header with gradient
//             _buildHeader(),
            
//             // Scrollable content
//             Expanded(
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // Quick Actions
//                       _buildQuickActions(),
                      
//                       // Trip Planner
//                       _buildTripPlanner(),
                      
//                       SizedBox(height: 20),
                      
//                       // Trending Now Section
//                       _buildSection('Trending Now', [
//                         _buildCard('Souq Waqif', 'Traditional Market • Old Doha', '⭐ 4.8', '• 2.1km away'),
//                         _buildCard('Museum of Islamic Art', 'Cultural Heritage • Corniche', '⭐ 4.9', '• 1.5km away'),
//                       ]),
                      
//                       SizedBox(height: 20),
                      
//                       // Personalized Recommendations
//                       Consumer<UserService>(
//                         builder: (context, userService, child) {
//                           if (userService.userPreferences != null) {
//                             return _buildPersonalizedSection(userService);
//                           }
//                           return SizedBox.shrink();
//                         },
//                       ),
                      
//                       SizedBox(height: 20),
                      
//                       // Near You Section
//                       _buildSection('Near You', [
//                         _buildCard('Al Mourjan Restaurant', 'Middle Eastern • Budget', '⭐ 4.6', '• Open now'),
//                         _buildCard('Katara Cultural Village', 'Arts & Culture • Free', '⭐ 4.7', '• 15min drive'),
//                       ]),
                      
//                       SizedBox(height: 100), // Space for bottom nav
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
      
//       // Floating Action Button for Chat
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Navigate to chat screen
//           _showChatDialog();
//         },
//         backgroundColor: AppColors.primaryBlue,
//         child: Text('🤖', style: TextStyle(fontSize: 24)),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
//       // Bottom Navigation
//       bottomNavigationBar: _buildBottomNavigation(),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.primaryBlue, AppColors.mediumGray],
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background circle
//           Positioned(
//             top: -50,
//             right: -20,
//             child: Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           // Header content
//           Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Consumer<UserService>(
//                           builder: (context, userService, child) {
//                             if (userService.userPreferences != null) {
//                               return Text(
//                                 'مرحباً • Welcome',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.8),
//                                   fontSize: 16,
//                                 ),
//                               );
//                             }
//                             return Text(
//                               'مرحباً • Welcome',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.8),
//                                 fontSize: 16,
//                               ),
//                             );
//                           },
//                         ),
//                         SizedBox(height: 5),
//                         Text(
//                           'Discover Qatar',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     // Profile/Settings button
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: IconButton(
//                         onPressed: () => _showProfileMenu(),
//                         icon: Icon(
//                           Icons.person_outline,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 15),
//                 // Search bar
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(25),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                     ),
//                   ),
//                   child: TextField(
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: 'Search places, food, experiences...',
//                       hintStyle: TextStyle(
//                         color: Colors.white.withOpacity(0.7),
//                       ),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                       prefixIcon: Icon(
//                         Icons.search,
//                         color: Colors.white.withOpacity(0.7),
//                       ),
//                     ),
//                     onSubmitted: (value) {
//                       if (value.isNotEmpty) {
//                         _performSearch(value);
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildActionButton('🍽️', 'Restaurants'),
//           _buildActionButton('🏛️', 'Attractions'),
//           _buildActionButton('🛍️', 'Shopping'),
//           _buildActionButton('☕', 'Cafés'),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(String icon, String label) {
//     return Expanded(
//       child: Container(
//         margin: EdgeInsets.symmetric(horizontal: 7.5),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () => _navigateToCategory(label.toLowerCase()),
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               decoration: AppStyles.gradientContainer,
//               padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
//               child: Column(
//                 children: [
//                   Text(
//                     icon,
//                     style: TextStyle(fontSize: 24),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     label,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTripPlanner() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.mediumGray, AppColors.primaryBlue],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             top: -30,
//             left: -30,
//             child: Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.15),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Plan Your Perfect Day',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'AI-powered itinerary based on your preferences',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 14,
//                   ),
//                 ),
//                 SizedBox(height: 15),
//                 ElevatedButton(
//                   onPressed: () => _navigateToTripPlanner(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white.withOpacity(0.15),
//                     side: BorderSide(
//                       color: Colors.white.withOpacity(0.3),
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     child: Text(
//                       'Create Trip Plan',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPersonalizedSection(UserService userService) {
//     final preferences = userService.userPreferences!;
//     String sectionTitle = 'Recommended for You';
    
//     // Customize title based on user preferences
//     if (preferences.interests.contains('food')) {
//       sectionTitle = 'Perfect Dining Spots';
//     } else if (preferences.interests.contains('culture')) {
//       sectionTitle = 'Cultural Experiences';
//     } else if (preferences.visitPurpose == 'business') {
//       sectionTitle = 'Business-Friendly Places';
//     }

//     return _buildSection(sectionTitle, [
//       _buildPersonalizedCard(preferences),
//       _buildPersonalizedCard(preferences, isSecondary: true),
//     ]);
//   }

//   Widget _buildPersonalizedCard(UserPreferences preferences, {bool isSecondary = false}) {
//     if (preferences.budgetRange == 'budget' && preferences.interests.contains('food')) {
//       return isSecondary 
//           ? _buildCard('Karak House', 'Authentic Qatari tea • Budget', '⭐ 4.5', '• Perfect for your budget')
//           : _buildCard('Local Shawarma Corner', 'Street food • Budget-friendly', '⭐ 4.3', '• Matches your preferences');
//     } else if (preferences.interests.contains('culture')) {
//       return isSecondary
//           ? _buildCard('Qatar National Library', 'Modern Architecture • Free', '⭐ 4.8', '• Cultural experience')
//           : _buildCard('Falcon Souq', 'Traditional Market • Cultural', '⭐ 4.6', '• Authentic Qatar');
//     } else {
//       return isSecondary
//           ? _buildCard('The Pearl-Qatar', 'Luxury Shopping • Premium', '⭐ 4.7', '• Upscale experience')
//           : _buildCard('Aspire Park', 'Family Recreation • Free', '⭐ 4.5', '• Great for families');
//     }
//   }

//   Widget _buildSection(String title, List<Widget> cards) {
//     return Column(
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () => _navigateToSeeAll(title),
//                 child: Text(
//                   'See all',
//                   style: TextStyle(
//                     color: AppColors.mediumGray,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 15),
//         Container(
//           height: 160,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.symmetric(horizontal: 20),
//             itemCount: cards.length,
//             itemBuilder: (context, index) {
//               return Container(
//                 margin: EdgeInsets.only(right: 15),
//                 child: cards[index],
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCard(String title, String subtitle, String rating, String additional) {
//     return Container(
//       width: 280,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.primaryBlue, AppColors.darkPurple],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _navigateToDetails(title),
//           borderRadius: BorderRadius.circular(16),
//           child: Stack(
//             children: [
//               Positioned(
//                 top: -50,
//                 right: -30,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           subtitle,
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Text(
//                           rating,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                           ),
//                         ),
//                         Text(
//                           additional,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNavigation() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.darkPurple,
//         border: Border(
//           top: BorderSide(
//             color: Colors.white.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//           _handleNavigation(index);
//         },
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.transparent,
//         selectedItemColor: Colors.white,
//         unselectedItemColor: AppColors.mediumGray,
//         elevation: 0,
//         selectedFontSize: 12,
//         unselectedFontSize: 12,
//         items: [
//           BottomNavigationBarItem(
//             icon: Text('🏠', style: TextStyle(fontSize: 24)),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Text('📅', style: TextStyle(fontSize: 24)),
//             label: 'Day Planner',
//           ),
//           BottomNavigationBarItem(
//             icon: Text('🤖', style: TextStyle(fontSize: 24)),
//             label: 'Chatbot',
//           ),
//           BottomNavigationBarItem(
//             icon: Text('👤', style: TextStyle(fontSize: 24)),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }

  // // Navigation methods
  // void _handleNavigation(int index) {
  //   switch (index) {
  //     case 0:
  //       // Home - already here
  //       break;
  //     case 1:
  //       _navigateToTripPlanner();
  //       break;
  //     case 2:
  //       _showChatDialog();
  //       break;
  //     case 3:
  //       _showProfileMenu();
  //       break;
  //   }
  // }

//   void _navigateToCategory(String category) {
//     // Navigate to category screen
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.darkNavy,
//         title: Text(
//           'Category: ${category.capitalize()}',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'This would navigate to the $category screen with filtered results.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.gold)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToTripPlanner() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.darkNavy,
//         title: Text(
//           'Trip Planner',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'This would open the AI-powered trip planning interface.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.gold)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToDetails(String title) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.darkNavy,
//         title: Text(
//           title,
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'This would show detailed information about $title including photos, reviews, booking options, etc.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.gold)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToSeeAll(String category) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.darkNavy,
//         title: Text(
//           category,
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'This would show all items in the $category category.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.gold)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _performSearch(String query) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.darkNavy,
//         title: Text(
//           'Search Results',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'Searching for: "$query"\n\nThis would show personalized search results based on your preferences.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.gold)),
//           ),
//         ],
//       ),
//     );
//   }

  // void _showChatDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: AppColors.darkNavy,
  //       title: Row(
  //         children: [
  //           Text('🤖', style: TextStyle(fontSize: 24)),
  //           SizedBox(width: 8),
  //           Text(
  //             'AI Assistant',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //         ],
  //       ),
  //       content: Text(
  //         'This would open the AI-powered chat interface where you can ask questions about Qatar, get recommendations, make bookings, etc.',
  //         style: TextStyle(color: Colors.white70),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Close', style: TextStyle(color: AppColors.gold)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

//   void _showProfileMenu() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.darkNavy,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Handle bar
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: 20),
            
//             // Profile header
//             Consumer<AuthService>(
//               builder: (context, authService, child) {
//                 final user = authService.currentUser;
//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: AppColors.gold,
//                     child: Text(
//                       user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
//                       style: TextStyle(
//                         color: AppColors.maroon,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     user?.displayName ?? 'User',
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     user?.email ?? 'Guest',
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 );
//               },
//             ),
            
//             Divider(color: Colors.white.withOpacity(0.2)),
            
//             // Menu items
//             _buildProfileMenuItem(Icons.person_outline, 'Edit Profile', () {}),
//             _buildProfileMenuItem(Icons.favorite_outline, 'Favorites', () {}),
//             _buildProfileMenuItem(Icons.history, 'Trip History', () {}),
//             _buildProfileMenuItem(Icons.settings , 'Settings', () {}),
//             _buildProfileMenuItem(Icons.help_outline, 'Help & Support', () {}),
            
//             Divider(color: Colors.white.withOpacity(0.2)),
            
//             // Sign out
//             Consumer<AuthService>(
//               builder: (context, authService, child) {
//                 return _buildProfileMenuItem(
//                   Icons.logout,
//                   'Sign Out',
//                   () async {
//                     Navigator.pop(context);
//                     await authService.signOut();
//                     Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
//                   },
//                   isDestructive: true,
//                 );
//               },
//             ),
            
//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: isDestructive ? AppColors.error : Colors.white,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isDestructive ? AppColors.error : Colors.white,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }

// // Extension to capitalize strings
// extension StringExtension on String {
//   String capitalize() {
//     return "${this[0].toUpperCase()}${this.substring(1)}";
//   }
// }



// RED 

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../constants/app_theme.dart';
// import 'package:manara/services/user_services.dart';
// import 'package:manara/services/auth_services.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> 
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: AppDurations.medium,
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
    
//     _slideAnimation = Tween<Offset>(
//       begin: Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutCubic,
//     ));
    
//     _animationController.forward();
    
//     // Load user data on init
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<UserService>().loadUserPreferences();
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.darkNavy,
//       body: SafeArea(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 AppColors.maroon,
//                 AppColors.darkNavy,
//               ],
//             ),
//           ),
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: Column(
//                 children: [
//                   // Header
//                   _buildHeader(),
                  
//                   // Main Content
//                   Expanded(
//                     child: SingleChildScrollView(
//                       padding: AppStyles.defaultPadding,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Welcome Section
//                           _buildWelcomeSection(),
                          
//                           SizedBox(height: 32),
                          
//                           // Quick Stats
//                           _buildQuickStats(),
                          
//                           SizedBox(height: 32),
                          
//                           // Recent Activity
//                           _buildRecentActivity(),
                          
//                           SizedBox(height: 32),
                          
//                           // Recommendations
//                           _buildRecommendations(),
                          
//                           SizedBox(height: 32),
                          
//                           // Trip Planning Quick Access
//                           _buildTripPlanningSection(),
                          
//                           SizedBox(height: 100), // Space for bottom navigation
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
      
//       // Floating Action Button
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showQuickActions(),
//         backgroundColor: AppColors.gold,
//         foregroundColor: AppColors.maroon,
//         child: Icon(Icons.add, size: 28),
//       ),
      
//       // Bottom Navigation
//       bottomNavigationBar: _buildBottomNavigation(),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.all(24),
//       child: Row(
//         children: [
//           // App logo and title
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'مَنارة',
//                 style: GoogleFonts.amiri(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.gold,
//                 ),
//               ),
//               Text(
//                 'Dashboard',
//                 style: GoogleFonts.inter(
//                   fontSize: 16,
//                   color: Colors.white70,
//                 ),
//               ),
//             ],
//           ),
          
//           Spacer(),
          
//           // Profile and notifications
//           Row(
//             children: [
//               // Notifications
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: IconButton(
//                   onPressed: () => _showNotifications(),
//                   icon: Stack(
//                     children: [
//                       Icon(
//                         Icons.notifications_outlined,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                       Positioned(
//                         right: 0,
//                         top: 0,
//                         child: Container(
//                           width: 8,
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: AppColors.gold,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(width: 12),
              
//               // Profile button
//               Consumer<AuthService>(
//                 builder: (context, authService, child) {
//                   final user = authService.currentUser;
//                   return GestureDetector(
//                     onTap: () => _showProfileMenu(),
//                     child: Container(
//                       width: 48,
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: AppColors.gold,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.gold.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
//                           style: GoogleFonts.inter(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.maroon,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWelcomeSection() {
//     return Consumer<UserService>(
//       builder: (context, userService, child) {
//         return Container(
//           padding: EdgeInsets.all(24),
//           decoration: AppStyles.gradientContainer,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'مرحباً بك',
//                           style: GoogleFonts.amiri(
//                             fontSize: 20,
//                             color: AppColors.gold,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Consumer<AuthService>(
//                           builder: (context, authService, child) {
//                             return Text(
//                               'Welcome back, ${authService.currentUser?.displayName?.split(' ').first ?? 'Explorer'}!',
//                               style: GoogleFonts.inter(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             );
//                           },
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           _getWelcomeMessage(userService.userPreferences),
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Icon(
//                       Icons.emoji_people,
//                       color: AppColors.gold,
//                       size: 32,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildQuickStats() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Your Qatar Journey',
//           style: GoogleFonts.inter(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(child: _buildStatCard('12', 'Places\nVisited', Icons.location_on)),
//             SizedBox(width: 16),
//             Expanded(child: _buildStatCard('5', 'Trip Plans\nCreated', Icons.route)),
//             SizedBox(width: 16),
//             Expanded(child: _buildStatCard('8', 'Favorites\nSaved', Icons.favorite)),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(String number, String label, IconData icon) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppColors.primaryBlue,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             icon,
//             color: AppColors.gold,
//             size: 24,
//           ),
//           SizedBox(height: 12),
//           Text(
//             number,
//             style: GoogleFonts.inter(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             label,
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: Colors.white70,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentActivity() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Recent Activity',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             TextButton(
//               onPressed: () => _navigateToHistory(),
//               child: Text(
//                 'View All',
//                 style: GoogleFonts.inter(
//                   color: AppColors.gold,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 16),
//         _buildActivityItem(
//           'Visited Souq Waqif',
//           'Traditional Market • 2 days ago',
//           Icons.shopping_bag,
//           AppColors.success,
//         ),
//         _buildActivityItem(
//           'Saved The Pearl-Qatar',
//           'Added to favorites • 1 week ago',
//           Icons.favorite,
//           AppColors.gold,
//         ),
//         _buildActivityItem(
//           'Completed City Tour',
//           'West Bay exploration • 2 weeks ago',
//           Icons.tour,
//           AppColors.info,
//         ),
//       ],
//     );
//   }

//   Widget _buildActivityItem(String title, String subtitle, IconData icon, Color iconColor) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               icon,
//               color: iconColor,
//               size: 20,
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: GoogleFonts.inter(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: GoogleFonts.inter(
//                     fontSize: 14,
//                     color: Colors.white70,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Icon(
//             Icons.chevron_right,
//             color: Colors.white.withOpacity(0.3),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendations() {
//     return Consumer<UserService>(
//       builder: (context, userService, child) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Recommended for You',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 16),
//             Container(
//               height: 200,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _buildRecommendationCard(
//                     'Katara Cultural Village',
//                     'Art & Culture • Free Entry',
//                     '⭐ 4.7',
//                     'Perfect for culture lovers',
//                     AppColors.primaryBlue,
//                   ),
//                   SizedBox(width: 16),
//                   _buildRecommendationCard(
//                     'Doha Corniche',
//                     'Waterfront • Walking & Cycling',
//                     '⭐ 4.8',
//                     'Great for morning walks',
//                     AppColors.mediumGray,
//                   ),
//                   SizedBox(width: 16),
//                   _buildRecommendationCard(
//                     'Al Wakra Souq',
//                     'Traditional Market • Local Food',
//                     '⭐ 4.5',
//                     'Authentic Qatar experience',
//                     AppColors.darkPurple,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildRecommendationCard(
//     String title,
//     String subtitle,
//     String rating,
//     String description,
//     Color backgroundColor,
//   ) {
//     return Container(
//       width: 280,
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: GoogleFonts.inter(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               Text(
//                 rating,
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: AppColors.gold,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: GoogleFonts.inter(
//               fontSize: 14,
//               color: Colors.white70,
//             ),
//           ),
//           Spacer(),
//           Text(
//             description,
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: AppColors.gold,
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//           SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: () => _navigateToPlace(title),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.gold,
//               foregroundColor: AppColors.maroon,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               minimumSize: Size(double.infinity, 36),
//             ),
//             child: Text(
//               'Explore',
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTripPlanningSection() {
//     return Container(
//       padding: EdgeInsets.all(24),
//       decoration: AppStyles.goldGradientContainer,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.lightbulb_outline,
//                 color: AppColors.maroon,
//                 size: 28,
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   'Plan Your Next Adventure',
//                   style: GoogleFonts.inter(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.maroon,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Text(
//             'Let our AI create a personalized itinerary based on your preferences and available time.',
//             style: GoogleFonts.inter(
//               fontSize: 16,
//               color: AppColors.maroon.withOpacity(0.8),
//             ),
//           ),
//           SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _navigateToTripPlanner(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.maroon,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: Text(
//                     'Create Trip Plan',
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => _navigateToSavedTrips(),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: AppColors.maroon,
//                   side: BorderSide(color: AppColors.maroon),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                 ),
//                 child: Icon(Icons.bookmark_outline),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigation() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.darkPurple,
//         border: Border(
//           top: BorderSide(
//             color: Colors.white.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: 0,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.transparent,
//         selectedItemColor: AppColors.gold,
//         unselectedItemColor: AppColors.mediumGray,
//         elevation: 0,
//         selectedFontSize: 12,
//         unselectedFontSize: 12,
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.explore),
//             label: 'Explore',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.route),
//             label: 'My Trips',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'AI Chat',
//           ),
//         ],
//         onTap: (index) => _handleNavigation(index),
//       ),
//     );
//   }

//   // Helper methods
//   String _getWelcomeMessage(UserPreferences? preferences) {
//     if (preferences == null) return 'Ready to explore Qatar today?';
    
//     switch (preferences.visitPurpose) {
//       case 'business':
//         return 'Make the most of your business trip!';
//       case 'vacation':
//         return 'Your Qatar adventure awaits!';
//       case 'family':
//         return 'Enjoy your time with loved ones!';
//       case 'transit':
//         return 'Perfect layover activities for you!';
//       case 'resident':
//         return 'Discover new places in your city!';
//       default:
//         return 'Ready to explore Qatar today?';
//     }
//   }

  // void _handleNavigation(int index) {
  //   switch (index) {
  //     case 0:
  //       // Already on dashboard
  //       break;
  //     case 1:
  //       Navigator.pushNamed(context, '/explore');
  //       break;
  //     case 2:
  //       Navigator.pushNamed(context, '/trips');
  //       break;
  //     case 3:
  //       Navigator.pushNamed(context, '/chat');
  //       break;
  //   }
  // }

//   void _showQuickActions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.darkNavy,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Handle bar
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: 20),
            
//             Text(
//               'Quick Actions',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 24),
            
//             Row(
//               children: [
//                 Expanded(child: _buildQuickActionButton('🗺️', 'Plan Trip', () {})),
//                 SizedBox(width: 16),
//                 Expanded(child: _buildQuickActionButton('📍', 'Add Place', () {})),
//               ],
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(child: _buildQuickActionButton('💬', 'Ask AI', () {})),
//                 SizedBox(width: 16),
//                 Expanded(child: _buildQuickActionButton('📸', 'Share Photo', () {})),
//               ],
//             ),
//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActionButton(String emoji, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 20),
//         decoration: BoxDecoration(
//           color: AppColors.primaryBlue,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.1),
//           ),
//         ),
//         child: Column(
//           children: [
//             Text(emoji, style: TextStyle(fontSize: 32)),
//             SizedBox(height: 8),
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showNotifications() {
//     // Navigate to notifications screen
//   }

//   void _showProfileMenu() {
//     // Navigate to profile screen
//   }

//   void _navigateToHistory() {
//     // Navigate to activity history
//   }

//   void _navigateToPlace(String placeName) {
//     // Navigate to place details
//   }

//   void _navigateToTripPlanner() {
//     // Navigate to trip planning screen
//   }

//   void _navigateToSavedTrips() {
//     // Navigate to saved trips
//   }
// }
// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import 'package:manara/services/auth_services.dart';
import '../../services/ai_recommendation_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
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
    final authService = context.read<AuthService>();
    
    _aiService = AIRecommendationService(userService, authService);
    
    // Add as provider for the widget tree
    // Note: In a real app, you'd want to add this at the app level
    
    // Load all recommendations
    _aiService!.loadAllRecommendations();
    
    // Listen to changes
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
    return Scaffold(
      appBar: AppBar(
        title: _buildHeader(),
        backgroundColor: AppColors.primaryBlue,
      ),
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Container(
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
                        // Welcome Section
                          _buildWelcomeSection(),
                        
                         SizedBox(height: 32),
                          
                          // Quick Stats
                          _buildQuickActions(),

                          SizedBox(height: 32),

                          // Trip Planning Quick Access
                          _buildTripPlanningSection(),
                          
                          SizedBox(height: 32),
                                                
                        // Loading indicator or recommendations
                        if (_aiService?.isLoading == true)
                          _buildLoadingSection()
                        else ...[
                          // Trending Now Section
                          if (_aiService?.trendingRecommendations.isNotEmpty == true)
                            _buildRecommendationSection(
                              'Trending Now',
                              _aiService!.trendingRecommendations,
                            ),
                          
                          SizedBox(height: 32),
                          
                          // Personalized Recommendations
                          if (_aiService?.personalizedRecommendations.isNotEmpty == true)
                            _buildRecommendationSection(
                              _aiService?.getPersonalizedSectionTitle() ?? 'Recommended for You',
                              _aiService!.personalizedRecommendations,
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
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
      
      // Floating Action Button for Chat
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _showAIChatDialog();
      //   },
      //   backgroundColor: AppColors.primaryBlue,
      //   child: Text('🤖', style: TextStyle(fontSize: 24)),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [AppColors.primaryBlue, AppColors.mediumGray],
  //       ),
  //     ),
  //     child: Stack(
  //       children: [
  //         // Background circle
  //         Positioned(
  //           top: -50,
  //           right: -20,
  //           child: Container(
  //             width: 200,
  //             height: 200,
  //             decoration: BoxDecoration(
  //               color: Colors.white.withOpacity(0.1),
  //               shape: BoxShape.circle,
  //             ),
  //           ),
  //         ),
  //         // Header content
  //         Padding(
  //           padding: EdgeInsets.all(20),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           _aiService?.getPersonalizedWelcomeMessage() ?? 'مرحباً • Welcome',
  //                           style: TextStyle(
  //                             color: Colors.white.withOpacity(0.8),
  //                             fontSize: 16,
  //                           ),
  //                         ),
  //                         SizedBox(height: 5),
  //                         Text(
  //                           'Discover Qatar',
  //                           style: TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 24,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   // Profile/Settings button
  //                   Container(
  //                     decoration: BoxDecoration(
  //                       color: Colors.white.withOpacity(0.2),
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     child: IconButton(
  //                       onPressed: () => _showProfileMenu(),
  //                       icon: Icon(
  //                         Icons.person_outline,
  //                         color: Colors.white,
  //                         size: 24,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 15),
  //               // Search bar
  //               Container(
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.15),
  //                   borderRadius: BorderRadius.circular(25),
  //                   border: Border.all(
  //                     color: Colors.white.withOpacity(0.2),
  //                   ),
  //                 ),
  //                 child: TextField(
  //                   controller: _searchController,
  //                   style: TextStyle(color: Colors.white),
  //                   decoration: InputDecoration(
  //                     hintText: 'Search places, food, experiences...',
  //                     hintStyle: TextStyle(
  //                       color: Colors.white.withOpacity(0.7),
  //                     ),
  //                     border: InputBorder.none,
  //                     contentPadding: EdgeInsets.symmetric(
  //                       horizontal: 20,
  //                       vertical: 15,
  //                     ),
  //                     prefixIcon: Icon(
  //                       Icons.search,
  //                       color: Colors.white.withOpacity(0.7),
  //                     ),
  //                   ),
  //                   onSubmitted: (value) {
  //                     if (value.isNotEmpty) {
  //                       _performAISearch(value);
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
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
          
          // Profile and notifications
          Row(
            children: [
              // Notifications
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: IconButton(
              //     onPressed: () => _showNotifications(),
              //     icon: Stack(
              //       children: [
              //         Icon(
              //           Icons.notifications_outlined,
              //           color: Colors.white,
              //           size: 24,
              //         ),
              //         Positioned(
              //           right: 0,
              //           top: 0,
              //           child: Container(
              //             width: 8,
              //             height: 8,
              //             decoration: BoxDecoration(
              //               color: AppColors.gold,
              //               shape: BoxShape.circle,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
                            
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
          'Your Qatar Journey',
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
            SizedBox(width: 18),
            Expanded(child: _buildActionButton(Icons.account_balance_sharp, 'Attractions')),
            SizedBox(width: 18),
            Expanded(child: _buildActionButton(Icons.shopping_bag_outlined, 'Shopping')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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
  Widget _buildRecommendationSection(String title, List<RecommendationItem> items) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        SizedBox(height: 16),
        Container(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // padding: EdgeInsets.symmetric(horizontal: 20),
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
      margin: EdgeInsets.symmetric( vertical: 10),
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

  // Widget _buildQuickActions() {
  //   return Container(
  //     padding: EdgeInsets.all(20),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildActionButton('🍽️', 'Restaurants'),
  //         _buildActionButton('🏛️', 'Attractions'),
  //         _buildActionButton('🛍️', 'Shopping'),
  //         _buildActionButton('☕', 'Cafés'),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildActionButton(String icon, String label) {
  //   return Expanded(
  //     child: Container(
  //       margin: EdgeInsets.symmetric(horizontal: 7.5),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           onTap: () => _navigateToCategory(label.toLowerCase()),
  //           borderRadius: BorderRadius.circular(16),
  //           child: Container(
  //             decoration: AppStyles.gradientContainer,
  //             padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
  //             child: Column(
  //               children: [
  //                 Text(
  //                   icon,
  //                   style: TextStyle(fontSize: 24),
  //                 ),
  //                 SizedBox(height: 8),
  //                 Text(
  //                   label,
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTripPlanner() {
  //   return Container(
  //     margin: EdgeInsets.symmetric(horizontal: 20),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [AppColors.mediumGray, AppColors.primaryBlue],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Stack(
  //       children: [
  //         Positioned(
  //           top: -30,
  //           left: -30,
  //           child: Container(
  //             width: 80,
  //             height: 80,
  //             decoration: BoxDecoration(
  //               color: Colors.white.withOpacity(0.15),
  //               shape: BoxShape.circle,
  //             ),
  //           ),
  //         ),
  //         Padding(
  //           padding: EdgeInsets.all(20),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Plan Your Perfect Day',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               SizedBox(height: 10),
  //               Text(
  //                 'AI-powered itinerary based on your preferences',
  //                 style: TextStyle(
  //                   color: Colors.white.withOpacity(0.9),
  //                   fontSize: 14,
  //                 ),
  //               ),
  //               SizedBox(height: 15),
  //               ElevatedButton(
  //                 onPressed: () => _navigateToAITripPlanner(),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.white.withOpacity(0.15),
  //                   side: BorderSide(
  //                     color: Colors.white.withOpacity(0.3),
  //                   ),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(25),
  //                   ),
  //                 ),
  //                 child: Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: 20,
  //                     vertical: 12,
  //                   ),
  //                   child: Text(
  //                     'Create Trip Plan',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
Widget _buildTripPlanningSection() {
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
                  'Plan Your Next Adventure',
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
                  child: Text(
                    'Create Trip Plan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            ],
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
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.mediumGray,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Day Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: 'Profile',
          ),
        ],
        onTap: (index) => _handleNavigation(index),
      ),
    );
  }

  // Navigation and action methods
  Future<void> _refreshRecommendations() async {
    await _aiService?.refreshRecommendations();
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        _navigateToAITripPlanner();
        break;
      case 2:
        _showAIChatDialog();
        break;
      case 3:
        _showProfileMenu();
        break;
    }
  }

  void _navigateToCategory(String category) async {
    if (_aiService != null) {
      String query = 'best $category in Qatar';
      final results = await _aiService!.searchRecommendations(query);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: Text(
            '${category.capitalize()} Recommendations',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: results.isNotEmpty
                ? ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${item.location} • ${item.priceRange}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '⭐ ${item.rating.toStringAsFixed(1)}',
                          style: TextStyle(color: AppColors.gold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDetails(item);
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No recommendations found',
                      style: TextStyle(color: Colors.white70),
                    ),
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

  void _navigateToAITripPlanner() async {
    if (_aiService != null) {
      final userService = context.read<UserService>();
      String query = 'plan a perfect day in Qatar';
      
      // Add user context to the query
      if (userService.userPreferences != null) {
        final prefs = userService.userPreferences!;
        query += ' for ${prefs.visitPurpose} with ${prefs.budgetRange} budget';
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
              SizedBox(width: 20),
              Text(
                'Creating your perfect day plan...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      final dayPlan = await _aiService!.createDayPlan(query);
      Navigator.pop(context); // Close loading dialog

      if (dayPlan != null) {
        _showDayPlanDialog(dayPlan);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create day plan. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDayPlanDialog(Map<String, dynamic> dayPlan) {
    final plan = dayPlan['day_plan'];
    final activities = plan['activities'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          plan['title'] ?? 'Your Day Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Cost: ${plan['total_estimated_cost']} • Duration: ${plan['total_duration']}',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Card(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    activity['time'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.maroon,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activity['activity'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              activity['description'] ?? '',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '📍 ${activity['location']} • 💰 ${activity['estimated_cost']} • ⏱️ ${activity['duration']}',
                              style: TextStyle(color: AppColors.gold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement save plan functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Day plan saved!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Save Plan'),
          ),
        ],
      ),
    );
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
              SizedBox(height: 12),
              Text(
                'Best time to visit: ${item.bestTimeToVisit}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              Text(
                'Estimated duration: ${item.estimatedDuration}',
                style: TextStyle(color: Colors.white70),
              ),
              if (item.features.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Features:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: item.features.map((feature) => Chip(
                    label: Text(
                      feature.replaceAll('_', ' ').toLowerCase(),
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.7),
                    labelStyle: TextStyle(color: Colors.white),
                  )).toList(),
                ),
              ],
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
        title: Text(
          'Book ${item.name}',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would open the booking interface for ${item.name}. Integration with actual booking systems would be implemented here.',
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
    // This would navigate to a full screen showing all items in the category
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          category,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would show all items in the $category category with filtering and sorting options.',
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

  Future<void> _performAISearch(String query) async {
    if (_aiService != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
              SizedBox(width: 20),
              Text(
                'Searching...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      final results = await _aiService!.searchRecommendations(query);
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: Text(
            'Search Results for "$query"',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: results.isNotEmpty
                ? ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${item.location} • ${item.priceRange}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '⭐ ${item.rating.toStringAsFixed(1)}',
                          style: TextStyle(color: AppColors.gold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDetails(item);
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No results found for "$query"',
                      style: TextStyle(color: Colors.white70),
                    ),
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

  void _showAIChatDialog() {
    showDialog(
      context: context,
      builder: (context) => _AIChatDialog(aiService: _aiService),
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
            _buildProfileMenuItem(Icons.settings, 'Settings', () {}),
            _buildProfileMenuItem(Icons.help_outline, 'Help & Support', () {}),
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            // Refresh recommendations
            // _buildProfileMenuItem(
            //   Icons.refresh,
            //   'Refresh Recommendations',
            //   () {
            //     Navigator.pop(context);
            //     _refreshRecommendations();
            //   },
            // ),
            
            // Divider(color: Colors.white.withOpacity(0.2)),
            
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

// AI Chat Dialog Widget
class _AIChatDialog extends StatefulWidget {
  final AIRecommendationService? aiService;

  const _AIChatDialog({Key? key, this.aiService}) : super(key: key);

  @override
  _AIChatDialogState createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<_AIChatDialog> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'ai',
      'message': 'Hi! I\'m your AI guide for Qatar. How can I help you today?',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            // Messages
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isAI = message['sender'] == 'ai';
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (isAI) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.gold,
                            child: Text('🤖', style: TextStyle(fontSize: 16)),
                          ),
                          SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAI 
                                  ? AppColors.primaryBlue.withOpacity(0.7)
                                  : AppColors.gold.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['message'] ?? '',
                              style: TextStyle(
                                color: isAI ? Colors.white : AppColors.maroon,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        if (!isAI) ...[
                          SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.mediumGray,
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            
            if (_isLoading)
              Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI is thinking...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about places, food, activities...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: AppColors.gold),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: _isLoading ? null : () => _sendMessage(_chatController.text),
                  backgroundColor: AppColors.gold,
                  child: Icon(Icons.send, color: AppColors.maroon),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _isLoading = true;
    });

    _chatController.clear();

    try {
      final response = await widget.aiService?.getChatResponse(message) ?? 
          'I\'m here to help you explore Qatar! What would you like to know?';
      
      setState(() {
        _messages.add({'sender': 'ai', 'message': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai', 
          'message': 'Sorry, I\'m having trouble connecting right now. Please try again.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}