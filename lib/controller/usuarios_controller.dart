import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UsuariosController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // crear nuevo usuario
  Future<void> crearUsuario({
    required String uid,
    required String nombres,
    required String apellidos,
    required String email,
    required String telefono,
    required String dni,
    required String fechaNacimiento,
  }) async {
    try {
      debugPrint('Creando usuario: $uid');

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombres': nombres,
        'apellidos': apellidos,
        'email': email,
        'telefono': telefono,
        'dni': dni,
        'fechaNacimiento': fechaNacimiento,
        'rol': null,
        'estado': 'Pendiente',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      debugPrint('Usuario creado exitosamente');
    } catch (e) {
      debugPrint('Error al crear usuario: $e');
      rethrow;
    }
  }

  // actualizar datos del usuario
  Future<void> actualizarUsuario({
    required String userId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      debugPrint('Actualizando usuario: $userId');
      debugPrint('Datos a actualizar: $datos');

      await _firestore.collection('usuarios').doc(userId).update(datos);

      debugPrint('Usuario actualizado exitosamente');
    } catch (e) {
      debugPrint('Error al actualizar usuario: $e');
      rethrow;
    }
  }

  // actualizar perfil del usuario actual
  Future<void> actualizarPerfilActual(Map<String, dynamic> datos) async {
    try {
      User? user = _auth.currentUser;
      debugPrint('Actualizando perfil del usuario actual: ${user?.uid}');
      debugPrint('Datos a actualizar: $datos');

      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).update(datos);
        debugPrint('Perfil actualizado exitosamente');
      } else {
        debugPrint('No hay usuario autenticado');
      }
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // eliminar usuario
  Future<void> eliminarUsuario(String userId) async {
    try {
      debugPrint('Eliminando usuario: $userId');

      await _firestore.collection('usuarios').doc(userId).delete();

      debugPrint('Usuario eliminado exitosamente');
    } catch (e) {
      debugPrint('Error al eliminar usuario: $e');
      rethrow;
    }
  }

  // obtener datos del usuario actual
  Future<Map<String, dynamic>?> obtenerDatosUsuarioActual() async {
    try {
      User? user = _auth.currentUser;
      debugPrint('Usuario actual: ${user?.uid}');

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();

        debugPrint('Documento existe: ${doc.exists}');
        debugPrint('Datos: ${doc.data()}');

        return doc.data() as Map<String, dynamic>?;
      }
      debugPrint('No hay usuario autenticado');
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      rethrow;
    }
  }

  // obtener usuario por id
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String userId) async {
    try {
      debugPrint('Buscando usuario: $userId');

      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(userId).get();

      debugPrint('Documento existe: ${doc.exists}');
      debugPrint('Datos: ${doc.data()}');

      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      rethrow;
    }
  }

  // obtener todos los usuarios
  Future<List<Map<String, dynamic>>> obtenerTodosUsuarios() async {
    try {
      debugPrint('Obteniendo todos los usuarios...');

      QuerySnapshot snapshot = await _firestore.collection('usuarios').get();

      debugPrint('Se encontraron ${snapshot.docs.length} usuarios');

      return snapshot.docs
          .map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'uid': doc.id,
      })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener usuarios: $e');
      rethrow;
    }
  }

  // filtrar usuarios por estado
  List<Map<String, dynamic>> filtrarPorEstado(
      List<Map<String, dynamic>> usuarios, String estado) {
    if (estado == 'Todos') return usuarios;
    return usuarios.where((u) => u['estado'] == estado).toList();
  }

  // buscar usuarios por nombre o email
  List<Map<String, dynamic>> buscarUsuarios(
      List<Map<String, dynamic>> usuarios, String busqueda) {
    if (busqueda.isEmpty) return usuarios;

    final busquedaLower = busqueda.toLowerCase();
    return usuarios.where((usuario) {
      final nombres = (usuario['nombres'] ?? '').toString().toLowerCase();
      final apellidos = (usuario['apellidos'] ?? '').toString().toLowerCase();
      final email = (usuario['email'] ?? '').toString().toLowerCase();

      return nombres.contains(busquedaLower) ||
          apellidos.contains(busquedaLower) ||
          email.contains(busquedaLower);
    }).toList();
  }

  // aprobar usuario
  Future<void> aprobarUsuario(String userId) async {
    try {
      debugPrint('Aprobando usuario: $userId');

      await actualizarUsuario(
        userId: userId,
        datos: {
          'estado': 'Aprobado',
          'rol': 'Conductor',
        },
      );

      debugPrint('Usuario aprobado y rol asignado');
    } catch (e) {
      debugPrint('Error al aprobar usuario: $e');
      rethrow;
    }
  }

  // rechazar usuario
  Future<void> rechazarUsuario(String userId) async {
    try {
      debugPrint('Rechazando usuario: $userId');

      await actualizarUsuario(
        userId: userId,
        datos: {
          'estado': 'Rechazado',
        },
      );

      debugPrint('Usuario rechazado');
    } catch (e) {
      debugPrint('Error al rechazar usuario: $e');
      rethrow;
    }
  }

  // asignar vehículo a conductor
  Future<void> asignarVehiculo({
    required String userId,
    required String vehiculoPlaca,
    required String vehiculoModelo,
  }) async {
    try {
      debugPrint('Asignando vehículo a conductor: $userId');

      await _firestore.collection('usuarios').doc(userId).update({
        'vehiculoPlaca': vehiculoPlaca,
        'vehiculoModelo': vehiculoModelo,
        'vehiculoEstado': 'Activo',
      });

      debugPrint('Vehículo asignado exitosamente');
    } catch (e) {
      debugPrint('Error al asignar vehículo: $e');
      rethrow;
    }
  }

  // cambiar estado del conductor
  Future<void> cambiarEstadoConductor({
    required String userId,
    required String nuevoEstado,
  }) async {
    try {
      debugPrint('Cambiando estado de conductor: $userId a $nuevoEstado');

      await _firestore.collection('usuarios').doc(userId).update({
        'estado': nuevoEstado,
      });

      debugPrint('Estado cambiado exitosamente');
    } catch (e) {
      debugPrint('Error al cambiar estado: $e');
      rethrow;
    }
  }

  // obtener todos los conductores
  Future<List<Map<String, dynamic>>> obtenerTodosConductores() async {
    try {
      debugPrint('Obteniendo todos los conductores...');

      QuerySnapshot snapshot =
      await _firestore.collection('usuarios').where('rol', isEqualTo: 'Conductor').get();

      debugPrint('Se encontraron ${snapshot.docs.length} conductores');

      return snapshot.docs
          .map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'uid': doc.id,
      })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener conductores: $e');
      rethrow;
    }
  }

  // obtener todos los administradores
  Future<List<Map<String, dynamic>>> obtenerTodosAdmins() async {
    try {
      debugPrint('Obteniendo todos los administradores...');

      QuerySnapshot snapshot =
      await _firestore.collection('usuarios').where('rol', isEqualTo: 'Admin').get();

      debugPrint('Se encontraron ${snapshot.docs.length} administradores');

      return snapshot.docs
          .map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'uid': doc.id,
      })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener administradores: $e');
      rethrow;
    }
  }

  // subir documento de usuario
  Future<void> subirDocumentoUsuario({
    required String userId,
    required String tipoDocumento,
    required String urlDocumento,
  }) async {
    try {
      debugPrint('Subiendo documento: $tipoDocumento para usuario: $userId');

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('documentos')
          .doc(tipoDocumento)
          .set({
        'tipo': tipoDocumento,
        'url': urlDocumento,
        'fechaSubida': FieldValue.serverTimestamp(),
      });

      debugPrint('Documento subido exitosamente');
    } catch (e) {
      debugPrint('Error al subir documento: $e');
      rethrow;
    }
  }

  // obtener documentos del usuario
  Future<List<Map<String, dynamic>>> obtenerDocumentosUsuario(String userId) async {
    try {
      debugPrint('Obteniendo documentos del usuario: $userId');

      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('documentos')
          .get();

      debugPrint('Se encontraron ${snapshot.docs.length} documentos');

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error al obtener documentos: $e');
      rethrow;
    }
  }

  // obtener documentos del usuario actual
  Future<List<Map<String, dynamic>>> obtenerDocumentosUsuarioActual() async {
    try {
      User? user = _auth.currentUser;
      debugPrint('Obteniendo documentos del usuario actual: ${user?.uid}');

      if (user != null) {
        return await obtenerDocumentosUsuario(user.uid);
      }
      debugPrint('No hay usuario autenticado');
      return [];
    } catch (e) {
      debugPrint('Error al obtener documentos del usuario actual: $e');
      rethrow;
    }
  }

  // escuchar cambios de un usuario
  Stream<DocumentSnapshot> escucharUsuario(String userId) {
    debugPrint('Escuchando cambios del usuario: $userId');
    return _firestore.collection('usuarios').doc(userId).snapshots();
  }

  // escuchar cambios del usuario actual
  Stream<DocumentSnapshot?> escucharUsuarioActual() {
    User? user = _auth.currentUser;
    debugPrint('Escuchando cambios del usuario actual: ${user?.uid}');

    if (user != null) {
      return _firestore.collection('usuarios').doc(user.uid).snapshots();
    }
    return Stream.empty();
  }

  // verificar si es admin
  Future<bool> esAdmin(String userId) async {
    try {
      Map<String, dynamic>? usuario = await obtenerUsuarioPorId(userId);
      return usuario?['rol'] == 'Admin';
    } catch (e) {
      debugPrint('Error al verificar rol de admin: $e');
      return false;
    }
  }

  // asignar rol
  Future<void> asignarRol(String userId, String rol) async {
    try {
      final dynamic rolValue = rol.isEmpty ? FieldValue.delete() : rol;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({
        'rol': rolValue,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error al asignar rol: $e';
    }
  }

  // verificar si es conductor
  Future<bool> esConductor(String userId) async {
    try {
      Map<String, dynamic>? usuario = await obtenerUsuarioPorId(userId);
      return usuario?['rol'] == 'Conductor';
    } catch (e) {
      debugPrint('Error al verificar rol de conductor: $e');
      return false;
    }
  }
}