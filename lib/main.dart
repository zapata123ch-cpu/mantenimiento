import 'package:carmanten/test.dart';
import 'package:carmanten/view/admin/notificaciones/notificaciones_view.dart';
import 'package:carmanten/view/admin/vehiculos/AsignarConductorDialog.dart';
import 'package:carmanten/view/admin/vehiculos/detalle_vehiculo_view.dart';
import 'package:carmanten/view/admin/vehiculos/registrar_vehiculo_view.dart';
import 'package:carmanten/view/auth/registrar_view.dart';
import 'package:carmanten/view/conductor/checklist/historial_checklist_view.dart';
import 'package:carmanten/view/conductor/fallas/historial_fallas_view.dart';
import 'package:carmanten/view/conductor/mis_datos/documentos_personales_view.dart';
import 'package:carmanten/view/conductor/notificaciones/notificaciones_view.dart';
import 'package:carmanten/view/conductor/recorridos/historial_recorridos_view.dart';
import 'package:carmanten/view/splash/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:carmanten/services/simple_maintenance_checker.dart'; // ✅ AGREGAR


import 'package:carmanten/services/maintenance_background_service.dart'; // ✅ AGREGAR ESTA LÍNEA
import 'package:carmanten/view/admin/notificaciones/notificaciones_view.dart';
import 'package:carmanten/view/admin/vehiculos/AsignarConductorDialog.dart';
import 'package:carmanten/view/admin/reportes/admin_reportes_page.dart';

import 'controller/vehiculos_controller.dart';
import 'firebase_options.dart';

// Vistas
import 'package:carmanten/view/admin/dashboard_admin.dart';
import 'package:carmanten/view/admin/fallas/lista_fallas_view.dart';
import 'package:carmanten/view/admin/mantenimientos/supervisar_mantenimientos_view.dart';
import 'package:carmanten/view/admin/usuarios/lista_usuarios_view.dart';
import 'package:carmanten/view/admin/vehiculos/lista_vehiculos_view.dart';
import 'package:carmanten/view/auth/login_view.dart';
import 'package:carmanten/view/conductor/checklist/checklist_view.dart';
import 'package:carmanten/view/conductor/dashboard_conductor.dart';
import 'package:carmanten/view/conductor/fallas/reportar_falla_view.dart';
import 'package:carmanten/view/conductor/mantenimientos/programar_mantenimiento_view.dart';
import 'package:carmanten/view/conductor/mi_vehiculo/mi_vehiculo_view.dart';
import 'package:carmanten/view/conductor/mis_datos/mi_perfil_view.dart';
import 'package:carmanten/view/conductor/recorridos/registrar_recorrido_view.dart';

import 'model/vehiculo_model.dart';
import 'rutas/app_routes.dart';
import 'controller/auth_controller.dart';

Future<String?> _obtenerVehiculoDelConductor(String conductorId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('conductores').doc(conductorId).get();

    if (doc.exists) {
      final vehiculoId = doc.data()?['vehiculoId'] as String?;
      print('✅ Vehículo obtenido para conductor $conductorId: $vehiculoId');
      return vehiculoId;
    }
  } catch (e) {
    print('❌ Error obteniendo vehículo del conductor: $e');
  }
  return null;
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String> _initialRoute;
  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _initialRoute = _determinarRutaInicial();
  }

  Future<String> _determinarRutaInicial() async {
    try {
      print('🔍 Verificando sesión inicial...');
      await SimpleMaintenanceChecker.verificarMantenimientosHoy();

      // 1️⃣ PRIMERO: Verificar sesión guardada localmente
      print('📱 Verificando almacenamiento local...');
      final usuarioGuardado =
      await _authController.obtenerSesionGuardada();

      if (usuarioGuardado != null) {
        print('✅ Sesión guardada encontrada');
        final estado = usuarioGuardado.estado ?? '';
        final rol = usuarioGuardado.rol ?? '';

        print('📋 Estado: $estado');
        print('🔑 Rol: $rol');

        // Validar que la sesión siga siendo válida
        if (estado == 'Aprobado' && rol.isNotEmpty) {
          if (rol == 'Admin') {
            print('🎯 Navegando a Admin Dashboard (sesión guardada)');
            return AppRoutes.adminDashboard;
          }
          if (rol == 'Conductor') {
            print('🎯 Navegando a Conductor Dashboard (sesión guardada)');
            return AppRoutes.conductorDashboard;
          }
        }

        // Si la sesión guardada no es válida, limpiarla
        print('⚠️ Sesión guardada no válida, limpiando...');
        await _authController.limpiarSesionGuardada();
      }

      // 2️⃣ SEGUNDO: Verificar autenticación en Firebase
      print('🔐 Verificando autenticación en Firebase...');
      if (!_authController.estaAutenticado()) {
        print('❌ No hay usuario en Firebase');
        return AppRoutes.login;
      }

      print('✅ Usuario autenticado en Firebase');

      // 3️⃣ TERCERO: Obtener datos actuales de Firestore
      final usuario = await _authController.obtenerUsuarioActual();
      if (usuario == null) {
        print('❌ No se encontró usuario en Firestore');
        await _authController.logout();
        return AppRoutes.login;
      }

      final estado = usuario.estado ?? '';
      final rol = usuario.rol ?? '';

      print('📋 Estado: $estado');
      print('🔑 Rol: $rol');

      if (estado.isEmpty || estado == 'Pendiente' || estado == 'Rechazado') {
        print('⏳ Cuenta no aprobada');
        await _authController.logout();
        return AppRoutes.login;
      }

      if (rol.trim().isEmpty) {
        print('⏳ Rol sin asignar');
        await _authController.logout();
        return AppRoutes.login;
      }

      if (rol == 'Admin') {
        print('🎯 Navegando a Admin Dashboard');
        return AppRoutes.adminDashboard;
      }
      if (rol == 'Conductor') {
        print('🎯 Navegando a Conductor Dashboard');
        return AppRoutes.conductorDashboard;
      }

      print('❌ Rol desconocido: $rol');
      await _authController.logout();
      return AppRoutes.login;
    } catch (e) {
      print('❌ Error determinando ruta inicial: $e');
      return AppRoutes.login;
    }
  }

  Widget _obtenerHomePorRuta(String ruta) {
    switch (ruta) {
      case AppRoutes.adminDashboard:
        return const DashboardAdmin();
      case AppRoutes.conductorDashboard:
        return const DashboardConductor();
      case AppRoutes.login:
      default:
        return const LoginView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initialRoute,
      builder: (context, snapshot) {
        // Mientras carga, mostrar splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        // Cuando termina de cargar, obtener la ruta inicial
        final rutaInicial = snapshot.data ?? AppRoutes.login;
        print('🛩 Ruta inicial calculada: $rutaInicial');

        return MaterialApp(
          title: 'Gestión Vehicular',
          debugShowCheckedModeBanner: false,
          locale: const Locale('es', 'ES'),
          supportedLocales: const [
            Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _obtenerHomePorRuta(rutaInicial),
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.login: (context) => const LoginView(),
            AppRoutes.register: (context) => const RegistrarView(),
            AppRoutes.test: (context) => const TestNotificationView(),
            AppRoutes.adminDashboard: (context) => const DashboardAdmin(),
            AppRoutes.adminUsuarios: (context) => const ListaUsuariosView(),
            AppRoutes.adminVehiculos: (context) => const ListaVehiculosView(),
            AppRoutes.adminRegistrarVehiculo: (context) => const RegistrarVehiculoView(),
            AppRoutes.adminReportes: (context) => const AdminReportesPage(),
            AppRoutes.detalleVehiculo: (context) {
              final vehiculo = ModalRoute.of(context)?.settings.arguments as Vehiculo;
              return DetalleVehiculoView(vehiculo: vehiculo);
            },
            AppRoutes.asignarConductor: (context) {
              final vehiculo = ModalRoute.of(context)?.settings.arguments as Vehiculo;
              return AsignarConductorView(vehiculo: vehiculo);
            },
            AppRoutes.subirDocumentos: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar documentos'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final idUsuario = snapshot.data!;
                  return DocumentosPersonalesView(idUsuario: idUsuario);
                },
              );
            },
            AppRoutes.conductorHistorialChecklist: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar historial'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;

                  // Obtener el vehiculoId asignado al conductor
                  return FutureBuilder<String?>(
                    future: _obtenerVehiculoDelConductor(conductorId),
                    builder: (context, vehiculoSnapshot) {
                      if (vehiculoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final vehiculoId = vehiculoSnapshot.data ?? 'SIN_ASIGNAR';

                      return HistorialChecklistView(
                        conductorId: conductorId,
                        vehiculoId: vehiculoId,
                      );
                    },
                  );
                },
              );
            },
            AppRoutes.conductorNotificaciones: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar notificaciones'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;
                  print("🛠 Navegando a Notificaciones del conductor: $conductorId");
                  return NotificacionesView(usuarioActualId: conductorId);
                },
              );
            },
            AppRoutes.adminNotificaciones: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar alertas'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  print("🛠 Navegando a Alertas y Reportes");
                  return const AlertasAdminView();
                },
              );
            },
            AppRoutes.adminMantenimientos: (context) =>
            const SupervisarMantenimientosView(),
            AppRoutes.adminFallas: (context) => const ListaFallasView(),
            AppRoutes.conductorDashboard: (context) =>
            const DashboardConductor(),
            AppRoutes.conductorPerfil: (context) => const MiPerfilView(),
            AppRoutes.conductorVehiculo: (context) {
              final authController = AuthController();

              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar vehículo'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;
                  return MiVehiculoView(conductorId: conductorId);
                },
              );
            },
            AppRoutes.conductorRecorridos: (context) {
              final authController = AuthController();
              final vehiculoController = VehiculosController();

              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al obtener conductor'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;

                  // 🔧 OBTENER EL VEHÍCULO DEL CONDUCTOR
                  return FutureBuilder<Vehiculo?>(
                    future: vehiculoController.obtenerVehiculoDelConductor(conductorId),
                    builder: (context, vehiculoSnapshot) {
                      if (vehiculoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (vehiculoSnapshot.hasError || vehiculoSnapshot.data == null) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_alert_sharp, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                const Text('No tienes vehículo asignado'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Volver'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final vehiculo = vehiculoSnapshot.data!;
                      final vehiculoId = vehiculo.id; // ✅ UID DEL DOCUMENTO

                      // Validar que vehiculoId no sea nulo
                      if (vehiculoId == null || vehiculoId.isEmpty) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text('Error: ID del vehículo no válido'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Volver'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      print('🚗 Navegando a recorridos con:');
                      print('   - Conductor: $conductorId');
                      print('   - Vehículo ID: $vehiculoId');
                      print('   - Placa: ${vehiculo.placa}');

                      return RegistrarRecorridoView(
                        conductorId: conductorId,
                        vehiculoId: vehiculoId, // ✅ ID DEL DOCUMENTO, NO LA PLACA
                      );
                    },
                  );
                },
              );
            },// En el archivo main.dart, reemplaza esta sección:
            AppRoutes.conductorHistorialRecorridos: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar historial'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;
                  final vehiculoId = ModalRoute.of(context)?.settings.arguments as String? ?? '';

                  return HistorialRecorridosView(
                    conductorId: conductorId,
                    vehiculoId: vehiculoId,
                  );
                },
              );
            },
            AppRoutes.conductorChecklist: (context) {
              final authController = AuthController();
              final vehiculosCtrl = VehiculosController();

              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar checklist'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;

                  // ✅ Obtener el OBJETO completo del vehículo
                  return FutureBuilder<Vehiculo?>(
                    future: vehiculosCtrl.obtenerVehiculoDelConductor(conductorId),
                    builder: (context, vehiculoSnapshot) {
                      if (vehiculoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (vehiculoSnapshot.hasError || vehiculoSnapshot.data == null) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_alert_sharp, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                const Text('No tienes vehículo asignado'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Volver'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final vehiculo = vehiculoSnapshot.data!;
                      final vehiculoId = vehiculo.id; // ✅ ID del documento, no la placa

                      return ChecklistView(
                        conductorId: conductorId,
                        vehiculoId: vehiculoId ?? 'ERROR',
                      );
                    },
                  );
                },
              );
            },
            AppRoutes.conductorFallas: (context) {
              final authController = AuthController();
              final vehiculosCtrl = VehiculosController();

              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al obtener datos del conductor'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;

                  // ✅ Obtener el OBJETO completo del vehículo
                  return FutureBuilder<Vehiculo?>(
                    future: vehiculosCtrl.obtenerVehiculoDelConductor(conductorId),
                    builder: (context, vehiculoSnapshot) {
                      if (vehiculoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (vehiculoSnapshot.hasError || vehiculoSnapshot.data == null) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_alert_sharp, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                const Text('No tienes vehículo asignado'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Volver'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final vehiculo = vehiculoSnapshot.data!;
                      final vehiculoId = vehiculo.id; // ✅ ID del documento, no la placa

                      return ReportarFallaView(
                        vehiculoId: vehiculoId ?? 'ERROR',
                        conductorId: conductorId,
                      );
                    },
                  );
                },
              );
            },
            AppRoutes.conductorHistorialFallas: (context) {
              final authController = AuthController();
              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar historial'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;
                  return HistorialFallasView(conductorId: conductorId);
                },
              );
            },
            AppRoutes.conductorMantenimientos: (context) {
              final authController = AuthController();
              final vehiculosCtrl = VehiculosController();

              return FutureBuilder<String?>(
                future: authController.obtenerIdUsuarioActual(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al obtener datos'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final conductorId = snapshot.data!;

                  // ✅ Obtener el OBJETO completo del vehículo
                  return FutureBuilder<Vehiculo?>(
                    future: vehiculosCtrl.obtenerVehiculoDelConductor(conductorId),
                    builder: (context, vehiculoSnapshot) {
                      if (vehiculoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (vehiculoSnapshot.hasError || vehiculoSnapshot.data == null) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_alert_sharp, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                const Text('No tienes vehículo asignado'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Volver'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final vehiculo = vehiculoSnapshot.data!;
                      final vehiculoId = vehiculo.id; // ✅ ID del documento, no la placa

                      return ProgramarMantenimientoView(
                        vehiculoId: vehiculoId ?? 'ERROR',
                        conductorId: conductorId,
                      );
                    },
                  );
                },
              );
            },

          },
        );
      },
    );
  }
}