// lib/features/auth/presentation/provider_setup_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../shared/widgets/language_toggle.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController businessNameCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController experienceCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  File? profileImage;
  List<File> certificates = [];
  Map<String, bool> availability = {
    "weekdays": false,
    "weekends": false,
    "somedays": false,
    "everyday": false,
  };

  bool loading = false;

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => profileImage = File(picked.path));
  }

  Future<void> pickCertificates() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() => certificates.addAll(pickedFiles.map((e) => File(e.path))));
  }

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token. Please login again.")),
      );
      setState(() => loading = false);
      return;
    }

    final providerService = ProviderService(authService: _authService);

    try {
      await providerService.createProviderProfile(
        businessName: businessNameCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        experience: int.tryParse(experienceCtrl.text.trim()),
        location: locationCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.trim()),
        profileImage: profileImage,
        certificates: certificates,
        availability: availability,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile created successfully!")),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(loc.providerProfileSetup, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LanguageToggle(alignment: Alignment.centerRight),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  child: profileImage == null
                      ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  textInput(businessNameCtrl, "Business Name", Icons.business),
                  textInput(descriptionCtrl, "Description", Icons.description,
                      maxLines: 3),
                  textInput(categoryCtrl, "Category", Icons.category),
                  textInput(experienceCtrl, "Experience (years)", Icons.timeline,
                      numbers: true),
                  textInput(locationCtrl, "Location", Icons.location_on),
                  textInput(priceCtrl, "Price", Icons.monetization_on, numbers: true),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Certificates",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: pickCertificates,
                        icon: const Icon(Icons.upload_file),
                        label:
                            const Text("Upload", style: TextStyle(color: Colors.white)),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: certificates
                        .map((file) => Chip(
                              label: Text(file.path.split('/').last),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () =>
                                  setState(() => certificates.remove(file)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Availability",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ...availability.keys.map((day) => SwitchListTile(
                        title: Text(day[0].toUpperCase() + day.substring(1)),
                        activeThumbColor: Colors.deepPurple,
                        activeTrackColor: Colors.deepPurple.shade200,
                        value: availability[day]!,
                        onChanged: (val) => setState(() => availability[day] = val),
                      )),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : submitProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Profile",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textInput(TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, bool numbers = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numbers ? TextInputType.number : TextInputType.text,
        validator: (v) => v == null || v.trim().isEmpty ? "$label required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
