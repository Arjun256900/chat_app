import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text('Just a sec...'),
            const SizedBox(
              height: 15,
            ),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.background,
            ),
          ],
        ),
      ),
    );
  }
}
