// lib/core/models/service_model.dart

class ServiceCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class Service {
  final String id;
  final String title;
  final String description;
  final double price;
  final int durationHours;
  final String categoryId;
  final bool isActive;
  final String? categoryName;
  final String? categoryIcon;
  final ServiceProvider? provider;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.durationHours,
    required this.categoryId,
    required this.isActive,
    this.categoryName,
    this.categoryIcon,
    this.provider,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationHours: json['durationHours'] ??
          json['duration_hours'] ??
          json['duration'] ??
          0,
      categoryId: json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      categoryName: json['categoryName'] ?? json['category_name'],
      categoryIcon: json['categoryIcon'] ?? json['category_icon'],
      provider: json['provider'] != null
          ? ServiceProvider.fromJson(json['provider'])
          : null,
    );
  }
}

class ServiceProvider {
  final String id;
  final String businessName;
  final String? location;
  final String? name;

  ServiceProvider({
    required this.id,
    required this.businessName,
    this.location,
    this.name,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName'] ??
          json['business_name'] ??
          json['providerName'] ??
          '',
      location: json['location'],
      name: json['name'],
    );
  }
}

