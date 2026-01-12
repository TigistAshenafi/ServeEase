import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/employee_provider.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/animated_input_field.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Employees'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddEmployeeDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, employeeProvider, child) {
          if (employeeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employeeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    employeeProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => employeeProvider.fetchEmployees(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (employeeProvider.employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No employees added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add employees to help manage service requests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: () => _showAddEmployeeDialog(),
                    text: 'ADD FIRST EMPLOYEE',
                    icon: Icons.person_add,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: employeeProvider.employees.length,
            itemBuilder: (context, index) {
              final employee = employeeProvider.employees[index];
              return _buildEmployeeCard(employee, employeeProvider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployeeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmployeeCard(
      dynamic employee, EmployeeProvider employeeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : 'E',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          employee.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: employee.isActive
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      employee.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: employee.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Phone: ${employee.phone ?? 'Not provided'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Position: ${employee.position}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (employee.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: employee.skills
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditEmployeeDialog(employee),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _toggleEmployeeStatus(employee, employeeProvider),
                      icon: Icon(
                        employee.isActive ? Icons.pause : Icons.play_arrow,
                        size: 16,
                      ),
                      label:
                          Text(employee.isActive ? 'Deactivate' : 'Activate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            employee.isActive ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    _showEmployeeDialog();
  }

  void _showEditEmployeeDialog(dynamic employee) {
    _showEmployeeDialog(employee: employee);
  }

  void _showEmployeeDialog({dynamic employee}) {
    final nameController = TextEditingController(text: employee?.name ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final phoneController = TextEditingController(text: employee?.phone ?? '');
    final positionController =
        TextEditingController(text: employee?.position ?? '');
    final skillsController = TextEditingController(
      text: employee?.skills?.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee == null ? 'Add Employee' : 'Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedInputField(
                controller: nameController,
                label: 'Full Name',
                hintText: 'Enter employee name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              AnimatedInputField(
                controller: emailController,
                label: 'Email',
                hintText: 'Enter email address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AnimatedInputField(
                controller: phoneController,
                label: 'Phone',
                hintText: 'Enter phone number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AnimatedInputField(
                controller: positionController,
                label: 'Position',
                hintText: 'Enter job position',
                prefixIcon: Icons.work,
              ),
              const SizedBox(height: 16),
              AnimatedInputField(
                controller: skillsController,
                label: 'Skills',
                hintText: 'Enter skills separated by commas',
                prefixIcon: Icons.star,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveEmployee(
              employee?.id,
              nameController.text,
              emailController.text,
              phoneController.text,
              positionController.text,
              skillsController.text,
            ),
            child: Text(employee == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEmployee(
    String? employeeId,
    String name,
    String email,
    String phone,
    String position,
    String skillsText,
  ) async {
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final skills = skillsText
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final employeeProvider =
        Provider.of<EmployeeProvider>(context, listen: false);

    final result = employeeId == null
        ? await employeeProvider.addEmployee(
            name: name,
            email: email,
            phone: phone,
            position: position,
            skills: skills,
          )
        : await employeeProvider.updateEmployee(
            employeeId: employeeId,
            name: name,
            email: email,
            phone: phone,
            position: position,
            skills: skills,
          );

    if (mounted) Navigator.pop(context);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(employeeId == null
                ? 'Employee added successfully'
                : 'Employee updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save employee: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleEmployeeStatus(
      dynamic employee, EmployeeProvider employeeProvider) async {
    final result = await employeeProvider.toggleEmployeeStatus(employee.id);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Employee ${employee.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to update employee status: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
