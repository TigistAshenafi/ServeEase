import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool disabled;

  const CustomButton({super.key, required this.label, required this.onPressed, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
