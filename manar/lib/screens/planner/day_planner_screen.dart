// screens/day_planner/ai_day_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/models/day_planner_model.dart';
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
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  
  int currentQuestionIndex = 0;
  Map<String, dynamic> userResponses = {};
  bool isTyping = false;
  bool questionsCompleted = false;

  final List<PlannerQuestion> questions = [
    PlannerQuestion(
      id: 'time_available',
      question: 'How much time do you have for your Qatar adventure today?',
      options: ['Half day (4 hours)', 'Full day (8 hours)', 'Extended day (12 hours)'],
      followUp: 'Perfect! What time would you like to start?',
      responseKey: 'duration',
    ),
    PlannerQuestion(
      id: 'start_time',
      question: 'What time would you like to start your day?',
      options: ['Early morning (7-9 AM)', 'Morning (9-11 AM)', 'Afternoon (12-2 PM)'],
      followUp: 'Got it! What type of experiences are you most interested in?',
      responseKey: 'start_time',
    ),
    PlannerQuestion(
      id: 'interests',
      question: 'What type of experiences excite you most?',
      options: ['Cultural & Historic', 'Food & Dining', 'Modern & Shopping', 'Mix of everything'],
      followUp: 'Excellent choice! What\'s your budget range for today?',
      responseKey: 'interests',
    ),
    PlannerQuestion(
      id: 'budget',
      question: 'What\'s your budget range for today\'s adventure?',
      options: ['Budget-friendly (\$50-100)', 'Moderate (\$100-200)', 'Premium (\$200+)'],
      followUp: 'Great! Any specific places you definitely want to visit or avoid?',
      responseKey: 'budget',
    ),
    PlannerQuestion(
      id: 'preferences',
      question: 'Any specific preferences or must-visit places?',
      options: ['Surprise me with the best!', 'Include traditional souqs', 'Modern attractions only'],
      followUp: 'Perfect! I have everything I need to create your amazing day plan.',
      responseKey: 'special_preferences',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
    
    // Start conversation
    _addMessage(ChatMessage(
      text: 'Hi there! 👋 I\'m your AI trip planner. I\'ll ask you a few quick questions to create the perfect day plan for you in Qatar!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    // Start first question after a delay
    Future.delayed(Duration(milliseconds: 1500), () {
      _askQuestion(0);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _handleTextResponse(String text) {
    if (text.trim().isEmpty) return;

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Store custom response
    if (currentQuestionIndex < questions.length) {
      final question = questions[currentQuestionIndex];
      userResponses[question.responseKey] = text;

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

  void _generatePlan() {
    // Navigate to generated plan screen with user responses
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeneratedPlanScreen(
          planningData: userResponses,
        ),
      ),
    );
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
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isTyping && index == messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(messages[index]);
                },
              ),
            ),
            
            // Input area
            if (!questionsCompleted) _buildInputArea(),
          ],
        ),
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
                        onPressed: () => _handleOptionSelected(option, message.questionId!),
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
                    
                    // Custom answer option
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          // Focus on text input
                          setState(() {});
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
                              'Generate My Day Plan',
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