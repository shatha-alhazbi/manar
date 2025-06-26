// screens/day_planner/generated_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/models/day_planner_model.dart';
import 'booking_agent_screen.dart';

class GeneratedPlanScreen extends StatefulWidget {
  final Map<String, dynamic> planningData;

  const GeneratedPlanScreen({Key? key, required this.planningData}) : super(key: key);

  @override
  _GeneratedPlanScreenState createState() => _GeneratedPlanScreenState();
}

class _GeneratedPlanScreenState extends State<GeneratedPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<PlanStop> dayPlan = [];
  bool isLoading = true;
  PageController _pageController = PageController();
  int currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _generatePlan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _generatePlan() async {
    // Simulate AI generation
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      dayPlan = _createPlanBasedOnResponses();
      isLoading = false;
    });
    
    _animationController.forward();
  }

  List<PlanStop> _createPlanBasedOnResponses() {
    // Generate plan based on user responses
    final duration = widget.planningData['duration'] ?? 'Full day (8 hours)';
    final startTime = widget.planningData['start_time'] ?? 'Morning (9-11 AM)';
    final interests = widget.planningData['interests'] ?? 'Mix of everything';
    final budget = widget.planningData['budget'] ?? 'Moderate (\$100-200)';
    
    return [
      PlanStop(
        id: '1',
        name: 'Traditional Qatari Breakfast',
        location: 'Al Mourjan Restaurant, Corniche',
        type: 'restaurant',
        startTime: '09:00',
        duration: '1h 30min',
        description: 'Start your day with authentic Qatari breakfast overlooking the beautiful Corniche',
        estimatedCost: '\$25',
        travelToNext: '15 min walk',
        coordinates: LatLng(25.2854, 51.5310),
        tips: 'Try the traditional machboos and karak tea',
        rating: 4.6,
        bookingRequired: true,
      ),
      PlanStop(
        id: '2',
        name: 'Museum of Islamic Art',
        location: 'Corniche, Doha',
        type: 'attraction',
        startTime: '11:00',
        duration: '2h 30min',
        description: 'Explore world-class Islamic art collection in stunning architecture',
        estimatedCost: 'Free',
        travelToNext: '20 min taxi',
        coordinates: LatLng(25.2760, 51.5390),
        tips: 'Don\'t miss the manuscript collection on the 4th floor',
        rating: 4.9,
        bookingRequired: false,
      ),
      PlanStop(
        id: '3',
        name: 'Souq Waqif Lunch',
        location: 'Souq Waqif Traditional Restaurant',
        type: 'restaurant',
        startTime: '14:00',
        duration: '1h 15min',
        description: 'Authentic Middle Eastern cuisine in historic market atmosphere',
        estimatedCost: '\$30',
        travelToNext: '5 min walk',
        coordinates: LatLng(25.2867, 51.5329),
        tips: 'Try the mixed grill platter and fresh hummus',
        rating: 4.4,
        bookingRequired: false,
      ),
      PlanStop(
        id: '4',
        name: 'Souq Waqif Exploration',
        location: 'Traditional Souq Market',
        type: 'shopping',
        startTime: '15:30',
        duration: '2h 00min',
        description: 'Browse traditional crafts, spices, and enjoy cultural performances',
        estimatedCost: '\$50',
        travelToNext: '25 min taxi',
        coordinates: LatLng(25.2871, 51.5335),
        tips: 'Best time for photos and cultural shows',
        rating: 4.7,
        bookingRequired: false,
      ),
      PlanStop(
        id: '5',
        name: 'Sunset at The Pearl',
        location: 'The Pearl-Qatar Marina',
        type: 'attraction',
        startTime: '18:00',
        duration: '1h 30min',
        description: 'Enjoy beautiful sunset views at Qatar\'s luxury marina',
        estimatedCost: '\$15',
        travelToNext: '10 min walk',
        coordinates: LatLng(25.3780, 51.5540),
        tips: 'Perfect for photos during golden hour',
        rating: 4.8,
        bookingRequired: false,
      ),
      PlanStop(
        id: '6',
        name: 'Dinner at Porto Arabia',
        location: 'Seafood Restaurant, The Pearl',
        type: 'restaurant',
        startTime: '19:45',
        duration: '2h 00min',
        description: 'End your day with fresh seafood and marina views',
        estimatedCost: '\$60',
        travelToNext: 'Trip complete',
        coordinates: LatLng(25.3785, 51.5545),
        tips: 'Try the grilled hammour with Arabic rice',
        rating: 4.5,
        bookingRequired: true,
      ),
    ];
  }

  void _removeStop(String stopId) {
    setState(() {
      dayPlan.removeWhere((stop) => stop.id == stopId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stop removed from your plan'),
        backgroundColor: AppColors.primaryBlue,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.gold,
          onPressed: () {
            // Could implement undo functionality
          },
        ),
      ),
    );
  }

  void _bookAllStops() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingAgentScreen(
          dayPlan: dayPlan,
          planningData: widget.planningData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: isLoading ? _buildLoadingScreen() : _buildPlanScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlue, AppColors.darkNavy],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                strokeWidth: 6,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Creating Your Perfect Day...',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Our AI is crafting a personalized itinerary\nbased on your preferences',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Plan content
            Expanded(
              child: Column(
                children: [
                  // Plan timeline
                  Expanded(
                    flex: 6,
                    child: _buildTimelineView(),
                  ),
                  
                  // Map view
                  Expanded(
                    flex: 4,
                    child: _buildMapView(),
                  ),
                ],
              ),
            ),
            
            // Book plan button
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalCost = dayPlan.fold<int>(0, (sum, stop) {
      final cost = stop.estimatedCost.replaceAll(RegExp(r'[^\d]'), '');
      return sum + (int.tryParse(cost) ?? 0);
    });

    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkPurple],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Your Perfect Day Plan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Share plan functionality
                },
                icon: Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.schedule, '${dayPlan.length} stops', 'Total Stops'),
                _buildStatItem(Icons.access_time, '8 hours', 'Duration'),
                _buildStatItem(Icons.attach_money, '\$${totalCost}', 'Est. Cost'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: dayPlan.length,
      itemBuilder: (context, index) {
        final stop = dayPlan[index];
        final isLast = index == dayPlan.length - 1;
        
        return _buildStopCard(stop, isLast, index);
      },
    );
  }

  Widget _buildStopCard(PlanStop stop, bool isLast, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: 16),
          
          // Stop card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with remove button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.startTime,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              stop.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeStop(stop.id),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Location and type
                  Row(
                    children: [
                      Icon(
                        _getStopIcon(stop.type),
                        color: AppColors.gold,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.location,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Description
                  Text(
                    stop.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStopStat(Icons.schedule, stop.duration),
                      SizedBox(width: 16),
                      _buildStopStat(Icons.attach_money, stop.estimatedCost),
                      SizedBox(width: 16),
                      _buildStopStat(Icons.star, '${stop.rating}'),
                    ],
                  ),
                  
                  if (stop.tips.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stop.tips,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Travel to next
                  if (!isLast && stop.travelToNext != 'Trip complete') ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            stop.travelToNext,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  IconData _getStopIcon(String type) {
    switch (type) {
      case 'restaurant':
        return Icons.restaurant;
      case 'attraction':
        return Icons.place;
      case 'shopping':
        return Icons.shopping_bag;
      case 'cafe':
        return Icons.local_cafe;
      default:
        return Icons.location_on;
    }
  }

  Widget _buildMapView() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map placeholder - In real app, use Google Maps or similar
            Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Interactive Route Map',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your day plan route through Qatar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Map overlay with route info
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Route: 12.5 km • Est. Travel Time: 45 min',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Mock route markers
            ...dayPlan.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final left = 50.0 + (index * 40.0); // Mock positioning
              final top = 60.0 + (index * 20.0);
              
              return Positioned(
                left: left,
                top: top,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _bookAllStops,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.maroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Book My Entire Plan with AI',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Our AI agent will automatically book all reservations for you',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}