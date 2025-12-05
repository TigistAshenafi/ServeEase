import 'package:flutter/material.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/provider_model.dart';

class MyProviderScreen extends StatefulWidget {
  const MyProviderScreen({super.key});

  @override
  State<MyProviderScreen> createState() => _MyProviderScreenState();
}

class _MyProviderScreenState extends State<MyProviderScreen> {
  ProviderProfile? profile;
  bool loading = true;

  // Instantiate AuthService and ProviderService
  final AuthService _authService = AuthService();
  late final ProviderService _providerService;

  @override
  void initState() {
    super.initState();
    _providerService = ProviderService(authService: _authService);
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final response = await _providerService.getMyProviderProfile();
      if (response.statusCode == 200) {
        // Assuming your API returns JSON that can be converted to ProviderProfile
        setState(() {
          profile = ProviderProfile.fromJson(response.data);
        });
      }
    } catch (e) {
      // handle error
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (profile == null) return const Center(child: Text('No provider profile found'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Provider Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Name: ${profile!.businessName}'),
            Text('Description: ${profile!.description}'),
            Text('Status: ${profile!.status}'),
            // ...
          ],
        ),
      ),
    );
  }
}
