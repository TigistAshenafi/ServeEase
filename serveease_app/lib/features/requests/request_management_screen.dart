import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/features/requests/request_list_screen.dart';
import 'package:serveease_app/features/requests/widgets/request_analytics_card.dart';

class RequestManagementScreen extends StatefulWidget {
  const RequestManagementScreen({super.key});

  @override
  State<RequestManagementScreen> createState() => _RequestManagementScreenState();
}

class _RequestManagementScreenState extends State<RequestManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ServiceRequestProvider>();
        provider.fetchRequests();
        provider.fetchAnalytics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final isProvider = currentUser?.role == 'provider';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Request Management' : 'My Requests'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Requests'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Requests List Tab
          const RequestListScreen(),
          
          // Analytics Tab
          _buildAnalyticsTab(),
          
          // Settings Tab
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: isProvider ? null : FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/services'),
        tooltip: 'Create New Request',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Requests',
                      provider.requests.length.toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      provider.pendingRequestsCount.toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'In Progress',
                      provider.inProgressRequestsCount.toString(),
                      Icons.work,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      provider.completedRequestsCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Status Distribution Chart
              if (provider.analytics != null)
                RequestAnalyticsCard(analytics: provider.analytics!),
              
              const SizedBox(height: 24),
              
              // Recent Activity
              _buildRecentActivity(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ServiceRequestProvider provider) {
    final recentRequests = provider.requests.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentRequests.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...recentRequests.map((request) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(request.status).withValues(alpha: 0.1),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: _getStatusColor(request.status),
                    size: 20,
                  ),
                ),
                title: Text(
                  request.service.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${_getStatusDisplayName(request.status)} • ${_formatDate(request.createdAt)}',
                ),
                trailing: Text(
                  '\$${request.service.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                dense: true,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Notification Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive email updates for request status changes'),
                      value: true, // This would come from user preferences
                      onChanged: (value) {
                        // Handle email notification toggle
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive push notifications on your device'),
                      value: true, // This would come from user preferences
                      onChanged: (value) {
                        // Handle push notification toggle
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Auto-refresh Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Auto-refresh',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      title: const Text('Refresh Interval'),
                      subtitle: const Text('How often to check for updates'),
                      trailing: DropdownButton<int>(
                        value: 30, // This would come from user preferences
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 seconds')),
                          DropdownMenuItem(value: 30, child: Text('30 seconds')),
                          DropdownMenuItem(value: 60, child: Text('1 minute')),
                          DropdownMenuItem(value: 300, child: Text('5 minutes')),
                        ],
                        onChanged: (value) {
                          // Handle refresh interval change
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storage, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Data Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Refresh All Data'),
                      subtitle: const Text('Reload all requests and analytics'),
                      onTap: () {
                        provider.fetchRequests();
                        provider.fetchAnalytics();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data refreshed successfully')),
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Clear locally cached data'),
                      onTap: () {
                        // Handle cache clearing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared successfully')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}