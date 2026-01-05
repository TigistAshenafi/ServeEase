// test/phone_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/utils/phone_validator.dart';

void main() {
  group('Ethiopian Phone Validator Tests', () {
    test('Valid Ethiopian phone numbers (without country code) should pass validation', () {
      // Valid formats - 9 digits starting with 9 or 7
      expect(EthiopianPhoneValidator.validateEthiopianPhone('912345678'), isNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('787654321'), isNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('9 1234 5678'), isNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('7 8765 4321'), isNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('911111111'), isNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('722222222'), isNull);
    });

    test('Invalid Ethiopian phone numbers should fail validation', () {
      // Wrong first digit
      expect(EthiopianPhoneValidator.validateEthiopianPhone('812345678'), isNotNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('512345678'), isNotNull);
      
      // Too short (less than 9 digits)
      expect(EthiopianPhoneValidator.validateEthiopianPhone('9123'), isNotNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone('91234567'), isNotNull);
      
      // Too long (more than 9 digits)
      expect(EthiopianPhoneValidator.validateEthiopianPhone('9123456789'), isNotNull);
      
      // Empty
      expect(EthiopianPhoneValidator.validateEthiopianPhone(''), isNotNull);
      expect(EthiopianPhoneValidator.validateEthiopianPhone(null), isNotNull);
    });

    test('Phone number formatting should work correctly', () {
      expect(EthiopianPhoneValidator.formatEthiopianPhone(''), equals(''));
      expect(EthiopianPhoneValidator.formatEthiopianPhone('9'), equals('9'));
      expect(EthiopianPhoneValidator.formatEthiopianPhone('91234'), equals('9 1234'));
      expect(EthiopianPhoneValidator.formatEthiopianPhone('912345678'), equals('9 1234 5678'));
      expect(EthiopianPhoneValidator.formatEthiopianPhone('787654321'), equals('7 8765 4321'));
    });

    test('Full phone number generation should work correctly', () {
      expect(EthiopianPhoneValidator.getFullPhoneNumber('912345678'), equals('+251912345678'));
      expect(EthiopianPhoneValidator.getFullPhoneNumber('9 1234 5678'), equals('+251912345678'));
      expect(EthiopianPhoneValidator.getFullPhoneNumber('787654321'), equals('+251787654321'));
    });

    test('isValidEthiopianPhone should return correct boolean', () {
      expect(EthiopianPhoneValidator.isValidEthiopianPhone('912345678'), isTrue);
      expect(EthiopianPhoneValidator.isValidEthiopianPhone('787654321'), isTrue);
      expect(EthiopianPhoneValidator.isValidEthiopianPhone('812345678'), isFalse);
      expect(EthiopianPhoneValidator.isValidEthiopianPhone('91234567'), isFalse);
    });
  });
}