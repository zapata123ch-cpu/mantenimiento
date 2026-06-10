import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentosController {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // ======================== CAPTURAR AMBOS LADOS ========================
  Future<Map<String, String>?> capturarAmbosLados() async {
    print('📸 [CONTROLLER] Capturando FRENTE...');

    XFile? fotoFrente = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (fotoFrente == null) {
      print('❌ [CONTROLLER] Captura de frente cancelada');
      return null;
    }
    print('✅ [CONTROLLER] Frente capturado: ${fotoFrente.name}');

    print('📸 [CONTROLLER] Capturando REVERSO...');
    XFile? fotoReverso = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (fotoReverso == null) {
      print('❌ [CONTROLLER] Captura de reverso cancelada');
      return null;
    }
    print('✅ [CONTROLLER] Reverso capturado: ${fotoReverso.name}');

    return {
      'frente': fotoFrente.path,
      'reverso': fotoReverso.path,
    };
  }

  // ======================== CAPTURAR UN LADO ========================
  Future<String?> capturarUnLado() async {
    print('📸 [CONTROLLER] Capturando documento...');

    XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (foto == null) {
      print('❌ [CONTROLLER] Captura cancelada');
      return null;
    }

    print('✅ [CONTROLLER] Foto capturada: ${foto.name}');
    return foto.path;
  }

  // ======================== SUBIR DOCUMENTO AMBOS LADOS ========================
  Future<String?> subirDocumentoAmbosLados({
    required String idUsuario,
    required String tipoDocumento,
    required String rutaFrente,
    required String rutaReverso,
  }) async {
    try {
      print('🚀 [CONTROLLER] Subiendo $tipoDocumento ambos lados');

      // Subir frente
      print('📤 [STORAGE] Subiendo FRENTE...');
      String urlFrente = await _subirArchivo(
        rutaLocal: rutaFrente,
        idUsuario: idUsuario,
        tipoDocumento: tipoDocumento,
        lado: 'frente',
      );

      // Subir reverso
      print('📤 [STORAGE] Subiendo REVERSO...');
      String urlReverso = await _subirArchivo(
        rutaLocal: rutaReverso,
        idUsuario: idUsuario,
        tipoDocumento: tipoDocumento,
        lado: 'reverso',
      );

      // Guardar en Firestore
      print('💾 [FIRESTORE] Guardando en Firestore...');
      String docId = await _guardarEnFirestore(
        idUsuario: idUsuario,
        tipoDocumento: tipoDocumento,
        urlFrente: urlFrente,
        urlReverso: urlReverso,
        nombreFrente: File(rutaFrente).path.split('/').last,
        nombreReverso: File(rutaReverso).path.split('/').last,
      );

      print('✅ [CONTROLLER] Documento completamente guardado: $docId');
      return docId;
    } catch (e) {
      print('❌ [CONTROLLER] Error: $e');
      rethrow;
    }
  }

  // ======================== SUBIR DOCUMENTO UN LADO ========================
  Future<String?> subirDocumentoUnLado({
    required String idUsuario,
    required String tipoDocumento,
    required String rutaDocumento,
  }) async {
    try {
      print('🚀 [CONTROLLER] Subiendo $tipoDocumento un lado');

      String url = await _subirArchivo(
        rutaLocal: rutaDocumento,
        idUsuario: idUsuario,
        tipoDocumento: tipoDocumento,
        lado: 'unico',
      );

      print('💾 [FIRESTORE] Guardando en Firestore...');
      String docId = await _guardarEnFirestoreUnLado(
        idUsuario: idUsuario,
        tipoDocumento: tipoDocumento,
        url: url,
        nombreArchivo: File(rutaDocumento).path.split('/').last,
      );

      print('✅ [CONTROLLER] Documento completamente guardado: $docId');
      return docId;
    } catch (e) {
      print('❌ [CONTROLLER] Error: $e');
      rethrow;
    }
  }

  // ======================== SUBIR ARCHIVO A STORAGE ========================
  Future<String> _subirArchivo({
    required String rutaLocal,
    required String idUsuario,
    required String tipoDocumento,
    required String lado,
  }) async {
    try {
      File archivo = File(rutaLocal);

      if (!await archivo.exists()) {
        throw Exception('El archivo no existe');
      }

      String extension = _obtenerExtension(rutaLocal);
      String nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}_${lado}.$extension';
      String rutaStorage =
          'documentos/$idUsuario/$tipoDocumento/$nombreArchivo';

      print('📍 [STORAGE] Ruta: $rutaStorage');
      print('📦 [STORAGE] Tamaño: ${await archivo.length()} bytes');

      Reference ref = _storage.ref(rutaStorage);

      UploadTask uploadTask = ref.putFile(
        archivo,
        SettableMetadata(
          contentType: _obtenerMimeType(extension),
          customMetadata: {
            'tipo': tipoDocumento,
            'lado': lado,
            'usuario': idUsuario,
            'fechaCarga': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitorear progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('⬆️ [STORAGE] Progreso ($lado): ${progress.toStringAsFixed(2)}%');
      });

      await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
              'Timeout al subir $lado - La subida tardó más de 60 segundos');
        },
      );

      print('✓ [STORAGE] $lado subido exitosamente');

      String url = await ref.getDownloadURL();
      print('🔗 [STORAGE] URL: $url');

      return url;
    } catch (e) {
      print('❌ [STORAGE] Error: $e');
      rethrow;
    }
  }

  // ======================== GUARDAR EN FIRESTORE (AMBOS LADOS) ========================
  Future<String> _guardarEnFirestore({
    required String idUsuario,
    required String tipoDocumento,
    required String urlFrente,
    required String urlReverso,
    required String nombreFrente,
    required String nombreReverso,
  }) async {
    try {
      print('📝 [FIRESTORE] Preparando documento...');

      DocumentReference docRef = await _firestore
          .collection('usuarios')
          .doc(idUsuario)
          .collection('documentos')
          .add({
        'tipoDocumento': tipoDocumento,
        'urlFrente': urlFrente,
        'urlReverso': urlReverso,
        'nombreArchivoFrente': nombreFrente,
        'nombreArchivoReverso': nombreReverso,
        'estado': 'pendiente_revision',
        'fechaCarga': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [FIRESTORE] Guardado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [FIRESTORE] Error: $e');
      rethrow;
    }
  }

  // ======================== GUARDAR EN FIRESTORE (UN LADO) ========================
  Future<String> _guardarEnFirestoreUnLado({
    required String idUsuario,
    required String tipoDocumento,
    required String url,
    required String nombreArchivo,
  }) async {
    try {
      print('📝 [FIRESTORE] Preparando documento...');

      DocumentReference docRef = await _firestore
          .collection('usuarios')
          .doc(idUsuario)
          .collection('documentos')
          .add({
        'tipoDocumento': tipoDocumento,
        'urlDocumento': url,
        'nombreArchivo': nombreArchivo,
        'estado': 'pendiente_revision',
        'fechaCarga': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [FIRESTORE] Guardado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [FIRESTORE] Error: $e');
      rethrow;
    }
  }

  // ======================== OBTENER DOCUMENTOS ========================
  Future<List<Map<String, dynamic>>> obtenerDocumentos(
      String idUsuario) async {
    print('📥 [FIRESTORE] Obteniendo documentos...');

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .doc(idUsuario)
          .collection('documentos')
          .orderBy('fechaCarga', descending: true)
          .get();

      print('📊 [FIRESTORE] Documentos: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('❌ [FIRESTORE] Error: $e');
      rethrow;
    }
  }

  // ======================== ELIMINAR DOCUMENTO ========================
  Future<void> eliminarDocumento({
    required String idUsuario,
    required String idDocumento,
  }) async {
    try {
      print('🗑️ [FIRESTORE] Eliminando: $idDocumento');

      await _firestore
          .collection('usuarios')
          .doc(idUsuario)
          .collection('documentos')
          .doc(idDocumento)
          .delete();

      print('✅ [FIRESTORE] Eliminado');
    } catch (e) {
      print('❌ [FIRESTORE] Error: $e');
      rethrow;
    }
  }

  // ======================== UTILIDADES ========================
  String _obtenerExtension(String ruta) {
    return ruta.split('.').last.toLowerCase();
  }

  String _obtenerMimeType(String extension) {
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