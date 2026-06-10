// lib/models/user_model.dart

class UserModel {
  final String? id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String fechaNacimiento;
  final String email;
  final String telefono;
  String? rol; // <-- aquí lo haces opcional
  final String estado;
  final DateTime fechaRegistro;
  final String? idVehiculo;

  UserModel({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.fechaNacimiento,
    required this.email,
    required this.telefono,
    this.rol,
    this.estado = 'Pendiente',
    required this.fechaRegistro,
    this.idVehiculo,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'dni': dni,
      'fechaNacimiento': fechaNacimiento,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'estado': estado,
      'fechaRegistro': fechaRegistro,
      'idVehiculo': idVehiculo,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      dni: map['dni'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      rol: map['rol'] ?? 'Conductor',
      estado: map['estado'] ?? 'Pendiente',
      fechaRegistro: (map['fechaRegistro'] as dynamic)?.toDate() ?? DateTime.now(),
      idVehiculo: map['idVehiculo'],
    );
  }
}