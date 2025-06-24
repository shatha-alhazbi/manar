// screens/onboarding/onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';
import '../../widgets/common/loading_overlay.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // User selections
  String _visitPurpose = '';
  String _budgetRange = '';
  List<String> _interests = [];
  List<String> _cuisinePreferences = [];
  String _transportMode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          return LoadingOverlay(
            isLoading: userService.isLoading,
            child:
            //  SafeArea(
            //   child: 
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryBlue, AppColors.darkNavy],
                  ),
                ),
                child: Column(
                  children: [
                    _buildProgressHeader(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildVisitPurposeStep(),
                          _buildBudgetStep(),
                          _buildInterestsStep(),
                          _buildCuisineStep(),
                          _buildTransportStep(),
                        ],
                      ),
                    ),
                    _buildNavigationButtons(userService),
                     SizedBox(height: 5),
                  ],
                ),
              ),
            // ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: AppStyles.defaultPadding,
      child: Column(
        children: [
          SizedBox(height: 40),
          Row(
            children: [
              Text(
                'مَنار',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              Spacer(),
              Text(
                'Step ${_currentStep + 1} of 5',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Progress indicator
          Row(
            children: List.generate(5, (index) {
              bool isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.gold : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitPurposeStep() {
    return _buildStepContainer(
      title: 'What brings you to Qatar?',
      subtitle: 'Help us understand your visit to give you the best recommendations',
      child: Column(
        children: [
          _buildOptionCard(
            icon: Icons.business_center,
            title: 'Business Travel',
            subtitle: 'Here for work or conferences',
            isSelected: _visitPurpose == 'business',
            onTap: () => setState(() => _visitPurpose = 'business'),
          ),
          _buildOptionCard(
            icon: Icons.beach_access,
            title: 'Vacation',
            subtitle: 'Leisure travel and sightseeing',
            isSelected: _visitPurpose == 'vacation',
            onTap: () => setState(() => _visitPurpose = 'vacation'),
          ),
          _buildOptionCard(
            icon: Icons.family_restroom,
            title: 'Family Visit',
            subtitle: 'Visiting family or friends',
            isSelected: _visitPurpose == 'family',
            onTap: () => setState(() => _visitPurpose = 'family'),
          ),
          _buildOptionCard(
            icon: Icons.flight_takeoff,
            title: 'Transit/Stopover',
            subtitle: 'Short layover or connecting flight',
            isSelected: _visitPurpose == 'transit',
            onTap: () => setState(() => _visitPurpose = 'transit'),
          ),
          _buildOptionCard(
            icon: Icons.home,
            title: 'Living Here',
            subtitle: 'Resident looking for new places',
            isSelected: _visitPurpose == 'resident',
            onTap: () => setState(() => _visitPurpose = 'resident'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStep() {
    return _buildStepContainer(
      title: 'What\'s your budget range?',
      subtitle: 'For dining and activities per day',
      child: Column(
        children: [
          _buildBudgetCard(
            symbol: '\$',
            title: 'Budget-Friendly',
            subtitle: 'Under QR 100 per day',
            description: 'Street food, local cafes, free attractions',
            isSelected: _budgetRange == 'budget',
            onTap: () => setState(() => _budgetRange = 'budget'),
          ),
          _buildBudgetCard(
            symbol: '\$\$',
            title: 'Mid-Range',
            subtitle: 'QR 100-300 per day',
            description: 'Good restaurants, paid attractions',
            isSelected: _budgetRange == 'mid_range',
            onTap: () => setState(() => _budgetRange = 'mid_range'),
          ),
          _buildBudgetCard(
            symbol: '\$\$\$',
            title: 'Premium',
            subtitle: 'QR 300+ per day',
            description: 'Fine dining, luxury experiences',
            isSelected: _budgetRange == 'premium',
            onTap: () => setState(() => _budgetRange = 'premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    final interests = [
      {'icon': Icons.mosque, 'title': 'Traditional Culture', 'key': 'culture'},
      {'icon': Icons.location_city, 'title': 'Modern Attractions', 'key': 'modern'},
      {'icon': Icons.restaurant, 'title': 'Food & Dining', 'key': 'food'},
      {'icon': Icons.shopping_bag, 'title': 'Shopping & Markets', 'key': 'shopping'},
      {'icon': Icons.palette, 'title': 'Art & Museums', 'key': 'art'},
      {'icon': Icons.sports_soccer, 'title': 'Sports & Adventure', 'key': 'sports'},
    ];

    return _buildStepContainer(
      title: 'What interests you most?',
      subtitle: 'Select all that apply - we\'ll personalize your experience',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: interests.map((interest) {
          bool isSelected = _interests.contains(interest['key']);
          return _buildInterestChip(
            icon: interest['icon'] as IconData,
            title: interest['title'] as String,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _interests.remove(interest['key']);
                } else {
                  _interests.add(interest['key'] as String);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCuisineStep() {
    final cuisines = [
      {'title': 'Traditional Qatari/Gulf', 'key': 'qatari'},
      {'title': 'Middle Eastern', 'key': 'middle_eastern'},
      {'title': 'International', 'key': 'international'},
      {'title': 'Healthy/Vegetarian', 'key': 'healthy'},
      {'title': 'Street Food & Local', 'key': 'street_food'},
    ];

    return _buildStepContainer(
      title: 'What\'s your cuisine style?',
      subtitle: 'Select your preferred food types',
      child: Column(
        children: cuisines.map((cuisine) {
          bool isSelected = _cuisinePreferences.contains(cuisine['key']);
          return _buildCuisineOption(
            title: cuisine['title'] as String,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _cuisinePreferences.remove(cuisine['key']);
                } else {
                  _cuisinePreferences.add(cuisine['key'] as String);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransportStep() {
    return _buildStepContainer(
      title: 'How do you prefer to get around?',
      subtitle: 'This helps us suggest nearby attractions',
      child: Column(
        children: [
          _buildOptionCard(
            icon: Icons.directions_walk,
            title: 'Walking + Public Transport',
            subtitle: 'Metro, buses, short walks',
            isSelected: _transportMode == 'public',
            onTap: () => setState(() => _transportMode = 'public'),
          ),
          _buildOptionCard(
            icon: Icons.local_taxi,
            title: 'Taxi/Ride-sharing',
            subtitle: 'Karwa, Uber, convenient door-to-door',
            isSelected: _transportMode == 'taxi',
            onTap: () => setState(() => _transportMode = 'taxi'),
          ),
          _buildOptionCard(
            icon: Icons.car_rental,
            title: 'Rental Car',
            subtitle: 'Drive yourself, more flexibility',
            isSelected: _transportMode == 'car',
            onTap: () => setState(() => _transportMode = 'car'),
          ),
          _buildOptionCard(
            icon: Icons.group,
            title: 'Tour Groups',
            subtitle: 'Organized tours and group activities',
            isSelected: _transportMode == 'tour',
            onTap: () => setState(() => _transportMode = 'tour'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: AppStyles.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.gold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.gold
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.maroon : Colors.white,
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
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.gold,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard({
    required String symbol,
    required String title,
    required String subtitle,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.gold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.gold
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        symbol,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.maroon : Colors.white,
                        ),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.gold,
                        size: 28,
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestChip({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.gold.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.gold : Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuisineOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.gold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.gold,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(UserService userService) {
    return Container(
      padding: AppStyles.defaultPadding,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text('Back'),
              ),
            ),
          
          if (_currentStep > 0) SizedBox(width: 16),
          
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _canProceed() && !userService.isLoading
                  ? () => _handleNextStep(userService)
                  : null,
              child: Text(
                _currentStep < 4 ? 'Continue' : 'Complete Setup',
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _visitPurpose.isNotEmpty;
      case 1:
        return _budgetRange.isNotEmpty;
      case 2:
        return _interests.isNotEmpty;
      case 3:
        return _cuisinePreferences.isNotEmpty;
      case 4:
        return _transportMode.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleNextStep(UserService userService) async {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final step - save preferences
      final preferences = UserPreferences(
        visitPurpose: _visitPurpose,
        budgetRange: _budgetRange,
        interests: _interests,
        cuisinePreferences: _cuisinePreferences,
        transportMode: _transportMode,
      );
      
      bool success = await userService.saveUserPreferences(preferences);
      
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userService.errorMessage ?? 'Failed to save preferences'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}