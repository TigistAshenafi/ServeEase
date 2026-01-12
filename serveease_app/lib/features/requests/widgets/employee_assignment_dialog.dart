import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/employee_assignment_service.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class EmployeeAssignmentDialog extends StatefulWidget {
  final ServiceRequest request;

  const EmployeeAssignmentDialog({
    super.key,
    required this.request,
  });

  @override
  State<EmployeeAssignmentDialog> createState() =>
      _EmployeeAssignmentDialogState();
}

class _EmployeeAssignmentDialogState extends State<EmployeeAssignmentDialog> {
  String? _selectedEmployeeId;
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isAssigning = false;
  List<EmployeeAssignmentRecommendation> _recommendations = [];
  List<String> _requiredSkills = [];

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.request.assignedEmployeeId;
    _requiredSkills = _getRequiredSkills();
    _loadAssignmentRecommendations();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignmentRecommendations() async {
    try {
      final result =
          await EmployeeAssignmentService.getAssignmentRecommendations(
        requestId: widget.request.id,
        requiredSkills: _requiredSkills,
        preferredStartTime: widget.request.scheduledDate,
        preferredEndTime: widget.request.scheduledDate?.add(
          Duration(hours: widget.request.service.durationHours),
        ),
      );

      if (result.success && result.data != null) {
        setState(() {
          _recommendations = result.data!;
          _isLoading = false;
        });
      } else {
        // Fallback to basic employee list
        await _loadAvailableEmployees();
      }
    } catch (e) {
      await _loadAvailableEmployees();
    }
  }

  Future<void> _loadAvailableEmployees() async {
    final provider = context.read<ServiceRequestProvider>();
    await provider.fetchAvailableEmployees(
      requestId: widget.request.id,
      requiredSkills: _requiredSkills,
    );
    setState(() => _isLoading = false);
  }

  List<String> _getRequiredSkills() {
    // Extract skills from service title or description
    // This is a simplified implementation - in a real app,
    // services would have associated skill requirements
    final serviceTitle = widget.request.service.title.toLowerCase();
    final skills = <String>[];

    if (serviceTitle.contains('plumb')) skills.add('plumbing');
    if (serviceTitle.contains('electric')) skills.add('electrical');
    if (serviceTitle.contains('clean')) skills.add('cleaning');
    if (serviceTitle.contains('repair')) skills.add('repair');
    if (serviceTitle.contains('install')) skills.add('installation');

    return skills;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Assign Employee'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.service.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${widget.request.seeker.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.request.urgency != 'medium') ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(widget.request.urgency)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Priority: ${widget.request.urgency.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getUrgencyColor(widget.request.urgency),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Employee selection with recommendations
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (_recommendations.isNotEmpty) ...[
                  const Text(
                    'Recommended Employees',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final recommendation = _recommendations[index];
                        final employee = recommendation.employee;
                        final isSelected = _selectedEmployeeId == employee.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.1)
                              : null,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      isSelected ? Colors.blue : Colors.grey,
                                  child: Text(
                                    employee.name.characters.first
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(
                                          recommendation.overallScore),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${(recommendation.overallScore * 100).round()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(employee.name)),
                                _buildScoreIndicator(
                                    recommendation.overallScore),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(employee.position),
                                const SizedBox(height: 4),
                                _buildSkillsDisplay(recommendation),
                                const SizedBox(height: 4),
                                _buildScoreBreakdown(recommendation),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue)
                                : null,
                            onTap: () => setState(
                                () => _selectedEmployeeId = employee.id),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (provider.availableEmployees.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('No available employees found'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Select Employee',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.availableEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = provider.availableEmployees[index];
                        final isSelected = _selectedEmployeeId == employee.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.1)
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isSelected ? Colors.blue : Colors.grey,
                              child: Text(
                                employee.name.characters.first.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(employee.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(employee.position),
                                if (employee.skills.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: employee.skills
                                        .take(3)
                                        .map(
                                          (skill) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              skill,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue)
                                : null,
                            onTap: () => setState(
                                () => _selectedEmployeeId = employee.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Assignment Notes (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add any special instructions or notes...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isAssigning ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedEmployeeId != null && !_isAssigning
                  ? _assignEmployee
                  : null,
              child: _isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.request.assignedEmployeeId != null
                      ? 'Reassign'
                      : 'Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignEmployee() async {
    if (_selectedEmployeeId == null) return;

    setState(() => _isAssigning = true);

    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.assignEmployee(
      requestId: widget.request.id,
      employeeId: _selectedEmployeeId!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isAssigning = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Employee assigned successfully!'
              : result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildScoreIndicator(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${(score * 100).round()}%',
        style: TextStyle(
          fontSize: 10,
          color: _getScoreColor(score),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSkillsDisplay(EmployeeAssignmentRecommendation recommendation) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...recommendation.matchingSkills.map(
          (skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        ...recommendation.missingSkills.take(2).map(
              (skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildScoreBreakdown(EmployeeAssignmentRecommendation recommendation) {
    return Row(
      children: [
        _buildMiniScore('Skills', recommendation.skillMatchScore, Colors.blue),
        const SizedBox(width: 8),
        _buildMiniScore(
            'Performance', recommendation.performanceScore, Colors.purple),
        const SizedBox(width: 8),
        _buildMiniScore(
            'Available', recommendation.availabilityScore, Colors.teal),
      ],
    );
  }

  Widget _buildMiniScore(String label, double score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
