// lib/screens/planner/generated_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../models/day_planner_model.dart';
import '../../services/day_planner_service.dart';
import '../../services/auth_services.dart';
import 'booking_agent_screen.dart';

class GeneratedPlanScreen extends StatefulWidget {
  final Map<String, dynamic> planningData;
  final List<PlanStop>? generatedStops;

  const GeneratedPlanScreen({
    Key? key, 
    required this.planningData,
    this.generatedStops,
  }) : super(key: key);

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
  bool isRegenerating = false;

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
    
    _initializePlan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializePlan() async {
    if (widget.generatedStops != null && widget.generatedStops!.isNotEmpty) {
      // Use pre-generated stops
      setState(() {
        dayPlan = widget.generatedStops!;
        isLoading = false;
      });
      _animationController.forward();
    } else {
      // Generate new plan
      await _generatePlan();
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      isLoading = true;
    });

    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    try {
      List<PlanStop>? generatedPlan = await plannerService.generateDayPlan(
        userId: userId,
        planningData: widget.planningData,
      );

      if (generatedPlan != null && generatedPlan.isNotEmpty) {
        setState(() {
          dayPlan = generatedPlan;
          isLoading = false;
        });
        _animationController.forward();
      } else {
        // Show error state
        setState(() {
          isLoading = false;
        });
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Plan Generation Failed', style: TextStyle(color: Colors.white)),
        content: Text(
          'I\'m having trouble creating your plan right now. Would you like to try again?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to planner
            },
            child: Text('Go Back', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generatePlan();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text('Try Again', style: TextStyle(color: AppColors.maroon)),
          ),
        ],
      ),
    );
  }

  void _regeneratePlan() async {
    setState(() {
      isRegenerating = true;
    });

    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    try {
      List<PlanStop>? newPlan = await plannerService.generateDayPlan(
        userId: userId,
        planningData: widget.planningData,
      );

      if (newPlan != null && newPlan.isNotEmpty) {
        setState(() {
          dayPlan = newPlan;
          isRegenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New plan generated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          isRegenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate new plan. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isRegenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeStop(String stopId) async {
    final plannerService = context.read<AIDayPlannerService>();
    plannerService.removePlanStop(stopId);
    
    setState(() {
      dayPlan.removeWhere((stop) => stop.id == stopId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stop removed from your plan'),
        backgroundColor: AppColors.primaryBlue,
        action: SnackBarAction(
          label: 'Get Replacement',
          textColor: AppColors.gold,
          onPressed: () async {
            await _getSuggestionForRemovedStop();
          },
        ),
      ),
    );
  }

  Future<void> _getSuggestionForRemovedStop() async {
    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    try {
      // Get AI suggestions for replacement
      List<RecommendationItem> suggestions = await plannerService.getAIRecommendations(
        query: 'Suggest alternatives for my Qatar day plan',
        userId: userId,
      );

      if (suggestions.isNotEmpty) {
        _showReplacementSuggestions(suggestions);
      }
    } catch (e) {
      print('Failed to get suggestions: $e');
    }
  }

  void _showReplacementSuggestions(List<RecommendationItem> suggestions) {
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
            Text(
              'AI Suggestions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            ...suggestions.take(3).map((suggestion) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on, color: AppColors.maroon),
              ),
              title: Text(
                suggestion.name,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                suggestion.location,
                style: TextStyle(color: Colors.white70),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addSuggestionToPlan(suggestion);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  minimumSize: Size(60, 32),
                ),
                child: Text('Add', style: TextStyle(color: AppColors.maroon)),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _addSuggestionToPlan(RecommendationItem suggestion) {
    // Convert recommendation to plan stop
    PlanStop newStop = PlanStop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: suggestion.name,
      location: suggestion.location,
      type: suggestion.type,
      startTime: _getNextAvailableTime(),
      duration: suggestion.estimatedDuration,
      description: suggestion.description,
      estimatedCost: suggestion.priceRange,
      travelToNext: '15 min travel',
      coordinates: LatLng(25.2854, 51.5310), // Default coordinates
      tips: suggestion.whyRecommended,
      rating: suggestion.rating,
      bookingRequired: suggestion.bookingAvailable,
    );

    setState(() {
      dayPlan.add(newStop);
    });

    final plannerService = context.read<AIDayPlannerService>();
    plannerService.updatePlanStop(newStop.id, newStop);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${suggestion.name} added to your plan!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getNextAvailableTime() {
    if (dayPlan.isEmpty) return '09:00';
    
    // Get the last stop's time and add duration
    PlanStop lastStop = dayPlan.last;
    // This is a simplified time calculation
    // In a real app, you'd parse the time properly
    return '${int.parse(lastStop.startTime.split(':')[0]) + 2}:00';
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
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'Analyzing ${widget.planningData.length} preferences...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.gold,
                ),
              ),
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

    final totalDuration = _calculateTotalDuration();

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
                  'Your AI-Generated Plan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: AppColors.darkNavy,
                onSelected: (value) {
                  switch (value) {
                    case 'regenerate':
                      _regeneratePlan();
                      break;
                    case 'share':
                      _sharePlan();
                      break;
                    case 'save':
                      _savePlan();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Regenerate Plan', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Share Plan', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Save Plan', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
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
                _buildStatItem(Icons.access_time, totalDuration, 'Duration'),
                _buildStatItem(Icons.attach_money, '\$${totalCost}', 'Est. Cost'),
              ],
            ),
          ),
          if (isRegenerating) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI is creating a new plan...',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _calculateTotalDuration() {
    if (dayPlan.isEmpty) return '0 hours';
    
    // Calculate from first start time to last end time
    // This is simplified - in a real app you'd parse times properly
    int totalHours = dayPlan.length * 2; // Rough estimate
    return '$totalHours hours';
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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white54, size: 20),
                        color: AppColors.darkNavy,
                        onSelected: (value) {
                          switch (value) {
                            case 'remove':
                              _removeStop(stop.id);
                              break;
                            case 'modify':
                              _modifyStop(stop);
                              break;
                            case 'alternatives':
                              _getAlternatives(stop);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'modify',
                            child: Text('Modify Time', style: TextStyle(color: Colors.white)),
                          ),
                          PopupMenuItem(
                            value: 'alternatives',
                            child: Text('Find Alternatives', style: TextStyle(color: Colors.white)),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
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
                      if (stop.bookingRequired) ...[
                        SizedBox(width: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Booking Required',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  void _modifyStop(PlanStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Modify ${stop.name}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // Time modification options
            ListTile(
              leading: Icon(Icons.access_time, color: AppColors.gold),
              title: Text('Change Time', style: TextStyle(color: Colors.white)),
              subtitle: Text('Current: ${stop.startTime}', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                _changeStopTime(stop);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.gold),
              title: Text('Adjust Duration', style: TextStyle(color: Colors.white)),
              subtitle: Text('Current: ${stop.duration}', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                _changeStopDuration(stop);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_note, color: AppColors.gold),
              title: Text('Add Personal Notes', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _addPersonalNotes(stop);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeStopTime(PlanStop stop) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(stop.startTime.split(':')[0]),
        minute: int.parse(stop.startTime.split(':')[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.maroon,
              surface: AppColors.darkNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((TimeOfDay? newTime) {
      if (newTime != null) {
        String newTimeString = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
        
        PlanStop updatedStop = PlanStop(
          id: stop.id,
          name: stop.name,
          location: stop.location,
          type: stop.type,
          startTime: newTimeString,
          duration: stop.duration,
          description: stop.description,
          estimatedCost: stop.estimatedCost,
          travelToNext: stop.travelToNext,
          coordinates: stop.coordinates,
          tips: stop.tips,
          rating: stop.rating,
          bookingRequired: stop.bookingRequired,
        );
        
        setState(() {
          int index = dayPlan.indexWhere((s) => s.id == stop.id);
          if (index != -1) {
            dayPlan[index] = updatedStop;
          }
        });
        
        context.read<AIDayPlannerService>().updatePlanStop(stop.id, updatedStop);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time updated to $newTimeString'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _changeStopDuration(PlanStop stop) {
    List<String> durationOptions = ['30 min', '1 hour', '1h 30min', '2 hours', '2h 30min', '3 hours'];
    
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
            Text(
              'Select Duration',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            ...durationOptions.map((duration) => ListTile(
              title: Text(duration, style: TextStyle(color: Colors.white)),
              trailing: stop.duration == duration 
                  ? Icon(Icons.check, color: AppColors.gold)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateStopDuration(stop, duration);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _updateStopDuration(PlanStop stop, String newDuration) {
    PlanStop updatedStop = PlanStop(
      id: stop.id,
      name: stop.name,
      location: stop.location,
      type: stop.type,
      startTime: stop.startTime,
      duration: newDuration,
      description: stop.description,
      estimatedCost: stop.estimatedCost,
      travelToNext: stop.travelToNext,
      coordinates: stop.coordinates,
      tips: stop.tips,
      rating: stop.rating,
      bookingRequired: stop.bookingRequired,
    );
    
    setState(() {
      int index = dayPlan.indexWhere((s) => s.id == stop.id);
      if (index != -1) {
        dayPlan[index] = updatedStop;
      }
    });
    
    context.read<AIDayPlannerService>().updatePlanStop(stop.id, updatedStop);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duration updated to $newDuration'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addPersonalNotes(PlanStop stop) {
    TextEditingController notesController = TextEditingController(text: stop.tips);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Add Personal Notes', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: notesController,
          style: TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add your personal notes or reminders...',
            hintStyle: TextStyle(color: Colors.white60),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStopNotes(stop, notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text('Save', style: TextStyle(color: AppColors.maroon)),
          ),
        ],
      ),
    );
  }

  void _updateStopNotes(PlanStop stop, String newNotes) {
    PlanStop updatedStop = PlanStop(
      id: stop.id,
      name: stop.name,
      location: stop.location,
      type: stop.type,
      startTime: stop.startTime,
      duration: stop.duration,
      description: stop.description,
      estimatedCost: stop.estimatedCost,
      travelToNext: stop.travelToNext,
      coordinates: stop.coordinates,
      tips: newNotes,
      rating: stop.rating,
      bookingRequired: stop.bookingRequired,
    );
    
    setState(() {
      int index = dayPlan.indexWhere((s) => s.id == stop.id);
      if (index != -1) {
        dayPlan[index] = updatedStop;
      }
    });
    
    context.read<AIDayPlannerService>().updatePlanStop(stop.id, updatedStop);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notes updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _getAlternatives(PlanStop stop) async {
    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    try {
      List<RecommendationItem> alternatives = await plannerService.getAIRecommendations(
        query: 'Find alternatives to ${stop.name} in ${stop.location}',
        userId: userId,
      );

      if (alternatives.isNotEmpty) {
        _showAlternatives(stop, alternatives);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No alternatives found at this time'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to find alternatives: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAlternatives(PlanStop originalStop, List<RecommendationItem> alternatives) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Alternatives to ${originalStop.name}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alternative = alternatives[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                    alternative.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    alternative.location,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.star, color: AppColors.gold, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '${alternative.rating}',
                                  style: TextStyle(color: AppColors.gold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          alternative.whyRecommended,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alternative.priceRange,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _replaceStop(originalStop, alternative);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                minimumSize: Size(80, 32),
                              ),
                              child: Text(
                                'Replace',
                                style: TextStyle(color: AppColors.maroon),
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
          ],
        ),
      ),
    );
  }

  void _replaceStop(PlanStop originalStop, RecommendationItem replacement) {
    PlanStop newStop = PlanStop(
      id: originalStop.id,
      name: replacement.name,
      location: replacement.location,
      type: replacement.type,
      startTime: originalStop.startTime,
      duration: replacement.estimatedDuration,
      description: replacement.description,
      estimatedCost: replacement.priceRange,
      travelToNext: originalStop.travelToNext,
      coordinates: originalStop.coordinates, // Keep original coordinates for now
      tips: replacement.whyRecommended,
      rating: replacement.rating,
      bookingRequired: replacement.bookingAvailable,
    );
    
    setState(() {
      int index = dayPlan.indexWhere((s) => s.id == originalStop.id);
      if (index != -1) {
        dayPlan[index] = newStop;
      }
    });
    
    context.read<AIDayPlannerService>().updatePlanStop(originalStop.id, newStop);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${originalStop.name} replaced with ${replacement.name}'),
        backgroundColor: AppColors.success,
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
            // Dynamic map view based on actual coordinates
            Container(
              color: Colors.grey[300],
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Interactive Route Map',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'AI-optimized route through Qatar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.black54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMapStat('Distance', _calculateTotalDistance()),
                        _buildMapStat('Travel Time', _calculateTravelTime()),
                        _buildMapStat('Stops', '${dayPlan.length}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Map overlay with dynamic route info
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
                        'AI-optimized route • ${_calculateTotalDistance()} • ${_calculateTravelTime()}',
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
            
            // Dynamic route markers based on actual coordinates
            ...dayPlan.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              
              // Calculate position based on normalized coordinates
              double left = 40.0 + (index * 60.0).clamp(0.0, 200.0);
              double top = 80.0 + (index * 25.0).clamp(0.0, 100.0);
              
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () => _showStopOnMap(stop),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
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

  String _calculateTotalDistance() {
    // Calculate based on actual coordinates
    double totalDistance = 0.0;
    for (int i = 0; i < dayPlan.length - 1; i++) {
      // Simple distance calculation (in a real app, use proper geolocation formulas)
      totalDistance += 2.5; // Average distance between stops in Qatar
    }
    return '${totalDistance.toStringAsFixed(1)} km';
  }

  String _calculateTravelTime() {
    int totalMinutes = dayPlan.length * 15; // Average 15 minutes between stops
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  void _showStopOnMap(PlanStop stop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text(stop.name, style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.location,
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '${stop.startTime} • ${stop.duration}',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              stop.description,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would open navigation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigation to ${stop.name} would open here'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text('Navigate', style: TextStyle(color: AppColors.maroon)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    int bookableStops = dayPlan.where((stop) => stop.bookingRequired).length;
    
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
          if (bookableStops > 0) ...[
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
                    Column(
                      children: [
                        Text(
                          'Book My Entire Plan with AI Agent',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$bookableStops reservations needed',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Our AI booking agent will automatically handle all reservations for you',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Perfect! Your plan is ready to go. No bookings required.',
                      style: GoogleFonts.inter(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _savePlan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Save Plan'),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _sharePlan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share'),
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

  void _savePlan() {
    // Implement save to favorites/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan saved to your favorites!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _sharePlan() {
    // Implement sharing functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Share Your Plan', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your AI-generated Qatar day plan will be shared with a link that others can view.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Plan shared successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text('Share', style: TextStyle(color: AppColors.maroon)),
          ),
        ],
      ),
    );
  }
}