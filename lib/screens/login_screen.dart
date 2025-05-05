import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/providers/auth_provider.dart';
import 'package:shopspot/widgets/custom_button.dart';
import 'package:shopspot/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;

      // Validate email
      if (_emailController.text.isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(_emailController.text)) {
        _emailError = 'Invalid email format';
        isValid = false;
      }

      // Validate password
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _login() async {
    if (!_validateInputs()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      context,
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: "Login successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.restaurants,
        );
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: authProvider.error ??
              "Unable to sign in. Please check your credentials and try again.",
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
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Form fields
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
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

              const SizedBox(height: 20),

              // Login button
              CustomButton(
                text: 'Login',
                onPressed: _login,
                isLoading: authProvider.isLoading,
              ),

              const SizedBox(height: 20),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _emailController.clear();
                        _passwordController.clear();
                        _emailError = null;
                        _passwordError = null;
                        _showPassword = false;
                      });
                      Navigator.pushNamed(
                        context,
                        AppRoutes.register,
                      );
                    },
                    child: const Text('Sign Up'),
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
}
