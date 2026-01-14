import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/service_request_model.dart';

class StatusTimelineWidget extends StatelessWidget {
  final List<StatusChange> statusHistory;
  final String currentStatus;

  const StatusTimelineWidget({
    super.key,
    required this.statusHistory,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final allStatuses = [
      'pending',
      'accepted',
      'assigned',
      'in_progress',
      'completed',
    ];

    // Filter out cancelled/rejected from normal flow
    if (['cancelled', 'rejected'].contains(currentStatus)) {
      return _buildCancelledTimeline(context);
    }

    return Column(
      children: allStatuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = _isStatusCompleted(status);
        final isCurrent = status == currentStatus;
        final isLast = index == allStatuses.length - 1;

        return _buildTimelineItem(
          context,
          status: status,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: isLast,
          timestamp: _getStatusTimestamp(status),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    DateTime? timestamp,
  }) {
    final color = isCompleted || isCurrent ? _getStatusColor(status) : Colors.grey[300]!;
    
    return Row(
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : isCurrent
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Status info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusDisplayName(status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted || isCurrent ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledTimeline(BuildContext context) {
    final cancelledHistory = statusHistory.where((h) => 
        ['cancelled', 'rejected'].contains(h.toStatus)).toList();
    
    if (cancelledHistory.isEmpty) return const SizedBox.shrink();

    final lastChange = cancelledHistory.last;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            currentStatus == 'cancelled' ? Icons.cancel : Icons.block,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStatus == 'cancelled' ? 'Request Cancelled' : 'Request Rejected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(lastChange.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (lastChange.notes != null && lastChange.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastChange.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStatusCompleted(String status) {
    final statusOrder = ['pending', 'accepted', 'assigned', 'in_progress', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final statusIndex = statusOrder.indexOf(status);
    
    if (currentIndex == -1 || statusIndex == -1) return false;
    return statusIndex < currentIndex;
  }

  DateTime? _getStatusTimestamp(String status) {
    final change = statusHistory.firstWhere(
      (h) => h.toStatus == status,
      orElse: () => StatusChange(
        fromStatus: '',
        toStatus: status,
        timestamp: DateTime.now(),
      ),
    );
    return change.timestamp;
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
        return 'Request Submitted';
      case 'accepted':
        return 'Accepted by Provider';
      case 'assigned':
        return 'Employee Assigned';
      case 'in_progress':
        return 'Work in Progress';
      case 'completed':
        return 'Service Completed';
      case 'rejected':
        return 'Request Rejected';
      case 'cancelled':
        return 'Request Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}