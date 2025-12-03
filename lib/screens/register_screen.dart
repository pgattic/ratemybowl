import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/widgets/custom_input_field.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:rate_my_bowl/widgets/bowl_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isUsernameValid = false;

  final RegExp _emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");

  void _updatePasswordValidity() {
    setState(() {
      final pw = _passwordController.text.trim();
      final hasUpper = pw.contains(RegExp(r'[A-Z]'));
      final hasLower = pw.contains(RegExp(r'[a-z]'));
      _isPasswordValid = pw.length >= 8 && hasUpper && hasLower;
    });
  }

  void _updateEmailValidity() {
    setState(() {
      final email = _emailController.text.trim();
      _isEmailValid = _emailRegex.hasMatch(email);
    });
  }

  void _updateUsernameValidity() {
    setState(() {
      _isUsernameValid = _usernameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email, username, and password"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.register(
        _emailController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid email, username, or password"),
            backgroundColor: Colors.red,
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Register failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateEmailValidity);
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.removeListener(_updatePasswordValidity);
    _passwordController.dispose();
    _usernameController.removeListener(_updateUsernameValidity);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateEmailValidity);
    _passwordController.addListener(_updatePasswordValidity);
    _usernameController.addListener(_updateUsernameValidity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 16.0,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RateMyBowlLogo(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(style: TextStyle(fontSize: 24.0), "create an account"),
                ],
              ),
              CustomInputField(hintText: "email", controller: _emailController),
              if (!_isEmailValid && _emailController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    'Please enter a valid email address!',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 235, 4, 4),
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              CustomInputField(
                hintText: "username",
                controller: _usernameController,
              ),
              CustomInputField(
                hintText: "password",
                obscureText: true,
                controller: _passwordController,
              ),
              // inline rule hint
              if (!_isPasswordValid && _passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    'Password must be at least 8 characters and include both upper and lower case letters.',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 235, 4, 4),
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed:
                    (_isLoading ||
                        !_isPasswordValid ||
                        !_isEmailValid ||
                        !_isUsernameValid)
                    ? null
                    : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text("register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
