import 'package:flutter/material.dart';

Widget buildInputField({
  required TextEditingController controller,
  bool obscureText = false,
  VoidCallback? togglePasswordVisibility,
  Color textColor = Colors.black,
  Color labelColor = Colors.black54, // Añadido el color de la etiqueta
  Color fillColor = const Color(0xFFF5F5F5),
  Color iconColor = Colors.black54,
  required String hintText,
}) {
  final isPassword = togglePasswordVisibility != null;

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: textColor,
      ),
      cursorColor: textColor.withOpacity(0.7),
      decoration: InputDecoration(
        labelText: isPassword ? 'Contraseña' : 'Correo',
        labelStyle: TextStyle(
          color: labelColor, // Usamos el color de la etiqueta aquí
          fontSize: 20,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: fillColor,
        hintText: hintText,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: togglePasswordVisibility,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

Widget buildLoginButton({
  required VoidCallback onPressed,
  Color buttonColor = const Color(0xFF1A237E),
  Color textColor = Colors.white,
}) {
  return SizedBox(
    width: 320,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: textColor),
        ),
        elevation: 5,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Iniciar Sesión'),
    ),
  );
}

Widget buildRememberMeCheckbox({
  required bool value,
  required ValueChanged<bool?> onChanged,
  Color activeColor = const Color(0xFF1A237E),
  Color checkColor = Colors.white,
  Color textColor = const Color(0xFF263238),
}) {
  return Row(
    children: [
      Checkbox(
        value: value,
        onChanged: onChanged,
        side: BorderSide(color: activeColor),
        checkColor: checkColor,
        activeColor: activeColor,
      ),
      Text(
        'Recordar inicio de sesión',
        style: TextStyle(color: textColor),
      ),
    ],
  );
}

Widget buildForgotPasswordText({
  required VoidCallback onTap,
  Color textColor = const Color(0xFF263238),
}) {
  return GestureDetector(
    onTap: onTap,
    child: Text(
      '¿Has olvidado la contraseña?',
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        decoration: TextDecoration.underline,
        decorationColor: textColor.withOpacity(0.7),
        decorationThickness: 1.2,
        height: 2.2,
      ),
    ),
  );
}
