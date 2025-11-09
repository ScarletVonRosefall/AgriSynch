// lib/services/validation_service.dart
class ValidationService {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    
    if (!hasLetter || !hasNumber) {
      return 'Password must contain both letters and numbers';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 100) {
      return 'Name must not exceed 100 characters';
    }
    
    // Only letters, spaces, hyphens, apostrophes, and commas (for formatted names)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-',]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Nickname validation
  static String? validateNickname(String? value) {
    // Nickname is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    if (value.trim().length < 2) {
      return 'Nickname must be at least 2 characters';
    }
    
    if (value.trim().length > 30) {
      return 'Nickname must not exceed 30 characters';
    }
    
    // Only letters and spaces - no numbers or special characters
    final nicknameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nicknameRegex.hasMatch(value.trim())) {
      return 'Nickname can only contain letters and spaces';
    }
    
    return null;
  }

  // Phone number validation (Philippine format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Philippine mobile: 09xxxxxxxxx or +639xxxxxxxxx
    final mobileRegex = RegExp(r'^(09|\+639)\d{9}$');
    
    if (!mobileRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Philippine mobile number (e.g., 09171234567)';
    }
    
    return null;
  }

  // Optional phone number validation (Philippine format)
  static String? validateOptionalPhoneNumber(String? value) {
    // Phone is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Philippine mobile: 09xxxxxxxxx or +639xxxxxxxxx
    final mobileRegex = RegExp(r'^(09|\+639)\d{9}$');
    
    if (!mobileRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Philippine mobile number (e.g., 09171234567)';
    }
    
    return null;
  }

  // Product name validation
  static String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    
    if (value.trim().length < 3) {
      return 'Product name must be at least 3 characters';
    }
    
    if (value.trim().length > 100) {
      return 'Product name must not exceed 100 characters';
    }
    
    return null;
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value.trim());
    
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price <= 0) {
      return 'Price must be greater than zero';
    }
    
    if (price > 1000000) {
      return 'Price seems too high. Please verify';
    }
    
    // Check for valid decimal places (max 2)
    if (value.contains('.')) {
      final parts = value.split('.');
      if (parts[1].length > 2) {
        return 'Price can have at most 2 decimal places';
      }
    }
    
    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = int.tryParse(value.trim());
    
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    
    if (quantity > 100000) {
      return 'Quantity seems too high. Please verify';
    }
    
    return null;
  }

  // Stock validation
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock is required';
    }
    
    final stock = int.tryParse(value.trim());
    
    if (stock == null) {
      return 'Please enter a valid stock amount';
    }
    
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    
    if (stock > 1000000) {
      return 'Stock amount seems too high. Please verify';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.trim().length > 500) {
      return 'Description must not exceed 500 characters';
    }
    
    return null;
  }

  // Optional description validation (can be empty)
  static String? validateOptionalDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    if (value.trim().length > 500) {
      return 'Description must not exceed 500 characters';
    }
    
    return null;
  }

  // Category validation
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    
    return null;
  }

  // Unit validation
  static String? validateUnit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Unit is required';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    if (value.trim().length > 200) {
      return 'Address must not exceed 200 characters';
    }
    
    return null;
  }

  // Location validation (for profile)
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    
    if (value.trim().length < 12) {
      return 'Location must be at least 12 characters';
    }
    
    if (value.trim().length > 200) {
      return 'Location must not exceed 200 characters';
    }
    
    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // URL validation (for image URLs)
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Number range validation
  static String? validateNumberInRange(
    String? value,
    String fieldName,
    double min,
    double max,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value.trim());
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Sanitize input (remove leading/trailing whitespace and limit length)
  static String sanitizeInput(String input, {int maxLength = 500}) {
    String sanitized = input.trim();
    
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }

  // Check if string contains only numbers
  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  // Format phone number for display
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.startsWith('+639')) {
      return '+63 ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    } else if (cleaned.startsWith('09')) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    
    return phone;
  }
}
