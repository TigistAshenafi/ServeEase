import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/providers/employee_provider.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EmployeeProvider>().fetchEmployees());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Team Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEmployeeForm(context),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${provider.error}',
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.fetchEmployees(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchEmployees(),
                  child: provider.employees.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.employees.length,
                          itemBuilder: (context, index) {
                            final employee = provider.employees[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: employee.isActive 
                                      ? Colors.green.shade100 
                                      : Colors.grey.shade300,
                                  child: Text(
                                    employee.employeeName.isNotEmpty 
                                        ? employee.employeeName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: employee.isActive 
                                          ? Colors.green.shade700 
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  employee.employeeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      employee.role,
                                      style: TextStyle(
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(employee.email),
                                    if (employee.phone != null && employee.phone!.isNotEmpty)
                                      Text(employee.phone!),
                                    if (employee.skills.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: employee.skills.take(3).map((skill) => 
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              skill,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Switch(
                                      value: employee.isActive,
                                      onChanged: (val) => _toggleEmployeeStatus(employee.id),
                                      activeThumbColor: Colors.green,
                                    ),
                                    Text(
                                      employee.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: employee.isActive ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _openEmployeeForm(context, employee: employee),
                                onLongPress: () => _showDeleteDialog(employee),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Employees Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first team member to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openEmployeeForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Employee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _openEmployeeForm(BuildContext context, {dynamic employee}) {
    final provider = context.read<EmployeeProvider>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: employee?.employeeName ?? '');
    final emailCtrl = TextEditingController(text: employee?.email ?? '');
    final roleCtrl = TextEditingController(text: employee?.role ?? '');
    final phoneCtrl = TextEditingController(text: employee?.phone ?? '');
    final skillsCtrl = TextEditingController(
      text: employee?.skills?.join(', ') ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    employee == null ? Icons.person_add : Icons.person_outline,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    employee == null ? 'Add Employee' : 'Edit Employee',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role/Position *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Role is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: skillsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                  hintText: 'e.g., Plumbing, Electrical, Carpentry',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    final skills = skillsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    try {
                      late ApiResponse<dynamic> result;
                      if (employee == null) {
                        result = await provider.addEmployee(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          position: roleCtrl.text.trim(),
                          skills: skills,
                        );
                      } else {
                        result = await provider.updateEmployee(
                          employeeId: employee.id,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          position: roleCtrl.text.trim(),
                          skills: skills,
                        );
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.success 
                                  ? (employee == null 
                                      ? 'Employee added successfully' 
                                      : 'Employee updated successfully')
                                  : result.message,
                            ),
                            backgroundColor: result.success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(employee == null ? 'ADD EMPLOYEE' : 'UPDATE EMPLOYEE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEmployeeStatus(String employeeId) async {
    final provider = context.read<EmployeeProvider>();
    final result = await provider.toggleEmployeeStatus(employeeId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success 
                ? 'Employee status updated' 
                : 'Failed to update status: ${result.message}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(dynamic employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
          'Are you sure you want to remove ${employee.employeeName} from your team? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<EmployeeProvider>();
              final result = await provider.remove(employee.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success 
                          ? 'Employee removed successfully' 
                          : 'Failed to remove employee: ${result.message}',
                    ),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

