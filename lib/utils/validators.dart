class AppValidators {
  // Required field validator
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Email validator
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  // Password validator
  static String? password(String? value, {int minLength = 4}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
  
  // Confirm password validator
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  // Phone number validator (Indian)
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
  
  // Username validator
  static String? username(String? value, {int minLength = 3, int maxLength = 30}) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < minLength) {
      return 'Username must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return 'Username cannot exceed $maxLength characters';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
  
  // Amount validator
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amountValue = double.tryParse(value);
    if (amountValue == null || amountValue <= 0) {
      return 'Enter a valid amount greater than 0';
    }
    return null;
  }
  
  // Number validator
  static String? number(String? value, {double min = 0, double max = double.infinity}) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Enter a valid number';
    }
    if (numValue < min) {
      return 'Value must be at least $min';
    }
    if (numValue > max) {
      return 'Value cannot exceed $max';
    }
    return null;
  }
  
  // URL validator
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Enter a valid URL';
    }
    return null;
  }
  
  // Date validator
  static String? date(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Enter a valid date (YYYY-MM-DD)';
    }
  }
  
  // Future date validator
  static String? futureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    return null;
  }
  
  // Past date validator
  static String? pastDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (date.isAfter(DateTime.now())) {
      return 'Date must be in the past';
    }
    return null;
  }
  
  // OTP validator
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.length != length) {
      return 'OTP must be $length digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }
  
  // PAN Card validator
  static String? panCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid PAN card number';
    }
    return null;
  }
  
  // Aadhar Card validator
  static String? aadharCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final aadharRegex = RegExp(r'^\d{12}$');
    if (!aadharRegex.hasMatch(value.trim())) {
      return 'Enter a valid 12-digit Aadhar number';
    }
    return null;
  }
  
  // Vehicle number validator
  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$');
    if (!vehicleRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid vehicle number (e.g., MH01AB1234)';
    }
    return null;
  }
  
  // PIN code validator
  static String? pinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final pinRegex = RegExp(r'^\d{6}$');
    if (!pinRegex.hasMatch(value.trim())) {
      return 'Enter a valid 6-digit PIN code';
    }
    return null;
  }
}