import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/shared/widgets/custom_button.dart';

class CreateRequestDialog extends StatefulWidget {
  final Service service;

  const CreateRequestDialog({
    super.key,
    required this.service,
  });

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;
  String _urgency = 'medium';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _urgencyOptions = [
    {'value': 'low', 'label': 'Low Priority', 'color': Colors.green},
    {'value': 'medium', 'label': 'Medium Priority', 'color': Colors.orange},
    {'value': 'high', 'label': 'High Priority', 'color': Colors.red},
    {'value': 'urgent', 'label': 'Urgent', 'color': Colors.red.shade700},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(hours: 1));
    final lastDate = now.add(const Duration(days: 90));

    final date = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select preferred date',
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 2)),
        ),
        helpText: 'Select preferred time',
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<ServiceRequestProvider>();
      final response = await provider.createRequest(
        serviceId: widget.service.id,
        providerId: widget.service.provider?.id ?? '',
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        scheduledDate: _scheduledDate,
        urgency: _urgency,
      );

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.serviceBooked ?? 
                'Service request sent successfully!'
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.request_quote,
                    color: theme.colorScheme.onPrimary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      l10n?.requestService ?? 'Request Service',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Info
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.service.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              widget.service.provider?.businessName ?? 'Provider',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 16.sp,
                                  color: theme.colorScheme.primary,
                                ),
                                Text(
                                  '\$${widget.service.price.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Icon(
                                  Icons.schedule,
                                  size: 16.sp,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${widget.service.durationHours}h',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Scheduled Date
                      Text(
                        'Preferred Date & Time',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: theme.colorScheme.primary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _scheduledDate != null
                                      ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${TimeOfDay.fromDateTime(_scheduledDate!).format(context)}'
                                      : 'Select date and time (optional)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _scheduledDate != null
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (_scheduledDate != null)
                                IconButton(
                                  onPressed: () => setState(() => _scheduledDate = null),
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20.sp,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Urgency Level
                      Text(
                        'Urgency Level',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _urgencyOptions.map((option) {
                          final isSelected = _urgency == option['value'];
                          return FilterChip(
                            selected: isSelected,
                            label: Text(option['label']),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _urgency = option['value']);
                              }
                            },
                            selectedColor: (option['color'] as Color).withValues(alpha: 0.2),
                            checkmarkColor: option['color'],
                            side: BorderSide(
                              color: isSelected 
                                  ? option['color'] 
                                  : theme.colorScheme.outline,
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24.h),

                      // Notes
                      Text(
                        l10n?.additionalNotes ?? 'Additional Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Any specific requirements or instructions...',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'Notes must be less than 500 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Disclaimer
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.sp,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Your request will be sent to the provider. They will review and respond within 24 hours.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting 
                          ? null 
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: 'Send Request',
                      isLoading: _isSubmitting,
                      onPressed: _submitRequest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}