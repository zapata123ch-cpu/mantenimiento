import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../model/vehiculo_model.dart';

class VehiculosController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'vehiculos';

  // crear: crea un vehiculo con archivos en storage y lo guarda en firestore
  Future<String?> crearVehiculoConArchivos(
      Vehiculo vehiculo,
      Map<String, File?> archivos,
      ) async {
    try {
      debugPrint('[Controller] Iniciando creación de vehículo: ${vehiculo.placa}');

      // Validar que la placa sea única
      debugPrint('[Controller] Validando placa única: ${vehiculo.placa}');
      final existe = await _placaExiste(vehiculo.placa);
      if (existe) {
        debugPrint('[Controller] La placa ${vehiculo.placa} ya existe');
        throw Exception('La placa ${vehiculo.placa} ya existe en el sistema');
      }

      debugPrint('[Controller] Placa válida');

      // Subir documentos a Storage
      debugPrint('[Controller] Subiendo documentos a Storage...');
      final urlsDocumentos = await _subirDocumentos(vehiculo.placa, archivos);

      if (urlsDocumentos.isEmpty) {
        debugPrint('[Controller] No se subieron documentos, continuando...');
      }

      debugPrint('[Controller] Documentos subidos exitosamente');
      debugPrint('[Controller] URLs: $urlsDocumentos');

      // Actualizar el objeto vehiculo con las URLs
      final vehiculoConUrls = Vehiculo(
        placa: vehiculo.placa,
        marca: vehiculo.marca,
        modelo: vehiculo.modelo,
        ano: vehiculo.ano,
        color: vehiculo.color,
        // Usamos las listas (aunque probablemente estarán vacías al crear)
        conductores: vehiculo.conductores,
        conductoresUIDs: vehiculo.conductoresUIDs,
        estado: vehiculo.estado,
        kilometrajeAcumulado: vehiculo.kilometrajeAcumulado,
        documentosBase64: urlsDocumentos,
        documentos: vehiculo.documentos,
        fechaRegistro: vehiculo.fechaRegistro,
      );

      // Guardar en Firestore
      debugPrint('[Controller] Guardando en Firestore...');
      final mapa = vehiculoConUrls.toMap();
      final docRef = await _db.collection(_collection).add(mapa);

      debugPrint('[Controller] Vehículo registrado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[Controller] Error al crear vehículo: $e');
      return null;
    }
  }

  // crear: crea un vehiculo simple en firestore (sin archivos)
  Future<String?> crearVehiculo(Vehiculo vehiculo) async {
    try {
      debugPrint('[VehiculosController] Iniciando creación de vehículo: ${vehiculo.placa}');

      // Validar que la placa sea única
      debugPrint('[VehiculosController] Validando placa única: ${vehiculo.placa}');
      final existe = await _placaExiste(vehiculo.placa);
      if (existe) {
        debugPrint('[VehiculosController] La placa ${vehiculo.placa} ya existe');
        throw Exception('La placa ${vehiculo.placa} ya existe en el sistema');
      }

      debugPrint('[VehiculosController] Placa válida, procediendo a guardar...');
      final mapa = vehiculo.toMap();
      debugPrint('[VehiculosController] Datos a guardar: $mapa');

      final docRef = await _db.collection(_collection).add(mapa);
      debugPrint('[VehiculosController] Vehículo registrado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[VehiculosController] Error al crear vehículo: $e');
      return null;
    }
  }

  // listar: obtener todos los vehículos
  Future<List<Vehiculo>> obtenerVehiculos() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Vehiculo.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener vehículos: $e');
      return [];
    }
  }

  // listar: stream de vehículos en tiempo real
  Stream<List<Vehiculo>> obtenerVehiculosStream() {
    return _db.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Vehiculo.fromMap(doc.data(), doc.id))
            .toList());
  }

  // filtrar: obtener vehículos por conductor (Ahora busca si el conductor está en la lista de UIDs)
  Future<List<Vehiculo>> obtenerVehiculosPorConductor(String conductorId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('conductoresUIDs', arrayContains: conductorId)
          .get();
      return snapshot.docs
          .map((doc) => Vehiculo.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener vehículos del conductor: $e');
      return [];
    }
  }

  // filtrar: obtener vehículos por estado
  Future<List<Vehiculo>> obtenerVehiculosPorEstado(String estado) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('estado', isEqualTo: estado)
          .get();
      return snapshot.docs
          .map((doc) => Vehiculo.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener vehículos por estado: $e');
      return [];
    }
  }

  // leer: obtener un vehículo por id
  Future<Vehiculo?> obtenerVehiculoPorId(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Vehiculo.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener vehículo: $e');
      return null;
    }
  }

  // leer: obtener el vehículo asignado a un conductor
  Future<Vehiculo?> obtenerVehiculoDelConductor(String conductorId) async {
    try {
      final doc = await _db.collection('usuarios').doc(conductorId).get();
      if (!doc.exists) return null;

      final vehiculoId = doc['idVehiculo'];
      if (vehiculoId == null) return null;

      final vehiculoDoc = await _db.collection(_collection).doc(vehiculoId).get();
      if (!vehiculoDoc.exists) return null;

      return Vehiculo.fromMap(vehiculoDoc.data()!, vehiculoDoc.id);

    } catch (e) {
      debugPrint('[Controller] Error obtenerVehiculoDelConductor: $e');
      return null;
    }
  }

  // stream: obtener vehículo del conductor en tiempo real
  Stream<Vehiculo?> obtenerVehiculoDelConductorStream(String conductorId) {
    return _db.collection('usuarios').doc(conductorId).snapshots().asyncExpand((conductorDoc) async* {
      if (!conductorDoc.exists) {
        yield null;
        return;
      }

      final idVehiculo = conductorDoc['idVehiculo'];

      if (idVehiculo == null) {
        yield null;
        return;
      }

      // Escuchar cambios del vehículo en tiempo real
      yield* _db.collection(_collection).doc(idVehiculo).snapshots().map((vehiculoDoc) {
        if (vehiculoDoc.exists) {
          return Vehiculo.fromMap(vehiculoDoc.data()!, vehiculoDoc.id);
        }
        return null;
      });
    });
  }

  // actualizar: actualizar vehículo completo
  Future<bool> actualizarVehiculo(String id, Vehiculo vehiculo) async {
    try {
      await _db.collection(_collection).doc(id).update(vehiculo.toMap());
      debugPrint('Vehículo actualizado');
      return true;
    } catch (e) {
      debugPrint('Error al actualizar vehículo: $e');
      return false;
    }
  }

  // actualizar: actualizar solo el estado
  Future<bool> actualizarEstado(String id, String nuevoEstado) async {
    try {
      await _db
          .collection(_collection)
          .doc(id)
          .update({'estado': nuevoEstado});
      debugPrint('Estado actualizado a: $nuevoEstado');
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      return false;
    }
  }

  // actualizar: actualizar kilometraje acumulado
  Future<bool> actualizarKilometraje(String id, int nuevoKilometraje) async {
    try {
      await _db
          .collection(_collection)
          .doc(id)
          .update({'kilometrajeAcumulado': nuevoKilometraje});
      debugPrint('Kilometraje actualizado');
      return true;
    } catch (e) {
      debugPrint('Error al actualizar kilometraje: $e');
      return false;
    }
  }

  // actualizar: actualizar documento específico en storage y firestore
  Future<bool> actualizarDocumento(
      String vehiculoId,
      String placa,
      String tipoDocumento,
      File nuevoArchivo,
      ) async {
    try {
      debugPrint('[Controller] Actualizando documento $tipoDocumento');

      // Obtener el vehículo actual
      final vehiculo = await obtenerVehiculoPorId(vehiculoId);
      if (vehiculo == null) {
        throw Exception('Vehículo no encontrado');
      }

      // Eliminar el archivo anterior de Storage si existe
      if (vehiculo.documentosBase64?[tipoDocumento] != null) {
        try {
          final oldUrl = vehiculo.documentosBase64![tipoDocumento]!;
          final ref = _storage.refFromURL(oldUrl);
          await ref.delete();
          debugPrint('[Storage] Documento anterior eliminado');
        } catch (e) {
          debugPrint('[Storage] No se pudo eliminar el documento anterior: $e');
        }
      }

      // Subir el nuevo archivo
      final extension = nuevoArchivo.path.split('.').last;
      final rutaStorage = 'vehiculos/$placa/${tipoDocumento}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final ref = _storage.ref().child(rutaStorage);
      final uploadTask = await ref.putFile(nuevoArchivo);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Actualizar en Firestore
      await _db.collection(_collection).doc(vehiculoId).update({
        'documentosBase64.$tipoDocumento': downloadUrl,
      });

      debugPrint('[Controller] Documento actualizado exitosamente');
      return true;
    } catch (e) {
      debugPrint('[Controller] Error al actualizar documento: $e');
      return false;
    }
  }


  // eliminar: eliminar documento específico del vehiculo
  Future<bool> eliminarDocumentoVehiculo(
      String vehiculoId,
      String placa,
      String tipoDocumento,
      ) async {
    try {
      debugPrint('[Controller] Eliminando documento $tipoDocumento');

      // Obtener el vehículo
      final vehiculo = await obtenerVehiculoPorId(vehiculoId);
      if (vehiculo == null) {
        throw Exception('Vehículo no encontrado');
      }

      // Eliminar de Storage si existe
      if (vehiculo.documentosBase64?[tipoDocumento] != null) {
        try {
          final url = vehiculo.documentosBase64![tipoDocumento]!;
          final ref = _storage.refFromURL(url);
          await ref.delete();
          debugPrint('[Storage] Documento eliminado de Storage');
        } catch (e) {
          debugPrint('[Storage] Error al eliminar de Storage: $e');
        }
      }

      // Eliminar de Firestore usando FieldValue.delete()
      await _db.collection(_collection).doc(vehiculoId).update({
        'documentosBase64.$tipoDocumento': FieldValue.delete(),
      });

      debugPrint('[Controller] Documento eliminado de Firestore');
      return true;
    } catch (e) {
      debugPrint('[Controller] Error al eliminar documento: $e');
      return false;
    }
  }

  // eliminar: eliminar vehículo, sus documentos y desasignar conductores
  Future<bool> eliminarVehiculo(String id) async {
    try {
      debugPrint('[Controller] Eliminando vehículo: $id');

      // Obtener el vehículo para eliminar sus documentos y desasignar conductores
      final vehiculoDoc = await _db.collection(_collection).doc(id).get();
      if (!vehiculoDoc.exists) {
        throw Exception('Vehículo no encontrado');
      }
      final vehiculoData = vehiculoDoc.data()!;

      // 1. desasignar conductores (en plural)
      final List<String> conductoresUIDs = List<String>.from(vehiculoData['conductoresUIDs'] ?? []);
      if (conductoresUIDs.isNotEmpty) {
        debugPrint('[Controller] Desasignando ${conductoresUIDs.length} conductores...');
        for (final conductorId in conductoresUIDs) {
          try {
            await _db.collection('usuarios').doc(conductorId).update({
              'idVehiculo': null,
            });
            debugPrint('[Controller] Conductor $conductorId desasignado correctamente');
          } catch (e) {
            debugPrint('[Controller] Error al desasignar conductor $conductorId: $e');
          }
        }
      }

      // 2 eliminar documentos de Storage
      final vehiculo = Vehiculo.fromMap(vehiculoData, id); // Usamos el modelo para acceder a documentosBase64
      if (vehiculo.documentosBase64 != null) {
        for (var url in vehiculo.documentosBase64!.values) {
          try {
            final ref = _storage.refFromURL(url);
            await ref.delete();
            debugPrint('[Storage] Documento eliminado de Storage');
          } catch (e) {
            debugPrint('[Storage] Error al eliminar documento: $e');
          }
        }
      }

      // 3 eliminar de Firestore
      await _db.collection(_collection).doc(id).delete();
      debugPrint('[Controller] Vehículo eliminado de Firestore');

      debugPrint('[Controller] Vehículo ${vehiculo.placa} eliminado completamente');
      return true;

    } catch (e) {
      debugPrint('[Controller] Error al eliminar vehículo: $e');
      return false;
    }
  }

  // actualizar: actualizar estado del vehículo con timestamp
  Future<void> actualizarEstadoVehiculo(String vehiculoId, String nuevoEstado) async {
    try {
      debugPrint('[Controller] Actualizando estado del vehículo $vehiculoId a: $nuevoEstado');

      await FirebaseFirestore.instance
          .collection('vehiculos')
          .doc(vehiculoId)
          .update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      debugPrint('[Controller] Estado actualizado a: $nuevoEstado');
    } catch (e) {
      debugPrint('[Controller] Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado del vehículo: $e');
    }
  }

  // helper: validar si una placa ya existe en la colección
  Future<bool> _placaExiste(String placa) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('placa', isEqualTo: placa)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al validar placa: $e');
      return false;
    }
  }

  /// ======================== OBTENER ID CONDUCTOR ========================
  /// Busca un conductor comparando nombre completo normalizado
  Future<String?> _obtenerIdConductor(String nombreCompleto) async {
    try {
      if (nombreCompleto.trim().isEmpty) return null;

      // Normalizamos para comparar correctamente
      String _normalize(String s) {
        s = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        return s
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ñ', 'n');
      }

      final inputNorm = _normalize(nombreCompleto);

      debugPrint('[Controller] Buscando conductor normalizado: "$inputNorm"');

      // Traemos solo conductores
      final snapshot = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'Conductor')
          .get();

      // Buscamos localmente para evitar problemas con Firestore
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final nombres = data['nombres']?.toString() ?? '';
        final apellidos = data['apellidos']?.toString() ?? '';

        final nombreGuardadoNorm = _normalize('$nombres $apellidos');

        if (nombreGuardadoNorm == inputNorm) {
          debugPrint('[Controller] Conductor encontrado: ${doc.id}');
          return doc.id;
        }
      }

      debugPrint('[Controller] Conductor NO encontrado');
      return null;

    } catch (e) {
      debugPrint('[Controller] Error en _obtenerIdConductor: $e');
      return null;
    }
  }

  /// ======================== ASIGNAR CONDUCTOR (Soporta 2) ========================
  // acción: asignar un conductor al vehículo y actualizar relaciones
  Future<bool> asignarConductor(String vehiculoId, String nombreConductor) async {
    try {
      debugPrint('[Controller] Asignando conductor "$nombreConductor" al vehículo: $vehiculoId');

      // 1. Obtener vehículo actual y sus datos de Firestore
      final vehiculoDoc = await _db.collection(_collection).doc(vehiculoId).get();
      if (!vehiculoDoc.exists) {
        throw Exception('Vehículo no encontrado');
      }
      final vehiculoData = vehiculoDoc.data()!;

      // 2. Obtener UID y verificar disponibilidad del nuevo conductor
      final conductorNuevoId = await _obtenerIdConductor(nombreConductor);
      if (conductorNuevoId == null) {
        throw Exception('Conductor no encontrado');
      }

      // 3. Obtener la lista de conductores actuales del vehículo
      final List<String> conductoresUIDs = List<String>.from(vehiculoData['conductoresUIDs'] ?? []);
      final List<String> conductoresNombres = List<String>.from(vehiculoData['conductores'] ?? []);

      // 4. Validar si el conductor ya está asignado o si ya hay 2
      if (conductoresUIDs.contains(conductorNuevoId)) {
        debugPrint('[Controller] El conductor ya está asignado a este vehículo.');
        return true;
      }

      // 🛑 REGLA: Máximo 2 conductores
      if (conductoresUIDs.length >= 2) {
        throw Exception('El vehículo ya tiene el máximo de 2 conductores asignados.');
      }

      // 5. Agregar el nuevo conductor a ambas listas
      conductoresUIDs.add(conductorNuevoId);
      conductoresNombres.add(nombreConductor);

      // 6. Actualizar el vehículo en Firestore
      await _db.collection(_collection).doc(vehiculoId).update({
        'conductores': conductoresNombres,
        'conductoresUIDs': conductoresUIDs,
        // Para compatibilidad hacia atrás o si la UI lo necesita, actualiza el campo singular
      });
      debugPrint('[Controller] Vehículo actualizado con conductor');

      // 7. Actualizar el conductor (el conductor solo tiene 1 vehículo asignado)
      await _db.collection('usuarios').doc(conductorNuevoId).update({
        'idVehiculo': vehiculoId,
      });
      debugPrint('[Controller] Conductor actualizado');

      return true;

    } catch (e) {
      debugPrint('[Controller] Error al asignar conductor: $e');
      return false;
    }
  }


  /// ======================== DESASIGNAR CONDUCTOR (Específico) ========================
  // acción: desasignar UN conductor específico del vehículo
  Future<bool> desasignarConductor(String vehiculoId, String nombreConductorARemover) async {
    try {
      debugPrint('[Controller] Desasignando conductor "$nombreConductorARemover" del vehículo: $vehiculoId');

      // 1. Obtener vehículo actual y sus datos de Firestore
      final vehiculoDoc = await _db.collection(_collection).doc(vehiculoId).get();
      if (!vehiculoDoc.exists) {
        throw Exception('Vehículo no encontrado');
      }
      final vehiculoData = vehiculoDoc.data()!;

      // 2. Obtener UID del conductor a remover
      final conductorIdARemover = await _obtenerIdConductor(nombreConductorARemover);
      if (conductorIdARemover == null) {
        debugPrint('[Controller] Conductor a remover no encontrado en la base de datos.');
        return true;
      }

      // 3. Limpiar relación en el usuario (desasignar vehículo)
      await _db.collection('usuarios').doc(conductorIdARemover).update({
        'idVehiculo': null,
      });
      debugPrint('[Controller] Usuario desasignado del vehículo');

      // 4. Obtener las listas actuales
      final List<String> conductoresUIDs = List<String>.from(vehiculoData['conductoresUIDs'] ?? []);
      final List<String> conductoresNombres = List<String>.from(vehiculoData['conductores'] ?? []);

      // 5. Remover el UID y el Nombre de las listas
      conductoresUIDs.remove(conductorIdARemover);
      conductoresNombres.remove(nombreConductorARemover);

      // 6. Actualizar el vehículo en Firestore
      await _db.collection(_collection).doc(vehiculoId).update({
        'conductores': conductoresNombres.isNotEmpty ? conductoresNombres : FieldValue.delete(),
        'conductoresUIDs': conductoresUIDs.isNotEmpty ? conductoresUIDs : FieldValue.delete(),
        // Actualizar campos singulares de compatibilidad
      });

      debugPrint('[Controller] Vehículo actualizado, conductor removido.');
      return true;

    } catch (e) {
      debugPrint('[Controller] Error al desasignar conductor: $e');
      return false;
    }
  }

  // listar: obtener conductores con su estado (disponible/ocupado)
  Future<Map<String, dynamic>> obtenerConductoresConStatus() async {
    try {
      debugPrint('[Controller] Obteniendo conductores con status...');

      final snapshot = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'Conductor')
          .get();

      List<Map<String, dynamic>> disponibles = [];
      List<Map<String, dynamic>> ocupados = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final nombres = data['nombres'] ?? '';
        final apellidos = data['apellidos'] ?? '';
        final idVehiculo = data['idVehiculo'];
        final uid = doc.id;

        if (nombres.isEmpty || apellidos.isEmpty) {
          debugPrint('[Controller] Usuario ignorado, falta nombres/apellidos');
          continue;
        }

        final nombreCompleto = '$nombres $apellidos';
        final conductor = {
          'nombre': nombreCompleto,
          'uid': uid,
          'idVehiculo': idVehiculo,
        };

        if (idVehiculo == null || idVehiculo == '' || idVehiculo == 'Sin asignar') {
          disponibles.add(conductor);
          debugPrint('[Controller] Disponible: $nombreCompleto');
        } else {
          ocupados.add(conductor);
          debugPrint('[Controller] Ocupado: $nombreCompleto (Vehículo: $idVehiculo)');
        }
      }

      debugPrint('[Controller] Disponibles: ${disponibles.length}');
      debugPrint('[Controller] Ocupados: ${ocupados.length}');

      return {
        'disponibles': disponibles,
        'ocupados': ocupados,
        'todos': [...disponibles, ...ocupados],
      };

    } catch (e) {
      debugPrint('[Controller] Error: $e');
      return {
        'disponibles': [],
        'ocupados': [],
        'todos': [],
      };
    }
  }

  // listar: obtener nombres de conductores disponibles
  Future<List<String>> obtenerConductoresDisponibles() async {
    try {
      debugPrint('[Controller] Obteniendo conductores...');

      final snapshot = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'Conductor')
          .get();

      List<String> disponibles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final nombres = data['nombres'] ?? '';
        final apellidos = data['apellidos'] ?? '';
        final idVehiculo = data['idVehiculo'];

        if (nombres.isEmpty || apellidos.isEmpty) {
          debugPrint('[Controller] Usuario ignorado, falta nombres/apellidos');
          continue;
        }

        final nombreCompleto = '$nombres $apellidos';

        // revisar si idVehiculo es null, string vacío, o 'Sin asignar'
        if (idVehiculo == null || idVehiculo == '' || idVehiculo == 'Sin asignar') {
          disponibles.add(nombreCompleto);
          debugPrint('[Controller] Disponible: $nombreCompleto (idVehiculo: $idVehiculo)');
        } else {
          debugPrint('[Controller] Ocupado: $nombreCompleto (idVehiculo: $idVehiculo)');
        }
      }

      debugPrint('[Controller] Total Disponibles: ${disponibles.length}');
      debugPrint('[Controller] Lista final (${disponibles.length}): $disponibles');
      return disponibles;

    } catch (e) {
      debugPrint('[Controller] Error: $e');
      return [];
    }
  }

  // helper: subir documentos a firebase storage y devolver mapa de urls
  Future<Map<String, String>> _subirDocumentos(
      String placa,
      Map<String, File?> archivos,
      ) async {

    Map<String, String> urls = {};

    for (var entry in archivos.entries) {
      final tipoDoc = entry.key;
      final archivo = entry.value;

      if (archivo != null) {
        try {
          debugPrint('[Storage] Subiendo $tipoDoc...');

          // Ruta en Storage: vehiculos/{placa}/{tipoDoc}.{extension}
          final extension = archivo.path.split('.').last;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final rutaStorage = 'vehiculos/$placa/${tipoDoc}_$timestamp.$extension';

          debugPrint('[Storage] Ruta: $rutaStorage');

          // Subir archivo con timeout
          final ref = _storage.ref().child(rutaStorage);

          // Configurar metadata
          final metadata = SettableMetadata(
            contentType: _getContentType(extension),
            customMetadata: {
              'tipo': tipoDoc,
              'placa': placa,
              'uploadDate': DateTime.now().toIso8601String(),
            },
          );

          debugPrint('[Storage] Iniciando subida...');

          final uploadTask = ref.putFile(archivo, metadata);

          // Monitorear progreso
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            debugPrint('[Storage] Progreso $tipoDoc: ${progress.toStringAsFixed(1)}%');
          });

          // Esperar a que termine con timeout de 60 segundos
          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Timeout al subir $tipoDoc - La subida tardó más de 60 segundos');
            },
          );

          debugPrint('[Storage] $tipoDoc subido exitosamente');

          // Obtener URL de descarga
          final downloadUrl = await snapshot.ref.getDownloadURL();

          urls[tipoDoc] = downloadUrl;
          debugPrint('[Storage] URL obtenida: $downloadUrl');
        } catch (e, stackTrace) {
          debugPrint('[Storage] Error al subir $tipoDoc: $e');
          debugPrint('[Storage] StackTrace: $stackTrace');
          throw Exception('Error al subir documento $tipoDoc: $e');
        }
      }
    }

    return urls;
  }

  // helper: obtener content-type segun la extension del archivo
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

}