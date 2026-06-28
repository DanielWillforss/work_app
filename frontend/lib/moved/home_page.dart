import 'package:flutter/material.dart';
import 'package:work_app/main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display the image
            Image.asset(
              'assets/images/lundsljud.jpeg',
              width: 300, // optional: adjust size
              height: 300,
            ),
            const SizedBox(height: 16), // spacing between image and text
            // Display version text
            const Text(
              'Version ${GlobalConstants.version}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
