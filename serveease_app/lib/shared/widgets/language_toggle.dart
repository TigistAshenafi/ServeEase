import 'package:flutter/material.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/localization/locale_controller.dart';

class LanguageToggle extends StatelessWidget {
  final Alignment alignment;

  const LanguageToggle({
    super.key,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentLocale = localeController.locale ?? Localizations.localeOf(context);

    final locales = [
      const Locale('en'),
      const Locale('am'),
    ];

    // Map each locale to an icon
    final localeIcons = {
      'en': Icons.language, // replace with actual icon/image if needed
      'am': Icons.language, // replace with Ethiopian flag icon if desired
    };

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: alignment == Alignment.centerRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.languageLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButton<Locale>(
            value: currentLocale,
            items: locales.map((locale) {
              final label = locale.languageCode == 'am'
                  ? l10n.amharicLabel
                  : l10n.englishLabel;

              return DropdownMenuItem(
                value: locale,
                child: Row(
                  children: [
                    Icon(localeIcons[locale.languageCode], size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (locale) {
              if (locale != null) localeController.setLocale(locale);
            },
          ),
        ],
      ),
    );
  }
}
