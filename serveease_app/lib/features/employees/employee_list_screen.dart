import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    Future.microtask(() => context.read<EmployeeProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.employees.length,
                itemBuilder: (context, index) {
                  final employee = provider.employees[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(employee.employeeName.characters.first),
                      ),
                      title: Text(employee.employeeName),
                      subtitle: Text(
                          '${employee.role} • ${employee.email}${employee.phone != null ? '\n${employee.phone}' : ''}'),
                      trailing: Switch(
                        value: employee.isActive,
                        onChanged: (val) => provider.update(
                          employee.id,
                          isActive: val,
                        ),
                      ),
                      onTap: () => _openForm(context, id: employee.id),
                      onLongPress: () => provider.remove(employee.id),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _openForm(BuildContext context, {String? id}) {
    final provider = context.read<EmployeeProvider>();
    final existing =
        id != null ? provider.employees.firstWhere((e) => e.id == id) : null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.employeeName);
    final emailCtrl = TextEditingController(text: existing?.email);
    final roleCtrl = TextEditingController(text: existing?.role);
    final phoneCtrl = TextEditingController(text: existing?.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
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
            children: [
              Text(
                id == null ? 'Add Employee' : 'Edit Employee',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (id == null) {
                      await provider.add(
                        employeeName: nameCtrl.text,
                        email: emailCtrl.text,
                        role: roleCtrl.text,
                        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                      );
                    } else {
                      await provider.update(
                        id,
                        employeeName: nameCtrl.text,
                        email: emailCtrl.text,
                        role: roleCtrl.text,
                        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

