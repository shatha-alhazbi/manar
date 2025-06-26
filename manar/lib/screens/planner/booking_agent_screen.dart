// screens/day_planner/booking_agent_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/models/day_planner_model.dart';

class BookingAgentScreen extends StatefulWidget {
  final List<PlanStop> dayPlan;
  final Map<String, dynamic> planningData;

  const BookingAgentScreen({
    Key? key,
    required this.dayPlan,
    required this.planningData,
  }) : super(key: key);

  @override
  _BookingAgentScreenState createState() => _BookingAgentScreenState();
}

class _BookingAgentScreenState extends State<BookingAgentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<BookingStep> bookingSteps = [];
  List<ChatMessage> conversation = [];
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  
  bool isProcessing = false;
  bool isCompleted = false;
  bool needsUserInput = false;
  String currentBookingId = '';
  int currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
    
    _initializeBookingProcess();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeBookingProcess() {
    // Create booking steps for each stop that requires booking
    bookingSteps = widget.dayPlan
        .where((stop) => stop.bookingRequired)
        .map((stop) => BookingStep(
              id: stop.id,
              stopName: stop.name,
              type: stop.type,
              location: stop.location,
              time: stop.startTime,
              status: BookingStatus.pending,
              details: {},
            ))
        .toList();

    // Start conversation
    _addMessage(ChatMessage(
      text: '🤖 Hi! I\'m your AI booking agent. I\'ll help you book all the reservations for your Qatar day plan.',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 1500), () {
      _addMessage(ChatMessage(
        text: 'I found ${bookingSteps.length} places that need reservations. Let me handle everything for you!',
        isUser: false,
        timestamp: DateTime.now(),
      ));

      Future.delayed(Duration(milliseconds: 1000), () {
        _startBookingProcess();
      });
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      conversation.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startBookingProcess() {
    if (currentStepIndex >= bookingSteps.length) {
      _completeBookingProcess();
      return;
    }

    final currentStep = bookingSteps[currentStepIndex];
    setState(() {
      isProcessing = true;
      currentBookingId = currentStep.id;
      currentStep.status = BookingStatus.processing;
    });

    _addMessage(ChatMessage(
      text: '📞 Now booking: ${currentStep.stopName}',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Simulate booking process
    _simulateBookingProcess(currentStep);
  }

  void _simulateBookingProcess(BookingStep step) async {
    // Step 1: Checking availability
    await Future.delayed(Duration(seconds: 2));
    _addMessage(ChatMessage(
      text: '🔍 Checking availability at ${step.stopName}...',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    await Future.delayed(Duration(seconds: 2));

    // Simulate different booking scenarios
    if (step.type == 'restaurant' && step.stopName.contains('Al Mourjan')) {
      // Need additional info
      setState(() {
        needsUserInput = true;
        isProcessing = false;
      });
      
      _addMessage(ChatMessage(
        text: '✅ Great news! ${step.stopName} has availability at ${step.time}.\n\nI need a few quick details to complete your reservation:',
        isUser: false,
        timestamp: DateTime.now(),
        needsInput: true,
        inputFields: ['Contact number', 'Party size', 'Dietary restrictions (optional)'],
        stepId: step.id,
      ));
    } else {
      // Automatic booking success
      await _completeStepBooking(step, true);
    }
  }

  void _handleUserInput(Map<String, String> inputData, String stepId) {
    setState(() {
      needsUserInput = false;
      isProcessing = true;
    });

    // Store user input
    final step = bookingSteps.firstWhere((s) => s.id == stepId);
    step.details.addAll(inputData);

    _addMessage(ChatMessage(
      text: 'Perfect! Let me finalize your reservation with those details.',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(seconds: 2), () {
      _completeStepBooking(step, true);
    });
  }

  Future<void> _completeStepBooking(BookingStep step, bool success) async {
    setState(() {
      step.status = success ? BookingStatus.confirmed : BookingStatus.failed;
    });

    if (success) {
      final confirmationNumber = 'QAT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      step.confirmationNumber = confirmationNumber;

      _addMessage(ChatMessage(
        text: '✅ Booking confirmed for ${step.stopName}!\n\nConfirmation: $confirmationNumber\nTime: ${step.time}\nLocation: ${step.location}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      _addMessage(ChatMessage(
        text: '❌ Unable to book ${step.stopName}. I\'ll find an alternative for you.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      currentStepIndex++;
      isProcessing = false;
    });

    Future.delayed(Duration(milliseconds: 800), () {
      _startBookingProcess();
    });
  }

  void _completeBookingProcess() {
    setState(() {
      isCompleted = true;
    });

    final successfulBookings = bookingSteps.where((s) => s.status == BookingStatus.confirmed).length;
    
    _addMessage(ChatMessage(
      text: '🎉 All done! I\'ve successfully booked $successfulBookings out of ${bookingSteps.length} reservations for your Qatar adventure.',
      isUser: false,
      timestamp: DateTime.now(),
      showSummary: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'AI Booking Agent',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Booking progress
            _buildProgressHeader(),
            
            // Conversation
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: conversation.length + (isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isProcessing && index == conversation.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(conversation[index]);
                },
              ),
            ),
            
            // Input area (when needed)
            if (needsUserInput) _buildInputArea(),
            
            // Completion actions
            if (isCompleted) _buildCompletionActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final totalSteps = bookingSteps.length;
    final completedSteps = bookingSteps.where((s) => s.status == BookingStatus.confirmed).length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkPurple],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Progress',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$completedSteps / $totalSteps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: totalSteps > 0 ? completedSteps / totalSteps : 0,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
          SizedBox(height: 16),
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bookingSteps.length,
              itemBuilder: (context, index) {
                final step = bookingSteps[index];
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: _buildStepIndicator(step, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BookingStep step, int index) {
    Color color;
    IconData icon;
    
    switch (step.status) {
      case BookingStatus.confirmed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BookingStatus.processing:
        color = AppColors.gold;
        icon = Icons.hourglass_empty;
        break;
      case BookingStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      width: 120,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.status == BookingStatus.processing
              ? AppColors.gold
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            step.stopName,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.smart_toy, color: AppColors.maroon, size: 24),
            ),
            SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isUser 
                  ? LinearGradient(colors: [AppColors.primaryBlue, AppColors.darkPurple])
                  : LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  
                  // Input fields for user data
                  if (message.needsInput == true && message.inputFields != null) ...[
                    SizedBox(height: 16),
                    _buildInputFields(message.inputFields!, message.stepId!),
                  ],
                  
                  // Booking summary
                  if (message.showSummary == true) ...[
                    SizedBox(height: 16),
                    _buildBookingSummary(),
                  ],
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputFields(List<String> fields, String stepId) {
    Map<String, TextEditingController> controllers = {};
    for (String field in fields) {
      controllers[field] = TextEditingController();
    }

    return Column(
      children: [
        ...fields.map((field) => Container(
          margin: EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: controllers[field],
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: field,
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.gold),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
          ),
        )).toList(),
        
        SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: () {
            Map<String, String> inputData = {};
            controllers.forEach((key, controller) {
              inputData[key] = controller.text;
            });
            _handleUserInput(inputData, stepId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.maroon,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Submit Information'),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          SizedBox(height: 12),
          ...bookingSteps.map((step) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: step.status == BookingStatus.confirmed
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: step.status == BookingStatus.confirmed
                    ? Colors.green
                    : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  step.status == BookingStatus.confirmed
                      ? Icons.check_circle
                      : Icons.error,
                  color: step.status == BookingStatus.confirmed
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.stopName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (step.confirmationNumber != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Confirmation: ${step.confirmationNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.smart_toy, color: AppColors.maroon, size: 24),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.4, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type additional information...',
                hintStyle: TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // Handle additional input if needed
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: AppColors.maroon,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionActions() {
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Show detailed itinerary with confirmations
                    _showDetailedItinerary();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'View Itinerary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to dashboard
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.maroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back Home',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Share complete plan
              _shareCompleteplan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
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
                Text(
                  'Share My Plan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedItinerary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.darkPurple],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Complete Itinerary',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: widget.dayPlan.length,
                itemBuilder: (context, index) {
                  final stop = widget.dayPlan[index];
                  final booking = bookingSteps
                      .where((b) => b.id == stop.id)
                      .firstOrNull;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.maroon,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.startTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    stop.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (booking != null && booking.status == BookingStatus.confirmed)
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          stop.location,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        if (booking?.confirmationNumber != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Confirmed: ${booking!.confirmationNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  void _shareCompleteplan() {
    // Implement sharing functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Share Your Plan', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your complete Qatar day plan with all confirmations will be shared.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual sharing
            },
            child: Text('Share', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}