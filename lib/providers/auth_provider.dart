import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  String _savedEmail = '';
  String _savedPassword = '';
  String get savedEmail => _savedEmail;
  String get savedPassword => _savedPassword;

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _savedEmail = prefs.getString('email') ?? '';
    _savedPassword = prefs.getString('password') ?? '';
    notifyListeners();
  }

  Future<String?> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = result.user!.uid;

      final user = await _userService.getUserByUid(uid);
      if (user != null) {
        _currentUser = user;
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('password', password);
        } else {
          await clearSavedCredentials();
        }
        notifyListeners();
        return null;
      } else {
        return 'No se pudo obtener la información del usuario.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error desconocido al iniciar sesión.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al enviar correo de recuperación';
    }
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
