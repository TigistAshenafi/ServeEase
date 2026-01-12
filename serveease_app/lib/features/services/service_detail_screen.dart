import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String categoryName;
  final List<Service> services;
  const ServiceDetailScreen(
      {super.key, required this.categoryName, required this.services});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(service.title),
              subtitle: Text(
                  '${service.description}\n${service.durationHours} hrs • \$${service.price.toStringAsFixed(2)}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () async {
                  final reqProvider = context.read<ServiceRequestProvider>();
                  final res = await reqProvider.createRequest(
                      serviceId: service.id,
                      providerId: service.provider?.id ?? '');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(res.success ? 'Request created' : res.message)));
                },
                child: const Text('Request'),
              ),
            ),
          );
        },
      ),
    );
  }
}
