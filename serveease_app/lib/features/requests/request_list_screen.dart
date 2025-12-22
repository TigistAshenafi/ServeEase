import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/features/requests/request_detail_screen.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<ServiceRequestProvider>().fetchRequests());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceRequestProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Requests'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _status,
            onSelected: (value) {
              setState(() => _status = value);
              provider.fetchRequests(status: value);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'in_progress', child: Text('In progress')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchRequests(status: _status),
              child: ListView.builder(
                itemCount: provider.requests.length,
                itemBuilder: (context, index) {
                  final req = provider.requests[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(req.service.title.characters.first),
                      ),
                      title: Text(req.service.title),
                      subtitle: Text(
                          '${req.status.toUpperCase()} • ${req.service.price.toStringAsFixed(2)}'),
                      trailing: Text(
                        req.provider.businessName ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(request: req),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

