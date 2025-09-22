import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chime_mobile/screens/chat_screen.dart';
import 'package:chime_mobile/screens/login_screen.dart';
import 'package:chime_mobile/screens/register_screen.dart';
import 'package:chime_mobile/userModel.dart';
import 'package:chime_mobile/update_service.dart'; // ✅ Import your update service

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

class MyApp extends StatefulWidget {
  final UserModel? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 1)); // small delay to avoid race
    final contextMounted = mounted;
    if (contextMounted) {
      final updateAvailable = await UpdateService.checkForUpdates();
      if (updateAvailable) {
        UpdateService.promptUserToUpdate(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chime',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: widget.initialUser != null ? '/chat' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/chat': (context) {
          final args =
              widget.initialUser ??
              ModalRoute.of(context)!.settings.arguments as UserModel;
          return ChatPage(currentUserId: args.id);
        },
      },
    );
  }
}
