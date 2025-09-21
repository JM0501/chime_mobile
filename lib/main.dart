import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chime_mobile/screens/chat_screen.dart';
import 'package:chime_mobile/screens/login_screen.dart';
import 'package:chime_mobile/screens/register_screen.dart';
import 'package:chime_mobile/userModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storedUserId = prefs.getString('userId');
  final storedUsername = prefs.getString('username');

  UserModel? user;
  if (storedUserId != null && storedUsername != null) {
    user = UserModel(id: storedUserId, username: storedUsername, email: '');
    // Email optional here
  }

  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final UserModel? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chime',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialUser != null ? '/chat' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/chat': (context) {
          final args =
              initialUser ??
              ModalRoute.of(context)!.settings.arguments as UserModel;
          return ChatPage(currentUserId: args.id);
        },
      },
    );
  }
}
