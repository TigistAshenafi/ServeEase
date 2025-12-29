// lib/screens/provider/create_profile_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
// import 'package:serveease_app/core/models/provider_model.dart';
import 'package:serveease_app/core/services/provider_service.dart';
import 'dart:io';
import '../../../providers/provider_profile_provider.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/animated_input_field.dart';
// import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/certificate_card.dart';
import '../../../shared/widgets/loading_overlay.dart';

class CreateProfileScreen extends StatefulWidget {
  final bool isEditMode;

  const CreateProfileScreen({super.key, this.isEditMode = false});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedProviderType = 'individual';
  String _selectedCategory = '';
  String _selectedCategoryId = ''; // Store category ID for backend
  List<String> _certificates = [];
  final List<File> _certificateFiles = [];
  bool _isLoading = false;
  bool _showCategoryGrid = false;
  List<ServiceCategory> _categories = []; // Store categories from backend

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadExistingProfile();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    final response = await ProviderService.getServiceCategories();
    
    if (response.success && response.data != null) {
      setState(() {
        _categories = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load categories: ${response.message}');
    }
  }

  Future<void> _loadExistingProfile() async {
    if (widget.isEditMode) {
      setState(() => _isLoading = true);
      final provider = Provider.of<ProviderProfileProvider>(context, listen: false);
      await provider.loadProfile();
      
      if (provider.profile != null) {
        final profile = provider.profile!;
        _selectedProviderType = profile.providerType;
        _businessNameController.text = profile.businessName;
        _descriptionController.text = profile.description;
        _selectedCategory = profile.category;
        _locationController.text = profile.location;
        _phoneController.text = profile.phone;
        _certificates = List.from(profile.certificates);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _certificateFiles.add(file);
          _certificates.add(image.name);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificates.removeAt(index);
      if (index < _certificateFiles.length) {
        _certificateFiles.removeAt(index);
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProviderType == 'individual' && _certificates.isEmpty) {
        _showErrorSnackbar('Individual providers must upload at least one certificate');
        return;
      }

      if (_selectedCategoryId.isEmpty) {
        _showErrorSnackbar('Please select a category');
        return;
      }

      setState(() => _isLoading = true);

      final provider = Provider.of<ProviderProfileProvider>(context, listen: false);
      
      final result = await provider.createOrUpdateProfile(
        providerType: _selectedProviderType,
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory, // Still send name for display
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
        certificates: _certificates,
      );

      setState(() => _isLoading = false);

      if (result.success) {
        await _showSuccessDialog();
      } else {
        _showErrorSnackbar(result.message);
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                ),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Saved!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        content: Text(
          'Your provider profile has been ${widget.isEditMode ? 'updated' : 'created'} successfully. '
          'Your profile will be reviewed by our team.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to profile view
              Navigator.pushReplacementNamed(context, '/provider/profile');
            },
            child: Text(
              'VIEW PROFILE',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'home_repair':
        return Icons.home_repair_service;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'gardening':
        return Icons.grass;
      case 'education':
        return Icons.school;
      case 'computer':
        return Icons.computer;
      case 'car':
        return Icons.car_repair;
      case 'spa':
        return Icons.spa;
      case 'pets':
        return Icons.pets;
      case 'truck':
        return Icons.local_shipping;
      case 'party':
        return Icons.celebration;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: size.height * 0.25,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor.withOpacity(0.9),
                        theme.primaryColor.withOpacity(0.7),
                        Colors.blue.shade300,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 60),
                            Text(
                              widget.isEditMode ? 'Edit Profile' : 'Become a Provider',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isEditMode
                                  ? 'Update your service provider details'
                                  : 'Join our network of professional service providers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GlassmorphicCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Provider Type Selection
                        _buildProviderTypeSection(),
                        const SizedBox(height: 30),
                        
                        // Business/Individual Information
                        _buildBusinessInfoSection(),
                        const SizedBox(height: 30),
                        
                        // Service Category
                        _buildCategorySection(),
                        const SizedBox(height: 30),
                        
                        // Location & Contact
                        _buildContactSection(),
                        const SizedBox(height: 30),
                        
                        // Certificates Section
                        if (_selectedProviderType == 'individual')
                          _buildCertificatesSection(),
                        
                        const SizedBox(height: 40),
                        
                        // Submit Button
                        GradientButton(
                          onPressed: _submitProfile,
                          text: widget.isEditMode ? 'UPDATE PROFILE' : 'CREATE PROFILE',
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Provider Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'individual',
                title: 'Individual',
                subtitle: 'Freelancer or sole proprietor',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: 'organization',
                title: 'Organization',
                subtitle: 'Company or business',
                icon: Icons.business,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedProviderType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedProviderType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business_center_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              _selectedProviderType == 'individual'
                  ? 'Personal Information'
                  : 'Business Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedInputField(
          controller: _businessNameController,
          label: _selectedProviderType == 'individual'
              ? 'Your Name'
              : 'Business Name',
          hintText: _selectedProviderType == 'individual'
              ? 'Enter your full name'
              : 'Enter business name',
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (value.length < 2) {
              return 'Must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AnimatedInputField(
          controller: _descriptionController,
          label: 'Description',
          hintText: 'Describe your services in detail...',
          prefixIcon: Icons.description_outlined,
          maxLines: 4,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Description is required';
            }
            if (value.length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Service Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() => _showCategoryGrid = !_showCategoryGrid);
            if (_showCategoryGrid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent * 0.4,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCategory.isEmpty
                        ? 'Select your service category'
                        : _selectedCategory,
                    style: TextStyle(
                      color: _selectedCategory.isEmpty
                          ? Colors.grey.shade500
                          : Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  _showCategoryGrid ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (_showCategoryGrid) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategoryId == category.id;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category.name;
                    _selectedCategoryId = category.id;
                    _showCategoryGrid = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(category.icon),
                          size: 18,
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AnimatedInputField(
                controller: _locationController,
                label: 'Location',
                hintText: 'City, State',
                prefixIcon: Icons.location_city_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedInputField(
                controller: _phoneController,
                label: 'Phone',
                hintText: '+1234567890',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCertificatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              'Certificates & Qualifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload your professional certificates or licenses',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (_certificates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.grey.shade400,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No certificates uploaded',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload at least one certificate to verify your qualifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_certificates.length, (index) {
                  return CertificateCard(
                    fileName: _certificates[index],
                    onRemove: () => _removeCertificate(index),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickCertificate,
          icon: Icon(Icons.add, color: Colors.blue.shade600),
          label: Text(
            'ADD CERTIFICATE',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.blue.shade600),
          ),
        ),
      ],
    );
  }
}