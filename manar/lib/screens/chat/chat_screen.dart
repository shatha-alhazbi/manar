// screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import 'package:manara/services/user_services.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'message': 'مرحباً! I\'m your AI guide for Qatar. How can I help you explore the best of Qatar today?',
      'timestamp': DateTime.now().subtract(Duration(minutes: 1)),
      'type': 'text',
    },
  ];

  final List<Map<String, String>> _quickQuestions = [
    {'text': 'Best restaurants nearby', 'icon': '🍽️'},
    {'text': 'Cultural attractions', 'icon': '🏛️'},
    {'text': 'Shopping destinations', 'icon': '🛍️'},
    {'text': 'Family-friendly activities', 'icon': '👨‍👩‍👧‍👦'},
    {'text': 'Budget-friendly options', 'icon': '💰'},
    {'text': 'Traditional experiences', 'icon': '🕌'},
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
    _messageController.dispose();
    _scrollController.dispose();
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
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Messages
            Expanded(
              child: _messages.isEmpty 
                  ? _buildEmptyState()
                  : _buildMessagesList(),
            ),
            
            // Quick questions (show when no messages or few messages)
            if (_messages.length <= 2) _buildQuickQuestions(),
            
            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your Qatar exploration guide',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button
          IconButton(
            onPressed: _showChatSettings,
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: AppColors.gold,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ask me anything about Qatar!',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isAI = message['sender'] == 'ai';
    final timestamp = message['timestamp'] as DateTime;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.gold,
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAI 
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.gold.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isAI ? Radius.circular(4) : Radius.circular(20),
                  bottomRight: isAI ? Radius.circular(20) : Radius.circular(4),
                ),
                border: Border.all(
                  color: isAI 
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.gold,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isAI ? Colors.white : AppColors.maroon,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTime(timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isAI 
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.maroon.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (!isAI) ...[
            SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.mediumGray,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold,
            child: Text('🤖', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
                SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = (_animationController.value - (index * 0.1)) % 1.0;
        final opacity = animationValue < 0.5 ? 1.0 : 0.3;
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick questions to get you started:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((question) {
              return _buildQuickQuestionChip(question);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionChip(Map<String, String> question) {
    return GestureDetector(
      onTap: () => _sendQuickQuestion(question['text']!),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question['icon']!,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(width: 6),
            Text(
              question['text']!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            
            // Text input
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask about places, food, activities...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            SizedBox(width: 8),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: Icon(
                  Icons.send,
                  color: AppColors.maroon,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _addMessage('user', message);
    _messageController.clear();
    
    _simulateAIResponse(message);
  }

  void _sendQuickQuestion(String question) {
    _addMessage('user', question);
    _simulateAIResponse(question);
  }

  void _addMessage(String sender, String message) {
    setState(() {
      _messages.add({
        'sender': sender,
        'message': message,
        'timestamp': DateTime.now(),
        'type': 'text',
      });
    });
    
    _scrollToBottom();
  }

  void _simulateAIResponse(String userMessage) async {
    setState(() => _isLoading = true);
    
    // Simulate AI processing time
    await Future.delayed(Duration(seconds: 2));
    
    // Generate response based on user message
    String response = _generateAIResponse(userMessage);
    
    setState(() => _isLoading = false);
    _addMessage('ai', response);
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('restaurant') || message.contains('food') || message.contains('eat')) {
      return "🍽️ Great! Here are some fantastic dining options in Qatar:\n\n• **Souq Waqif** - Traditional Qatari cuisine and street food\n• **The Pearl-Qatar** - International fine dining with waterfront views\n• **Al Mourjan** - Authentic Middle Eastern flavors\n• **Katara Cultural Village** - Various cuisines in a cultural setting\n\nWhat type of cuisine are you in the mood for? I can provide more specific recommendations!";
    } else if (message.contains('cultural') || message.contains('museum') || message.contains('heritage')) {
      return "🏛️ Qatar has amazing cultural attractions! Here are must-visit places:\n\n• **Museum of Islamic Art** - World-class collection with stunning architecture\n• **National Museum of Qatar** - Qatar's history and heritage\n• **Souq Waqif** - Traditional marketplace with authentic atmosphere\n• **Katara Cultural Village** - Arts, culture, and entertainment hub\n• **Al Zubarah Fort** - UNESCO World Heritage site\n\nWould you like detailed information about any of these places?";
    } else if (message.contains('shopping') || message.contains('mall') || message.contains('buy')) {
      return "🛍️ Perfect! Qatar offers great shopping experiences:\n\n• **The Pearl-Qatar** - Luxury brands and waterfront shopping\n• **Villaggio Mall** - Italian-themed with gondola rides\n• **City Center Doha** - Large mall with entertainment\n• **Souq Waqif** - Traditional crafts and souvenirs\n• **Mall of Qatar** - One of the largest malls in the region\n\nAre you looking for luxury items, local crafts, or general shopping?";
    } else if (message.contains('family') || message.contains('kids') || message.contains('children')) {
      return "👨‍👩‍👧‍👦 Excellent! Qatar is very family-friendly. Here are top family activities:\n\n• **Aspire Park** - Large park with playgrounds and lake\n• **Katara Beach** - Family beach with facilities\n• **Aqua Park Qatar** - Water park with slides and pools\n• **Gondolania Theme Park** - Indoor amusement park\n• **MIA Park** - Great for picnics with museum views\n• **The Pearl beaches** - Clean, safe beaches for families\n\nWhat ages are the children? I can suggest more specific activities!";
    } else if (message.contains('budget') || message.contains('cheap') || message.contains('affordable')) {
      return "💰 Great question! Here are budget-friendly options in Qatar:\n\n**Free Activities:**\n• Corniche waterfront walk\n• MIA Park and outdoor areas\n• Souq Waqif browsing\n• Public beaches\n\n**Low-cost Options:**\n• Street food at Souq Waqif (QR 10-30)\n• Public transport via Metro\n• Local cafes and karak tea\n• Traditional restaurants (QR 30-60)\n\nWhat's your approximate daily budget? I can create a cost-effective itinerary!";
    } else if (message.contains('traditional') || message.contains('authentic') || message.contains('local')) {
      return "🕌 Wonderful! For authentic Qatari experiences, I recommend:\n\n• **Souq Waqif** - Traditional architecture, spices, and crafts\n• **Falcon Souq** - See Qatar's national bird up close\n• **Traditional dhow cruise** - Historic boats on the bay\n• **Camel racing** - Unique local sport (seasonal)\n• **Bedouin camps** - Desert experiences with traditional activities\n• **Local majlis** - Traditional meeting places in neighborhoods\n\nWould you like help planning a traditional Qatari day experience?";
    } else if (message.contains('weather') || message.contains('temperature') || message.contains('climate')) {
      return "🌤️ Qatar's weather varies by season:\n\n**Current Season Tips:**\n• **Winter (Nov-Mar)**: Perfect weather, 18-28°C, ideal for outdoor activities\n• **Summer (Jun-Sep)**: Very hot, 35-45°C, focus on indoor attractions\n• **Spring/Fall**: Warm but manageable, 25-35°C\n\n**Today's Recommendations:**\nBased on current weather, I'd suggest indoor attractions during midday and outdoor activities in the evening. Would you like a weather-appropriate itinerary?";
    } else if (message.contains('transport') || message.contains('metro') || message.contains('taxi') || message.contains('uber')) {
      return "🚇 Getting around Qatar is easy! Here are your options:\n\n• **Doha Metro** - Clean, efficient, covers major areas (QR 2-6)\n• **Karwa Taxi** - Official taxis, reliable and safe\n• **Uber/Careem** - Ride-sharing apps, widely available\n• **Rental cars** - Good for exploring, right-hand driving\n• **Buses** - Extensive network, very affordable\n\n**Metro Lines:** Red (major attractions), Gold (airport), Green (education city)\n\nWhere would you like to go? I can suggest the best transport option!";
    } else if (message.contains('hotel') || message.contains('stay') || message.contains('accommodation')) {
      return "🏨 Qatar has excellent accommodation options:\n\n**Luxury Hotels:**\n• Four Seasons, St. Regis, Ritz-Carlton\n• The Pearl and West Bay areas\n\n**Mid-range Options:**\n• Souq Waqif Boutique Hotels\n• City center business hotels\n\n**Budget-friendly:**\n• Hostels in Mushayreb area\n• Apartment hotels for longer stays\n\n**Areas to Consider:**\n• **West Bay**: Modern, close to business district\n• **The Pearl**: Luxury, waterfront\n• **Souq Waqif**: Traditional, cultural\n\nWhat's your budget range and preferred area?";
    } else if (message.contains('hello') || message.contains('hi') || message.contains('مرحبا')) {
      return "مرحباً! Welcome to Qatar! 🇶🇦\n\nI'm here to help you discover the best of Qatar. I can assist you with:\n\n• 🍽️ Restaurant recommendations\n• 🏛️ Cultural attractions and museums\n• 🛍️ Shopping destinations\n• 👨‍👩‍👧‍👦 Family-friendly activities\n• 💰 Budget-friendly options\n• 🚇 Transportation guidance\n• 🗺️ Creating personalized itineraries\n\nWhat would you like to explore today?";
    } else if (message.contains('help') || message.contains('what can you do')) {
      return "I'm your AI guide for Qatar! Here's how I can help:\n\n🔍 **Ask me about:**\n• Best places to visit\n• Restaurant recommendations\n• Cultural experiences\n• Shopping locations\n• Transportation options\n• Budget planning\n• Family activities\n• Traditional experiences\n\n📍 **I can create:**\n• Custom itineraries\n• Route suggestions\n• Budget estimates\n• Time-optimized plans\n\n💬 **Just ask naturally!** For example:\n\"Best restaurants near me\" or \"Plan a cultural day\" or \"Family activities under QR 200\"\n\nWhat would you like to know about Qatar?";
    } else {
      return "I'd love to help you explore Qatar! 🇶🇦\n\nI didn't quite understand your question, but I can assist you with:\n\n• Finding great restaurants and local food\n• Discovering cultural attractions and museums\n• Planning shopping trips\n• Suggesting family-friendly activities\n• Creating budget-friendly itineraries\n• Transportation and getting around\n\nCould you please rephrase your question or let me know what specific aspect of Qatar you'd like to explore?";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showChatSettings() {
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
            
            Text(
              'Chat Settings',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 20),
            
            ListTile(
              leading: Icon(Icons.clear_all, color: AppColors.gold),
              title: Text('Clear Chat History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _clearChatHistory();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.download, color: AppColors.gold),
              title: Text('Export Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _exportChat();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.feedback, color: AppColors.gold),
              title: Text('Send Feedback', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _sendFeedback();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.help_outline, color: AppColors.gold),
              title: Text('Help & Tips', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showHelpTips();
              },
            ),
            
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
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
              'Share with AI',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.photo_camera,
                  'Camera',
                  () {
                    Navigator.pop(context);
                    _shareLocation();
                  },
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    _sharePhoto();
                  },
                ),
                _buildAttachmentOption(
                  Icons.location_on,
                  'Location',
                  () {
                    Navigator.pop(context);
                    _shareLocation();
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

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Clear Chat History', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to clear all messages? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'sender': 'ai',
                  'message': 'Chat history cleared. How can I help you explore Qatar today?',
                  'timestamp': DateTime.now(),
                  'type': 'text',
                });
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportChat() {
    // Implement chat export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat exported successfully!'),
        backgroundColor: AppColors.success,
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
            hintText: 'Tell us how we can improve the AI assistant...',
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

  void _showHelpTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Help & Tips', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Tips for better responses:', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Be specific about your preferences', style: TextStyle(color: Colors.white70)),
              Text('• Mention your budget range', style: TextStyle(color: Colors.white70)),
              Text('• Tell me how much time you have', style: TextStyle(color: Colors.white70)),
              Text('• Ask for recommendations by area', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
              Text('🗣️ Example questions:', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• "Best budget restaurants in Souq Waqif"', style: TextStyle(color: Colors.white70)),
              Text('• "Plan a 4-hour cultural tour"', style: TextStyle(color: Colors.white70)),
              Text('• "Family activities under QR 200"', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _sharePhoto() {
    _addMessage('user', '📷 [Photo shared] Can you help me identify this place in Qatar?');
    _simulateAIResponse('photo shared qatar location');
  }

  void _shareLocation() {
    _addMessage('user', '📍 [Location shared] What\'s interesting near my current location?');
    _simulateAIResponse('location shared nearby attractions');
  }
}