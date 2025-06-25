// screens/planner/day_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';

class DayPlannerScreen extends StatefulWidget {
  @override
  _DayPlannerScreenState createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends State<DayPlannerScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedDuration = '4_hours';
  String _selectedBudget = 'mid_range';
  List<String> _selectedInterests = [];
  bool _isGeneratingPlan = false;
  
  final List<Map<String, dynamic>> _savedPlans = [
    {
      'title': 'Cultural Heritage Tour',
      'date': 'Today',
      'duration': '6 hours',
      'places': 4,
      'status': 'active',
    },
    {
      'title': 'Food & Shopping Adventure',
      'date': 'Yesterday',
      'duration': '4 hours', 
      'places': 3,
      'status': 'completed',
    },
    {
      'title': 'Modern Doha Experience',
      'date': '2 days ago',
      'duration': '8 hours',
      'places': 6,
      'status': 'completed',
    },
  ];

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
              // Header
              _buildHeader(),
              
              SizedBox(height: 24),
              
              // Quick Plan Generator
              _buildQuickPlanGenerator(),
              
              SizedBox(height: 32),
              
              // Saved Plans
              _buildSavedPlans(),
              
              SizedBox(height: 32),
              
              // Plan Templates
              _buildPlanTemplates(),
              
              SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day Planner',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Create personalized itineraries with AI',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPlanGenerator() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppStyles.goldGradientContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.maroon,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Generate New Plan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroon,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Duration Selection
          Text(
            'How much time do you have?',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.maroon,
            ),
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildDurationOption('2_hours', '2 Hours', 'Quick visit')),
              SizedBox(width: 8),
              Expanded(child: _buildDurationOption('4_hours', '4 Hours', 'Half day')),
              SizedBox(width: 8),
              Expanded(child: _buildDurationOption('8_hours', '8 Hours', 'Full day')),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Budget Selection
          Text(
            'Budget preference?',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.maroon,
            ),
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildBudgetOption('budget', '\$', 'Budget')),
              SizedBox(width: 8),
              Expanded(child: _buildBudgetOption('mid_range', '\$\$', 'Mid-range')),
              SizedBox(width: 8),
              Expanded(child: _buildBudgetOption('premium', '\$\$\$', 'Premium')),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGeneratingPlan ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGeneratingPlan
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating Plan...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Generate AI Plan',
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
    );
  }

  Widget _buildDurationOption(String value, String title, String subtitle) {
    bool isSelected = _selectedDuration == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.maroon.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.maroon
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.maroon.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOption(String value, String symbol, String title) {
    bool isSelected = _selectedBudget == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedBudget = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.maroon.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.maroon
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.maroon.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Plans',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _showAllPlans(),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        ..._savedPlans.take(3).map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    Color statusColor = plan['status'] == 'active' 
        ? AppColors.success 
        : plan['status'] == 'completed' 
            ? AppColors.info 
            : AppColors.mediumGray;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewPlan(plan),
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan['title'],
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan['status'].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      plan['date'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      plan['duration'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.location_on, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${plan['places']} places',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTemplates() {
    final templates = [
      {
        'title': 'Cultural Heritage',
        'subtitle': 'Museums, souqs, and traditions',
        'duration': '6-8 hours',
        'icon': Icons.museum,
        'color': AppColors.primaryBlue,
      },
      {
        'title': 'Modern Qatar',
        'subtitle': 'Skyscrapers, malls, and luxury',
        'duration': '4-6 hours',
        'icon': Icons.location_city,
        'color': AppColors.mediumGray,
      },
      {
        'title': 'Food Adventure',
        'subtitle': 'Local cuisine and hidden gems',
        'duration': '3-5 hours',
        'icon': Icons.restaurant,
        'color': AppColors.darkPurple,
      },
      {
        'title': 'Family Fun',
        'subtitle': 'Parks, activities, and entertainment',
        'duration': '5-7 hours',
        'icon': Icons.family_restroom,
        'color': AppColors.primaryBlue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Templates',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Quick start with pre-made itineraries',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        
        SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _buildTemplateCard(template);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _useTemplate(template),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: template['color'],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    template['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  template['title'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  template['subtitle'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                
                Spacer(),
                
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text(
                      template['duration'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Action methods
  void _generatePlan() async {
    setState(() => _isGeneratingPlan = true);
    
    // Simulate AI plan generation
    await Future.delayed(Duration(seconds: 3));
    
    setState(() => _isGeneratingPlan = false);
    
    _showGeneratedPlan();
  }

  void _showGeneratedPlan() {
    final samplePlan = {
      'title': 'Your Perfect Day in Qatar',
      'total_duration': '${_selectedDuration.replaceAll('_', ' ')}',
      'total_cost': _selectedBudget == 'budget' ? 'QR 80-120' : 
                   _selectedBudget == 'mid_range' ? 'QR 200-300' : 'QR 400-600',
      'activities': [
        {
          'time': '9:00 AM',
          'activity': 'Museum of Islamic Art',
          'description': 'Explore world-class Islamic art collection',
          'location': 'Corniche',
          'duration': '2 hours',
          'cost': _selectedBudget == 'budget' ? 'Free' : 'QR 25',
        },
        {
          'time': '11:30 AM',
          'activity': 'Souq Waqif',
          'description': 'Traditional market with local crafts and spices',
          'location': 'Old Doha',
          'duration': '1.5 hours',
          'cost': _selectedBudget == 'budget' ? 'QR 50' : 'QR 100',
        },
        {
          'time': '1:00 PM',
          'activity': 'Local Restaurant',
          'description': 'Authentic Qatari cuisine experience',
          'location': 'Souq Waqif',
          'duration': '1 hour',
          'cost': _selectedBudget == 'budget' ? 'QR 40' : 'QR 80',
        },
        if (_selectedDuration != '2_hours') {
          'time': '3:00 PM',
          'activity': 'The Pearl-Qatar',
          'description': 'Luxury shopping and waterfront views',
          'location': 'The Pearl',
          'duration': '2 hours',
          'cost': _selectedBudget == 'budget' ? 'Free' : 'QR 50',
        },
      ],
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      samplePlan['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Duration: ${samplePlan['total_duration']} • ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.maroon.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          'Cost: ${samplePlan['total_cost']}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.maroon.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Activities list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: (samplePlan['activities'] as List).length,
                  itemBuilder: (context, index) {
                    final activity = (samplePlan['activities'] as List)[index] as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activity['time'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.maroon,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  activity['activity'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            activity['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                activity['location'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.access_time, color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                activity['duration'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.attach_money, color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                activity['cost'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text('Generate New'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _savePlan(samplePlan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.maroon,
                        ),
                        child: Text('Save Plan'),
                      ),
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

  void _savePlan(Map<String, dynamic> plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _viewPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          plan['title'],
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${plan['date']}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Duration: ${plan['duration']}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Places: ${plan['places']}',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Status: ${plan['status']}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (plan['status'] == 'active')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startPlan(plan);
              },
              child: Text('Start Plan', style: TextStyle(color: AppColors.gold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _startPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          'Start Plan',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would open the active plan interface with navigation and real-time updates.',
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

  void _useTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          template['title'],
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This would customize the ${template['title']} template based on your preferences and generate a personalized plan.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateTemplateBasedPlan(template);
            },
            child: Text('Customize & Generate'),
          ),
        ],
      ),
    );
  }

  void _generateTemplateBasedPlan(Map<String, dynamic> template) {
    // This would generate a plan based on the selected template
    _generatePlan();
  }

  void _showAllPlans() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(
          'All Your Plans',
          style: TextStyle(color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _savedPlans.length,
            itemBuilder: (context, index) {
              final plan = _savedPlans[index];
              return ListTile(
                title: Text(
                  plan['title'],
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${plan['date']} • ${plan['duration']}',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  plan['status'].toUpperCase(),
                  style: TextStyle(
                    color: plan['status'] == 'active' ? AppColors.success : AppColors.info,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewPlan(plan);
                },
              );
            },
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