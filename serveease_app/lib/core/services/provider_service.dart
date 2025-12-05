import 'dart:io';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class ProviderService {
  final AuthService authService;

  ProviderService({required this.authService});

  Future<void> createProviderProfile({
    required String businessName,
    String? description,
    String? category,
    int? experience,
    String? location,
    double? price,
    File? profileImage,
    List<File>? certificates,
    Map<String, bool>? availability,
  }) async {
    final dio = await authService.dioWithAuth();

    final formData = FormData();

    // Add text fields
    formData.fields.addAll([
      MapEntry('businessName', businessName),
      if (description != null) MapEntry('description', description),
      if (category != null) MapEntry('category', category),
      if (experience != null) MapEntry('experience', experience.toString()),
      if (location != null) MapEntry('location', location),
      if (price != null) MapEntry('price', price.toString()),
    ]);

    // Add profile image
    if (profileImage != null) {
      formData.files.add(MapEntry(
        'profileImage',
        await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        ),
      ));
    }

    // Add certificates
    if (certificates != null) {
      for (var i = 0; i < certificates.length; i++) {
        formData.files.add(MapEntry(
          'certificates[$i]',
          await MultipartFile.fromFile(
            certificates[i].path,
            filename: certificates[i].path.split('/').last,
          ),
        ));
      }
    }

    // Add availability
    if (availability != null) {
      formData.fields.addAll(availability.entries
          .map((e) => MapEntry('availability[${e.key}]', e.value.toString())));
    }

    await dio.post('/provider/profile', data: formData);
  }
   Future<Response> getMyProviderProfile() async {
    final dio = await authService.dioWithAuth();
    return dio.get('/provider/profile'); // adjust endpoint if needed
  }
}
