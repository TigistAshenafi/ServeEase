import 'package:flutter/material.dart';

import 'package:serveease_app/core/localization/l10n_extension.dart';

enum Role { seeker, provider }

class RoleSelector extends StatelessWidget {
  final Role selected;
  final ValueChanged<Role> onChanged;

  const RoleSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        ChoiceChip(
          label: Text(l10n.serviceSeekerLabel),
          selected: selected == Role.seeker,
          onSelected: (_) => onChanged(Role.seeker),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: Text(l10n.serviceProviderLabel),
          selected: selected == Role.provider,
          onSelected: (_) => onChanged(Role.provider),
        ),
      ],
    );
  }
}
