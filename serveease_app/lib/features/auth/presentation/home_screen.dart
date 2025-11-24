import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  void _logout() async {
    setState(() => _loading = true);
    await _authService.logout(); // make sure you have a logout function in AuthService
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ServeEase Home'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Welcome to ServeEase!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Explore services, request bookings, and manage your account.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to services page or other feature
                // Navigator.pushNamed(context, '/services');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                "Explore Services",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
