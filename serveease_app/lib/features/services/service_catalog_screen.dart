import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/service_provider.dart';
import 'service_detail_screen.dart';

class ServiceCatalogScreen extends StatefulWidget {
  const ServiceCatalogScreen({super.key});

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<ServiceProvider>().loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadCategories,
              child: ListView.builder(
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(category.name),
                    subtitle: Text(category.description ?? ''),
                    onTap: () async {
                      await provider.loadCategoryServices(category.id);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(
                            categoryName: category.name,
                            services: provider.categoryServices,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

