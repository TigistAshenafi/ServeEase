import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/service_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_profile_provider.dart';
import '../../../providers/service_request_provider.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'service_request_details_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String? providerType;

  const ProviderDashboardScreen({super.key, this.providerType});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final profileProvider = Provider.of<ProviderProfileProvider>(context, listen: false);
    final requestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    await profileProvider.loadProfile();
    await requestProvider.fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer3<AuthProvider, ProviderProfileProvider, ServiceRequestProvider>(
        builder: (context, authProvider, profileProvider, requestProvider, child) {
          final profile = profileProvider.profile;
          final providerType = profile?.providerType ?? widget.providerType ?? 'individual';
          
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, authProvider, profile, colorScheme),
              SliverToBoxAdapter(
                child: Container(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildStatsCards(requestProvider.requests, providerType),
                        const SizedBox(height: 20),
                        _buildTabSection(requestProvider, providerType),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider authProvider, profile, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.85),
                Colors.blue.shade400,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          profile?.providerType == 'organization' 
                              ? Icons.business 
                              : Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.businessName ?? 'Provider Dashboard',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.providerType == 'organization' 
                                  ? 'Organization Account' 
                                  : 'Individual Provider',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showProfileMenu(context),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      pinned: true,
      elevation: 0,
    );
  }

  Widget _buildStatsCards(List<ServiceRequest> requests, String providerType) {
    final pendingCount = requests.where((r) => r.status == 'pending').length;
    final activeCount = requests.where((r) => ['accepted', 'assigned', 'in_progress'].contains(r.status)).length;
    final completedCount = requests.where((r) => r.status == 'completed').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Pending', pendingCount, Colors.orange, Icons.pending)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Active', activeCount, Colors.blue, Icons.work)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Completed', completedCount, Colors.green, Icons.check_circle)),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection(ServiceRequestProvider requestProvider, String providerType) {
    return GlassmorphicCard(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Requests'),
              Tab(text: 'Profile'),
              Tab(text: 'Settings'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(requestProvider, providerType),
                _buildProfileTab(),
                _buildSettingsTab(providerType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(ServiceRequestProvider requestProvider, String providerType) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Requests')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    requestProvider.fetchRequests(status: value!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => requestProvider.fetchRequests(status: _selectedStatus),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: requestProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : requestProvider.requests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No service requests found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: requestProvider.requests.length,
                      itemBuilder: (context, index) {
                        final request = requestProvider.requests[index];
                        return _buildRequestCard(request, providerType, requestProvider);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(ServiceRequest request, String providerType, ServiceRequestProvider requestProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceRequestDetailsScreen(request: request),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.service.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${request.seeker.name}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Price: \$${request.service.price.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (request.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${request.notes}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (request.status == 'pending') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateRequestStatus(request.id, 'accepted', requestProvider),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateRequestStatus(request.id, 'cancelled', requestProvider),
                        child: const Text('Decline'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceRequestDetailsScreen(request: request),
                          ),
                        ),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
      case 'assigned':
        color = Colors.blue;
        break;
      case 'in_progress':
        color = Colors.purple;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer<ProviderProfileProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        
        if (profile == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No profile found'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileItem('Business Name', profile.businessName),
              _buildProfileItem('Type', profile.providerType),
              _buildProfileItem('Category', profile.category),
              _buildProfileItem('Location', profile.location),
              _buildProfileItem('Phone', profile.phone),
              _buildProfileItem('Description', profile.description),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/provider/edit-profile',
                    arguments: profile,
                  );
                },
                text: 'EDIT PROFILE',
                icon: Icons.edit,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(String providerType) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (providerType == 'organization') ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Employees'),
              subtitle: const Text('Add, edit, or remove employees'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/employees'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Organization Analytics'),
              subtitle: const Text('View business performance metrics'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showOrganizationAnalytics(),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('My Services'),
            subtitle: const Text('Manage your service offerings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/services/my'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/provider/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/provider/help'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/provider/edit-profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrganizationAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Organization Analytics'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Advanced analytics dashboard for organizations coming soon!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Track employee performance, revenue trends, and customer satisfaction.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(String requestId, String status, ServiceRequestProvider requestProvider) async {
    final result = await requestProvider.updateStatus(
      requestId: requestId,
      status: status,
    );

    if (result.success) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}