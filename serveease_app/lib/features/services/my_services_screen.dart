// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_model.dart';
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
    Future.microtask(() => context.read<provider.ServiceProvider>().loadMyServices());
  }

  @override
  Widget build(BuildContext context) {
    final providerObj = context.watch<provider.ServiceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: providerObj.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: providerObj.loadMyServices,
              child: ListView.builder(
                itemCount: providerObj.myServices.length,
                itemBuilder: (context, index) {
                  final service = providerObj.myServices[index];
                  return ListTile(
                    title: Text(service.title),
                    subtitle: Text(
                        '${service.categoryName ?? ''}\n\$${service.price.toStringAsFixed(2)} • ${service.durationHours}h'),
                    trailing: Switch(
                      value: service.isActive,
                      onChanged: (val) {
                        providerObj.updateService(
                            id: service.id, isActive: val);
                      },
                    ),
                    onTap: () => _openForm(context, service: service),
                  );
                },
              ),
            ),
    );
  }

  void _openForm(BuildContext context, {Service? service}) {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: service?.title);
    final description = TextEditingController(text: service?.description);
    final categoryId = TextEditingController(text: service?.categoryId);
    final price = TextEditingController(
        text: service != null ? service.price.toString() : '');
    final duration =
        TextEditingController(text: service?.durationHours.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final providerObj = context.read<provider.ServiceProvider>();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  service == null ? 'Create Service' : 'Edit Service',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category ID'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: duration,
                  decoration:
                      const InputDecoration(labelText: 'Duration (hours)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (service == null) {
                      await providerObj.createService(
                        title: title.text,
                        description: description.text,
                        categoryId: categoryId.text,
                        price: double.parse(price.text),
                        durationHours: int.parse(duration.text),
                      );
                    } else {
                      await providerObj.updateService(
                        id: service.id,
                        title: title.text,
                        description: description.text,
                        categoryId: categoryId.text,
                        price: double.tryParse(price.text),
                        durationHours: int.tryParse(duration.text),
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

