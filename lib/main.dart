import 'package:chime_mobile/userModel.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Chime",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      // Use onGenerateRoute for passing arguments between pages
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case '/chat':
            // Expecting UserModel as argument
            final user = settings.arguments as UserModel?;
            if (user != null) {
              return MaterialPageRoute(
                  builder: (_) => ChatPage(currentUserId: user.id));
            } else {
              return MaterialPageRoute(
                  builder: (_) => const LoginPage()); // fallback
            }
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
      initialRoute: "/login",
    );
  }
}
