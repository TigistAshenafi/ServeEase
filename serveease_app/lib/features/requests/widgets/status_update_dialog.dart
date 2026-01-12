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
  String? _selectedStatus;
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _scheduledDate;
  DateTime? _completionDate;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
    _scheduledDate = widget.request.scheduledDate;
    _completionDate = widget.request.completionDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validTransitions = _getValidTransitions(widget.request.status);

    return AlertDialog(
      title: const Text('Update Status'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.request.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _getStatusColor(widget.request.status)),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(widget.request.status),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status selection
              const Text(
                'New Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (validTransitions.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                      'No status transitions available from current state'),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: validTransitions.contains(_selectedStatus)
                      ? _selectedStatus
                      : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select new status',
                  ),
                  items: validTransitions
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(_getStatusDisplayName(status)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ],

              const SizedBox(height: 16),

              // Conditional fields based on selected status
              if (_selectedStatus != null) ...[
                // Scheduled date for accepted status
                if (_selectedStatus == 'accepted') ...[
                  const Text(
                    'Scheduled Date (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectScheduledDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event),
                          const SizedBox(width: 8),
                          Text(
                            _scheduledDate != null
                                ? _formatDateTime(_scheduledDate!)
                                : 'Select scheduled date',
                          ),
                          const Spacer(),
                          if (_scheduledDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _scheduledDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Completion date for completed status
                if (_selectedStatus == 'completed') ...[
                  const Text(
                    'Completion Date',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectCompletionDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available),
                          const SizedBox(width: 8),
                          Text(
                            _completionDate != null
                                ? _formatDateTime(_completionDate!)
                                : 'Select completion date',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reason for rejected/cancelled status
                if (_selectedStatus == 'rejected' ||
                    _selectedStatus == 'cancelled') ...[
                  const Text(
                    'Reason (Required)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: _selectedStatus == 'rejected'
                          ? 'Why are you rejecting this request?'
                          : 'Why is this request being cancelled?',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Add any additional notes...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canUpdate() && !_isUpdating ? _updateStatus : null,
          child: _isUpdating
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

  bool _canUpdate() {
    if (_selectedStatus == null || _selectedStatus == widget.request.status) {
      return false;
    }

    // Check if reason is required and provided
    if ((_selectedStatus == 'rejected' || _selectedStatus == 'cancelled') &&
        _reasonController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);

    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.updateStatus(
      requestId: widget.request.id,
      status: _selectedStatus!,
      scheduledDate: _scheduledDate,
      completionDate: _completionDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );

    setState(() => _isUpdating = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result.success ? 'Status updated successfully!' : result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectCompletionDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now(),
      firstDate: widget.request.createdAt,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_completionDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _completionDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  List<String> _getValidTransitions(String currentStatus) {
    const validTransitions = {
      'pending': ['accepted', 'rejected', 'cancelled'],
      'accepted': ['assigned', 'in_progress', 'cancelled'],
      'assigned': ['in_progress', 'cancelled'],
      'in_progress': ['completed', 'cancelled'],
      'completed': <String>[], // Terminal state
      'rejected': <String>[], // Terminal state
      'cancelled': <String>[], // Terminal state
    };

    return validTransitions[currentStatus] ?? <String>[];
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
