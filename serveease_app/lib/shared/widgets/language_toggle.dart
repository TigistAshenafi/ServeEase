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
          Wrap(
            spacing: 8,
            children: const [
              _LanguageChip(locale: Locale('en')),
              _LanguageChip(locale: Locale('am')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final Locale locale;

  const _LanguageChip({required this.locale});

  @override
  Widget build(BuildContext context) {
    final currentCode = (localeController.locale ??
            Localizations.localeOf(context))
        .languageCode;
    final l10n = context.l10n;
    final label = locale.languageCode == 'am'
        ? l10n.amharicLabel
        : l10n.englishLabel;

    return ChoiceChip(
      label: Text(label),
      selected: currentCode == locale.languageCode,
      onSelected: (_) => localeController.setLocale(locale),
      selectedColor: Colors.blue.shade100,
    );
  }
}

