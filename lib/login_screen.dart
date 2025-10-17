import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rate_my_bowl/custom_widgets/account_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
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
                    "rate my "
                  ),
                  SvgPicture.asset(
                    width: 16.0,
                    height: 32.0,
                    "assets/toilet.svg"
                  ),
                  Text(
                    style: GoogleFonts.quicksand(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    "owl"
                  ),
                ],
              ),
              AccountInputField(hintText: "username"),
              AccountInputField(hintText: "password", obscureText: true,),
              ElevatedButton(
                onPressed: () {},
                child: const Text("log in"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "create an account",
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "forgot my password",
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}
