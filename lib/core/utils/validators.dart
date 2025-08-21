class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? deviceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device name is required';
    }
    if (value.trim().length < 2) {
      return 'Device name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Device name must be less than 50 characters';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }
    return null;
  }

  static String? range(
    String? value,
    double min,
    double max, [
    String? fieldName,
  ]) {
    final numberError = positiveNumber(value, fieldName);
    if (numberError != null) return numberError;

    final number = double.parse(value!);
    if (number < min || number > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }
    return null;
  }
}
