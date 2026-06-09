import 'package:driving_quiz_app/views/CategoriesScreen.dart';
import 'package:driving_quiz_app/views/LoginScreen.dart';
import 'package:driving_quiz_app/views/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const DrivingQuizApp());
}

class DrivingQuizApp extends StatelessWidget {
  const DrivingQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منصة تعليم السياقة',
      initialRoute: '/',
      routes: {
        '/': (context) => const CategoriesScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
      },
      locale: const Locale('ar', ''),
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: const CategoriesScreen(),
    );
  }
}

class MainCategoryScreen extends StatefulWidget {
  const MainCategoryScreen({super.key});

  @override
  State<MainCategoryScreen> createState() => _MainCategoryScreenState();
}

class _MainCategoryScreenState extends State<MainCategoryScreen> {
  // This controller helps us get the text from the input box
  final TextEditingController _controller = TextEditingController();
  String _userName = ""; // This variable stores the "result"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driving Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // This centers everything vertically
          children: [
            const Icon(Icons.directions_car, size: 80, color: Colors.blue),
            const SizedBox(height: 10),

            const Text(
              'Welcome to the Quiz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // 2. THE INPUT FIELD
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your name to start',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 20),

            // 3. THE BUTTON (Triggers the code result)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // This updates the UI with the text from the input
                  _userName = _controller.text;
                });
              },
              child: const Text("Confirm Name"),
            ),

            const SizedBox(height: 30),

            // 4. THE RESULT (Displays the code output)
            if (_userName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.blue.withOpacity(0.1),
                child: Text(
                  'Result: Hello $_userName, you are ready to drive!',
                  style: const TextStyle(fontSize: 18, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
