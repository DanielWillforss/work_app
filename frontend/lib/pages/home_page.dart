import 'package:flutter/material.dart';

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
              width: 200, // optional: adjust size
              height: 200,
            ),
            const SizedBox(height: 16), // spacing between image and text
            // Display version text
            const Text('Version 0.1.0', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
