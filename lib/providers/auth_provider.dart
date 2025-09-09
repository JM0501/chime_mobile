import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? get token => _token;

  Future<bool> login(String email, String password) async {
    final res = await ApiService.login(email, password);

    if (res.containsKey("token")) {
      _token = res["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", _token!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    final res = await ApiService.register(username, email, password);
    return res.containsKey("message");
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    notifyListeners();
  }
}
