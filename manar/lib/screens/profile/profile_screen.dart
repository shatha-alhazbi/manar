// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import 'package:manara/services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        child: SingleChildScrollView(
          padding: AppStyles.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(),
              
              SizedBox(height: 32),
              
              // Stats Section
              _buildStatsSection(),
              
              SizedBox(height: 32),
              
              // Quick Actions
              _buildQuickActions(),
              
              SizedBox(height: 32),
              
              // Preferences Section
              _buildPreferencesSection(),
              
              SizedBox(height: 32),
              
              // Account Settings
              _buildAccountSettings(),
              
              SizedBox(height: 32),
              
              // Support & Info
              _buildSupportSection(),
              
              SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        return Container(
          padding: EdgeInsets.all(24),
          decoration: AppStyles.gradientContainer,
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // User Info
              Text(
                user?.displayName ?? 'User Name',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                user?.email ?? 'user@example.com',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Membership badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppColors.gold, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Explorer Member',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _editProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
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
            Expanded(child: _buildStatCard('15', 'Places\nVisited', Icons.location_on, AppColors.success)),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('8', 'Bookings\nMade', Icons.book_online, AppColors.info)),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('12', 'Reviews\nWritten', Icons.star, AppColors.warning)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 12),
          Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard('❤️', 'Favorites', 'Saved places', () => _showFavorites()),
            _buildActionCard('📝', 'Reviews', 'Your ratings', () => _showReviews()),
            _buildActionCard('🎯', 'Preferences', 'Update interests', () => _updatePreferences()),
            _buildActionCard('🏆', 'Achievements', 'View badges', () => _showAchievements()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String emoji, String title, String subtitle, VoidCallback onTap) {
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

  Widget _buildPreferencesSection() {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final preferences = userService.userPreferences;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => _updatePreferences(),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (preferences != null) ...[
              _buildPreferenceItem('Visit Purpose', _getVisitPurposeText(preferences.visitPurpose)),
              _buildPreferenceItem('Budget Range', _getBudgetText(preferences.budgetRange)),
              _buildPreferenceItem('Interests', preferences.interests.join(', ')),
              _buildPreferenceItem('Cuisine Preferences', preferences.cuisinePreferences.join(', ')),
              _buildPreferenceItem('Transport Mode', _getTransportText(preferences.transportMode)),
            ] else ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.settings, color: AppColors.gold, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'No preferences set',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set your preferences to get personalized recommendations',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _updatePreferences(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.maroon,
                      ),
                      child: Text('Set Preferences'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPreferenceItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        
        _buildSettingsItem(Icons.notifications_outlined, 'Notifications', 'Manage your alerts', () => _manageNotifications()),
        _buildSettingsItem(Icons.language_outlined, 'Language', 'English (العربية)', () => _changeLanguage()),
        _buildSettingsItem(Icons.location_on_outlined, 'Location Services', 'Allow location access', () => _manageLocation()),
        _buildSettingsItem(Icons.security_outlined, 'Privacy & Security', 'Manage your data', () => _managePrivacy()),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & Information',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        
        _buildSettingsItem(Icons.help_outline, 'Help Center', 'Get support and answers', () => _showHelpCenter()),
        _buildSettingsItem(Icons.feedback_outlined, 'Send Feedback', 'Help us improve', () => _sendFeedback()),
        _buildSettingsItem(Icons.info_outline, 'About Manara', 'App version and info', () => _showAbout()),
        _buildSettingsItem(Icons.description_outlined, 'Terms & Privacy', 'Legal information', () => _showTerms()),
        
        SizedBox(height: 24),
        
        // Sign Out Button
        SizedBox(
          width: double.infinity,
          child: Consumer<AuthService>(
            builder: (context, authService, child) {
              return ElevatedButton(
                onPressed: () => _showSignOutDialog(authService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.gold,
                    size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // Helper methods for text conversion
  String _getVisitPurposeText(String purpose) {
    switch (purpose) {
      case 'business': return 'Business Travel';
      case 'vacation': return 'Vacation';
      case 'family': return 'Family Visit';
      case 'transit': return 'Transit/Stopover';
      case 'resident': return 'Living Here';
      default: return purpose;
    }
  }

  String _getBudgetText(String budget) {
    switch (budget) {
      case 'budget': return 'Budget-Friendly (\$)';
      case 'mid_range': return 'Mid-Range (\$\$)';
      case 'premium': return 'Premium (\$\$\$)';
      default: return budget;
    }
  }

  String _getTransportText(String transport) {
    switch (transport) {
      case 'public': return 'Public Transport';
      case 'taxi': return 'Taxi/Ride-sharing';
      case 'car': return 'Rental Car';
      case 'tour': return 'Tour Groups';
      default: return transport;
    }
  }

  // Action methods
  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the profile editing interface where you can update your name, email, and photo.',
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

  void _showFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Your Favorites', style: TextStyle(color: Colors.white)),
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

  void _showReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Your Reviews', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would show all the reviews and ratings you\'ve written for places you\'ve visited.',
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

  void _updatePreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Update Preferences', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the preferences flow to update your interests, budget, and travel style.',
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

  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Achievements', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would show your badges and achievements for exploring Qatar.',
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

  void _manageNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Notification Settings', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open notification preferences where you can control what alerts you receive.',
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

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Language Settings', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would allow you to switch between English and Arabic.',
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

  void _manageLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Location Services', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would manage location permissions for better recommendations.',
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

  void _managePrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would show privacy settings and data management options.',
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

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Help Center', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the help center with FAQs and support contact information.',
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

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Send Feedback', style: TextStyle(color: Colors.white)),
        content: TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tell us how we can improve Manara...',
            hintStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('About Manara', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مَنارة', style: GoogleFonts.amiri(fontSize: 24, color: AppColors.gold, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text(
              'Your AI-powered guide to discovering the best of Qatar. From traditional souqs to modern attractions, we help you explore Qatar like a local.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
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

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Terms & Privacy', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would show the terms of service and privacy policy documents.',
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

  void _showSignOutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  }