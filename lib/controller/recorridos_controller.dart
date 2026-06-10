import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/recorrido_model.dart';
import 'package:flutter/material.dart';

class RecorridoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'recorridos';
  final String _vehiculosColeccion = 'vehiculos';

  // guardar un recorrido y actualizar kilometraje
  Future<void> guardarRecorrido(Recorrido recorrido) async {
    try {
      debugPrint('Guardando recorrido con id: ${recorrido.id}');
      debugPrint('Placa/VehículoId: ${recorrido.vehiculoId}');
      debugPrint('KM Inicial: ${recorrido.kmInicial}, KM Final: ${recorrido.kmFinal}');
      debugPrint('Distancia calculada: ${recorrido.distancia}');

      debugPrint('Guardando recorrido en Firestore...');
      await _firestore.collection(_coleccion).doc(recorrido.id).set(recorrido.toJson());
      debugPrint('Recorrido guardado exitosamente');

      debugPrint('Usando vehiculoId como UID del documento: ${recorrido.vehiculoId}');

      final vehiculoDocId = recorrido.vehiculoId;
      debugPrint('UID del vehículo: $vehiculoDocId');

      debugPrint('Actualizando datos del vehículo...');
      debugPrint('   - Nuevo KM: ${recorrido.kmFinal}');
      debugPrint('   - Último recorrido: ${DateTime.now().toIso8601String()}');

      await _firestore.collection(_vehiculosColeccion).doc(vehiculoDocId).update({
        'kilometrajeAcumulado': recorrido.kmFinal,
        'ultimoRecorrido': DateTime.now().toIso8601String(),
      });

      debugPrint('Vehículo actualizado correctamente');
      debugPrint('   - Nuevo KM en BD: ${recorrido.kmFinal}');
    } catch (e) {
      debugPrint('ERROR CRÍTICO al guardar recorrido: $e');
      rethrow;
    }
  }

  // actualizar recorrido
  Future<void> actualizarRecorrido(Recorrido recorrido) async {
    try {
      debugPrint('Actualizando recorrido: ${recorrido.id}');
      await _firestore.collection(_coleccion).doc(recorrido.id).update(recorrido.toJson());
      debugPrint('Recorrido actualizado');
    } catch (e) {
      debugPrint('Error al actualizar: $e');
      throw Exception('Error al actualizar recorrido: $e');
    }
  }


  Future<void> eliminarRecorrido(String recorridoId) async {
    try {
      debugPrint('Eliminando recorrido: $recorridoId');

      // obtener recorrido antes de eliminar para saber el vehiculoId
      final doc = await _firestore.collection(_coleccion).doc(recorridoId).get();
      if (!doc.exists) return;
      final vehiculoId = Recorrido.fromJson(doc.data()!).vehiculoId;

      // eliminar el recorrido
      await _firestore.collection(_coleccion).doc(recorridoId).delete();
      debugPrint('Recorrido eliminado');

      // recalcular kilometraje acumulado
      final snapshot = await _firestore
          .collection(_coleccion)
          .where('vehiculoId', isEqualTo: vehiculoId)
          .get();

      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();
      recorridos.sort((a, b) => b.fecha.compareTo(a.fecha));

      final nuevoKilometraje = recorridos.isNotEmpty ? recorridos.first.kmFinal : 0;

      // actualizar vehículo
      await _firestore.collection(_vehiculosColeccion).doc(vehiculoId).update({
        'kilometrajeAcumulado': nuevoKilometraje,
      });

      debugPrint('Vehículo actualizado con kilometraje acumulado: $nuevoKilometraje');
    } catch (e) {
      debugPrint('Error al eliminar: $e');
      throw Exception('Error al eliminar recorrido: $e');
    }
  }


  // obtener recorrido por id
  Future<Recorrido?> obtenerRecorrido(String recorridoId) async {
    try {
      debugPrint('Obteniendo recorrido: $recorridoId');
      final doc = await _firestore.collection(_coleccion).doc(recorridoId).get();

      if (doc.exists) {
        final recorrido = Recorrido.fromJson(doc.data() as Map<String, dynamic>);
        debugPrint('Recorrido encontrado');
        return recorrido;
      }
      debugPrint('Recorrido no encontrado');
      return null;
    } catch (e) {
      debugPrint('Error al obtener recorrido: $e');
      throw Exception('Error al obtener recorrido: $e');
    }
  }

  // obtener recorridos por conductor
  Stream<List<Recorrido>> obtenerRecorridosPorConductor(String conductorId) {
    debugPrint('Obteniendo recorridos del conductor: $conductorId');
    return _firestore
        .collection(_coleccion)
        .where('conductorId', isEqualTo: conductorId)
        .snapshots()
        .map((snapshot) {
      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();

      recorridos.sort((a, b) => b.fecha.compareTo(a.fecha));

      debugPrint('Recorridos obtenidos: ${recorridos.length}');
      return recorridos;
    });
  }

  // obtener recorridos por vehiculo
  Stream<List<Recorrido>> obtenerRecorridosPorVehiculo(String vehiculoId) {
    debugPrint('Obteniendo recorridos del vehículo: $vehiculoId');
    return _firestore
        .collection(_coleccion)
        .where('vehiculoId', isEqualTo: vehiculoId)
        .snapshots()
        .map((snapshot) {
      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();

      recorridos.sort((a, b) => b.fecha.compareTo(a.fecha));

      debugPrint('Recorridos para vehículo: ${recorridos.length}');
      return recorridos;
    });
  }

  // obtener total km por conductor
  Future<int> obtenerTotalKmConductor(String conductorId) async {
    try {
      debugPrint('Calculando total km para conductor: $conductorId');
      final snapshot =
      await _firestore.collection(_coleccion).where('conductorId', isEqualTo: conductorId).get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final recorrido = Recorrido.fromJson(doc.data());
        total += recorrido.distancia;
      }
      debugPrint('Total km: $total');
      return total;
    } catch (e) {
      debugPrint('Error al calcular: $e');
      throw Exception('Error al calcular total km: $e');
    }
  }

  // obtener último km final registrado
  Future<int?> obtenerUltimoKmFinal(String vehiculoId) async {
    try {
      debugPrint('Obteniendo último km para: $vehiculoId');

      final snapshot =
      await _firestore.collection(_coleccion).where('vehiculoId', isEqualTo: vehiculoId).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('Sin registros para este vehículo');
        return null;
      }

      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();

      recorridos.sort((a, b) => b.fecha.compareTo(a.fecha));

      final ultimoKm = recorridos.first.kmFinal;
      debugPrint('Último km: $ultimoKm');
      return ultimoKm;
    } catch (e) {
      debugPrint('Error: $e');
      throw Exception('Error al obtener último km: $e');
    }
  }

  // obtener estadísticas de un vehículo
  Future<Map<String, dynamic>> obtenerEstadisticasVehiculo(String vehiculoId) async {
    try {
      debugPrint('Obteniendo estadísticas para: $vehiculoId');

      final snapshot =
      await _firestore.collection(_coleccion).where('vehiculoId', isEqualTo: vehiculoId).get();

      if (snapshot.docs.isEmpty) {
        return {'totalRecorridos': 0, 'totalKm': 0, 'kmPromedio': 0};
      }

      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();

      int totalKm = 0;
      for (var recorrido in recorridos) {
        totalKm += recorrido.distancia;
      }

      final kmPromedio =
      recorridos.isNotEmpty ? (totalKm / recorridos.length).toInt() : 0;

      final stats = {
        'totalRecorridos': recorridos.length,
        'totalKm': totalKm,
        'kmPromedio': kmPromedio,
      };

      debugPrint('Estadísticas: $stats');
      return stats;
    } catch (e) {
      debugPrint('Error: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // stream de estadísticas en tiempo real
  Stream<Map<String, dynamic>> obtenerEstadisticasVehiculoStream(String vehiculoId) {
    debugPrint('Stream de estadísticas para: $vehiculoId');

    return _firestore
        .collection(_coleccion)
        .where('vehiculoId', isEqualTo: vehiculoId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {'totalRecorridos': 0, 'totalKm': 0, 'kmPromedio': 0};
      }

      final recorridos = snapshot.docs.map((doc) => Recorrido.fromJson(doc.data())).toList();

      int totalKm = 0;
      for (var recorrido in recorridos) {
        totalKm += recorrido.distancia;
      }

      final kmPromedio =
      recorridos.isNotEmpty ? (totalKm / recorridos.length).toInt() : 0;

      return {
        'totalRecorridos': recorridos.length,
        'totalKm': totalKm,
        'kmPromedio': kmPromedio,
      };
    });
  }
}
