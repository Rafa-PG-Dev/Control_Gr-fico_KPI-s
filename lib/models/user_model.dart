class AppUser {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;

  AppUser({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      nombre: map['nombre'] ?? '',
      correo: map['email'] ?? '',
      rol: map['rol'] ?? '',
    );
  }
}
