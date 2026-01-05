// lib/core/utils/phone_validator.dart
class EthiopianPhoneValidator {
  /// Validates Ethiopian phone number format
  /// Expected format: 9XXXXXXXXX or 7XXXXXXXXX (9 digits without country code)
  static String? validateEthiopianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove formatting (spaces) to check the actual number
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Should be exactly 9 digits (without country code +251)
    if (cleanNumber.length != 9) {
      return 'Phone number must be exactly 9 digits';
    }
    
    // First digit must be 9 or 7
    if (!cleanNumber.startsWith('9') && !cleanNumber.startsWith('7')) {
      return 'Ethiopian mobile numbers must start with 9 or 7';
    }
    
    return null; // Valid
  }

  /// Validates Ethiopian phone number format with country code
  /// Expected format: +251 9XXXXXXXXX or +251 7XXXXXXXXX
  static String? validateEthiopianPhoneWithCountryCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove formatting to check the actual number
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Should be: 251 + (9 or 7) + 8 more digits = 12 digits total
    if (cleanNumber.length != 12) {
      return 'Phone number must be 9 digits after +251 (12 digits total)';
    }
    
    if (!cleanNumber.startsWith('251')) {
      return 'Phone number must start with +251';
    }
    
    String afterCountryCode = cleanNumber.substring(3);
    if (!afterCountryCode.startsWith('9') && !afterCountryCode.startsWith('7')) {
      return 'Ethiopian mobile numbers must start with 9 or 7 after +251';
    }
    
    // Check that we have exactly 9 digits after country code
    if (afterCountryCode.length != 9) {
      return 'Phone number must have exactly 9 digits after +251';
    }
    
    return null; // Valid
  }

  /// Formats Ethiopian phone number (without country code)
  static String formatEthiopianPhone(String input) {
    String text = input.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove +251 prefix if present
    if (text.startsWith('251')) {
      text = text.substring(3);
    }
    
    // Limit to 9 digits
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
    
    return formatted;
  }

  /// Formats Ethiopian phone number with country code
  static String formatEthiopianPhoneWithCountryCode(String input) {
    String text = input.replaceAll(RegExp(r'[^\d]'), '');
    
    // Always start with +251
    if (text.isEmpty) {
      return '+251';
    }
    
    // If user tries to delete +251, prevent it
    if (!text.startsWith('251')) {
      if (text.length == 1 && (text == '9' || text == '7')) {
        text = '251$text';
      } else {
        text = '251$text';
      }
    }
    
    // Format: +251 X XXXX XXXX
    String formatted = '+251';
    String remaining = text.substring(3);
    
    if (remaining.isNotEmpty) {
      // First digit after country code
      formatted += ' ${remaining.substring(0, 1)}';
      if (remaining.length > 1) {
        // Next 4 digits
        int endIndex = remaining.length > 5 ? 5 : remaining.length;
        formatted += ' ${remaining.substring(1, endIndex)}';
        if (remaining.length > 5) {
          // Last 4 digits
          int lastEndIndex = remaining.length > 9 ? 9 : remaining.length;
          formatted += ' ${remaining.substring(5, lastEndIndex)}';
        }
      }
    }
    
    return formatted;
  }

  /// Get full phone number with country code
  static String getFullPhoneNumber(String phoneWithoutCountryCode) {
    String clean = phoneWithoutCountryCode.replaceAll(RegExp(r'[^\d]'), '');
    return '+251$clean';
  }

  /// Check if phone number is valid Ethiopian format
  static bool isValidEthiopianPhone(String phone) {
    return validateEthiopianPhone(phone) == null;
  }
}