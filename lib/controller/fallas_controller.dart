import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/falla_model.dart';
import 'package:flutter/material.dart';

class FallasController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'fallas';
  final String _coleccionConductores = 'conductores';
  final String _coleccionVehiculos = 'vehiculos';

  // guardar una falla
  Future<void> guardarFalla(Falla falla) async {
    try {
      final fallaData = falla.toJson();
      fallaData['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_coleccion).doc(falla.id).set(fallaData);
      debugPrint('Falla guardada correctamente');
    } catch (e) {
      debugPrint('Error al guardar falla: $e');
      throw Exception('Error al guardar falla: $e');
    }
  }

  // actualizar el estado de una falla
  Future<void> actualizarEstado(String fallaId, String nuevoEstado,
      {String? comentarios}) async {
    final Map<String, dynamic> data = {'estado': nuevoEstado};
    if (comentarios != null) {
      data['comentariosAdmin'] = comentarios;
    }
    await _firestore.collection(_coleccion).doc(fallaId).update(data);
    debugPrint('Estado actualizado a $nuevoEstado');
  }

  // eliminar una falla
  Future<void> eliminarFalla(String fallaId) async {
    await _firestore.collection(_coleccion).doc(fallaId).delete();
    debugPrint('Falla eliminada');
  }

  // obtener falla por id
  Future<Falla?> obtenerFalla(String fallaId) async {
    final doc = await _firestore.collection(_coleccion).doc(fallaId).get();
    if (doc.exists) {
      return Falla.fromJson(doc.data()!);
    }
    return null;
  }

  // obtener todas las fallas con detalles
  Stream<List<Map<String, dynamic>>> obtenerTodasLasFallasConDetalles() {
    return _firestore
        .collection(_coleccion)
        .snapshots()
        .asyncMap((snapshot) async {
      final fallasList = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final fallaData = doc.data();
        final falla = Falla.fromJson(fallaData);

        // obtener nombre del conductor
        String nombreConductor = falla.conductorId;
        try {
          final conductorDoc = await _firestore
              .collection(_coleccionConductores)
              .doc(falla.conductorId)
              .get();
          if (conductorDoc.exists) {
            nombreConductor =
                conductorDoc.data()?['nombre'] ?? falla.conductorId;
          }
        } catch (e) {
          debugPrint('Error obteniendo conductor: $e');
        }

        // obtener placa del vehículo
        String placaVehiculo = falla.vehiculoId;
        try {
          final vehiculoDoc = await _firestore
              .collection(_coleccionVehiculos)
              .doc(falla.vehiculoId)
              .get();
          if (vehiculoDoc.exists) {
            placaVehiculo = vehiculoDoc.data()?['placa'] ?? falla.vehiculoId;
          }
        } catch (e) {
          debugPrint('Error obteniendo vehículo: $e');
        }

        fallasList.add({
          'falla': falla,
          'nombreConductor': nombreConductor,
          'placaVehiculo': placaVehiculo,
        });
      }

      // ordenar por fecha reciente
      fallasList.sort((a, b) =>
          (b['falla'] as Falla).createdAtDate.compareTo(
              (a['falla'] as Falla).createdAtDate));

      return fallasList;
    }).handleError((error) {
      debugPrint('Error obteniendo fallas: $error');
      return <Map<String, dynamic>>[];
    });
  }

  // obtener todas las fallas sin detalles
  Stream<List<Falla>> obtenerTodasLasFallas() {
    return _firestore.collection(_coleccion).snapshots().map((snapshot) {
      final fallas = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Documento falla: ${doc.id}');
        debugPrint('Estado guardado: ${data['estado']}');
        debugPrint('Vehículo ID: ${data['vehiculoId']}');
        debugPrint('Conductor ID: ${data['conductorId']}');

        return Falla.fromJson(data);
      }).toList();

      fallas.sort((a, b) => b.createdAtDate.compareTo(a.createdAtDate));

      return fallas;
    }).handleError((error) {
      debugPrint('Error obteniendo fallas: $error');
      return <Falla>[];
    });
  }

  // obtener fallas por conductor
  Stream<List<Falla>> obtenerFallasPorConductor(String conductorId) {
    return _firestore
        .collection(_coleccion)
        .where('conductorId', isEqualTo: conductorId)
        .snapshots()
        .map((snapshot) {
      debugPrint('Snapshot recibido: ${snapshot.docs.length} documentos');

      final fallas = snapshot.docs.map((doc) {
        debugPrint('Documento: ${doc.id}');
        return Falla.fromJson(doc.data());
      }).toList();

      fallas.sort((a, b) {
        final dateA = a.createdAtDate;
        final dateB = b.createdAtDate;
        return dateB.compareTo(dateA);
      });

      return fallas;
    }).handleError((error) {
      debugPrint('Error en stream: $error');
      return <Falla>[];
    });
  }

  // obtener nombre del conductor
  Future<String> obtenerNombreConductor(String conductorId) async {
    try {
      debugPrint('Buscando conductor en firebase...');
      debugPrint('conductorId: $conductorId');

      final doc =
      await _firestore.collection('usuarios').doc(conductorId).get();

      debugPrint('¿Existe en usuarios? ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        debugPrint('Datos encontrados: $data');

        final nombres = data?['nombres'] ?? '';
        final apellidos = data?['apellidos'] ?? '';

        debugPrint('nombres: "$nombres"');
        debugPrint('apellidos: "$apellidos"');

        if (nombres.isNotEmpty && apellidos.isNotEmpty) {
          final nombreCompleto = '$nombres $apellidos';
          debugPrint('Retornando nombre completo: "$nombreCompleto"');
          return nombreCompleto;
        } else if (nombres.isNotEmpty) {
          debugPrint('Retornando solo nombres: "$nombres"');
          return nombres;
        } else if (apellidos.isNotEmpty) {
          debugPrint('Retornando solo apellidos: "$apellidos"');
          return apellidos;
        }
      } else {
        debugPrint('Documento no encontrado en usuarios');
      }
    } catch (e) {
      debugPrint('Error obteniendo nombre del conductor: $e');
    }

    debugPrint('Retornando conductorId por defecto: $conductorId');
    return conductorId;
  }

  // obtener placa del vehículo
  Future<String> obtenerPlacaVehiculo(String vehiculoId) async {
    try {
      debugPrint('Buscando vehículo en firebase...');
      debugPrint('Colección: $_coleccionVehiculos');
      debugPrint('vehiculoId: $vehiculoId');

      final doc = await _firestore
          .collection(_coleccionVehiculos)
          .doc(vehiculoId)
          .get();

      debugPrint('¿Existe el documento? ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        debugPrint('Datos del documento: $data');

        final placa = data?['placa'] ?? vehiculoId;
        debugPrint('Retornando placa: "$placa"');
        return placa;
      } else {
        debugPrint('Documento no encontrado');
      }
    } catch (e) {
      debugPrint('Error obteniendo placa del vehículo: $e');
    }

    debugPrint('Retornando vehiculoId por defecto: $vehiculoId');
    return vehiculoId;
  }
}
