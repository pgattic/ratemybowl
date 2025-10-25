import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/custom_widgets/account_input_field.dart';
import 'package:rate_my_bowl/services/auth_service.dart';

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
        _emailController.text,
        _usernameController.text,
        _passwordController.text,
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
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    style: GoogleFonts.quicksand(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    "rate my ",
                  ),
                  SvgPicture.asset(
                    width: 16.0,
                    height: 32.0,
                    "assets/toilet.svg",
                  ),
                  Text(
                    style: GoogleFonts.quicksand(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    "owl",
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    style: GoogleFonts.quicksand(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    "create an account",
                  ),
                ],
              ),
              AccountInputField(
                hintText: "email",
                controller: _emailController,
              ),
              AccountInputField(
                hintText: "username",
                controller: _usernameController,
              ),
              AccountInputField(
                hintText: "password",
                obscureText: true,
                controller: _passwordController,
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
