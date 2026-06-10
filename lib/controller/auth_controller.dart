import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../model/usuario_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();

  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final dniController = TextEditingController();
  final fechaNacimientoController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // obtener id del usuario actual
  Future<String?> obtenerIdUsuarioActual() async {
    try {
      debugPrint('[AuthController] Obteniendo ID del usuario actual desde Firebase...');

      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
        debugPrint('[AuthController] ID usuario obtenido: ${firebaseUser.uid}');
        return firebaseUser.uid;
      }

      debugPrint('[AuthController] No hay usuario autenticado en Firebase');
      return null;
    } catch (e) {
      debugPrint('[AuthController] Error al obtener ID del usuario: $e');
      return null;
    }
  }

  // registrar usuario
  Future<void> registrar() async {
    try {
      debugPrint('Iniciando registro...');
      debugPrint('Validando campos...');

      // Validar campos vacíos
      if (nombresController.text.isEmpty ||
          apellidosController.text.isEmpty ||
          dniController.text.isEmpty ||
          fechaNacimientoController.text.isEmpty ||
          emailController.text.isEmpty ||
          telefonoController.text.isEmpty ||
          passwordController.text.isEmpty) {
        throw Exception('Por favor completa todos los campos');
      }

      if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(nombresController.text) ||
          !RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(apellidosController.text)) {
        throw Exception('Los nombres y apellidos solo deben contener letras');
      }

      if (!RegExp(r'^[0-9]{8}$').hasMatch(dniController.text)) {
        throw Exception('El DNI debe tener 8 dígitos numéricos');
      }

      if (!RegExp(r'^9[0-9]{8}$').hasMatch(telefonoController.text)) {
        throw Exception('El teléfono debe iniciar con 9 y tener 9 dígitos');
      }

      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
        throw Exception('Ingresa un correo electrónico válido');
      }

      // Validar contraseñas
      if (passwordController.text != confirmPasswordController.text) {
        throw Exception('Las contraseñas no coinciden');
      }

      if (passwordController.text.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      debugPrint('Creando usuario en Firebase Auth...');

      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      debugPrint('Usuario creado en Auth: ${userCredential.user!.uid}');
      debugPrint('Creando modelo de usuario...');

      final usuario = UserModel(
        id: userCredential.user!.uid,
        nombres: nombresController.text,
        apellidos: apellidosController.text,
        dni: dniController.text,
        fechaNacimiento: fechaNacimientoController.text,
        email: emailController.text,
        telefono: telefonoController.text,
        rol: null,
        estado: 'Pendiente',
        fechaRegistro: DateTime.now(),
      );

      debugPrint('Modelo creado');
      debugPrint('Guardando en Firestore...');

      try {
        await _firestore
            .collection('usuarios')
            .doc(usuario.id)
            .set(usuario.toMap());
        debugPrint('Usuario guardado en Firestore');
      } catch (firestoreError) {
        throw Exception('Error guardando datos: $firestoreError');
      }

      debugPrint('Cerrando sesión...');
      await _auth.signOut();
      debugPrint('Registro completado exitosamente');
    } catch (e) {
      debugPrint('Error en registro: $e');
      rethrow;
    }
  }

  // login de usuario
  Future<UserModel?> login(String email, String password,
      {bool recordarSesion = false}) async {
    try {
      debugPrint('Iniciando login...');

      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Autenticado: ${userCredential.user!.uid}');

      final usuario = await _obtenerUsuario(userCredential.user!.uid);

      if (usuario == null) {
        await _auth.signOut();
        throw Exception('Usuario no encontrado');
      }

      if (usuario.estado == 'Pendiente') {
        await _auth.signOut();
        throw Exception('Tu cuenta está pendiente de aprobación del administrador');
      }

      if (usuario.estado == 'Rechazado') {
        await _auth.signOut();
        throw Exception('Tu solicitud de cuenta fue rechazada');
      }

      if (usuario.rol == null || usuario.rol!.isEmpty) {
        return usuario;
      }

      if (recordarSesion) {
        await _guardarSesion(usuario);
      }

      return usuario;
    } catch (e) {
      debugPrint('Error en login: $e');
      rethrow;
    }
  }

  // obtener usuario actual en firestore
  Future<UserModel?> _obtenerUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final usuario =
      UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      return usuario;
    } catch (e) {
      return null;
    }
  }

  // obtener usuario actual en sesión
  Future<UserModel?> obtenerUsuarioActual() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      return await _obtenerUsuario(uid);
    } catch (e) {
      return null;
    }
  }

  // verificar autenticación
  bool estaAutenticado() {
    return _auth.currentUser != null;
  }

  // cerrar sesión
  Future<void> logout() async {
    try {
      await limpiarSesionGuardada();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // guardar sesión local
  Future<void> _guardarSesion(UserModel usuario) async {
    try {
      final usuarioJson = jsonEncode(usuario.toMap());
      await _storage.write(key: 'sesion_usuario', value: usuarioJson);
      await _storage.write(key: 'sesion_activa', value: 'true');
    } catch (e) {}
  }

  // obtener sesión guardada
  Future<UserModel?> obtenerSesionGuardada() async {
    try {
      final sesionActiva = await _storage.read(key: 'sesion_activa');

      if (sesionActiva != 'true') {
        return null;
      }

      final usuarioJson = await _storage.read(key: 'sesion_usuario');
      if (usuarioJson == null) return null;

      final usuarioMap = jsonDecode(usuarioJson) as Map<String, dynamic>;
      final usuario = UserModel.fromMap(usuarioMap, usuarioMap['id']);
      return usuario;
    } catch (e) {
      return null;
    }
  }

  // limpiar sesión local
  Future<void> limpiarSesionGuardada() async {
    try {
      await _storage.delete(key: 'sesion_usuario');
      await _storage.delete(key: 'sesion_activa');
    } catch (e) {}
  }

  // obtener vehículo actual
  Future<String?> obtenerVehiculoActual() async {
    final conductorId = await obtenerIdUsuarioActual();

    final doc = await FirebaseFirestore.instance
        .collection('vehiculos')
        .where('conductorId', isEqualTo: conductorId)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return doc.docs.first.id;
    }

    return null;
  }

  // seleccionar fecha
  Future<void> seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      fechaNacimientoController.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  // limpiar controladores
  void limpiar() {
    nombresController.clear();
    apellidosController.clear();
    dniController.clear();
    fechaNacimientoController.clear();
    emailController.clear();
    telefonoController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  // liberar recursos
  void dispose() {
    nombresController.dispose();
    apellidosController.dispose();
    dniController.dispose();
    fechaNacimientoController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
