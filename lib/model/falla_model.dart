import 'package:cloud_firestore/cloud_firestore.dart';

class Falla {
  String id;
  String vehiculoId;
  String conductorId;
  String tipoFalla;
  String descripcion;
  String? fotoUrl; //
  String estado;
  String? comentariosAdmin;
  dynamic createdAt; // Puede ser Timestamp o DateTime

  Falla({
    required this.id,
    required this.vehiculoId,
    required this.conductorId,
    required this.tipoFalla,
    required this.descripcion,
    this.fotoUrl,
    this.estado = 'Reportada',
    this.comentariosAdmin,
    this.createdAt,
  });

  // ✅ Getter para convertir createdAt a DateTime
  DateTime get createdAtDate {
    if (createdAt == null) {
      return DateTime.now();
    }
    if (createdAt is Timestamp) {
      return (createdAt as Timestamp).toDate();
    }
    if (createdAt is DateTime) {
      return createdAt as DateTime;
    }
    return DateTime.now();
  }

  factory Falla.fromJson(Map<String, dynamic> json) {
    return Falla(
      id: json['id'] ?? '',
      vehiculoId: json['vehiculoId'] ?? '',
      conductorId: json['conductorId'] ?? '',
      tipoFalla: json['tipoFalla'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fotoUrl: json['fotoUrl'],
      estado: json['estado'] ?? 'Reportada',
      comentariosAdmin: json['comentariosAdmin'],
      createdAt: json['createdAt'], // Firestore devuelve Timestamp
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculoId': vehiculoId,
      'conductorId': conductorId,
      'tipoFalla': tipoFalla,
      'descripcion': descripcion,
      'fotoUrl': fotoUrl,
      'estado': estado,
      'comentariosAdmin': comentariosAdmin,
      'createdAt': createdAt,
    };
  }
}