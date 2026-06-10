import 'package:cloud_firestore/cloud_firestore.dart';

class Mantenimiento {
  final String id;
  final String vehiculoId;
  final String conductorId;
  final String tipoServicio;
  final String tipoMantenimiento; // Preventivo o Correctivo
  final DateTime fechaProgramada; // fecha SIN hora (normalizada a 00:00 local)
  double precio;
  final String? observaciones;
  String estado; // Pendiente, Aceptado, Urgente, Completado
  dynamic createdAt;

  // CAMPOS DE EJECUCIÓN
  DateTime? fechaEjecucion;
  int? kilometrajeEjecutado;
  String? serviciosRealizados;
  String? piezasCambiadas;
  String? comentarios;

  Mantenimiento({
    required this.id,
    required this.vehiculoId,
    required this.conductorId,
    required this.tipoServicio,
    required this.tipoMantenimiento,
    required this.fechaProgramada,
    required this.precio,
    this.observaciones,
    this.estado = 'Pendiente',
    this.fechaEjecucion,
    this.kilometrajeEjecutado,
    this.serviciosRealizados,
    this.piezasCambiadas,
    this.comentarios,
    this.createdAt,
  });

  // Normaliza a fecha sin hora (00:00) EN HORA LOCAL.
  // Si prefieres UTC, cambia DateTime(...) por DateTime.utc(...)
  static DateTime _onlyDateLocal(DateTime dt) => DateTime(dt.year, dt.month, dt.day, 0, 0, 0);

  DateTime get createdAtDate {
    if (createdAt == null) return DateTime.now();
    if (createdAt is Timestamp) return (createdAt as Timestamp).toDate();
    if (createdAt is DateTime) return createdAt as DateTime;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculoId': vehiculoId,
      'conductorId': conductorId,
      'tipoServicio': tipoServicio,
      'tipoMantenimiento': tipoMantenimiento,
      // Guardamos fechaProgramada como Timestamp con hora 00:00 local
      'fechaProgramada': Timestamp.fromDate(_onlyDateLocal(fechaProgramada)),
      'precio': precio,
      'observaciones': observaciones,
      'estado': estado,
      'createdAt': createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt,
      'fechaEjecucion': fechaEjecucion != null ? Timestamp.fromDate(fechaEjecucion!) : null,
      'kilometrajeEjecutado': kilometrajeEjecutado,
      'serviciosRealizados': serviciosRealizados,
      'piezasCambiadas': piezasCambiadas,
      'comentarios': comentarios,
    };
  }

  factory Mantenimiento.fromJson(Map<String, dynamic> json) {
    DateTime parseFechaProgramada(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is Timestamp) return _onlyDateLocal(raw.toDate());
      if (raw is DateTime) return _onlyDateLocal(raw);
      if (raw is String) {
        try {
          return _onlyDateLocal(DateTime.parse(raw));
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    DateTime? parseFechaEjecucion(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) {
        try {
          return DateTime.parse(raw);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Mantenimiento(
      id: json['id']?.toString() ?? '',
      vehiculoId: json['vehiculoId']?.toString() ?? '',
      conductorId: json['conductorId']?.toString() ?? '',
      tipoServicio: json['tipoServicio']?.toString() ?? '',
      tipoMantenimiento: json['tipoMantenimiento']?.toString() ?? 'Preventivo',
      fechaProgramada: parseFechaProgramada(json['fechaProgramada']),
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      observaciones: json['observaciones']?.toString(),
      estado: json['estado']?.toString() ?? 'Pendiente',
      createdAt: json['createdAt'],
      fechaEjecucion: parseFechaEjecucion(json['fechaEjecucion']),
      kilometrajeEjecutado: json['kilometrajeEjecutado'] as int?,
      serviciosRealizados: json['serviciosRealizados']?.toString(),
      piezasCambiadas: json['piezasCambiadas']?.toString(),
      comentarios: json['comentarios']?.toString(),
    );
  }
}