// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/providers/service_provider.dart' as provider;

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final serviceProvider = context.read<provider.ServiceProvider>();
        serviceProvider.loadCategories();
        serviceProvider.loadMyServices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<provider.ServiceProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openServiceForm(context),
          ),
        ],
      ),
      body: serviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : serviceProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${serviceProvider.error}',
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => serviceProvider.loadMyServices(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: serviceProvider.loadMyServices,
                  child: serviceProvider.myServices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: serviceProvider.myServices.length,
                          itemBuilder: (context, index) {
                            final service = serviceProvider.myServices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: service.isActive 
                                                ? Colors.green.shade100 
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(service.categoryIcon),
                                            color: service.isActive 
                                                ? Colors.green.shade700 
                                                : Colors.grey.shade600,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                service.categoryName ?? 'No Category',
                                                style: TextStyle(
                                                  color: Colors.blue.shade600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: service.isActive,
                                          onChanged: (val) async {
                                            final result = await serviceProvider.updateService(
                                              id: service.id,
                                              isActive: val,
                                            );
                                            if (mounted && !result.success && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to update service: ${result.message}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          activeThumbColor: Colors.green,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      service.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '\$${service.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${service.durationHours}h',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () => _openServiceForm(context, service: service),
                                          icon: const Icon(Icons.edit),
                                          iconSize: 20,
                                        ),
                                        IconButton(
                                          onPressed: () => _showDeleteDialog(service),
                                          icon: const Icon(Icons.delete),
                                          iconSize: 20,
                                          color: Colors.red.shade400,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
            Icons.work_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first service to start receiving requests',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openServiceForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Service'),
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

  void _openServiceForm(BuildContext context, {Service? service}) {
    final serviceProvider = context.read<provider.ServiceProvider>();
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: service?.title ?? '');
    final descriptionCtrl = TextEditingController(text: service?.description ?? '');
    final priceCtrl = TextEditingController(
      text: service != null ? service.price.toString() : '',
    );
    final durationCtrl = TextEditingController(
      text: service?.durationHours.toString() ?? '',
    );
    
    String? selectedCategoryId = service?.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                      service == null ? Icons.add_business : Icons.edit,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      service == null ? 'Create Service' : 'Edit Service',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Service Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: serviceProvider.categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedCategoryId = value;
                    });
                  },
                  validator: (v) => v == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Price (\$) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Price is required';
                          if (double.tryParse(v) == null) return 'Enter valid price';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: durationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Duration (hours) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Duration is required';
                          if (int.tryParse(v) == null) return 'Enter valid hours';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      try {
                        late ApiResponse<Service> result;
                        if (service == null) {
                          result = await serviceProvider.createService(
                            title: titleCtrl.text.trim(),
                            description: descriptionCtrl.text.trim(),
                            categoryId: selectedCategoryId!,
                            price: double.parse(priceCtrl.text),
                            durationHours: int.parse(durationCtrl.text),
                          );
                        } else {
                          result = await serviceProvider.updateService(
                            id: service.id,
                            title: titleCtrl.text.trim(),
                            description: descriptionCtrl.text.trim(),
                            categoryId: selectedCategoryId,
                            price: double.tryParse(priceCtrl.text),
                            durationHours: int.tryParse(durationCtrl.text),
                          );
                        }
                        
                        if (mounted && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.success 
                                    ? (service == null 
                                        ? 'Service created successfully' 
                                        : 'Service updated successfully')
                                    : result.message,
                              ),
                              backgroundColor: result.success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted && context.mounted) {
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
                    child: Text(service == null ? 'CREATE SERVICE' : 'UPDATE SERVICE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final serviceProvider = context.read<provider.ServiceProvider>();
              final result = await serviceProvider.deleteService(service.id);
              
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success 
                          ? 'Service deleted successfully' 
                          : 'Failed to delete service: ${result.message}',
                    ),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'home_repair':
        return Icons.home_repair_service;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'gardening':
        return Icons.grass;
      case 'education':
        return Icons.school;
      case 'computer':
        return Icons.computer;
      case 'car':
        return Icons.car_repair;
      case 'spa':
        return Icons.spa;
      case 'pets':
        return Icons.pets;
      case 'truck':
        return Icons.local_shipping;
      case 'party':
        return Icons.celebration;
      default:
        return Icons.work;
    }
  }
}