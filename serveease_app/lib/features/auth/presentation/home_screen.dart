// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/features/admin/provider_approvals_screen.dart';
import 'package:serveease_app/features/ai/ai_chat_screen.dart';
import 'package:serveease_app/features/employees/employee_list_screen.dart';
import 'package:serveease_app/features/requests/request_list_screen.dart';
import 'package:serveease_app/features/services/my_services_screen.dart';
import 'package:serveease_app/features/services/service_catalog_screen.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/app_bar_language_toggle.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/providers/provider_profile_provider.dart';
import 'package:serveease_app/providers/service_provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProviderProfile();
  }

  Future<void> _loadProviderProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.role == 'provider') {
      final profileProvider =
          Provider.of<ProviderProfileProvider>(context, listen: false);
      await profileProvider.loadProfile();
    }
  }

  List<Widget> _buildTabs(String role) {
    if (role == 'admin') {
      return [
        ProviderApprovalsScreen(),
        RequestListScreen(),
        AiChatScreen(),
        ProfileTab(),
      ];
    }
    if (role == 'provider') {
      return [
        ProviderDashboardTab(),
        MyServicesScreen(),
        RequestListScreen(),
        EmployeeListScreen(),
        AiChatScreen(),
        ProfileTab(),
      ];
    }
    return [
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
          // Language Toggle
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: AppBarLanguageToggle(
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
          ),
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

class SeekerDashboardTab extends StatefulWidget {
  const SeekerDashboardTab({super.key});

  @override
  State<SeekerDashboardTab> createState() => _SeekerDashboardTabState();
}

class _SeekerDashboardTabState extends State<SeekerDashboardTab> {
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load service requests
    context.read<ServiceRequestProvider>().fetchRequests();

    // Load service categories
    await _loadServiceCategories();
  }

  Future<void> _loadServiceCategories() async {
    try {
      final response =
          await ApiService.get('${ApiService.servicesBase}/categories');
      if (response.statusCode == 200) {
        final apiResponse = ApiService.handleResponse<Map<String, dynamic>>(
          response,
          (json) => json as Map<String, dynamic>,
        );
        if (apiResponse.success && apiResponse.data != null) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(
                apiResponse.data!['categories'] ?? []);
            _loadingCategories = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestProvider>(
      builder: (context, requestProvider, child) {
        return RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                automaticallyImplyLeading: false,
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
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Stats
                    _buildStatsCard(requestProvider),
                    SizedBox(height: 20.h),

                    // Service Categories
                    Text(
                      AppLocalizations.of(context)?.services ??
                          'Service Categories',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _buildCategoriesGrid(),
                    SizedBox(height: 20.h),

                    // Recent Bookings
                    _buildRecentBookings(requestProvider),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(ServiceRequestProvider requestProvider) {
    final requests = requestProvider.requests;
    final activeCount = requests
        .where(
            (r) => ['accepted', 'assigned', 'in_progress'].contains(r.status))
        .length;
    final completedCount =
        requests.where((r) => r.status == 'completed').length;
    final pendingCount = requests.where((r) => r.status == 'pending').length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                'Active', '$activeCount', Icons.schedule, Colors.blue),
            _buildStatItem('Completed', '$completedCount', Icons.check_circle,
                Colors.green),
            _buildStatItem(
                'Pending', '$pendingCount', Icons.pending, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    if (_loadingCategories) {
      return SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Map category icons to Flutter icons
    final iconMap = {
      'home_repair': Icons.home_repair_service,
      'cleaning': Icons.cleaning_services,
      'gardening': Icons.grass,
      'education': Icons.school,
      'computer': Icons.computer,
      'car': Icons.directions_car,
      'spa': Icons.spa,
      'pets': Icons.pets,
      'truck': Icons.local_shipping,
      'party': Icons.celebration,
    };

    final colorMap = {
      'home_repair': Colors.blue,
      'cleaning': Colors.green,
      'gardening': Colors.green[700],
      'education': Colors.purple,
      'computer': Colors.indigo,
      'car': Colors.red,
      'spa': Colors.pink,
      'pets': Colors.orange,
      'truck': Colors.brown,
      'party': Colors.amber,
    };

    final displayCategories = _categories.take(6).toList();

    // Get screen width to determine responsive layout
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine cross axis count based on screen size
    int crossAxisCount;
    double childAspectRatio;
    double iconSize;
    double fontSize;

    if (screenWidth < 600) {
      // Mobile phones
      crossAxisCount = 3;
      childAspectRatio = 0.85;
      iconSize = 20.sp; // Reduced from 28.sp
      fontSize = 11.sp;
    } else if (screenWidth < 900) {
      // Tablets
      crossAxisCount = 4;
      childAspectRatio = 0.9;
      iconSize = 24.sp; // Reduced from 32.sp
      fontSize = 12.sp;
    } else {
      // Large tablets/Desktop
      crossAxisCount = 6;
      childAspectRatio = 1.0;
      iconSize = 28.sp; // Reduced from 36.sp
      fontSize = 13.sp;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: displayCategories.length > 5 ? 6 : displayCategories.length,
      itemBuilder: (context, index) {
        if (index == 5 && _categories.length > 6) {
          // Show "More" card if there are more than 6 categories
          return Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/services/catalog');
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz, color: Colors.grey, size: 30),
                  SizedBox(height: 8),
                  Text(
                    'More',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final category = displayCategories[index];
        final icon = iconMap[category['icon']] ?? Icons.category;
        final color = colorMap[category['icon']] ?? Colors.grey;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/services/catalog');
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Flexible(
                    child: Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookings(ServiceRequestProvider requestProvider) {
    final recentRequests = requestProvider.requests.take(3).toList();

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
                    Navigator.pushNamed(context, '/requests');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (requestProvider.isLoading)
              Center(child: CircularProgressIndicator())
            else if (recentRequests.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'No bookings yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Start by browsing our services',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentRequests.map((request) => _buildBookingItem(request)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(dynamic request) {
    Color statusColor;
    switch (request.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'assigned':
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.work, color: Colors.blue),
      ),
      title: Text(
        request.service?.title ?? 'Service Request',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        request.createdAt != null
            ? DateFormat('MMM dd, yyyy').format(request.createdAt)
            : 'Recent',
      ),
      trailing: Chip(
        label: Text(
          request.status.toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: statusColor,
      ),
    );
  }
}

// =============== PROVIDER TABS ===============

class ProviderDashboardTab extends StatefulWidget {
  const ProviderDashboardTab({super.key});

  @override
  State<ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<ProviderDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load service requests
    context.read<ServiceRequestProvider>().fetchRequests();
    // Load provider services
    context.read<ServiceProvider>().loadMyServices();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServiceRequestProvider, ServiceProvider>(
      builder: (context, requestProvider, serviceProvider, child) {
        return RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                automaticallyImplyLeading: false,
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
                    _buildEarningsCard(requestProvider, serviceProvider),
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

                    // Recent Requests
                    _buildRecentRequests(requestProvider),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsCard(
      ServiceRequestProvider requestProvider, ServiceProvider serviceProvider) {
    final requests = requestProvider.requests;
    final completedRequests =
        requests.where((r) => r.status == 'completed').toList();
    final pendingRequests =
        requests.where((r) => r.status == 'pending').toList();
    final cancelledRequests =
        requests.where((r) => r.status == 'cancelled').toList();

    // Calculate monthly earnings (this month's completed requests)
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final monthlyCompleted = completedRequests.where((r) {
      return r.createdAt.isAfter(thisMonth);
    }).toList();

    // Estimate earnings (you might want to add actual price calculation)
    final monthlyEarnings =
        monthlyCompleted.length * 50.0; // Placeholder calculation

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
              '\$${monthlyEarnings.toStringAsFixed(2)}',
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
                _buildEarningItem(
                    'Completed', '${completedRequests.length}', Colors.green),
                _buildEarningItem(
                    'Pending', '${pendingRequests.length}', Colors.orange),
                _buildEarningItem(
                    'Cancelled', '${cancelledRequests.length}', Colors.red),
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
      {
        'label': 'Add Service',
        'icon': Icons.add_circle,
        'color': Colors.blue,
        'route': '/services/my'
      },
      {
        'label': 'View Requests',
        'icon': Icons.list_alt,
        'color': Colors.green,
        'route': '/requests'
      },
      {
        'label': 'Messages',
        'icon': Icons.message,
        'color': Colors.purple,
        'route': '/requests'
      },
      {
        'label': 'AI Assistant',
        'icon': Icons.smart_toy,
        'color': Colors.orange,
        'route': '/ai'
      },
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
              Navigator.pushNamed(context, action['route'] as String);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(action['icon'] as IconData,
                      color: action['color'] as Color),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action['label'] as String,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentRequests(ServiceRequestProvider requestProvider) {
    final recentRequests = requestProvider.requests.take(5).toList();
    final todayRequests = recentRequests.where((r) {
      final requestDate = r.createdAt;
      final today = DateTime.now();
      return requestDate.year == today.year &&
          requestDate.month == today.month &&
          requestDate.day == today.day;
    }).toList();

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
                  "Recent Requests",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Badge(
                  label: Text('${todayRequests.length}'),
                  backgroundColor: Colors.blue,
                  child: Text('Today'),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (requestProvider.isLoading)
              Center(child: CircularProgressIndicator())
            else if (recentRequests.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'No requests yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Requests will appear here when customers book your services',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentRequests.map((request) => _buildRequestItem(request)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(dynamic request) {
    Color statusColor;
    switch (request.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'assigned':
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(Icons.person, color: statusColor),
      ),
      title: Text(
        request.seeker?.name ?? 'Customer',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(request.service?.title ?? 'Service Request'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            request.createdAt != null
                ? DateFormat('MMM dd').format(request.createdAt!)
                : 'Recent',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 4),
          Chip(
            label: Text(
              request.status.toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: statusColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/requests');
      },
    );
  }
}

// =============== OTHER TABS ===============

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

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
  const MyServicesTab({super.key});

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
  const BookingsTab({super.key});

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
  const AppointmentsTab({super.key});

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
  const EarningsTab({super.key});

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
  const ProfileTab({super.key});

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
              child: InkWell(
                onTap: () {
                  if (user?.role == 'provider') {
                    Navigator.pushNamed(context, '/provider/profile');
                  } else {
                    _showEditProfileDialog(context, user);
                  }
                },
                borderRadius: BorderRadius.circular(8),
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
                                user?.role.toUpperCase() ?? 'USER',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: user?.role == 'provider'
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit, color: Colors.grey[600]),
                    ],
                  ),
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
                  _buildProfileItem('Status', 'Active',
                      isVerified: user?.emailVerified ?? false),
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
                  _buildSettingItem('Edit Profile', Icons.edit, context),
                  _buildSettingItem('Change Password', Icons.lock, context),
                  _buildSettingItem(
                      'Notification Settings', Icons.notifications, context),
                  _buildSettingItem('Privacy', Icons.privacy_tip, context),
                  _buildSettingItem('Help & Support', Icons.help, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value,
      {bool isVerified = false}) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
      trailing: isVerified ? Icon(Icons.verified, color: Colors.green) : null,
    );
  }

  Widget _buildSettingItem(String label, IconData icon, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        _handleSettingTap(context, label);
      },
    );
  }

  void _handleSettingTap(BuildContext context, String setting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    switch (setting) {
      case 'Edit Profile':
        if (user?.role == 'provider') {
          // Navigate to provider profile edit
          Navigator.pushNamed(context, '/provider/edit-profile');
        } else {
          // For seekers, show a profile edit dialog or navigate to a profile edit screen
          _showEditProfileDialog(context, user);
        }
        break;
      case 'Change Password':
        _showChangePasswordDialog(context);
        break;
      case 'Notification Settings':
        _showNotificationSettings(context);
        break;
      case 'Privacy':
        _showPrivacySettings(context);
        break;
      case 'Help & Support':
        _showHelpAndSupport(context);
        break;
    }
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false, // Email usually can't be changed
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
              
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Profile update feature coming soon!')),
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match!')),
                  );
                  return;
                }
              
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Password change feature coming soon!')),
                );
                Navigator.pop(context);
              },
              child: Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Push Notifications'),
                subtitle: Text('Receive notifications for new requests'),
                value: true,
                onChanged: (bool value) {

                },
              ),
              SwitchListTile(
                title: Text('Email Notifications'),
                subtitle: Text('Receive email updates'),
                value: false,
                onChanged: (bool value) {

                },
              ),
              SwitchListTile(
                title: Text('SMS Notifications'),
                subtitle: Text('Receive SMS alerts'),
                value: false,
                onChanged: (bool value) {
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification settings saved!')),
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Privacy Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Profile Visibility'),
                subtitle: Text('Control who can see your profile'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Location Sharing'),
                subtitle: Text('Control location sharing preferences'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('FAQ'),
                subtitle: Text('Frequently asked questions'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_support),
                title: Text('Contact Support'),
                subtitle: Text('Get help from our support team'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(Icons.feedback),
                title: Text('Send Feedback'),
                subtitle: Text('Help us improve the app'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
