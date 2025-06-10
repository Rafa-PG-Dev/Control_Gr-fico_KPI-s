import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_widgets.dart';
import '../widgets/animated_logo.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.loadSavedCredentials().then((_) {
        _emailController.text = authProvider.savedEmail;
        _passwordController.text = authProvider.savedPassword;
        setState(() {
          _rememberMe = authProvider.savedEmail.isNotEmpty;
        });
      });
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(email, password, rememberMe: _rememberMe);

    if (!mounted) return;
    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showMessage(error);
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Introduce tu correo para recuperar la contraseña');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.sendPasswordReset(email);
    _showMessage(error ?? 'Correo de recuperación enviado');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF263238);
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);
    final inputFieldColor = isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5);
    final buttonColor = isDark ? const Color(0xFF1A237E) : const Color(0xFF3F51B5); // Azul oscuro para el modo oscuro

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const AnimatedLoginLogo(width: 320, height: 240),
                const SizedBox(height: 50),
                buildInputField(
                  controller: _emailController,
                  textColor: textColor,
                  hintText: 'Correo',
                  fillColor: inputFieldColor,
                  labelColor: isDark ? Colors.white : Colors.black54, // Color de la etiqueta
                ),
                const SizedBox(height: 20),
                buildInputField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  togglePasswordVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  textColor: textColor,
                  hintText: 'Contraseña',
                  fillColor: inputFieldColor,
                  labelColor: isDark ? Colors.white : Colors.black54, // Color de la etiqueta
                ),
                const SizedBox(height: 20),
                buildRememberMeCheckbox(
                  value: _rememberMe,
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: buttonColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 30),
                buildLoginButton(
                  onPressed: _handleLogin,
                  buttonColor: buttonColor,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 20),
                buildForgotPasswordText(
                  onTap: _handlePasswordReset,
                  textColor: textColor,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
