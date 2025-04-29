import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/validator.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _gender;
  String? _level;

  // Password visibility toggles
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _nameError;
  String? _emailError;
  String? _studentIdError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _nameError = null;
      _emailError = null;
      _studentIdError = null;
      _passwordError = null;
      _confirmPasswordError = null;

      // Validate name (mandatory)
      if (!Validator.isValidName(_nameController.text)) {
        _nameError = 'Name is required';
        isValid = false;
      }

      // Validate student ID (YYYYNNNN format)
      final studentIdValidationMsg =
          Validator.getStudentIdValidationMessage(_studentIdController.text);
      if (studentIdValidationMsg != null) {
        _studentIdError = studentIdValidationMsg;
        isValid = false;
      } else if (!Validator.studentIdMatchesEmail(
          _studentIdController.text, _emailController.text)) {
        _studentIdError = 'Student ID must match the one in your email';
        isValid = false;
      }

      // Validate email (FCI email format validation)
      if (Validator.isNullOrEmpty(_emailController.text)) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!Validator.isValidFciEmail(_emailController.text)) {
        _emailError = 'Invalid FCI email format (studentID@stud.fci-cu.edu.eg)';
        isValid = false;
      }

      // Validate password (at least 8 characters with 1 number)
      if (Validator.isNullOrEmpty(_passwordController.text)) {
        _passwordError = 'Password is required';
        isValid = false;
      } else if (!Validator.isValidPassword(_passwordController.text)) {
        _passwordError =
            'Password must be at least 8 characters with at least 1 number';
        isValid = false;
      }

      // Validate confirm password (must match password)
      if (Validator.isNullOrEmpty(_confirmPasswordController.text)) {
        _confirmPasswordError = 'Confirm password is required';
        isValid = false;
      } else if (!Validator.passwordsMatch(
          _passwordController.text, _confirmPasswordController.text)) {
        _confirmPasswordError = 'Passwords do not match';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      context: context,
      name: _nameController.text,
      studentId: _studentIdController.text,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      gender: _gender,
      level: _level,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: "Signup successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/stores');
      }
    } else {
      if (mounted) {
        // Get validation errors from the response
        final validationErrors = authProvider.validationErrors;
        String errorMessage = authProvider.error ??
            "Unable to create account. Please check your information and try again.";

        // Clear previous field errors
        setState(() {
          _nameError = null;
          _emailError = null;
          _studentIdError = null;
          _passwordError = null;
          _confirmPasswordError = null;
        });

        // Process validation errors directly from the API response
        if (validationErrors != null) {
          setState(() {
            // Map server validation errors to specific form fields
            if (validationErrors.containsKey('name')) {
              _nameError = validationErrors['name'][0];
            }

            if (validationErrors.containsKey('student_id')) {
              _studentIdError = validationErrors['student_id'][0];
              // Make error message more user-friendly
              if (_studentIdError!.contains("has already been taken")) {
                _studentIdError = "This student ID is already registered";
              }
            }

            if (validationErrors.containsKey('email')) {
              _emailError = validationErrors['email'][0];
              // Make error message more user-friendly
              if (_emailError!.contains("has already been taken")) {
                _emailError = "This email is already registered";
              }
            }

            if (validationErrors.containsKey('password')) {
              _passwordError = validationErrors['password'][0];
            }

            if (validationErrors.containsKey('password_confirmation')) {
              _confirmPasswordError =
                  validationErrors['password_confirmation'][0];
            }
          });

          // Set a more user-friendly error message for the toast
          if (validationErrors.containsKey('student_id') &&
              validationErrors['student_id'][0]
                  .contains("has already been taken")) {
            errorMessage =
                "Student ID already registered. Please use a different ID.";
          } else if (validationErrors.containsKey('email') &&
              validationErrors['email'][0].contains("has already been taken")) {
            errorMessage =
                "Email already registered. Please use a different email.";
          } else {
            errorMessage = "Please check the highlighted fields for errors.";
          }
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Title
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                'Please fill in the form to sign up',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Form fields
              CustomTextField(
                controller: _nameController,
                labelText: 'Name *',
                errorText: _nameError,
              ),

              // Gender radio buttons
              _buildGenderSelection(),

              // Student ID field with sync button for email generation
              CustomTextField(
                controller: _studentIdController,
                labelText: 'Student ID *',
                hintText: 'YYYY + [1-1999] (e.g., 20011002)',
                helperText:
                    'First 4: year (1996-2025), Last 4: number between 1-1999',
                errorText: _studentIdError,
                keyboardType: TextInputType.number,
                maxLength: 8,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.sync,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Generate Email from ID',
                  onPressed: () {
                    // Check if student ID is valid before generating email
                    if (Validator.isValidStudentId(_studentIdController.text)) {
                      setState(() {
                        _emailController.text =
                            '${_studentIdController.text}@stud.fci-cu.edu.eg';
                        _emailError = null; // Clear any previous email errors
                      });
                      Fluttertoast.showToast(
                        msg: "Email generated successfully",
                        backgroundColor: Colors.green,
                      );
                    } else {
                      final errorMsg = Validator.getStudentIdValidationMessage(
                          _studentIdController.text);
                      Fluttertoast.showToast(
                        msg: errorMsg ?? "Invalid Student ID format",
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                ),
              ),

              CustomTextField(
                controller: _emailController,
                labelText: 'Email (FCI Email) *',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  // Auto-extract student ID from email
                  final studentId = Validator.extractStudentIdFromEmail(value);
                  if (studentId != null && _studentIdController.text.isEmpty) {
                    _studentIdController.text = studentId;
                  }
                },
              ),

              // Level dropdown
              _buildLevelDropdown(),

              // Password field with visibility toggle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    errorText: _passwordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                  ),
                  obscureText: !_showPassword,
                ),
              ),

              // Confirm password field with visibility toggle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    errorText: _confirmPasswordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                  ),
                  obscureText: !_showConfirmPassword,
                ),
              ),

              const SizedBox(height: 20),

              // Register button
              CustomButton(
                text: 'Sign Up',
                onPressed: _register,
                isLoading: authProvider.isLoading,
              ),

              const SizedBox(height: 20),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Level (Optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        value: _level,
        hint: const Text('Select level'),
        items: ['1', '2', '3', '4'].map((String level) {
          return DropdownMenuItem<String>(
            value: level,
            child: Text('Level $level'),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _level = value;
          });
        },
      ),
    );
  }
}
