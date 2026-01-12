import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/features/requests/widgets/status_timeline_widget.dart';
import 'package:serveease_app/features/requests/widgets/rating_dialog.dart';
import 'package:serveease_app/features/requests/widgets/employee_assignment_dialog.dart';
import 'package:serveease_app/features/requests/widgets/status_update_dialog.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ServiceRequestProvider>()
          .fetchRequestDetails(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.selectedRequest == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request Details')),
            body: const Center(child: Text('Request not found')),
          );
        }

        final request = provider.selectedRequest!;
        final currentUser = context.watch<AuthProvider>().user;
        final isProvider = currentUser?.id == request.providerId;
        final isSeeker = currentUser?.id == request.seekerId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Details'),
            actions: [
              if (request.notificationsEnabled)
                IconButton(
                  icon: const Icon(Icons.notifications_active),
                  onPressed: () =>
                      _toggleNotifications(context, request, false),
                )
              else
                IconButton(
                  icon: const Icon(Icons.notifications_off),
                  onPressed: () => _toggleNotifications(context, request, true),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchRequestDetails(widget.requestId),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Information
                  _buildServiceCard(request),
                  const SizedBox(height: 16),

                  // Status and Timeline
                  _buildStatusCard(request, provider),
                  const SizedBox(height: 16),

                  // Parties Information
                  _buildPartiesCard(request),
                  const SizedBox(height: 16),

                  // Employee Assignment (if applicable)
                  if (request.assignedEmployee != null ||
                      request.requiresEmployeeAssignment)
                    _buildEmployeeCard(request, isProvider),
                  if (request.assignedEmployee != null ||
                      request.requiresEmployeeAssignment)
                    const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(context, request, isProvider, isSeeker),
                  const SizedBox(height: 16),

                  // Rating Section
                  if (request.isCompleted)
                    _buildRatingCard(request, isProvider, isSeeker),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(ServiceRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Service Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.service.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                Text('\$${request.service.price.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                Text('${request.service.durationHours}h'),
                const SizedBox(width: 16),
                Icon(Icons.priority_high, size: 16, color: Colors.grey[600]),
                Text(request.urgency.toUpperCase()),
              ],
            ),
            if (request.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${request.notes}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            if (request.scheduledDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Scheduled: ${_formatDate(request.scheduledDate!)}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      ServiceRequest request, ServiceRequestProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(request.status),
                    color: _getStatusColor(request.status)),
                const SizedBox(width: 8),
                const Text(
                  'Status & Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(request.status)),
              ),
              child: Text(
                _getStatusDisplayName(request.status),
                style: TextStyle(
                  color: _getStatusColor(request.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            StatusTimelineWidget(
              statusHistory: provider.statusHistory,
              currentStatus: request.status,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiesCard(ServiceRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Parties',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(request.seeker.name),
              subtitle: Text(request.seeker.email ?? 'Customer'),
              trailing: const Text('Seeker', style: TextStyle(fontSize: 12)),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.business, color: Colors.white),
              ),
              title:
                  Text(request.provider.businessName ?? request.provider.name),
              subtitle: Text(
                  request.provider.location ?? request.provider.email ?? ''),
              trailing: const Text('Provider', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(ServiceRequest request, bool isProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_ind, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Employee Assignment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (request.assignedEmployee != null) ...[
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person_pin, color: Colors.white),
                ),
                title: Text(request.assignedEmployee!.name),
                subtitle: Text(
                    '${request.assignedEmployee!.position} • ${request.assignedEmployee!.email}'),
                trailing: isProvider
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEmployeeAssignmentDialog(context, request),
                      )
                    : null,
              ),
              if (request.assignedEmployee!.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: request.assignedEmployee!.skills
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor:
                                Colors.purple.withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
              ],
            ] else if (request.requiresEmployeeAssignment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Employee assignment required'),
                    ),
                    if (isProvider)
                      ElevatedButton(
                        onPressed: () =>
                            _showEmployeeAssignmentDialog(context, request),
                        child: const Text('Assign'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceRequest request,
      bool isProvider, bool isSeeker) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Provider actions
                if (isProvider) ...[
                  if (request.isPending) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      onPressed: () => _acceptRequest(context, request),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      onPressed: () => _rejectRequest(context, request),
                    ),
                  ],
                  if (request.status == 'accepted' ||
                      request.status == 'assigned') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Work'),
                      onPressed: () => _startWork(context, request),
                    ),
                  ],
                  if (request.isInProgress) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete'),
                      onPressed: () => _completeRequest(context, request),
                    ),
                  ],
                ],

                // Common actions
                if ((isProvider || isSeeker) &&
                    !['completed', 'rejected', 'cancelled']
                        .contains(request.status)) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () => _cancelRequest(context, request),
                  ),
                ],

                // Status update action
                if (isProvider) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Update Status'),
                    onPressed: () => _showStatusUpdateDialog(context, request),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(
      ServiceRequest request, bool isProvider, bool isSeeker) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Ratings & Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Seeker rating
            if (request.seekerRating != null) ...[
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Customer Rating'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                          5,
                          (index) => Icon(
                                index < request.seekerRating!
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                    ),
                    if (request.seekerReview != null)
                      Text(request.seekerReview!),
                  ],
                ),
              ),
            ] else if (isSeeker) ...[
              ListTile(
                leading: const Icon(Icons.rate_review, color: Colors.blue),
                title: const Text('Rate this service'),
                trailing: ElevatedButton(
                  onPressed: () => _showRatingDialog(context, request, false),
                  child: const Text('Rate'),
                ),
              ),
            ],

            // Provider rating
            if (request.providerRating != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.business, color: Colors.orange),
                title: const Text('Provider Rating'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                          5,
                          (index) => Icon(
                                index < request.providerRating!
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                    ),
                    if (request.providerReview != null)
                      Text(request.providerReview!),
                  ],
                ),
              ),
            ] else if (isProvider) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.rate_review, color: Colors.orange),
                title: const Text('Rate this customer'),
                trailing: ElevatedButton(
                  onPressed: () => _showRatingDialog(context, request, true),
                  child: const Text('Rate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _acceptRequest(
      BuildContext context, ServiceRequest request) async {
    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.acceptRequest(requestId: request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _rejectRequest(
      BuildContext context, ServiceRequest request) async {
    final reason = await _showReasonDialog(
        context, 'Reject Request', 'Please provide a reason for rejection:');
    if (reason != null && reason.isNotEmpty && context.mounted) {
      final provider = context.read<ServiceRequestProvider>();
      final result =
          await provider.rejectRequest(requestId: request.id, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  Future<void> _startWork(BuildContext context, ServiceRequest request) async {
    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.startWork(requestId: request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _completeRequest(
      BuildContext context, ServiceRequest request) async {
    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.completeRequest(
      requestId: request.id,
      actualCompletionDate: DateTime.now(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _cancelRequest(
      BuildContext context, ServiceRequest request) async {
    final reason = await _showReasonDialog(
        context, 'Cancel Request', 'Please provide a reason for cancellation:');
    if (reason != null && reason.isNotEmpty && context.mounted) {
      final provider = context.read<ServiceRequestProvider>();
      final result =
          await provider.cancelRequest(requestId: request.id, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  Future<void> _toggleNotifications(
      BuildContext context, ServiceRequest request, bool enabled) async {
    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.toggleNotifications(
        requestId: request.id, enabled: enabled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  // Dialog methods
  void _showEmployeeAssignmentDialog(
      BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(request: request),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(request: request),
    );
  }

  void _showRatingDialog(
      BuildContext context, ServiceRequest request, bool isProviderReview) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        request: request,
        isProviderReview: isProviderReview,
      ),
    );
  }

  Future<String?> _showReasonDialog(
      BuildContext context, String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

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
}
