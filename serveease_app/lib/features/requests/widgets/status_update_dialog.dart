import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class StatusUpdateDialog extends StatefulWidget {
  final ServiceRequest request;

  const StatusUpdateDialog({
    super.key,
    required this.request,
  });

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  String? selectedStatus;
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _scheduledDate;
  DateTime? _completionDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.request.status;
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = _getAvailableStatuses();
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.update, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Update Status'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service: ${widget.request.service.title}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(widget.request.status),
                    color: _getStatusColor(widget.request.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current: ${_getStatusDisplayName(widget.request.status)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status selection
            const Text(
              'New Status:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: availableStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_getStatusDisplayName(status)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date fields based on status
            if (selectedStatus == 'accepted' || selectedStatus == 'assigned') ...[
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(_scheduledDate != null
                    ? 'Scheduled: ${_formatDate(_scheduledDate!)}'
                    : 'Set scheduled date (optional)'),
                onTap: () => _selectScheduledDate(context),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ],
            
            if (selectedStatus == 'completed') ...[
              ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(_completionDate != null
                    ? 'Completed: ${_formatDate(_completionDate!)}'
                    : 'Set completion date (optional)'),
                onTap: () => _selectCompletionDate(context),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ],
            
            // Notes/Reason field
            TextField(
              controller: selectedStatus == 'cancelled' || selectedStatus == 'rejected'
                  ? _reasonController
                  : _notesController,
              decoration: InputDecoration(
                labelText: selectedStatus == 'cancelled' || selectedStatus == 'rejected'
                    ? 'Reason (Required)'
                    : 'Notes (Optional)',
                hintText: selectedStatus == 'cancelled' || selectedStatus == 'rejected'
                    ? 'Please provide a reason...'
                    : 'Any additional information...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_canUpdate()
              ? null
              : () => _updateStatus(context),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  List<String> _getAvailableStatuses() {
    switch (widget.request.status) {
      case 'pending':
        return ['pending', 'accepted', 'rejected', 'cancelled'];
      case 'accepted':
        return ['accepted', 'assigned', 'in_progress', 'cancelled'];
      case 'assigned':
        return ['assigned', 'in_progress', 'cancelled'];
      case 'in_progress':
        return ['in_progress', 'completed', 'cancelled'];
      case 'completed':
        return ['completed']; // Cannot change from completed
      case 'cancelled':
      case 'rejected':
        return [widget.request.status]; // Cannot change from final states
      default:
        return [widget.request.status];
    }
  }

  bool _canUpdate() {
    if (selectedStatus == null || selectedStatus == widget.request.status) {
      return false;
    }
    
    // Require reason for cancellation/rejection
    if ((selectedStatus == 'cancelled' || selectedStatus == 'rejected') &&
        _reasonController.text.trim().isEmpty) {
      return false;
    }
    
    return true;
  }

  Future<void> _selectScheduledDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _selectCompletionDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _completionDate = date);
    }
  }

  Future<void> _updateStatus(BuildContext context) async {
    if (!_canUpdate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ServiceRequestProvider>();
      final result = await provider.updateStatus(
        requestId: widget.request.id,
        status: selectedStatus!,
        scheduledDate: _scheduledDate,
        completionDate: _completionDate,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}