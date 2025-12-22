import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:serveease_app/features/ai/ai_chat_screen.dart';
import 'package:serveease_app/features/employees/employee_list_screen.dart';
import 'package:serveease_app/features/requests/request_list_screen.dart';
import 'package:serveease_app/features/services/my_services_screen.dart';
import 'package:serveease_app/features/services/service_catalog_screen.dart';
import 'package:serveease_app/features/admin/provider_approvals_screen.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/core/utils/responsive.dart';
import 'package:serveease_app/shared/widgets/service_card.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _loading = false;

  List<Widget> _buildTabs(String role) {
    if (role == 'admin') {
      return  [
        ProviderApprovalsScreen(),
        RequestListScreen(),
        AiChatScreen(),
        ProfileTab(),
      ];
    }
    if (role == 'provider') {
      return  [
        ProviderDashboardTab(),
        MyServicesScreen(),
        RequestListScreen(),
        EmployeeListScreen(),
        AiChatScreen(),
        ProfileTab(),
      ];
    }
    return  [
      SeekerDashboardTab(),
      ServiceCatalogScreen(),
      RequestListScreen(),
      AiChatScreen(),
      ProfileTab(),
    ];
  }

  List<BottomNavigationBarItem> _navItems(String role) {
    if (role == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'Approvals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    if (role == 'provider') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_available),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Team',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Explore',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Services',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Requests',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.smart_toy),
        label: 'AI',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  void _logout() async {
    setState(() => _loading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = user?.role ?? 'seeker';

    final tabs = _buildTabs(role);
    final navItems = _navItems(role);
    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.handyman, color: Colors.white),
            SizedBox(width: 10),
            Text('ServeEase'),
          ],
        ),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        actions: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'profile') {
                  _selectedIndex = navItems.length - 1;
                  setState(() {});
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 10),
                      Text('My Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.name ?? 'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.email ?? 'email@example.com',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                user?.role == 'provider' ? Icons.work : Icons.person,
                color: Colors.blue[700],
                size: 40,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue[700]),
            title: Text('Notifications'),
            trailing: Badge(
              label: Text('3'),
              backgroundColor: Colors.red,
            ),
            onTap: () {
              // Navigate to notifications
            },
          ),
          ListTile(
            leading: Icon(Icons.message, color: Colors.blue[700]),
            title: Text('Messages'),
            trailing: Badge(
              label: Text('5'),
              backgroundColor: Colors.green,
            ),
            onTap: () {
              // Navigate to messages
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.blue[700]),
            title: Text('Settings'),
            onTap: () {
              // Navigate to settings
            },
          ),
          if (user?.role == 'seeker')
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.pink),
              title: Text('Favorites'),
              onTap: () {
                // Navigate to favorites
              },
            ),
          if (user?.role == 'provider')
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.purple),
              title: Text('Analytics'),
              onTap: () {
                // Navigate to analytics
              },
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.help, color: Colors.orange),
            title: Text('Help & Support'),
            onTap: () {
              // Navigate to help
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('About'),
            onTap: () {
              // Navigate to about
            },
          ),
          Spacer(),
          Container(
            color: Colors.grey[100],
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

// =============== SEEKER TABS ===============

class SeekerDashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[800]!, Colors.blue[400]!],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handyman, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Find Services Near You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Book trusted professionals for any task',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Quick Stats
              _buildStatsCard(context),
              SizedBox(height: 20),
              
              // Popular Categories
              Text(
                'Popular Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildCategoriesGrid(),
              SizedBox(height: 20),
              
              // Recent Bookings
              _buildRecentBookings(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Active', '3', Icons.schedule, Colors.blue),
            _buildStatItem('Completed', '12', Icons.check_circle, Colors.green),
            _buildStatItem('Pending', '1', Icons.pending, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.blue},
      {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.orange},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.green},
      {'name': 'Moving', 'icon': Icons.local_shipping, 'color': Colors.purple},
      {'name': 'Repair', 'icon': Icons.build, 'color': Colors.red},
      {'name': 'More', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              // Navigate to category
            },
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category['icon'] as IconData, color: category['color'] as Color, size: 30),
                SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookings() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all bookings
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildBookingItem('Plumber', 'Today, 10 AM', 'Confirmed', Colors.green),
            _buildBookingItem('Electrician', 'Tomorrow, 2 PM', 'Pending', Colors.orange),
            _buildBookingItem('Cleaner', 'Dec 12, 9 AM', 'Completed', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(String service, String time, String status, Color statusColor) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.work, color: Colors.blue),
      ),
      title: Text(service, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(time),
      trailing: Chip(
        label: Text(
          status,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: statusColor,
      ),
    );
  }
}

// =============== PROVIDER TABS ===============

class ProviderDashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 150,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[800]!, Colors.green[400]!],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Service Provider Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage your services and appointments',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Earnings Summary
              _buildEarningsCard(),
              SizedBox(height: 20),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildQuickActions(),
              SizedBox(height: 20),
              
              // Today's Appointments
              _buildTodayAppointments(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '\$2,450.00',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEarningItem('Completed', '24', Colors.green),
                _buildEarningItem('Pending', '5', Colors.orange),
                _buildEarningItem('Cancelled', '2', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Add Service', 'icon': Icons.add_circle, 'color': Colors.blue},
      {'label': 'Schedule', 'icon': Icons.calendar_today, 'color': Colors.green},
      {'label': 'Messages', 'icon': Icons.message, 'color': Colors.purple},
      {'label': 'Reviews', 'icon': Icons.star, 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              // Handle action
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color),
                  SizedBox(width: 12),
                  Text(
                    action['label'] as String,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAppointments() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Appointments",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Badge(
                  label: Text('3'),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildAppointmentItem('John D.', 'Plumbing Repair', '10:00 AM'),
            _buildAppointmentItem('Sarah M.', 'Installation', '2:30 PM'),
            _buildAppointmentItem('Mike R.', 'Maintenance', '4:00 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String name, String service, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(Icons.person, color: Colors.blue),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(service),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Chip(
            label: Text(
              'Upcoming',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ],
      ),
    );
  }
}

// =============== OTHER TABS ===============

class ServicesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Services',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Browse and book services',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class MyServicesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'My Services',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Manage your offered services',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class BookingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Bookings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'View your bookings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class AppointmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Appointments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Manage your appointments',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class EarningsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Earnings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'View your earnings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        user?.role == 'provider' ? Icons.work : Icons.person,
                        size: 40,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User Name',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            user?.email ?? 'email@example.com',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Chip(
                            label: Text(
                              user?.role?.toUpperCase() ?? 'USER',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: user?.role == 'provider'
                                ? Colors.green[700]
                                : Colors.blue[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Account Info
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _buildProfileItem('Email', user?.email ?? 'N/A'),
                  _buildProfileItem('Member Since', 'Nov 2024'),
                  _buildProfileItem('Status', 'Active', isVerified: user?.emailVerified ?? false),
                  _buildProfileItem('Total Bookings', '15'),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Settings
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _buildSettingItem('Edit Profile', Icons.edit),
                  _buildSettingItem('Change Password', Icons.lock),
                  _buildSettingItem('Notification Settings', Icons.notifications),
                  _buildSettingItem('Privacy', Icons.privacy_tip),
                  _buildSettingItem('Help & Support', Icons.help),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, {bool isVerified = false}) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
      trailing: isVerified
          ? Icon(Icons.verified, color: Colors.green)
          : null,
    );
  }

  Widget _buildSettingItem(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Handle setting tap
      },
    );
  }
}