import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/admin_provider.dart';

class ProviderApprovalsScreen extends StatefulWidget {
  const ProviderApprovalsScreen({super.key});

  @override
  State<ProviderApprovalsScreen> createState() =>
      _ProviderApprovalsScreenState();
}

class _ProviderApprovalsScreenState extends State<ProviderApprovalsScreen> {
  String status = 'pending';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminProvider>().fetchProviders(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Approvals'),
        actions: [
          PopupMenuButton<String>(
            initialValue: status,
            onSelected: (value) {
              setState(() => status = value);
              admin.fetchProviders(status: value);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'approved', child: Text('Approved')),
              PopupMenuItem(value: 'all', child: Text('All')),
            ],
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.fetchProviders(status: status),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: admin.providers.length,
                itemBuilder: (context, index) {
                  final provider = admin.providers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  provider.isApproved
                                      ? Icons.verified
                                      : Icons.pending,
                                  color: provider.isApproved
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.businessName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      provider.category,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  provider.providerType.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.indigo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(provider.description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Text(provider.location),
                              const SizedBox(width: 12),
                              const Icon(Icons.phone, size: 16),
                              const SizedBox(width: 4),
                              Text(provider.phone),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: provider.isApproved
                                    ? null
                                    : () => _reject(provider.id),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: provider.isApproved
                                    ? null
                                    : () => _approve(provider.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
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

  Future<void> _approve(String providerId) async {
    final admin = context.read<AdminProvider>();
    final res = await admin.approve(providerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }

  Future<void> _reject(String providerId) async {
    final admin = context.read<AdminProvider>();
    final res = await admin.reject(providerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }
}

