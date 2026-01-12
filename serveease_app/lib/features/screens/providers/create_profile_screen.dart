// lib/screens/provider/create_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/core/services/location_service.dart';
import 'package:serveease_app/core/services/provider_service.dart';
import 'package:serveease_app/core/utils/phone_validator.dart';

import '../../../providers/provider_profile_provider.dart';
import '../../../shared/widgets/certificate_card.dart';
import '../../../shared/widgets/ethiopian_phone_field.dart';
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
  String _selectedCategoryId = '';
  List<String> _certificates = [];
  final List<File> _certificateFiles = [];
  bool _isLoading = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  List<ServiceCategory> _categories = [];

  // Location search variables
  List<LocationSuggestion> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  LocationSuggestion? _selectedLocation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadExistingProfile();
    
    // Add location search listener
    _locationController.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    final query = _locationController.text.toLowerCase();
    if (query.isEmpty || query == '+251') {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    // Use LocationService to search for locations
    final suggestions = LocationService.searchLocations(query);

    setState(() {
      _locationSuggestions = suggestions;
      _showLocationSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectLocation(LocationSuggestion location) {
    setState(() {
      _selectedLocation = location;
      _locationController.text = location.name;
      _showLocationSuggestions = false;
      
      // Store coordinates if available
      if (location.latitude != null && location.longitude != null) {
        _currentPosition = Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    });
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
        
        // Handle phone number - remove +251 if present since the widget shows it
        String phoneNumber = profile.phone;
        if (phoneNumber.startsWith('+251')) {
          phoneNumber = phoneNumber.substring(4).trim(); // Remove +251 and any space
        }
        _phoneController.text = phoneNumber;
        
        _certificates = List.from(profile.certificates);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    final result = await LocationService.getCurrentLocation();
    
    setState(() => _isGettingLocation = false);

    if (result.success && result.suggestion != null && result.position != null) {
      setState(() {
        _currentPosition = result.position;
        _selectedLocation = result.suggestion;
        _locationController.text = 'Current Location (${result.position!.latitude.toStringAsFixed(4)}, ${result.position!.longitude.toStringAsFixed(4)})';
        _showLocationSuggestions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current location captured successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      _showErrorSnackbar(result.error ?? 'Failed to get location');
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
      
      // Prepare location string with coordinates if available
      String locationString = _locationController.text.trim();
      if (_selectedLocation != null && _selectedLocation!.latitude != null && _selectedLocation!.longitude != null) {
        locationString = '${_selectedLocation!.fullAddress} (${_selectedLocation!.latitude!.toStringAsFixed(6)}, ${_selectedLocation!.longitude!.toStringAsFixed(6)})';
      } else if (_currentPosition != null) {
        locationString = '$locationString (${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)})';
      }
      
      final result = await provider.createOrUpdateProfile(
        providerType: _selectedProviderType,
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: locationString,
        phone: EthiopianPhoneValidator.getFullPhoneNumber(_phoneController.text.trim()),
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
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              'VIEW DASHBOARD',
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

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: colorScheme.surface, // Same as login page
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.isEditMode ? 'Edit Profile' : 'Create Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section like login page
                  Center(
                    child: Column(
                      children: [
                        Text(
                          widget.isEditMode ? 'Update Your Profile' : 'Become a Provider',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isEditMode
                              ? 'Update your service provider details'
                              : 'Join our network of professional service providers',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Form sections with clean design like login
                  _buildProviderTypeSection(),
                  const SizedBox(height: 32),
                  _buildBusinessInfoSection(),
                  const SizedBox(height: 32),
                  _buildCategorySection(),
                  const SizedBox(height: 32),
                  _buildContactSection(),
                  const SizedBox(height: 32),
                  if (_selectedProviderType == 'individual')
                    _buildCertificatesSection(),
                  if (_selectedProviderType == 'individual')
                    const SizedBox(height: 32),
                  
                  // Submit button like login page
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEditMode ? 'UPDATE PROFILE' : 'CREATE PROFILE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTypeSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Type',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'individual',
                title: 'Individual',
                subtitle: 'Freelancer',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: 'organization',
                title: 'Organization',
                subtitle: 'Company',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedProviderType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedProviderType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
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
        // Name field
        TextFormField(
          controller: _businessNameController,
          decoration: InputDecoration(
            labelText: _selectedProviderType == 'individual' ? 'Your Name' : 'Business Name',
            hintText: _selectedProviderType == 'individual' ? 'Enter your full name' : 'Enter business name',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
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
        const SizedBox(height: 24),
        
        // Description field
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your services in detail...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description_outlined),
          ),
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
        // Category dropdown field
        DropdownButtonFormField<String>(
          value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Service Category',
            hintText: 'Select your service category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value ?? '';
              _selectedCategory = _categories.firstWhere((cat) => cat.id == value).name;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Field with Search
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Type city name (e.g., Addis Ababa)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: IconButton(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: colorScheme.primary,
                          ),
                    tooltip: 'Use current GPS location',
                  ),
                ),
              ],
            ),
            // Location Suggestions Dropdown
            if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_city, color: colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Ethiopian Cities',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.keyboard_arrow_down, color: colorScheme.primary, size: 16),
                        ],
                      ),
                    ),
                    // Suggestions list
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectLocation(suggestion),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            suggestion.fullAddress,
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Ethiopian Phone Field with Flag
        EthiopianPhoneField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: '9 1234 5678',
        ),
      ],
    );
  }

  Widget _buildCertificatesSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Certificates & Qualifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload your professional certificates or licenses',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_certificates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No certificates uploaded',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload at least one certificate to verify your qualifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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
          icon: Icon(Icons.add, color: colorScheme.primary),
          label: Text(
            'ADD CERTIFICATE',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}