// lib/shared/widgets/ethiopian_phone_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serveease_app/core/utils/phone_validator.dart';

class EthiopianPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String hintText;
  final bool enabled;

  const EthiopianPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Phone Number',
    this.hintText = '9 1234 5678',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        EthiopianPhoneFormatter(),
      ],
      validator: validator ?? EthiopianPhoneValidator.validateEthiopianPhone,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ethiopian Flag
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildEthiopianFlag(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+251',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 241, 237, 237),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
      ),
    );
  }

  Widget _buildEthiopianFlag() {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            // Green stripe
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF078930), // Ethiopian green
              ),
            ),
            // Yellow stripe with emblem
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFFCDD09), // Ethiopian yellow
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF078930),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDA020E),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFFFCDD09),
                      size: 6,
                    ),
                  ),
                ),
              ),
            ),
            // Red stripe
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFDA020E), // Ethiopian red
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Ethiopian phone number formatter
class EthiopianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // Remove all non-digits
    text = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove +251 prefix if user typed it (we show it as prefix)
    if (text.startsWith('251')) {
      text = text.substring(3);
    }
    
    // Limit to 9 digits (Ethiopian mobile number length after country code)
    if (text.length > 9) {
      text = text.substring(0, 9);
    }
    
    // Format as: X XXXX XXXX
    String formatted = '';
    if (text.isNotEmpty) {
      formatted = text.substring(0, 1);
      if (text.length > 1) {
        formatted += ' ${text.substring(1, text.length > 5 ? 5 : text.length)}';
        if (text.length > 5) {
          formatted += ' ${text.substring(5)}';
        }
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}