import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool obscureText;

  const AnimatedInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
  });

  @override
  State<AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: _isFocused ? 2 : 1,
              ),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      obscureText: widget.obscureText,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      validator: widget.validator,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}