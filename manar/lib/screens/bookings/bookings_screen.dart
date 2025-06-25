// screens/bookings/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedTab = 'upcoming';
  
  // Sample bookings data - will be replaced with Firebase data
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': '1',
      'type': 'restaurant',
      'name': 'Al Mourjan Restaurant',
      'location': 'Souq Waqif',
      'date': 'Today',
      'time': '7:30 PM',
      'guests': 4,
      'status': 'confirmed',
      'image': '🍽️',
      'bookingRef': 'MNR123456',
    },
    {
      'id': '2',
      'type': 'tour',
      'name': 'Desert Safari Experience',
      'location': 'Qatar Desert',
      'date': 'Tomorrow',
      'time': '4:00 PM',
      'guests': 2,
      'status': 'confirmed',
      'image': '🏜️',
      'bookingRef': 'DST789012',
    },
    {
      'id': '3',
      'type': 'museum',
      'name': 'Museum of Islamic Art',
      'location': 'Corniche',
      'date': 'Dec 28',
      'time': '10:00 AM',
      'guests': 3,
      'status': 'pending',
      'image': '🏛️',
      'bookingRef': 'MIA345678',
    },
  ];

  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': '4',
      'type': 'restaurant',
      'name': 'Katara Beach Restaurant',
      'location': 'Katara Cultural Village',
      'date': 'Dec 20',
      'time': '8:00 PM',
      'guests': 2,
      'status': 'completed',
      'image': '🍽️',
      'bookingRef': 'KBR901234',
      'rating': 4.5,
    },
    {
      'id': '5',
      'type': 'attraction',
      'name': 'The Pearl-Qatar Tour',
      'location': 'The Pearl',
      'date': 'Dec 18',
      'time': '2:00 PM',
      'guests': 4,
      'status': 'completed',
      'image': '🏝️',
      'bookingRef': 'TPQ567890',
      'rating': 5.0,
    },
    {
      'id': '6',
      'type': 'restaurant',
      'name': 'Souq Waqif Cafe',
      'location': 'Souq Waqif',
      'date': 'Dec 15',
      'time': '6:30 PM',
      'guests': 2,
      'status': 'cancelled',
      'image': '☕',
      'bookingRef': 'SWC123789',
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
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Bookings',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track and manage your reservations',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('upcoming', 'Upcoming', _upcomingBookings.length),
          ),
          Expanded(
            child: _buildTabButton('past', 'Past', _pastBookings.length),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String label, int count) {
    bool isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.maroon : Colors.white70,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.maroon.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.maroon : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final bookings = _selectedTab == 'upcoming' ? _upcomingBookings : _pastBookings;
    
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      backgroundColor: AppColors.darkNavy,
      color: AppColors.gold,
      child: ListView.builder(
        padding: EdgeInsets.all(24),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
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
              _selectedTab == 'upcoming' ? Icons.calendar_today : Icons.history,
              size: 50,
              color: AppColors.gold,
            ),
          ),
          SizedBox(height: 24),
          Text(
            _selectedTab == 'upcoming' ? 'No upcoming bookings' : 'No past bookings',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedTab == 'upcoming' 
                ? 'Start exploring and make your first reservation!'
                : 'Your booking history will appear here',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedTab == 'upcoming') ...[
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to explore/dashboard
                Navigator.pushNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.maroon,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Explore Qatar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    Color statusColor = _getStatusColor(booking['status']);
    bool isPast = _selectedTab == 'past';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBookingDetails(booking),
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
                // Header row
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          booking['image'],
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
                            booking['name'],
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking['location'],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking['status'].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Details row
                Row(
                  children: [
                    _buildDetailItem(Icons.calendar_today, booking['date']),
                    SizedBox(width: 24),
                    _buildDetailItem(Icons.access_time, booking['time']),
                    SizedBox(width: 24),
                    _buildDetailItem(Icons.people, '${booking['guests']} guests'),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Booking reference
                Row(
                  children: [
                    Icon(Icons.confirmation_number, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Ref: ${booking['bookingRef']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                
                // Past booking specific elements
                if (isPast && booking.containsKey('rating')) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Your rating: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < booking['rating'].floor() 
                                ? Icons.star 
                                : Icons.star_border,
                            color: AppColors.gold,
                            size: 16,
                          );
                        }),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${booking['rating']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Action buttons
                SizedBox(height: 16),
                Row(
                  children: [
                    if (!isPast && booking['status'] != 'cancelled') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _modifyBooking(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                          ),
                          child: Text('Modify'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelBooking(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                    ] else if (isPast && booking['status'] == 'completed' && !booking.containsKey('rating')) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rateExperience(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.maroon,
                          ),
                          child: Text('Rate Experience'),
                        ),
                      ),
                    ] else if (isPast) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _bookAgain(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                          ),
                          child: Text('Book Again'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.mediumGray;
    }
  }

  // Action methods
  Future<void> _refreshBookings() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      booking['image'],
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['name'],
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        booking['location'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Details
            _buildDetailRow('Date & Time', '${booking['date']} at ${booking['time']}'),
            _buildDetailRow('Guests', '${booking['guests']} people'),
            _buildDetailRow('Booking Reference', booking['bookingRef']),
            _buildDetailRow('Status', booking['status'].toUpperCase()),
            
            SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Text('Close'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _getDirections(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.maroon,
                    ),
                    child: Text('Get Directions'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  void _modifyBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Modify Booking', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the modification interface for your ${booking['name']} booking.',
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

  void _cancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Cancel Booking', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to cancel your booking at ${booking['name']}?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Booking', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _rateExperience(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Rate Your Experience', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your experience at ${booking['name']}?',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.star_border,
                    color: AppColors.gold,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
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
                  content: Text('Thank you for your rating!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Submit Rating'),
          ),
        ],
      ),
    );
  }

  void _bookAgain(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Book Again', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open the booking interface for ${booking['name']} with your previous preferences.',
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

  void _getDirections(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Text('Get Directions', style: TextStyle(color: Colors.white)),
        content: Text(
          'This would open navigation to ${booking['name']} at ${booking['location']}.',
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
}