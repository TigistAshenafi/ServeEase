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
  State<ProviderProfileViewScreen> createState() =>
      _ProviderProfileViewScreenState();
}

class _ProviderProfileViewScreenState
    extends State<ProviderProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final provider =
        Provider.of<ProviderProfileProvider>(context, listen: false);
    if (!provider.hasProfile) {
      await provider.loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderProfileProvider>(context);
    final profile = provider.profile;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off,
                  size: 90, color: colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No Profile Found',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your provider profile to continue.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreateProfileScreen()),
                  );
                },
                child: const Text(
                  'CREATE PROFILE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        onPressed: () {
          Navigator.pushNamed(context, '/provider/edit-profile');
        },
      ),
      body: CustomScrollView(
        slivers: [
          /// HEADER (kept but visually flattened)
          SliverAppBar(
            expandedHeight: size.height * 0.26,
            pinned: true,
            elevation: 0,
            backgroundColor: colors.primary,
            flexibleSpace: ProfileHeader(profile: profile),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                /// STATUS CARD — LOGIN STYLE
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        profile.isApproved
                            ? Icons.verified
                            : Icons.pending,
                        color: colors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.isApproved
                                  ? 'Profile Approved'
                                  : 'Pending Approval',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.isApproved
                                  ? 'Your profile is live and visible.'
                                  : 'Waiting for admin approval.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                      color:
                                          colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        status:
                            profile.isApproved ? 'Approved' : 'Pending',
                        isActive: profile.isApproved,
                      ),
                    ],
                  ),
                ),

                /// INFO CARDS — FORCED LOGIN COLORS
                InfoCard(
                  title: 'Business Information',
                  icon: Icons.business,
                  color: colors.surface,
                  borderColor: colors.primary.withOpacity(0.2),
                  children: [
                    _info('Provider Type',
                        profile.providerType.toUpperCase(), colors),
                    _info('Business Name',
                        profile.businessName, colors),
                    _info('Category', profile.category, colors),
                    _info('Location', profile.location, colors),
                    _info('Phone', profile.phone, colors),
                  ],
                ),

                InfoCard(
                  title: 'Service Description',
                  icon: Icons.description,
                  color: colors.surface,
                  borderColor: colors.primary.withOpacity(0.2),
                  children: [
                    Text(
                      profile.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                if (profile.certificates.isNotEmpty)
                  InfoCard(
                    title: 'Certificates',
                    icon: Icons.verified,
                    color: colors.surface,
                    borderColor:
                        colors.primary.withOpacity(0.2),
                    children: profile.certificates
                        .map((c) => _certificateChip(c, colors))
                        .toList(),
                  ),

                InfoCard(
                  title: 'Account Information',
                  icon: Icons.person,
                  color: colors.surface,
                  borderColor:
                      colors.primary.withOpacity(0.2),
                  children: [
                    if (profile.user != null) ...[
                      _info('Name', profile.user!.name, colors),
                      _info(
                          'Email', profile.user!.email, colors),
                    ],
                    _info('Member Since',
                        _format(profile.createdAt), colors),
                    _info('Last Updated',
                        _format(profile.updatedAt), colors),
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

  Widget _info(String label, String value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _certificateChip(String text, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }

  String _format(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
