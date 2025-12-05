class ProviderProfile {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String category;
  final String experience;
  final String location;
  final String price;
  final String profileImage;
  final List<String>? certificates;
  final List<String>? availability;
  final String status;

  ProviderProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    this.category = '',
    this.experience = '',
    this.location = '',
    this.price = '',
    this.profileImage = '',
    this.certificates,
    this.availability,
    this.status = 'pending',
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      description: json['description'],
      category: json['category'] ?? '',
      experience: json['experience'] ?? '',
      location: json['location'] ?? '',
      price: json['price'] ?? '',
      profileImage: json['profile_image'] ?? '',
      certificates: json['certificates'] != null
          ? List<String>.from(json['certificates'])
          : null,
      availability: json['availability'] != null
          ? List<String>.from(json['availability'])
          : null,
      status: json['status'] ?? 'pending',
    );
  }
}
