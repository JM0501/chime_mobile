import 'package:chime_mobile/config.dart';
import 'package:chime_mobile/userModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? error;
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          // Backend accepts username OR email here
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && data["token"] != null) {
        final user = UserModel.fromJson(data["user"]);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('token', data["token"]);

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          "/chat",
          arguments: user,
        );
      } else {
        setState(() {
          error = data["message"] ?? "Invalid credentials";
        });
      }
    } catch (e) {
      setState(() {
        error = "Unable to connect to server.";
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/images/chime_logo.png", height: 120),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome Back 👋",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email or Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, "/register"),
                      child: const Text("Don’t have an account? Register"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}