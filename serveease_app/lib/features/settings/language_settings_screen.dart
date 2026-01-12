import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/localization/locale_provider.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred language',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Language options
              ...localeProvider.supportedLocalesWithNames.entries.map(
                (entry) => _buildLanguageOption(
                  context,
                  locale: entry.key,
                  name: entry.value,
                  isSelected: entry.key == localeProvider.currentLocale,
                  onTap: () => localeProvider.setLocale(entry.key),
                ),
              ),

              const SizedBox(height: 32),

              // Quick toggle button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text('Quick Toggle'),
                  subtitle: Text('Switch between English and አማርኛ'),
                  trailing: Switch(
                    value: localeProvider.currentLocale.languageCode == 'am',
                    onChanged: (_) => localeProvider.toggleLocale(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Information card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Language Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your language preference will be saved and applied throughout the app. You can change it anytime from the settings.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required Locale locale,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          child: Text(
            locale.languageCode.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Language: ${locale.languageCode}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
