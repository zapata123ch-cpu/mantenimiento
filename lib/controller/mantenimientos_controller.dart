import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/mantenimiento_model.dart';
import 'package:flutter/material.dart';

class MantenimientosController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'mantenimientos';

  // obtener todos los mantenimientos
  Stream<List<Mantenimiento>> obtenerTodosMantenimientos() {
    return _firestore.collection(_coleccion).snapshots().map((snapshot) {
      final mantenimientos =
      snapshot.docs.map((doc) => Mantenimiento.fromJson(doc.data())).toList();

      // Ordeno por fechaProgramada (ya normalizada a 00:00)
      mantenimientos.sort((a, b) => b.fechaProgramada.compareTo(a.fechaProgramada));

      return mantenimientos;
    });
  }

  // obtener mantenimientos por vehiculo
  Stream<List<Mantenimiento>> obtenerMantenimientosPorVehiculo(String vehiculoId) {
    debugPrint('Obteniendo mantenimientos del vehículo: $vehiculoId');
    return _firestore
        .collection(_coleccion)
        .where('vehiculoId', isEqualTo: vehiculoId)
        .snapshots()
        .map((snapshot) {
      final mantenimientos =
      snapshot.docs.map((doc) => Mantenimiento.fromJson(doc.data())).toList();

      // Orden ascendente por fechaProgramada (fecha sin hora)
      mantenimientos.sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));

      debugPrint('Mantenimientos encontrados: ${mantenimientos.length}');
      return mantenimientos;
    });
  }

  // obtener un mantenimiento por id
  Future<Mantenimiento?> obtenerMantenimiento(String mantenimientoId) async {
    try {
      final doc = await _firestore.collection(_coleccion).doc(mantenimientoId).get();
      if (doc.exists) {
        return Mantenimiento.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener mantenimiento: $e');
      return null;
    }
  }

  // guardar un mantenimiento
  Future<void> guardarMantenimiento(Mantenimiento mantenimiento) async {
    try {
      debugPrint('Guardando mantenimiento con id: ${mantenimiento.id}');

      // Asignamos createdAt si es null (createdAt se guardará como Timestamp por el toJson)
      mantenimiento.createdAt ??= DateTime.now();

      // Nota: fechaProgramada se normaliza en Mantenimiento.toJson() a fecha sin hora.
      await _firestore.collection(_coleccion).doc(mantenimiento.id).set(mantenimiento.toJson());

      debugPrint('Mantenimiento guardado exitosamente');
    } catch (e) {
      debugPrint('Error al guardar mantenimiento: $e');
      throw Exception('Error al guardar mantenimiento: $e');
    }
  }

  // eliminar mantenimiento por id
  Future<void> eliminarMantenimientoPorId(String mantenimientoId) async {
    try {
      debugPrint('Eliminando mantenimiento con id: $mantenimientoId');
      await _firestore.collection(_coleccion).doc(mantenimientoId).delete();
      debugPrint('Mantenimiento eliminado exitosamente');
    } catch (e) {
      debugPrint('Error al eliminar mantenimiento: $e');
      throw Exception('Error al eliminar mantenimiento: $e');
    }
  }

  // actualizar estado de mantenimiento
  Future<void> actualizarEstado(String mantenimientoId, String nuevoEstado) async {
    try {
      debugPrint('Actualizando estado de mantenimiento $mantenimientoId a $nuevoEstado');
      await _firestore.collection(_coleccion).doc(mantenimientoId).update({'estado': nuevoEstado});
      debugPrint('Estado actualizado');
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // ejecutar mantenimiento
  Future<void> ejecutarMantenimiento(Mantenimiento mantenimiento) async {
    mantenimiento.estado = 'Completado';
    // fechaEjecucion mantiene hora (DateTime.now())
    mantenimiento.fechaEjecucion = DateTime.now();

    // Asignamos createdAt si es null
    mantenimiento.createdAt ??= DateTime.now();

    // Actualizamos todo el documento con el mapa (fechaProgramada seguirá guardada SIN hora por toJson)
    await _firestore.collection(_coleccion).doc(mantenimiento.id).update(mantenimiento.toJson());
  }

  // obtener placa de vehiculo
  Future<String?> obtenerPlacaVehiculo(String vehiculoId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vehiculos').doc(vehiculoId).get();

      if (doc.exists) {
        final data = doc.data();
        final placa = data?['placa'] ?? '';
        return placa.isNotEmpty ? placa : 'Sin placa';
      }
      return 'Vehículo no encontrado';
    } catch (e) {
      debugPrint('Error obteniendo placa del vehículo: $e');
      return 'Error al cargar';
    }
  }

  // obtener nombre del conductor
  Future<String?> obtenerNombreConductor(String conductorId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(conductorId).get();

      if (doc.exists) {
        final data = doc.data();
        final nombres = data?['nombres'] ?? '';
        final apellidos = data?['apellidos'] ?? '';

        if (nombres.isNotEmpty || apellidos.isNotEmpty) {
          return '$nombres $apellidos'.trim();
        }
        return 'Sin nombre';
      }
      return 'Conductor no encontrado';
    } catch (e) {
      debugPrint('Error obteniendo conductor: $e');
      return 'Error al cargar';
    }
  }
}