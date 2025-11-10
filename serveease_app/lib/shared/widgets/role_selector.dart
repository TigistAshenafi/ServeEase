import 'package:flutter/material.dart';

enum Role { seeker, provider }

class RoleSelector extends StatelessWidget {
  final Role selected;
  final ValueChanged<Role> onChanged;

  const RoleSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Service Seeker'),
          selected: selected == Role.seeker,
          onSelected: (_) => onChanged(Role.seeker),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Service Provider'),
          selected: selected == Role.provider,
          onSelected: (_) => onChanged(Role.provider),
        ),
      ],
    );
  }
}
