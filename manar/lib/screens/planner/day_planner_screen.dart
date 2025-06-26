// lib/screens/planner/day_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../models/day_planner_model.dart';
import '../../services/day_planner_service.dart';
import '../../services/auth_services.dart';
import 'generated_plan_screen.dart';

class AIDayPlannerScreen extends StatefulWidget {
  @override
  _AIDayPlannerScreenState createState() => _AIDayPlannerScreenState();
}

class _AIDayPlannerScreenState extends State<AIDayPlannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ChatMessage> messages = [];
  List<PlannerQuestion> questions = [];
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  
  int currentQuestionIndex = 0;
  Map<String, dynamic> userResponses = {};
  bool isTyping = false;
  bool questionsCompleted = false;
  bool isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
    
    _initializeConversation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeConversation() async {
    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';
    
    // Start conversation
    _addMessage(ChatMessage(
      text: 'Hi there! 👋 I\'m your AI trip planner. Let me ask you a few questions to create the perfect day plan for you in Qatar!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    // Generate dynamic questions using AI
    setState(() {
      isTyping = true;
    });
    
    try {
      questions = await plannerService.generateDynamicQuestions(userId);
      setState(() {
        isLoadingQuestions = false;
        isTyping = false;
      });
      
      Future.delayed(Duration(milliseconds: 1500), () {
        _askQuestion(0);
      });
    } catch (e) {
      setState(() {
        isLoadingQuestions = false;
        isTyping = false;
      });
      
      _addMessage(ChatMessage(
        text: 'I\'m having trouble connecting to my AI brain right now. Let me ask you some basic questions to get started!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      Future.delayed(Duration(milliseconds: 1000), () {
        _askQuestion(0);
      });
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      messages.add(message);
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

  void _askQuestion(int questionIndex) {
    if (questionIndex >= questions.length) {
      _completeQuestionnaire();
      return;
    }

    setState(() {
      isTyping = true;
      currentQuestionIndex = questionIndex;
    });

    Future.delayed(Duration(milliseconds: 1000), () {
      setState(() {
        isTyping = false;
      });
      
      _addMessage(ChatMessage(
        text: questions[questionIndex].question,
        isUser: false,
        timestamp: DateTime.now(),
        options: questions[questionIndex].options,
        questionId: questions[questionIndex].id,
      ));
    });
  }

  void _handleOptionSelected(String option, String questionId) {
    // Add user response
    _addMessage(ChatMessage(
      text: option,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Store response
    final question = questions.firstWhere((q) => q.id == questionId);
    userResponses[question.responseKey] = option;

    // Show follow-up and move to next question
    Future.delayed(Duration(milliseconds: 800), () {
      _addMessage(ChatMessage(
        text: question.followUp,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      Future.delayed(Duration(milliseconds: 1200), () {
        _askQuestion(currentQuestionIndex + 1);
      });
    });
  }

  void _handleTextResponse(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Use AI to understand and respond to custom input
    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    setState(() {
      isTyping = true;
    });

    try {
      String aiResponse = await plannerService.chatWithPlanningAI(
        message: text,
        userId: userId,
        conversationHistory: messages,
      );

      setState(() {
        isTyping = false;
      });

      _addMessage(ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Store custom response
      if (currentQuestionIndex < questions.length) {
        final question = questions[currentQuestionIndex];
        userResponses[question.responseKey] = text;

        Future.delayed(Duration(milliseconds: 1200), () {
          _askQuestion(currentQuestionIndex + 1);
        });
      }
    } catch (e) {
      setState(() {
        isTyping = false;
      });
      
      _addMessage(ChatMessage(
        text: 'I understand! Let me continue with the next question.',
        isUser: false,
        timestamp: DateTime.now(),
      ));

      if (currentQuestionIndex < questions.length) {
        final question = questions[currentQuestionIndex];
        userResponses[question.responseKey] = text;

        Future.delayed(Duration(milliseconds: 1200), () {
          _askQuestion(currentQuestionIndex + 1);
        });
      }
    }

    _textController.clear();
  }

  void _completeQuestionnaire() {
    setState(() {
      questionsCompleted = true;
    });

    _addMessage(ChatMessage(
      text: 'Excellent! I have all the information I need. Let me create an amazing personalized day plan just for you! 🎉',
      isUser: false,
      timestamp: DateTime.now(),
      showGenerateButton: true,
    ));
  }

  void _generatePlan() async {
    final authService = context.read<AuthService>();
    final plannerService = context.read<AIDayPlannerService>();
    final userId = authService.currentUser?.uid ?? 'guest';

    // Show loading state
    _addMessage(ChatMessage(
      text: 'Perfect! I\'m now creating your personalized Qatar adventure. This might take a moment while I craft the perfect itinerary for you... ✨',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    try {
      List<PlanStop>? generatedPlan = await plannerService.generateDayPlan(
        userId: userId,
        planningData: userResponses,
      );

      if (generatedPlan != null && generatedPlan.isNotEmpty) {
        // Navigate to generated plan screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GeneratedPlanScreen(
              planningData: userResponses,
              generatedStops: generatedPlan,
            ),
          ),
        );
      } else {
        _addMessage(ChatMessage(
          text: 'I\'m having trouble creating your plan right now. Please try again in a moment, or let me know if you\'d like to modify your preferences!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: 'Oops! Something went wrong while creating your plan. Let\'s try again - would you like to restart or modify any of your answers?',
        isUser: false,
        timestamp: DateTime.now(),
        options: ['Try again', 'Restart planning', 'Modify preferences'],
        questionId: 'error_recovery',
      ));
    }
  }

  void _handleErrorRecovery(String option) {
    switch (option) {
      case 'Try again':
        _generatePlan();
        break;
      case 'Restart planning':
        _restartPlanning();
        break;
      case 'Modify preferences':
        _modifyPreferences();
        break;
    }
  }

  void _restartPlanning() {
    setState(() {
      messages.clear();
      userResponses.clear();
      currentQuestionIndex = 0;
      questionsCompleted = false;
      isTyping = false;
    });
    _initializeConversation();
  }

  void _modifyPreferences() {
    _addMessage(ChatMessage(
      text: 'No problem! Which aspect would you like to change?',
      isUser: false,
      timestamp: DateTime.now(),
      options: [
        'Duration & timing',
        'Interests & activities',
        'Budget preferences',
        'Special requirements'
      ],
      questionId: 'modify_preferences',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'AI Day Planner',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userResponses.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _restartPlanning,
              tooltip: 'Restart planning',
            ),
        ],
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress indicator
            if (!questionsCompleted && questions.isNotEmpty)
              _buildProgressIndicator(),
            
            // Chat messages
            Expanded(
              child: Consumer<AIDayPlannerService>(
                builder: (context, plannerService, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length + (isTyping ? 1 : 0) + (plannerService.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (plannerService.isLoading && index == messages.length + (isTyping ? 1 : 0)) {
                        return _buildAIProcessingIndicator();
                      }
                      if (isTyping && index == messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(messages[index]);
                    },
                  );
                },
              ),
            ),
            
            // Input area
            if (!questionsCompleted) _buildInputArea(),
            
            // Error display
            Consumer<AIDayPlannerService>(
              builder: (context, plannerService, child) {
                if (plannerService.error.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    color: AppColors.error.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plannerService.error,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Clear error and retry
                            context.read<AIDayPlannerService>().clearError();
                          },
                          child: Text('Retry', style: TextStyle(color: AppColors.gold)),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    double progress = questions.isNotEmpty ? (currentQuestionIndex / questions.length) : 0.0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planning Progress',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${currentQuestionIndex + 1} of ${questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildAIProcessingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.psychology, color: AppColors.maroon, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI is thinking...',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Creating your personalized Qatar adventure',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
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
                  
                  // Options buttons
                  if (message.options != null && message.options!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ...message.options!.map((option) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (message.questionId == 'error_recovery') {
                            _handleErrorRecovery(option);
                          } else {
                            _handleOptionSelected(option, message.questionId!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold.withOpacity(0.1),
                          foregroundColor: AppColors.gold,
                          side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )).toList(),
                    
                    // Custom answer option (only for regular questions)
                    if (message.questionId != 'error_recovery' && message.questionId != 'modify_preferences')
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            // Focus on text input
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                          icon: Icon(Icons.edit, color: Colors.white70, size: 16),
                          label: Text(
                            'Or type your own answer',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                  
                  // Generate button
                  if (message.showGenerateButton == true) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generatePlan,
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
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Generate My AI Day Plan',
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
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: _handleTextResponse,
              maxLines: null,
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleTextResponse(_textController.text),
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
}