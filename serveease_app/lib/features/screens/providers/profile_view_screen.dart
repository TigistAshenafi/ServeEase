// lib/screens/provider/profile_view_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/features/screens/providers/create_profile_screen.dart';
import '../../../providers/provider_profile_provider.dart';
import '../../../shared/widgets/profile_header.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/status_badge.dart';

class ProviderProfileViewScreen extends StatefulWidget {
  const ProviderProfileViewScreen({super.key});

  @override
  State<ProviderProfileViewScreen> createState() => _ProviderProfileViewScreenState();
}

class _ProviderProfileViewScreenState extends State<ProviderProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final provider = Provider.of<ProviderProfileProvider>(context, listen: false);
    if (!provider.hasProfile) {
      await provider.loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderProfileProvider>(context);
    final profile = provider.profile;
    final size = MediaQuery.of(context).size;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_disabled, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                Text(
                  'No Profile Found',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Create a provider profile to start offering services.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'CREATE PROFILE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/provider/edit-profile');
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.28,
            backgroundColor: Colors.transparent,
            flexibleSpace: ProfileHeader(profile: profile),
            pinned: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 22),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateProfileScreen(isEditMode: true),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Approval Status
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: profile.isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: profile.isApproved ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          profile.isApproved ? Icons.verified_outlined : Icons.pending_outlined,
                          color: profile.isApproved ? Colors.green.shade700 : Colors.orange.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.isApproved ? 'Profile Approved' : 'Pending Approval',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: profile.isApproved ? Colors.green.shade900 : Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.isApproved
                                    ? 'Your profile is active and visible to customers.'
                                    : 'Your profile is under review by our team.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profile.isApproved ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                              if (profile.approvalDate != null)
                                Text(
                                  'Approved on: ${_formatDate(profile.approvalDate!)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        StatusBadge(status: profile.isApproved ? 'Approved' : 'Pending', isActive: profile.isApproved),
                      ],
                    ),
                  ),
                ),

                // Business Information
                InfoCard(
                  title: 'Business Information',
                  icon: Icons.business,
                  children: [
                    _buildInfoRow('Provider Type', profile.providerType.toUpperCase()),
                    _buildInfoRow('Business Name', profile.businessName),
                    _buildInfoRow('Category', profile.category),
                    _buildInfoRow('Location', profile.location),
                    _buildInfoRow('Phone', profile.phone),
                  ],
                ),

                // Service Description
                InfoCard(
                  title: 'Service Description',
                  icon: Icons.description,
                  children: [
                    Text(
                      profile.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
                    ),
                  ],
                ),

                // Certificates
                if (profile.certificates.isNotEmpty)
                  InfoCard(
                    title: 'Certificates & Qualifications',
                    icon: Icons.verified,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: profile.certificates.map((certificate) => _buildCertificateChip(certificate)).toList(),
                      ),
                    ],
                  ),

                // Account Information
                InfoCard(
                  title: 'Account Information',
                  icon: Icons.account_circle,
                  children: [
                    if (profile.user != null) ...[
                      _buildInfoRow('Name', profile.user!.name),
                      _buildInfoRow('Email', profile.user!.email),
                    ],
                    _buildInfoRow('Member Since', _formatDate(profile.createdAt)),
                    _buildInfoRow('Last Updated', _formatDate(profile.updatedAt)),
                  ],
                ),

                // Admin Notes
                if (profile.adminNotes != null && profile.adminNotes!.isNotEmpty)
                  InfoCard(
                    title: 'Admin Notes',
                    icon: Icons.note,
                    color: Colors.orange.shade50,
                    borderColor: Colors.orange.shade200,
                    children: [
                      Text(
                        profile.adminNotes!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateChip(String certificate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            certificate.length > 20 ? '${certificate.substring(0, 18)}...' : certificate,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
