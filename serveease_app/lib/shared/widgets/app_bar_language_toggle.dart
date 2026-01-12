import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/localization/locale_provider.dart';

class AppBarLanguageToggle extends StatelessWidget {
  final Color iconColor;
  final Color textColor;
  final bool isCompact;

  const AppBarLanguageToggle({
    super.key,
    this.iconColor = Colors.grey,
    this.textColor = Colors.black,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        if (isCompact) {
          // Compact version for AppBar with limited space
          return PopupMenuButton<Locale>(
            icon: Icon(Icons.language, color: iconColor),
            onSelected: (locale) async {
              await localeProvider.setLocale(locale);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text('English', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('am'),
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text('አማርኛ', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Inline dropdown version
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: localeProvider.currentLocale,
                dropdownColor: Colors.blue[700],
                icon: Icon(Icons.language, color: iconColor, size: 20),
                items: [
                  DropdownMenuItem(
                    value: const Locale('en'),
                    child: Text('EN',
                        style: TextStyle(color: textColor, fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: const Locale('am'),
                    child: Text('አማ',
                        style: TextStyle(color: textColor, fontSize: 12)),
                  ),
                ],
                onChanged: (locale) async {
                  if (locale != null) {
                    await localeProvider.setLocale(locale);
                  }
                },
              ),
            ),
          );
        }
      },
    );
  }
}
