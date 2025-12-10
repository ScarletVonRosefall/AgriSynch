/// Input validation and sanitization utility
/// Prevents injection attacks, special character exploits, and database corruption
class InputValidator {
  // Maximum lengths for different input types
  static const int maxNameLength = 100;
  static const int maxEmailLength = 254; // RFC 5321
  static const int maxPasswordLength = 128;
  static const int maxPhoneLength = 20;
  static const int maxAddressLength = 500;
  static const int maxDescriptionLength = 2000;
  static const int maxTitleLength = 200;
  static const int maxMessageLength = 5000;
  static const int maxSearchLength = 100;

  // Regex patterns for validation
  static final RegExp _namePattern = RegExp(r"^[a-zA-Z\s\-\.']+$");
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^[0-9\+\-\(\)\s]+$');
  
  // Dangerous characters that could be used for injection
  static final RegExp _dangerousChars = RegExp(r'[<>{};\$\[\]\\`]');
  static final RegExp _scriptTags = RegExp(r'<script|</script|javascript:|onerror=|onload=', caseSensitive: false);
  static final RegExp _sqlKeywords = RegExp(
    r'\b(DROP|DELETE|INSERT|UPDATE|SELECT|UNION|EXEC|EXECUTE|SCRIPT|JAVASCRIPT|ALERT)\b',
    caseSensitive: false,
  );

  /// Sanitize general text input (names, titles, etc.)
  static String sanitizeText(String? input, {int maxLength = maxTitleLength}) {
    if (input == null || input.isEmpty) return '';
    
    // Trim whitespace
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    // Remove dangerous characters
    sanitized = sanitized.replaceAll(_dangerousChars, '');
    
    // Remove script tags and SQL keywords
    sanitized = sanitized.replaceAll(_scriptTags, '');
    
    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized.trim();
  }

  /// Sanitize name input (first name, last name, etc.)
  static String sanitizeName(String? input) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxNameLength) {
      sanitized = sanitized.substring(0, maxNameLength);
    }
    
    // Remove any character that's not letter, space, hyphen, dot, or apostrophe
    sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-Z\s\-\.']"), '');
    
    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized.trim();
  }

  /// Sanitize email input
  static String sanitizeEmail(String? input) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim().toLowerCase();
    
    // Limit length
    if (sanitized.length > maxEmailLength) {
      sanitized = sanitized.substring(0, maxEmailLength);
    }
    
    // Remove dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>{};\[\]\\`]'), '');
    
    return sanitized;
  }

  /// Sanitize phone number input
  static String sanitizePhone(String? input) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxPhoneLength) {
      sanitized = sanitized.substring(0, maxPhoneLength);
    }
    
    // Keep only numbers, +, -, (, ), and spaces
    sanitized = sanitized.replaceAll(RegExp(r'[^0-9\+\-\(\)\s]'), '');
    
    return sanitized;
  }

  /// Sanitize address input
  static String sanitizeAddress(String? input) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxAddressLength) {
      sanitized = sanitized.substring(0, maxAddressLength);
    }
    
    // Remove dangerous characters but keep common punctuation
    sanitized = sanitized.replaceAll(_dangerousChars, '');
    sanitized = sanitized.replaceAll(_scriptTags, '');
    
    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized.trim();
  }

  /// Sanitize description/message input
  static String sanitizeDescription(String? input, {int maxLength = maxDescriptionLength}) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    // Remove dangerous characters but keep basic punctuation
    sanitized = sanitized.replaceAll(_dangerousChars, '');
    sanitized = sanitized.replaceAll(_scriptTags, '');
    
    // Normalize excessive whitespace but preserve line breaks
    sanitized = sanitized.replaceAll(RegExp(r' {2,}'), ' ');
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return sanitized.trim();
  }

  /// Sanitize numeric input
  static String sanitizeNumeric(String? input, {bool allowDecimal = false}) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    if (allowDecimal) {
      // Keep only numbers and one decimal point
      sanitized = sanitized.replaceAll(RegExp(r'[^0-9\.]'), '');
      
      // Ensure only one decimal point
      final parts = sanitized.split('.');
      if (parts.length > 2) {
        sanitized = '${parts[0]}.${parts.sublist(1).join('')}';
      }
    } else {
      // Keep only numbers
      sanitized = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    return sanitized;
  }

  /// Validate name
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final sanitized = sanitizeName(value);
    
    if (sanitized.isEmpty) {
      return '$fieldName contains invalid characters';
    }
    
    if (sanitized.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (sanitized.length > maxNameLength) {
      return '$fieldName is too long (max $maxNameLength characters)';
    }
    
    if (!_namePattern.hasMatch(sanitized)) {
      return '$fieldName can only contain letters, spaces, hyphens, dots, and apostrophes';
    }
    
    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final sanitized = sanitizeEmail(value);
    
    if (sanitized.isEmpty) {
      return 'Email contains invalid characters';
    }
    
    if (sanitized.length > maxEmailLength) {
      return 'Email is too long';
    }
    
    if (!_emailPattern.hasMatch(sanitized)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Phone number is required' : null;
    }
    
    final sanitized = sanitizePhone(value);
    
    if (sanitized.isEmpty && required) {
      return 'Phone number contains only invalid characters';
    }
    
    if (sanitized.length > maxPhoneLength) {
      return 'Phone number is too long';
    }
    
    // Remove all non-numeric characters for length check
    final numbersOnly = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbersOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (!_phonePattern.hasMatch(sanitized)) {
      return 'Phone number contains invalid characters';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {bool isSignup = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length > maxPasswordLength) {
      return 'Password is too long (max $maxPasswordLength characters)';
    }
    
    if (isSignup) {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      
      // Check for at least one letter and one number
      if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
        return 'Password must contain at least one letter';
      }
      
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }
    }
    
    return null;
  }

  /// Validate text input (general purpose)
  static String? validateText(String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = maxTitleLength,
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    final sanitized = sanitizeText(value, maxLength: maxLength);
    
    if (sanitized.isEmpty && required) {
      return '$fieldName contains only invalid characters';
    }
    
    if (sanitized.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (sanitized.length > maxLength) {
      return '$fieldName is too long (max $maxLength characters)';
    }
    
    // Check for SQL injection attempts
    if (_sqlKeywords.hasMatch(sanitized)) {
      return '$fieldName contains invalid content';
    }
    
    return null;
  }

  /// Validate description/message
  static String? validateDescription(String? value, {
    required String fieldName,
    int minLength = 0,
    int maxLength = maxDescriptionLength,
    bool required = false,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    final sanitized = sanitizeDescription(value, maxLength: maxLength);
    
    if (sanitized.isEmpty && required) {
      return '$fieldName contains only invalid characters';
    }
    
    if (sanitized.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (sanitized.length > maxLength) {
      return '$fieldName is too long (max $maxLength characters)';
    }
    
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, {
    required String fieldName,
    bool required = true,
    bool allowDecimal = false,
    double? min,
    double? max,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    final sanitized = sanitizeNumeric(value, allowDecimal: allowDecimal);
    
    if (sanitized.isEmpty) {
      return '$fieldName must be a number';
    }
    
    final number = double.tryParse(sanitized);
    
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  /// Check if string contains dangerous content
  static bool containsDangerousContent(String? value) {
    if (value == null || value.isEmpty) return false;
    
    return _dangerousChars.hasMatch(value) ||
           _scriptTags.hasMatch(value) ||
           _sqlKeywords.hasMatch(value);
  }

  /// Sanitize map data (for saving to Firestore)
  static Map<String, dynamic> sanitizeMapData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeText(value, maxLength: maxDescriptionLength);
      } else if (value is Map) {
        sanitized[key] = sanitizeMapData(value as Map<String, dynamic>);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeText(item, maxLength: maxDescriptionLength);
          } else if (item is Map) {
            return sanitizeMapData(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
}
