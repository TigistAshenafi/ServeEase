import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/features/chat/providers/chat_provider.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/providers/provider_profile_provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/shared/widgets/custom_button.dart';

class RequestActionButtons extends StatelessWidget {
  final ServiceRequest request;
  final bool isProvider;
  final bool isSeeker;

  const RequestActionButtons({
    super.key,
    required this.request,
    required this.isProvider,
    required this.isSeeker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Consumer2<ServiceRequestProvider, ProviderProfileProvider>(
      builder: (context, provider, profileProvider, child) {
        final isUpdating = provider.isUpdating;
        final providerType = profileProvider.profile?.providerType ?? 'individual';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Provider Actions
            if (isProvider) ..._buildProviderActions(context, theme, l10n, isUpdating, providerType),
            
            // Seeker Actions
            if (isSeeker) ..._buildSeekerActions(context, theme, l10n, isUpdating),
            
            // Common Actions
            ..._buildCommonActions(context, theme, l10n, isUpdating),
          ],
        );
      },
    );
  }

  List<Widget> _buildProviderActions(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    bool isUpdating,
    String providerType,
  ) {
    final actions = <Widget>[];

    switch (request.status) {
      case 'pending':
        actions.addAll([
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: l10n?.acceptRequest ?? 'Accept',
                  onPressed: isUpdating ? null : () => _acceptRequest(context),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: isUpdating ? null : () => _rejectRequest(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(l10n?.rejectRequest ?? 'Reject'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ]);
        break;

      case 'accepted':
        if (providerType == 'organization' && 
            request.assignedEmployeeId == null) {
          actions.addAll([
            PrimaryButton(
              text: l10n?.assignEmployee ?? 'Assign Employee',
              onPressed: isUpdating ? null : () => _assignEmployee(context),
              icon: Icons.person_add,
            ),
            SizedBox(height: 12.h),
          ]);
        }
        actions.addAll([
          PrimaryButton(
            text: l10n?.markInProgress ?? 'Start Work',
            onPressed: isUpdating ? null : () => _startWork(context),
            icon: Icons.play_arrow,
          ),
          SizedBox(height: 12.h),
        ]);
        break;

      case 'assigned':
        actions.addAll([
          PrimaryButton(
            text: l10n?.markInProgress ?? 'Start Work',
            onPressed: isUpdating ? null : () => _startWork(context),
            icon: Icons.play_arrow,
          ),
          SizedBox(height: 12.h),
        ]);
        break;

      case 'in_progress':
        actions.addAll([
          PrimaryButton(
            text: l10n?.markCompleted ?? 'Mark as Completed',
            onPressed: isUpdating ? null : () => _completeRequest(context),
            icon: Icons.check_circle,
          ),
          SizedBox(height: 12.h),
        ]);
        break;

      case 'completed':
        if (request.providerRating == null) {
          actions.addAll([
            OutlinedButton.icon(
              onPressed: isUpdating ? null : () => _rateSeeker(context),
              icon: const Icon(Icons.star),
              label: Text(l10n?.rateService ?? 'Rate Seeker'),
            ),
            SizedBox(height: 12.h),
          ]);
        }
        break;
    }

    return actions;
  }

  List<Widget> _buildSeekerActions(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    bool isUpdating,
  ) {
    final actions = <Widget>[];

    if (request.status == 'completed' && request.seekerRating == null) {
      actions.addAll([
        PrimaryButton(
          text: l10n?.rateService ?? 'Rate Service',
          onPressed: isUpdating ? null : () => _rateProvider(context),
          icon: Icons.star,
        ),
        SizedBox(height: 12.h),
      ]);
    }

    return actions;
  }

  List<Widget> _buildCommonActions(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    bool isUpdating,
  ) {
    final actions = <Widget>[];

    // Chat button (available for all active requests)
    if (!['cancelled'].contains(request.status)) {
      actions.addAll([
        OutlinedButton.icon(
          onPressed: isUpdating ? null : () => _openChat(context),
          icon: const Icon(Icons.chat),
          label: Text(l10n?.chat ?? 'Chat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
          ),
        ),
        SizedBox(height: 12.h),
      ]);
    }

    // Cancel button (available for most statuses)
    if (!['completed', 'cancelled'].contains(request.status)) {
      actions.addAll([
        OutlinedButton.icon(
          onPressed: isUpdating ? null : () => _cancelRequest(context),
          icon: const Icon(Icons.cancel),
          label: Text(l10n?.cancel ?? 'Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
        SizedBox(height: 12.h),
      ]);
    }

    return actions;
  }

  Future<void> _acceptRequest(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AcceptRequestDialog(),
    );

    if (result != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.acceptRequest(
          requestId: request.id,
          notes: result['notes'],
          scheduledDate: result['scheduledDate'],
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error accepting request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectRequestDialog(),
    );

    if (reason != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.rejectRequest(
          requestId: request.id,
          reason: reason,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _assignEmployee(BuildContext context) async {
    // This would open the employee assignment dialog
    // Implementation depends on the employee management system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee assignment feature coming soon'),
      ),
    );
  }

  Future<void> _startWork(BuildContext context) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _NotesDialog(
        title: 'Start Work',
        hint: 'Any notes about starting the work...',
      ),
    );

    if (context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.startWork(
          requestId: request.id,
          notes: notes,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error starting work: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeRequest(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CompleteRequestDialog(),
    );

    if (result != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.completeRequest(
          requestId: request.id,
          notes: result['notes'],
          actualCompletionDate: result['completionDate'],
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelRequest(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelRequestDialog(),
    );

    if (reason != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.cancelRequest(
          requestId: request.id,
          reason: reason,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rateProvider(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RatingDialog(isProvider: false),
    );

    if (result != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.addRating(
          requestId: request.id,
          rating: result['rating'],
          review: result['review'],
          isProviderReview: false,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting rating: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rateSeeker(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RatingDialog(isProvider: true),
    );

    if (result != null && context.mounted) {
      try {
        final provider = context.read<ServiceRequestProvider>();
        final response = await provider.addRating(
          requestId: request.id,
          rating: result['rating'],
          review: result['review'],
          isProviderReview: true,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting rating: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Use ChatProvider to create or get conversation for this service request
      final chatProvider = context.read<ChatProvider>();
      final conversation = await chatProvider.createConversationForServiceRequest(request.id);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        if (conversation != null) {
          // Navigate to chat screen
          Navigator.pushNamed(
            context,
            '/chat/${conversation.id}',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening chat: ${chatProvider.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Accept Request Dialog
class _AcceptRequestDialog extends StatefulWidget {
  @override
  State<_AcceptRequestDialog> createState() => _AcceptRequestDialogState();
}

class _AcceptRequestDialogState extends State<_AcceptRequestDialog> {
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Accept Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Any additional information...',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(_scheduledDate != null
                ? 'Scheduled: ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                : 'Set scheduled date (optional)'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() => _scheduledDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'notes': _notesController.text.trim().isEmpty 
                ? null 
                : _notesController.text.trim(),
            'scheduledDate': _scheduledDate,
          }),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

// Reject Request Dialog
class _RejectRequestDialog extends StatefulWidget {
  @override
  State<_RejectRequestDialog> createState() => _RejectRequestDialogState();
}

class _RejectRequestDialogState extends State<_RejectRequestDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Request'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
          hintText: 'Please provide a reason...',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isNotEmpty) {
              Navigator.pop(context, _reasonController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// Complete Request Dialog
class _CompleteRequestDialog extends StatefulWidget {
  @override
  State<_CompleteRequestDialog> createState() => _CompleteRequestDialogState();
}

class _CompleteRequestDialogState extends State<_CompleteRequestDialog> {
  final _notesController = TextEditingController();
  DateTime? _completionDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Completion notes (optional)',
              hintText: 'Summary of work completed...',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(_completionDate != null
                ? 'Completed: ${_completionDate!.day}/${_completionDate!.month}/${_completionDate!.year}'
                : 'Set completion date (optional)'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _completionDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'notes': _notesController.text.trim().isEmpty 
                ? null 
                : _notesController.text.trim(),
            'completionDate': _completionDate,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

// Cancel Request Dialog
class _CancelRequestDialog extends StatefulWidget {
  @override
  State<_CancelRequestDialog> createState() => _CancelRequestDialogState();
}

class _CancelRequestDialogState extends State<_CancelRequestDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Request'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Reason for cancellation',
          hintText: 'Please provide a reason...',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Request'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isNotEmpty) {
              Navigator.pop(context, _reasonController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel Request'),
        ),
      ],
    );
  }
}

// Notes Dialog
class _NotesDialog extends StatefulWidget {
  final String title;
  final String hint;

  const _NotesDialog({
    required this.title,
    required this.hint,
  });

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'Notes (optional)',
          hintText: widget.hint,
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            _notesController.text.trim().isEmpty 
                ? null 
                : _notesController.text.trim(),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// Rating Dialog
class _RatingDialog extends StatefulWidget {
  final bool isProvider;

  const _RatingDialog({required this.isProvider});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isProvider ? 'Rate Seeker' : 'Rate Service'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: 'Review (optional)',
              hintText: 'Share your experience...',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'rating': _rating,
            'review': _reviewController.text.trim().isEmpty 
                ? null 
                : _reviewController.text.trim(),
          }),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}