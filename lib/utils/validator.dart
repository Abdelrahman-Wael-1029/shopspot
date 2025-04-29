class Validator {
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }

  // Email validation for FCI structure (studentID@stud.fci-cu.edu.eg)
  static bool isValidFciEmail(String email) {
    final RegExp emailPattern = RegExp(
      r'^\d{8}@stud\.fci-cu\.edu\.eg$',
    );
    return emailPattern.hasMatch(email);
  }

  // Check if studentId matches email format
  static bool studentIdMatchesEmail(String studentId, String email) {
    if (!isValidFciEmail(email) || isNullOrEmpty(email)) return true;
    final extractedId = extractStudentIdFromEmail(email);
    return extractedId == studentId;
  }

  // Extract student ID from email
  static String? extractStudentIdFromEmail(String email) {
    if (!isValidFciEmail(email)) return null;
    
    final parts = email.split('@');
    return parts[0];
  }

  // Password validation (at least 8 characters with at least 1 number)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    // Check for at least one number
    final RegExp numberPattern = RegExp(r'[0-9]');
    return numberPattern.hasMatch(password);
  }

  // Password match validation
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  // Name validation (not empty)
  static bool isValidName(String name) {
    return !isNullOrEmpty(name);
  }

  // Student ID validation (format YYYYNNNN where YYYY is year and NNNN is a number between 1-1999)
  static bool isValidStudentId(String studentId) {
    if (isNullOrEmpty(studentId)) return false;
    
    // Check if it's exactly 8 digits
    final RegExp idPattern = RegExp(r'^\d{8}$');
    if (!idPattern.hasMatch(studentId)) return false;
    
    // Check if first 4 digits represent a valid year (e.g., 1996-2025)
    final yearPart = int.tryParse(studentId.substring(0, 4));
    if (yearPart! < 1996 || yearPart > DateTime.now().year) return false;
    
    // Check if last 4 digits represent a number between 1 and 1999
    final numberPart = int.tryParse(studentId.substring(4, 8));
    
    // Number should be between 1 and 1999
    return numberPart! >= 1 && numberPart <= 1999;
  }
  
  // Get validation message for student ID
  static String? getStudentIdValidationMessage(String studentId) {
    if (isNullOrEmpty(studentId)) {
      return 'Student ID is required';
    }
    
    final RegExp idPattern = RegExp(r'^\d{8}$');
    if (!idPattern.hasMatch(studentId)) {
      return 'Student ID must be 8 digits (eg. 20011002)';
    }
    
    final yearPart = int.tryParse(studentId.substring(0, 4));
    if (yearPart! < 1996 || yearPart > DateTime.now().year) {
      return 'First 4 digits must be a valid year (1996-${DateTime.now().year})';
    }
    
    final numberPart = int.tryParse(studentId.substring(4, 8));
    if (numberPart! < 1 || numberPart > 1999) {
      return 'Last 4 digits must be a number between 0001-1999';
    }
    
    return null;
  }
}
