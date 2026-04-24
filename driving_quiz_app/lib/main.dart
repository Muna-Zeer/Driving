import 'package:flutter/material.dart';

void main() {
  runApp(const DrivingQuizApp());
}

class DrivingQuizApp extends StatelessWidget {
  const DrivingQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainCategoryScreen(),
    );
  }
}

class MainCategoryScreen extends StatelessWidget {
  const MainCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // The body starts here
      body: Center(
        child: Text(
          'Driving Quiz App',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}