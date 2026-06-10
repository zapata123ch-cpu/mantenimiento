import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlertasAdminController {
  final FirebaseFirestore _db;

  // Mantener localmente las notificaciones eliminadas/ocultas
  final Set<String> notificacionesEliminadas = {};

  AlertasAdminController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Streams para los badges (queries más ligeras usadas en las pestañas)
  Stream<QuerySnapshot> streamChecklistsBadge() {
    return _db.collection('checklists').where('estado', isNotEqualTo: 'apto').snapshots();
  }

  Stream<QuerySnapshot> streamFallasBadge() {
    return _db.collection('fallas').where('estado', isEqualTo: 'Reportada').snapshots();
  }

  // Streams usados para las vistas completas (con orden)
  Stream<QuerySnapshot> streamChecklistsListado() {
    return _db
        .collection('checklists')
        .where('estado', isNotEqualTo: 'apto')
        .orderBy('estado')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamFallasListado() {
    return _db
        .collection('fallas')
        .where('estado', isEqualTo: 'Reportada')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener datos combinados de vehiculo y conductor (placa + nombre)
  Future<Map<String, String>> obtenerDatos(String vehiculoId, String conductorId) async {
    try {
      final vehiculoDoc = await _db.collection('vehiculos').doc(vehiculoId).get();
      final conductorDoc = await _db.collection('usuarios').doc(conductorId).get();

      final placa = vehiculoDoc.data()?['placa'] ?? vehiculoId;
      final nombres = conductorDoc.data()?['nombres'] ?? '';
      final apellidos = conductorDoc.data()?['apellidos'] ?? '';
      final nombre = '$nombres $apellidos'.trim();

      return {'placa': placa, 'nombre': nombre};
    } catch (e) {
      // En caso de error, devolvemos los ids para evitar null
      return {'placa': vehiculoId, 'nombre': conductorId};
    }
  }

  // Ocultar (localmente) una notificación por id
  void ocultarNotificacion(String id) {
    notificacionesEliminadas.add(id);
  }

  // Comprobar si una notificación está oculta
  bool estaOculta(String id) => notificacionesEliminadas.contains(id);
}

//CONDUCTOR

class NotificacionesController {
  final FirebaseFirestore _db;

  // IDs de notificaciones ocultadas localmente
  final Set<String> notificacionesEliminadas = {};

  NotificacionesController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Streams públicos (raw) que la vista usará y filtrará según el usuario
  Stream<QuerySnapshot> streamMantenimientos() {
    return _db.collection('mantenimientos').snapshots();
  }

  Stream<QuerySnapshot> streamFallas() {
    return _db.collection('fallas').snapshots();
  }

  // Helpers para determinar si un documento corresponde al usuario y estado esperado
  bool esMantenimientoRelevante(Map<String, dynamic> data, String usuarioId) {
    final conductorId = (data['conductorId'] ?? '') as String;
    final estado = (data['estado'] ?? '') as String;
    return conductorId == usuarioId && estado == 'Aceptado' || estado == 'Urgente';
  }

  bool esFallaRelevante(Map<String, dynamic> data, String usuarioId) {
    final conductorId = (data['conductorId'] ?? '') as String;
    final estado = (data['estado'] ?? '') as String;
    return conductorId == usuarioId &&
        (estado == 'En reparación');
  }

  // Gestión de notificaciones ocultas (local)
  void ocultarNotificacion(String id) {
    notificacionesEliminadas.add(id);
  }

  bool estaOculta(String id) {
    return notificacionesEliminadas.contains(id);
  }

  // Util: formatear fechas (Timestamp o String)
  String formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';
    try {
      if (date is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(date.toDate());
      } else if (date is String) {
        return date;
      }
      return 'Fecha inválida';
    } catch (e) {
      return 'Error fecha';
    }
  }
}