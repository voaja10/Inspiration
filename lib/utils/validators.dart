/// Validation utilities for form fields
class FormValidators {
  static String? validateAmount(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName (number format)';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? validatePositiveAmount(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName (number format)';
    }
    if (parsed == 0) {
      return '$fieldName cannot be 0';
    }
    return null;
  }

  static String? validateExchangeRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Exchange rate is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid exchange rate (number format)';
    }
    if (parsed <= 0) {
      return 'Exchange rate must be greater than 0';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateOptional(String? value) {
    return null;
  }

  static String? validateSessionName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Session name is required';
    }
    if (value.trim().length < 2) {
      return 'Session name must be at least 2 characters';
    }
    return null;
  }

  static String? validateInvoiceReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invoice reference is required';
    }
    if (value.trim().length < 2) {
      return 'Invoice reference must be at least 2 characters';
    }
    return null;
  }

  static String? validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Reason is required';
    }
    if (value.trim().length < 2) {
      return 'Reason must be at least 2 characters';
    }
    return null;
  }
}
