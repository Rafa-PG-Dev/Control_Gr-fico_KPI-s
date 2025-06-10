import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        await clearSavedCredentials();
      }

      return null; 
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error desconocido';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al enviar correo de recuperación';
    }
  }

  Future<Map<String, String>> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email') ?? '',
      'password': prefs.getString('password') ?? '',
    };
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
