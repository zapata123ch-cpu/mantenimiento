import 'package:flutter/material.dart';

class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Autenticación
  static const String login = '/login';
  static const String register = '/register';
  static const String test = '/test';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminVehiculos = '/admin/vehiculos';
  static const String adminRegistrarVehiculo = '/admin/vehiculos/registrar';
  static const String detalleVehiculo = '/detalle_vehiculo';
  static const String asignarConductor = '/asignar_conductor';
  static const String subirDocumentos = '/perfil/subirDocumentos';

  static const String adminMantenimientos = '/admin/mantenimientos';
  static const String adminFallas = '/admin/fallas';
// conductor
  static const String conductorNotificaciones = '/conductor/notificaciones';
  static const String adminNotificaciones = '/admin/notificaciones';

  // Conductor
  static const String conductorDashboard = '/conductor';
  static const String conductorPerfil = '/conductor/perfil';
  static const String conductorVehiculo = '/conductor/vehiculo';
  static const String conductorRecorridos = '/conductor/recorridos';
  static const String conductorHistorialRecorridos = '/conductor/recorridos/historial';
  static const String conductorChecklist = '/conductor/checklist';
  static const String conductorHistorialChecklist = '/conductor/checklist/historial'; // ✅ NUEVA
  static const String conductorMantenimientos = '/conductor/mantenimientos';
  static const String conductorFallas = '/conductor/fallas';
  static const String conductorHistorialFallas = '/conductor/fallas/historial';
  static const adminReportes = '/admin-reportes';
}