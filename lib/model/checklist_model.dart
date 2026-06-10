import 'package:cloud_firestore/cloud_firestore.dart';

class Checklist {
  final String id;
  final String conductorId;
  final String vehiculoId;
  final DateTime fecha;
  final Map<String, bool> items;
  final String estado; // apto, no_apto
  final String? observaciones;
  final DateTime createdAt;

  Checklist({
    required this.id,
    required this.conductorId,
    required this.vehiculoId,
    required this.fecha,
    required this.items,
    required this.estado,
    this.observaciones,
    required this.createdAt,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conductorId': conductorId,
      'vehiculoId': vehiculoId,
      'fecha': fecha,
      'items': items,
      'estado': estado,
      'observaciones': observaciones,
      'createdAt': createdAt,
    };
  }

  // Convertir desde JSON de Firestore
  factory Checklist.fromJson(Map<String, dynamic> json) {
    print('[ChecklistModel] 🔄 Convirtiendo checklist desde JSON');

    try {
      // 🔥 FIX: Manejar Timestamp correctamente
      DateTime _convertirFecha(dynamic valor) {
        print('[ChecklistModel] 🔍 Convertiendo fecha: ${valor.runtimeType} = $valor');

        if (valor is Timestamp) {
          print('[ChecklistModel] ✅ Es Timestamp, convirtiendo...');
          return valor.toDate();
        } else if (valor is DateTime) {
          print('[ChecklistModel] ✅ Es DateTime');
          return valor;
        } else if (valor is String) {
          print('[ChecklistModel] ✅ Es String, parseando...');
          return DateTime.parse(valor);
        } else {
          throw Exception(
              'Tipo de fecha no soportado: ${valor.runtimeType}');
        }
      }

      final fecha = _convertirFecha(json['fecha']);
      final createdAt = _convertirFecha(json['createdAt']);

      // Convertir items correctamente
      final Map<String, bool> items = {};
      if (json['items'] is Map) {
        (json['items'] as Map).forEach((key, value) {
          items[key.toString()] = value == true;
        });
        print('[ChecklistModel] ✅ Items convertidos: ${items.length}');
      }

      final checklist = Checklist(
        id: json['id'] ?? '',
        conductorId: json['conductorId'] ?? '',
        vehiculoId: json['vehiculoId'] ?? '',
        fecha: fecha,
        items: items,
        estado: json['estado'] ?? 'pendiente',
        observaciones: json['observaciones'],
        createdAt: createdAt,
      );

      print('[ChecklistModel] ✅ Checklist creado exitosamente: ${checklist.id}');
      return checklist;
    } catch (e) {
      print('[ChecklistModel] ❌ Error en fromJson: $e');
      print('[ChecklistModel] 📝 JSON recibido: $json');
      rethrow;
    }
  }

  // Copiar con cambios
  Checklist copyWith({
    String? id,
    String? conductorId,
    String? vehiculoId,
    DateTime? fecha,
    Map<String, bool>? items,
    String? estado,
    String? observaciones,
    DateTime? createdAt,
  }) {
    return Checklist(
      id: id ?? this.id,
      conductorId: conductorId ?? this.conductorId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fecha: fecha ?? this.fecha,
      items: items ?? this.items,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Checklist(id: $id, vehiculo: $vehiculoId, estado: $estado, fecha: $fecha)';
  }
}