import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/service_request_provider.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/provider_profile_provider.dart';
import '../../../core/models/service_request_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/widgets/gradient_button.dart';

class ServiceRequestDetailsScreen extends StatefulWidget {
  final ServiceRequest request;

  const ServiceRequestDetailsScreen({super.key, required this.request});

  @override
  State<ServiceRequestDetailsScreen> createState() => _ServiceRequestDetailsScreenState();
}

class _ServiceRequestDetailsScreenState extends State<ServiceRequestDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load employees if this is an organization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProviderProfileProvider>(context, listen: false);
      if (profileProvider.profile?.providerType == 'organization') {
        Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Service Request Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer3<ServiceRequestProvider, EmployeeProvider, ProviderProfileProvider>(
        builder: (context, requestProvider, employeeProvider, profileProvider, child) {
          final providerType = profileProvider.profile?.providerType ?? 'individual';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestHeader(),
                const SizedBox(height: 20),
                _buildServiceDetails(),
                const SizedBox(height: 20),
                _buildClientDetails(),
                const SizedBox(height: 20),
                if (widget.request.notes != null) ...[
                  _buildNotesSection(),
                  const SizedBox(height: 20),
                ],
                _buildStatusSection(requestProvider, providerType),
                const SizedBox(height: 20),
                if (providerType == 'organization' && 
                    widget.request.status == 'accepted') ...[
                  _buildEmployeeAssignment(requestProvider, employeeProvider),
                  const SizedBox(height: 20),
                ],
                _buildActionButtons(requestProvider, providerType),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestHeader() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.request.service.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(widget.request.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Requested: ${_formatDate(widget.request.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            if (widget.request.scheduledDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled: ${_formatDate(widget.request.scheduledDate!)}',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Price', '\$${widget.request.service.price.toStringAsFixed(2)}'),
            _buildDetailRow('Duration', '${widget.request.service.durationHours} hours'),
            if (widget.request.assignedEmployeeId != null)
              _buildDetailRow('Assigned Employee', 'Employee ID: ${widget.request.assignedEmployeeId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDetails() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Name', widget.request.seeker.name),
            if (widget.request.seeker.email != null)
              _buildDetailRow('Email', widget.request.seeker.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.request.notes!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ServiceRequestProvider requestProvider, String providerType) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = ['pending', 'accepted', 'assigned', 'in_progress', 'completed'];
    final currentIndex = statuses.indexOf(widget.request.status);
    
    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? (isCurrent ? Colors.blue : Colors.green)
                    : Colors.grey.shade300,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getStatusDisplayName(status),
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmployeeAssignment(ServiceRequestProvider requestProvider, EmployeeProvider employeeProvider) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.request.assignedEmployeeId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Employee assigned: ${widget.request.assignedEmployeeId}',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Select an employee to assign to this request:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (employeeProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (employeeProvider.employees.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('No employees available. Add employees first.'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: employeeProvider.employees
                      .where((e) => e.isActive)
                      .map((employee) => _buildEmployeeCard(employee, requestProvider))
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee, ServiceRequestProvider requestProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(employee.name),
        subtitle: Text('${employee.role} • ${employee.skills.join(', ')}'),
        trailing: ElevatedButton(
          onPressed: () => _assignEmployee(employee.id, requestProvider),
          child: const Text('Assign'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ServiceRequestProvider requestProvider, String providerType) {
    return Column(
      children: [
        if (widget.request.status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: () => _updateStatus('accepted', requestProvider),
                  text: 'ACCEPT REQUEST',
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('cancelled', requestProvider),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('DECLINE', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (widget.request.status == 'accepted' && providerType == 'individual') ...[
          GradientButton(
            onPressed: () => _updateStatus('in_progress', requestProvider),
            text: 'START WORK',
            icon: Icons.play_arrow,
          ),
        ],
        if (widget.request.status == 'assigned' || 
            (widget.request.status == 'accepted' && providerType == 'individual')) ...[
          GradientButton(
            onPressed: () => _updateStatus('in_progress', requestProvider),
            text: 'START WORK',
            icon: Icons.play_arrow,
          ),
        ],
        if (widget.request.status == 'in_progress') ...[
          GradientButton(
            onPressed: () => _updateStatus('completed', requestProvider),
            text: 'MARK COMPLETED',
            icon: Icons.check_circle,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'accepted':
        return 'Accepted';
      case 'assigned':
        return 'Employee Assigned';
      case 'in_progress':
        return 'Work in Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(String status, ServiceRequestProvider requestProvider) async {
    final result = await requestProvider.updateStatus(
      requestId: widget.request.id,
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
        Navigator.pop(context);
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

  Future<void> _assignEmployee(String employeeId, ServiceRequestProvider requestProvider) async {
    final result = await requestProvider.assignEmployee(
      requestId: widget.request.id,
      employeeId: employeeId,
    );

    if (result.success) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign employee: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}