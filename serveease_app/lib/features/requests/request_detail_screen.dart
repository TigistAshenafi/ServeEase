import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/employee_provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final ServiceRequest request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _updating = false;
  String? _selectedStatus;
  String? _notes;
  String? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
    _loadEmployeesIfNeeded();
  }

  Future<void> _loadEmployeesIfNeeded() async {
    final employeeProvider = context.read<EmployeeProvider>();
    if (employeeProvider.employees.isEmpty) {
      await employeeProvider.load();
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _updating = true);
    final provider = context.read<ServiceRequestProvider>();
    final res = await provider.updateStatus(
      requestId: widget.request.id,
      status: _selectedStatus!,
      notes: _notes,
    );
    setState(() => _updating = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
    if (res.success) Navigator.pop(context);
  }

  Future<void> _assignEmployee() async {
    if (_selectedEmployee == null) return;
    setState(() => _updating = true);
    final provider = context.read<ServiceRequestProvider>();
    final res = await provider.assignEmployee(
      requestId: widget.request.id,
      employeeId: _selectedEmployee!,
    );
    setState(() => _updating = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
    if (res.success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final employees = context.watch<EmployeeProvider>().employees;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: 'Service',
              child: ListTile(
                title: Text(req.service.title),
                subtitle: Text(
                    '\$${req.service.price.toStringAsFixed(2)} • ${req.service.durationHours}h'),
              ),
            ),
            _sectionCard(
              title: 'Customer',
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(req.seeker.name),
                subtitle: Text(req.seeker.email ?? ''),
              ),
            ),
            _sectionCard(
              title: 'Provider',
              child: ListTile(
                leading: const Icon(Icons.business),
                title: Text(req.provider.businessName ?? req.provider.name),
                subtitle: Text(req.provider.location ?? ''),
              ),
            ),
            _sectionCard(
              title: 'Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'accepted', child: Text('Accepted')),
                      DropdownMenuItem(
                          value: 'assigned', child: Text('Assigned')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v),
                    decoration:
                        const InputDecoration(labelText: 'Update status'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => _notes = v,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updating ? null : _updateStatus,
                      child: _updating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Status'),
                    ),
                  ),
                ],
              ),
            ),
            _sectionCard(
              title: 'Assign Employee (organizations)',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedEmployee,
                    items: employees
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.employeeName} (${e.role})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedEmployee = v),
                    decoration:
                        const InputDecoration(labelText: 'Select employee'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.assignment_turned_in),
                      onPressed: _updating ? null : _assignEmployee,
                      label: const Text('Assign'),
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

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

