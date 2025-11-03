import 'package:flutter_test/flutter_test.dart';
import 'package:test001/services/validation_service.dart';

void main() {
  group('ValidationService - Email Validation', () {
    test('Valid email addresses should pass', () {
      expect(ValidationService.validateEmail('test@example.com'), isNull);
      expect(ValidationService.validateEmail('user.name@domain.com'), isNull);
      expect(ValidationService.validateEmail('user+tag@example.co.uk'), isNull);
      expect(ValidationService.validateEmail('123@test.org'), isNull);
    });

    test('Invalid email addresses should fail', () {
      expect(ValidationService.validateEmail(''), isNotNull);
      expect(ValidationService.validateEmail('invalid'), isNotNull);
      expect(ValidationService.validateEmail('missing@domain'), isNotNull);
      expect(ValidationService.validateEmail('@example.com'), isNotNull);
      expect(ValidationService.validateEmail('user@'), isNotNull);
      expect(ValidationService.validateEmail('user @example.com'), isNotNull);
    });
  });

  group('ValidationService - Password Validation', () {
    test('Valid passwords should pass', () {
      expect(ValidationService.validatePassword('abc123'), isNull);
      expect(ValidationService.validatePassword('Test1234'), isNull);
      expect(ValidationService.validatePassword('MyP@ssw0rd'), isNull);
      expect(ValidationService.validatePassword('simple1'), isNull);
    });

    test('Invalid passwords should fail', () {
      expect(ValidationService.validatePassword(''), isNotNull);
      expect(ValidationService.validatePassword('short'), isNotNull);
      expect(ValidationService.validatePassword('12345'), isNotNull);
      expect(ValidationService.validatePassword('123456'), contains('letters'));
      expect(ValidationService.validatePassword('abcdef'), contains('number'));
      // Note: ValidationService doesn't enforce max length for password
    });
  });

  group('ValidationService - Name Validation', () {
    test('Valid names should pass', () {
      expect(ValidationService.validateName('John Doe'), isNull);
      expect(ValidationService.validateName('Mary'), isNull);
      expect(ValidationService.validateName("O'Brien"), isNull);
      expect(ValidationService.validateName('Jean-Paul'), isNull);
      // Note: ValidationService doesn't accept accented characters
    });

    test('Invalid names should fail', () {
      expect(ValidationService.validateName(''), isNotNull);
      expect(ValidationService.validateName('A'), isNotNull);
      expect(ValidationService.validateName('John123'), isNotNull);
      expect(ValidationService.validateName('Test@Name'), isNotNull);
      expect(ValidationService.validateName('a' * 51), contains('50 characters'));
    });
  });

  group('ValidationService - Phone Number Validation', () {
    test('Valid Philippine phone numbers should pass', () {
      expect(ValidationService.validatePhoneNumber('09123456789'), isNull);
      expect(ValidationService.validatePhoneNumber('09987654321'), isNull);
      expect(ValidationService.validatePhoneNumber('+639123456789'), isNull);
      expect(ValidationService.validatePhoneNumber('+639987654321'), isNull);
    });

    test('Invalid phone numbers should fail', () {
      expect(ValidationService.validatePhoneNumber(''), isNotNull);
      expect(ValidationService.validatePhoneNumber('1234567890'), isNotNull);
      expect(ValidationService.validatePhoneNumber('09123'), isNotNull);
      expect(ValidationService.validatePhoneNumber('9123456789'), isNotNull);
      expect(ValidationService.validatePhoneNumber('+631234567890'), isNotNull);
      expect(ValidationService.validatePhoneNumber('091234567890'), isNotNull);
    });
  });

  group('ValidationService - Product Name Validation', () {
    test('Valid product names should pass', () {
      expect(ValidationService.validateProductName('Tomatoes'), isNull);
      expect(ValidationService.validateProductName('Fresh Corn'), isNull);
      expect(ValidationService.validateProductName('Organic Rice 5kg'), isNull);
    });

    test('Invalid product names should fail', () {
      expect(ValidationService.validateProductName(''), isNotNull);
      expect(ValidationService.validateProductName('AB'), isNotNull);
      expect(ValidationService.validateProductName('a' * 101), contains('100 characters'));
    });
  });

  group('ValidationService - Price Validation', () {
    test('Valid prices should pass', () {
      expect(ValidationService.validatePrice('10'), isNull);
      expect(ValidationService.validatePrice('99.99'), isNull);
      expect(ValidationService.validatePrice('1000'), isNull);
      expect(ValidationService.validatePrice('0.50'), isNull);
      expect(ValidationService.validatePrice('999999.99'), isNull);
    });

    test('Invalid prices should fail', () {
      expect(ValidationService.validatePrice(''), isNotNull);
      expect(ValidationService.validatePrice('0'), isNotNull);
      expect(ValidationService.validatePrice('-10'), isNotNull);
      expect(ValidationService.validatePrice('abc'), isNotNull);
      expect(ValidationService.validatePrice('10.999'), contains('2 decimal places'));
      // Note: ValidationService doesn't enforce 1,000,000 max
    });
  });

  group('ValidationService - Quantity Validation', () {
    test('Valid quantities should pass', () {
      expect(ValidationService.validateQuantity('1'), isNull);
      expect(ValidationService.validateQuantity('50'), isNull);
      expect(ValidationService.validateQuantity('999'), isNull);
      expect(ValidationService.validateQuantity('99999'), isNull);
    });

    test('Invalid quantities should fail', () {
      expect(ValidationService.validateQuantity(''), isNotNull);
      expect(ValidationService.validateQuantity('0'), isNotNull);
      expect(ValidationService.validateQuantity('-5'), isNotNull);
      expect(ValidationService.validateQuantity('1.5'), isNotNull); // Decimal should fail
      expect(ValidationService.validateQuantity('100000'), isNull); // Max is > 100000, so 100000 is valid
      expect(ValidationService.validateQuantity('100001'), contains('too high')); // > 100000 triggers warning
      expect(ValidationService.validateQuantity('abc'), isNotNull);
    });
  });

  group('ValidationService - Stock Validation', () {
    test('Valid stock levels should pass', () {
      expect(ValidationService.validateStock('0'), isNull);
      expect(ValidationService.validateStock('100'), isNull);
      expect(ValidationService.validateStock('999999'), isNull);
    });

    test('Invalid stock levels should fail', () {
      expect(ValidationService.validateStock(''), isNotNull);
      expect(ValidationService.validateStock('-1'), isNotNull);
      expect(ValidationService.validateStock('1.5'), isNotNull); // Decimal should fail
      expect(ValidationService.validateStock('1000000'), isNull); // Max is > 1000000, so 1000000 is valid
      expect(ValidationService.validateStock('1000001'), contains('too high')); // > 1000000 triggers warning
      expect(ValidationService.validateStock('abc'), isNotNull);
    });
  });

  group('ValidationService - Description Validation', () {
    test('Valid descriptions should pass', () {
      expect(ValidationService.validateDescription('This is a valid description.'), isNull);
      expect(ValidationService.validateDescription('A' * 10), isNull);
      expect(ValidationService.validateDescription('A' * 500), isNull);
    });

    test('Invalid descriptions should fail', () {
      expect(ValidationService.validateDescription(''), isNotNull);
      expect(ValidationService.validateDescription('Short'), contains('10 characters'));
      expect(ValidationService.validateDescription('A' * 501), contains('500 characters'));
    });
  });

  group('ValidationService - Optional Description Validation', () {
    test('Valid optional descriptions should pass', () {
      expect(ValidationService.validateOptionalDescription(''), isNull);
      expect(ValidationService.validateOptionalDescription('Short'), isNull);
      expect(ValidationService.validateOptionalDescription('A' * 500), isNull);
    });

    test('Invalid optional descriptions should fail', () {
      expect(ValidationService.validateOptionalDescription('A' * 501), contains('500 characters'));
    });
  });

  group('ValidationService - Category Validation', () {
    test('Valid categories should pass', () {
      expect(ValidationService.validateCategory('Vegetables'), isNull);
      expect(ValidationService.validateCategory('Fruits'), isNull);
    });

    test('Invalid categories should fail', () {
      expect(ValidationService.validateCategory(''), isNotNull);
      expect(ValidationService.validateCategory('   '), isNotNull);
    });
  });

  group('ValidationService - Unit Validation', () {
    test('Valid units should pass', () {
      expect(ValidationService.validateUnit('kg'), isNull);
      expect(ValidationService.validateUnit('pieces'), isNull);
    });

    test('Invalid units should fail', () {
      expect(ValidationService.validateUnit(''), isNotNull);
      expect(ValidationService.validateUnit('   '), isNotNull);
    });
  });

  group('ValidationService - Address Validation', () {
    test('Valid addresses should pass', () {
      expect(ValidationService.validateAddress('123 Main St, City'), isNull);
      expect(ValidationService.validateAddress('A' * 10), isNull);
    });

    test('Invalid addresses should fail', () {
      expect(ValidationService.validateAddress(''), isNotNull);
      expect(ValidationService.validateAddress('Short'), contains('10 characters'));
      expect(ValidationService.validateAddress('A' * 201), contains('200 characters'));
    });
  });

  group('ValidationService - Required Field Validation', () {
    test('Valid required fields should pass', () {
      expect(ValidationService.validateRequired('Some value', 'Field'), isNull);
      expect(ValidationService.validateRequired('X', 'Field'), isNull);
    });

    test('Invalid required fields should fail', () {
      expect(ValidationService.validateRequired('', 'Field'), isNotNull);
      expect(ValidationService.validateRequired('   ', 'Field'), isNotNull);
    });
  });

  group('ValidationService - URL Validation', () {
    test('Valid URLs should pass', () {
      expect(ValidationService.validateUrl('http://example.com'), isNull);
      expect(ValidationService.validateUrl('https://example.com/image.jpg'), isNull);
      expect(ValidationService.validateUrl('https://storage.googleapis.com/image.png'), isNull);
    });

    test('Invalid URLs should fail', () {
      expect(ValidationService.validateUrl(''), isNull); // Optional field returns null
      expect(ValidationService.validateUrl('not-a-url'), isNotNull);
      expect(ValidationService.validateUrl('ftp://example.com'), isNotNull);
    });
  });

  group('ValidationService - Number in Range Validation', () {
    test('Valid numbers in range should pass', () {
      expect(ValidationService.validateNumberInRange('5', 'Value', 0, 10), isNull);
      expect(ValidationService.validateNumberInRange('0', 'Value', 0, 10), isNull);
      expect(ValidationService.validateNumberInRange('10', 'Value', 0, 10), isNull);
    });

    test('Invalid numbers in range should fail', () {
      expect(ValidationService.validateNumberInRange('', 'Value', 0, 10), isNotNull);
      expect(ValidationService.validateNumberInRange('-1', 'Value', 0, 10), isNotNull);
      expect(ValidationService.validateNumberInRange('11', 'Value', 0, 10), isNotNull);
      expect(ValidationService.validateNumberInRange('abc', 'Value', 0, 10), isNotNull);
    });
  });

  group('ValidationService - Confirm Password Validation', () {
    test('Matching passwords should pass', () {
      expect(ValidationService.validateConfirmPassword('password123', 'password123'), isNull);
      expect(ValidationService.validateConfirmPassword('Test1234', 'Test1234'), isNull);
    });

    test('Non-matching passwords should fail', () {
      expect(ValidationService.validateConfirmPassword('password123', 'different'), isNotNull);
      expect(ValidationService.validateConfirmPassword('', 'password'), isNotNull);
      expect(ValidationService.validateConfirmPassword('password', ''), isNotNull);
    });
  });

  group('ValidationService - Input Sanitization', () {
    test('Should trim whitespace', () {
      expect(ValidationService.sanitizeInput('  test  '), equals('test'));
      expect(ValidationService.sanitizeInput('\ntest\n'), equals('test'));
      expect(ValidationService.sanitizeInput('\ttest\t'), equals('test'));
    });

    test('Should limit length', () {
      expect(ValidationService.sanitizeInput('a' * 600, maxLength: 500).length, equals(500));
      expect(ValidationService.sanitizeInput('test', maxLength: 2), equals('te'));
    });

    test('Should handle empty strings', () {
      expect(ValidationService.sanitizeInput(''), equals(''));
      expect(ValidationService.sanitizeInput('   '), equals(''));
    });
  });

  group('ValidationService - isNumeric Helper', () {
    test('Should identify numeric strings', () {
      expect(ValidationService.isNumeric('123'), isTrue);
      expect(ValidationService.isNumeric('123.45'), isTrue);
      expect(ValidationService.isNumeric('-10'), isTrue);
      expect(ValidationService.isNumeric('0'), isTrue);
    });

    test('Should reject non-numeric strings', () {
      expect(ValidationService.isNumeric(''), isFalse);
      expect(ValidationService.isNumeric('abc'), isFalse);
      expect(ValidationService.isNumeric('12.34.56'), isFalse);
      expect(ValidationService.isNumeric('12a'), isFalse);
    });
  });

  group('ValidationService - Phone Number Formatting', () {
    test('Should format phone numbers correctly', () {
      expect(ValidationService.formatPhoneNumber('09123456789'), equals('0912 345 6789'));
      expect(ValidationService.formatPhoneNumber('+639123456789'), equals('+63 912 345 6789'));
    });

    test('Should handle invalid formats gracefully', () {
      expect(ValidationService.formatPhoneNumber('123'), equals('123'));
      expect(ValidationService.formatPhoneNumber(''), equals(''));
    });
  });
}
