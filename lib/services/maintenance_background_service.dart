// 📁 lib/services/maintenance_background_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';

class MaintenanceBackgroundService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Inicializar el servicio de fondo
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    if (Platform.isAndroid) {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: true,
          autoStart: true,
        ),
        iosConfiguration: IosConfiguration(
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    }

    service.startService();
    print('✅ Servicio de mantenimiento inicializado');
  }

  /// 🔄 Función que se ejecuta en el fondo
  static void onStart(ServiceInstance service) async {
    print('🚀 Servicio iniciado en segundo plano');

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // 🔄 Ejecutar verificación cada 1 hora
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Ejecutar cada 60 minutos
    Future.delayed(Duration.zero, () async {
      while (true) {
        print('⏰ Verificando mantenimientos programados...');
        await _verificarYActualizarMantenimientos();
        await Future.delayed(Duration(hours: 1));
      }
    });
  }

  /// iOS Background Task
  static Future<bool> onIosBackground(ServiceInstance service) async {
    print('🔄 Ejecutando tarea de fondo en iOS');
    await _verificarYActualizarMantenimientos();
    return true;
  }

  /// 🔧 FUNCIÓN PRINCIPAL - Verificar y actualizar estado de vehículos
  static Future<void> _verificarYActualizarMantenimientos() async {
    try {
      final ahora = DateTime.now();

      // Definir inicio y fin del día actual
      final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
      final finalDelDia = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

      print('📅 Buscando mantenimientos para: ${inicioDelDia.toLocal()}');

      // 1️⃣ Obtener mantenimientos programados para HOY
      final querySnapshot = await _firestore
          .collection('mantenimientos')
          .where(
        'fechaProgramada',
        isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia),
      )
          .where(
        'fechaProgramada',
        isLessThanOrEqualTo: Timestamp.fromDate(finalDelDia),
      )
          .get();

      // Filtrar mantenimientos no completados
      final docsNotCompleted = querySnapshot.docs
          .where((doc) => doc['estado'] != 'Completado')
          .toList();

      print('📋 Mantenimientos encontrados: ${docsNotCompleted.length}');

      if (docsNotCompleted.isEmpty) {
        print('✅ No hay mantenimientos para hoy');
        return;
      }

      // 2️⃣ Para cada mantenimiento, actualizar el vehículo
      for (final doc in docsNotCompleted) {
        final mantenimiento = doc.data();
        final vehiculoId = mantenimiento['vehiculoId'] as String;
        final estado = mantenimiento['estado'] as String?;

        print('🔧 Procesando vehículo: $vehiculoId (Estado: $estado)');

        if (estado != 'Completado') {
          final vehiculoDoc = await _firestore
              .collection('vehiculos')
              .doc(vehiculoId)
              .get();

          if (vehiculoDoc.exists) {
            final estadoActual = vehiculoDoc['estado'] as String?;

            if (estadoActual != 'En mantenimiento') {
              // ✅ Cambiar a "En mantenimiento"
              await _firestore
                  .collection('vehiculos')
                  .doc(vehiculoId)
                  .update({
                'estado': 'En mantenimiento',
                'fechaUltimaActualizacion': DateTime.now(),
              });

              // Registrar en el mantenimiento que fue actualizado
              await _firestore
                  .collection('mantenimientos')
                  .doc(doc.id)
                  .update({
                'estadoVehiculoActualizado': true,
                'fechaActualizacionVehiculo': DateTime.now(),
              });

              print('✅ Vehículo $vehiculoId cambiado a "En mantenimiento"');
            }
          }
        }
      }

      // 3️⃣ Verificar mantenimientos completados y cambiar a "Activo"
      await _revertirvehiculosCompletados();

    } catch (e) {
      print('❌ Error en _verificarYActualizarMantenimientos: $e');
    }
  }

  /// 🔄 Revertir vehículos a "Activo" después de completar mantenimiento
  static Future<void> _revertirvehiculosCompletados() async {
    try {
      print('🔄 Verificando mantenimientos completados...');

      final completadosSnapshot = await _firestore
          .collection('mantenimientos')
          .where('estado', isEqualTo: 'Completado')
          .where('estadoVehiculoActualizado', isEqualTo: true)
          .get();

      print(
        '✅ Mantenimientos completados encontrados: ${completadosSnapshot.docs.length}',
      );

      for (final doc in completadosSnapshot.docs) {
        final mantenimiento = doc.data();
        final vehiculoId = mantenimiento['vehiculoId'] as String;

        // Cambiar vehículo a "Activo"
        await _firestore
            .collection('vehiculos')
            .doc(vehiculoId)
            .update({
          'estado': 'Activo',
          'fechaUltimaActualizacion': DateTime.now(),
        });

        // Marcar como procesado
        await _firestore
            .collection('mantenimientos')
            .doc(doc.id)
            .update({
          'estadoVehiculoActualizado': false,
          'fechaActualizacionCompletada': DateTime.now(),
        });

        print('✅ Vehículo $vehiculoId cambiado a "Activo"');
      }
    } catch (e) {
      print('❌ Error en _revertirvehiculosCompletados: $e');
    }
  }

  /// ⏸️ Detener el servicio
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    print('⏹️ Servicio detenido');
  }
}