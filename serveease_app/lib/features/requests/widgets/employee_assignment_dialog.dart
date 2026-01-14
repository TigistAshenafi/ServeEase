import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class EmployeeAssignmentDialog extends StatefulWidget {
  final ServiceRequest request;

  const EmployeeAssignmentDialog({
    super.key,
    required this.request,
  });

  @override
  State<EmployeeAssignmentDialog> createState() => _EmployeeAssignmentDialogState();
}

class _EmployeeAssignmentDialogState extends State<EmployeeAssignmentDialog> {
  String? selectedEmployeeId;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch available employees when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceRequestProvider>().fetchAvailableEmployees(
        requestId: widget.request.id,
        requiredSkills: [], // Could be derived from service requirements
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.purple),
              SizedBox(width: 8),
              Text('Assign Employee'),
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
                
                // Employee selection
                const Text(
                  'Select Employee:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (provider.isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (provider.availableEmployees.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No available employees found for this service.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.availableEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = provider.availableEmployees[index];
                        final isSelected = selectedEmployeeId == employee.id;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedEmployeeId = employee.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.purple.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.purple 
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: employee.id,
                                  groupValue: selectedEmployeeId,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedEmployeeId = value;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        employee.position,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (employee.skills.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          children: employee.skills.take(3).map((skill) => 
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                skill,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            ),
                                          ).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Assignment notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Notes (Optional)',
                    hintText: 'Any specific instructions for the employee...',
                    border: OutlineInputBorder(),
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
              onPressed: _isLoading || selectedEmployeeId == null
                  ? null
                  : () => _assignEmployee(context, provider),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignEmployee(
    BuildContext context,
    ServiceRequestProvider provider,
  ) async {
    if (selectedEmployeeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await provider.assignEmployee(
        requestId: widget.request.id,
        employeeId: selectedEmployeeId!,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
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
            content: Text('Error assigning employee: ${e.toString()}'),
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}