import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/checklist_model.dart';
import 'package:flutter/material.dart';

class ChecklistController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'checklists';

  // guardar checklist
  Future<void> guardarChecklist(Checklist checklist) async {
    try {
      debugPrint('[ChecklistController] Guardando checklist con id: ${checklist.id}');
      debugPrint('[ChecklistController] Datos: ${checklist.toJson()}');

      await _firestore
          .collection(_coleccion)
          .doc(checklist.id)
          .set(checklist.toJson());

      debugPrint('[ChecklistController] Checklist guardado exitosamente');

      final algunNoApto = checklist.items.values.any((valor) => valor == false);

      debugPrint('[ChecklistController] Estado del checklist:');
      debugPrint('[ChecklistController] Estado guardado: ${checklist.estado}');
      debugPrint('[ChecklistController] Algún No Apto: $algunNoApto');
      debugPrint('[ChecklistController] Items: ${checklist.items}');

      if (algunNoApto) {
        debugPrint('[ChecklistController] Hay al menos un item No Apto');
        debugPrint('[ChecklistController] Actualizando vehículo a Fuera de servicio');

        await _firestore
            .collection('vehiculos')
            .doc(checklist.vehiculoId)
            .update({
          'estado': 'Fuera de servicio',
          'fechaActualizacion': FieldValue.serverTimestamp(),
          'razonFueraServicio': 'Checklist con al menos un item No Apto',
        });

        debugPrint('[ChecklistController] Vehículo actualizado a Fuera de servicio');
      } else {
        debugPrint('[ChecklistController] Todos los items están Apto');
        debugPrint('[ChecklistController] El vehículo mantiene su estado actual');
      }
    } catch (e) {
      debugPrint('[ChecklistController] Error al guardar checklist: $e');
      debugPrint('[ChecklistController] StackTrace: $e');
      throw Exception('Error al guardar checklist: $e');
    }
  }

  // actualizar checklist
  Future<void> actualizarChecklist(Checklist checklist) async {
    try {
      debugPrint('[ChecklistController] Actualizando checklist con id: ${checklist.id}');
      debugPrint('[ChecklistController] Nuevos datos: ${checklist.toJson()}');

      await _firestore
          .collection(_coleccion)
          .doc(checklist.id)
          .update(checklist.toJson());

      debugPrint('[ChecklistController] Checklist actualizado');

      final algunNoApto = checklist.items.values.any((valor) => valor == false);

      debugPrint('[ChecklistController] Verificando estado del vehículo:');
      debugPrint('[ChecklistController] Algún No Apto: $algunNoApto');

      if (algunNoApto) {
        debugPrint('[ChecklistController] Hay al menos un item No Apto');

        await _firestore
            .collection('vehiculos')
            .doc(checklist.vehiculoId)
            .update({
          'estado': 'Fuera de servicio',
          'fechaActualizacion': FieldValue.serverTimestamp(),
          'razonFueraServicio': 'Checklist con al menos un item No Apto',
        });

        debugPrint('[ChecklistController] Vehículo actualizado a Fuera de servicio');
      } else {
        debugPrint('[ChecklistController] Todos los items están Aptos. Volviendo a Activo');

        await _firestore
            .collection('vehiculos')
            .doc(checklist.vehiculoId)
            .update({
          'estado': 'Activo',
          'fechaActualizacion': FieldValue.serverTimestamp(),
          'razonFueraServicio': null,
        });
      }
    } catch (e) {
      debugPrint('[ChecklistController] Error al actualizar checklist: $e');
      throw Exception('Error al actualizar checklist: $e');
    }
  }

  // eliminar checklist
  Future<void> eliminarChecklist(String checklistId) async {
    try {
      debugPrint('[ChecklistController] Eliminando checklist con id: $checklistId');

      await _firestore.collection(_coleccion).doc(checklistId).delete();

      debugPrint('[ChecklistController] Checklist eliminado');
    } catch (e) {
      debugPrint('[ChecklistController] Error al eliminar checklist: $e');
      throw Exception('Error al eliminar checklist: $e');
    }
  }


  // obtener un checklist específico
  Future<Checklist?> obtenerChecklist(String checklistId) async {
    try {
      debugPrint('[ChecklistController] Obteniendo checklist con id: $checklistId');

      final doc = await _firestore.collection(_coleccion).doc(checklistId).get();

      debugPrint('[ChecklistController] Doc existe: ${doc.exists}');

      if (doc.exists) {
        try {
          final checklist = Checklist.fromJson(doc.data() as Map<String, dynamic>);
          debugPrint('[ChecklistController] Checklist encontrado y convertido');
          return checklist;
        } catch (e) {
          debugPrint('[ChecklistController] Error al convertir checklist: $e');
          debugPrint('[ChecklistController] Datos: ${doc.data()}');
          rethrow;
        }
      }

      debugPrint('[ChecklistController] Checklist no encontrado');
      return null;
    } catch (e) {
      debugPrint('[ChecklistController] Error al obtener checklist: $e');
      throw Exception('Error al obtener checklist: $e');
    }
  }

  // obtener checklists por conductor
  Stream<List<Checklist>> obtenerChecklistsPorConductor(String conductorId) {
    debugPrint('[ChecklistController] Obteniendo checklists del conductor: $conductorId');

    try {
      return _firestore
          .collection(_coleccion)
          .where('conductorId', isEqualTo: conductorId)
          .snapshots()
          .map((snapshot) {
        try {
          debugPrint('[ChecklistController] Snapshot recibido con ${snapshot.docs.length} documentos');

          final checklists = <Checklist>[];

          for (var i = 0; i < snapshot.docs.length; i++) {
            try {
              final doc = snapshot.docs[i];
              debugPrint('[ChecklistController] Procesando doc [$i]: ${doc.id}');
              debugPrint('[ChecklistController] Datos: ${doc.data()}');

              final checklist = Checklist.fromJson(doc.data());
              checklists.add(checklist);
              debugPrint('[ChecklistController] Checklist [$i] convertido exitosamente');
            } catch (e) {
              debugPrint('[ChecklistController] Error procesando doc [$i]: $e');
              debugPrint('[ChecklistController] Datos del doc: ${snapshot.docs[i].data()}');
              rethrow;
            }
          }

          checklists.sort((a, b) => b.fecha.compareTo(a.fecha));

          debugPrint('[ChecklistController] Checklists obtenidos: ${checklists.length}');
          return checklists;
        } catch (e) {
          debugPrint('[ChecklistController] Error en map: $e');
          debugPrint('[ChecklistController] StackTrace: $e');
          rethrow;
        }
      });
    } catch (e) {
      debugPrint('[ChecklistController] Error en stream: $e');
      rethrow;
    }
  }

  // obtener checklists por vehículo
  Stream<List<Checklist>> obtenerChecklistsPorVehiculo(String vehiculoId) {
    debugPrint('[ChecklistController] Obteniendo checklists del vehículo: $vehiculoId');

    try {
      return _firestore
          .collection(_coleccion)
          .where('vehiculoId', isEqualTo: vehiculoId)
          .snapshots()
          .map((snapshot) {
        try {
          debugPrint('[ChecklistController] Snapshot vehículo con ${snapshot.docs.length} documentos');

          final checklists = <Checklist>[];

          for (var i = 0; i < snapshot.docs.length; i++) {
            try {
              final checklist = Checklist.fromJson(snapshot.docs[i].data());
              checklists.add(checklist);
            } catch (e) {
              debugPrint('[ChecklistController] Error procesando checklist vehículo [$i]: $e');
              rethrow;
            }
          }

          checklists.sort((a, b) => b.fecha.compareTo(a.fecha));

          debugPrint('[ChecklistController] Checklists vehículo obtenidos: ${checklists.length}');
          return checklists;
        } catch (e) {
          debugPrint('[ChecklistController] Error en map vehículo: $e');
          rethrow;
        }
      });
    } catch (e) {
      debugPrint('[ChecklistController] Error en stream vehículo: $e');
      rethrow;
    }
  }

  // obtener checklists no aptos
  Stream<List<Checklist>> obtenerChecklistsNoAptos() {
    debugPrint('[ChecklistController] Obteniendo checklists no aptos');

    try {
      return _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'no_apto')
          .snapshots()
          .map((snapshot) {
        try {
          debugPrint('[ChecklistController] Snapshot no aptos con ${snapshot.docs.length} documentos');

          final checklists = <Checklist>[];

          for (var i = 0; i < snapshot.docs.length; i++) {
            try {
              final checklist = Checklist.fromJson(snapshot.docs[i].data());
              checklists.add(checklist);
            } catch (e) {
              debugPrint('[ChecklistController] Error procesando no apto [$i]: $e');
              rethrow;
            }
          }

          checklists.sort((a, b) => b.fecha.compareTo(a.fecha));

          debugPrint('[ChecklistController] Checklists no aptos encontrados: ${checklists.length}');
          return checklists;
        } catch (e) {
          debugPrint('[ChecklistController] Error en map no aptos: $e');
          rethrow;
        }
      });
    } catch (e) {
      debugPrint('[ChecklistController] Error en stream no aptos: $e');
      rethrow;
    }
  }

  // obtener el último checklist de un vehículo
  Future<Checklist?> obtenerUltimoChecklist(String vehiculoId) async {
    try {
      debugPrint('[ChecklistController] Obteniendo último checklist del vehículo: $vehiculoId');

      final snapshot = await _firestore
          .collection(_coleccion)
          .where('vehiculoId', isEqualTo: vehiculoId)
          .get();

      debugPrint('[ChecklistController] Documentos encontrados: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('[ChecklistController] No hay checklists para este vehículo');
        return null;
      }

      final checklists = <Checklist>[];

      for (var i = 0; i < snapshot.docs.length; i++) {
        try {
          final checklist = Checklist.fromJson(snapshot.docs[i].data());
          checklists.add(checklist);
        } catch (e) {
          debugPrint('[ChecklistController] Error procesando último checklist [$i]: $e');
          rethrow;
        }
      }

      checklists.sort((a, b) => b.fecha.compareTo(a.fecha));

      debugPrint('[ChecklistController] Último checklist encontrado');
      return checklists.first;
    } catch (e) {
      debugPrint('[ChecklistController] Error al obtener último checklist: $e');
      debugPrint('[ChecklistController] StackTrace: $e');
      throw Exception('Error al obtener último checklist: $e');
    }
  }

  // obtener cantidad de checklists no aptos hoy
  Future<int> obtenerChecklistsNoAptosHoy() async {
    try {
      debugPrint('[ChecklistController] Obteniendo checklists no aptos de hoy');

      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      debugPrint('[ChecklistController] Rango de fechas: $inicioDia - $finDia');

      final snapshot = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'no_apto')
          .where('fecha', isGreaterThanOrEqualTo: inicioDia)
          .where('fecha', isLessThanOrEqualTo: finDia)
          .get();

      final cantidad = snapshot.docs.length;
      debugPrint('[ChecklistController] Checklists no aptos hoy: $cantidad');
      return cantidad;
    } catch (e) {
      debugPrint('[ChecklistController] Error al obtener checklists no aptos de hoy: $e');
      debugPrint('[ChecklistController] Retornando 0');
      return 0;
    }
  }

  // verificar si existe checklist hoy
  Future<bool> existeChecklistHoy(String vehiculoId) async {
    try {
      debugPrint('[ChecklistController] Verificando si existe checklist hoy para: $vehiculoId');

      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

      final snapshot = await _firestore
          .collection(_coleccion)
          .where('vehiculoId', isEqualTo: vehiculoId)
          .get();

      debugPrint('[ChecklistController] Total de checklists para vehículo: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('[ChecklistController] No hay checklists para este vehículo');
        return false;
      }

      final checklists = <Checklist>[];

      for (var doc in snapshot.docs) {
        try {
          checklists.add(Checklist.fromJson(doc.data()));
        } catch (e) {
          debugPrint('[ChecklistController] Error procesando checklist: $e');
        }
      }

      final checklistsHoy = checklists.where((c) {
        return c.fecha.year == hoy.year &&
            c.fecha.month == hoy.month &&
            c.fecha.day == hoy.day;
      }).toList();

      debugPrint('[ChecklistController] Existe checklist hoy: ${checklistsHoy.isNotEmpty} (${checklistsHoy.length})');
      return checklistsHoy.isNotEmpty;
    } catch (e) {
      debugPrint('[ChecklistController] Error verificando checklist hoy: $e');
      return false;
    }
  }
}
