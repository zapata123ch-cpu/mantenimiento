// 📁 lib/services/simple_maintenance_checker.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleMaintenanceChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Verificar y actualizar estado de vehículos en mantenimiento
  /// Se ejecuta al iniciar la app
  static Future<void> verificarMantenimientosHoy() async {
    try {
      print('🔍 Verificando mantenimientos para HOY...');

      final ahora = DateTime.now();
      // Formato 'YYYY-MM-DD' para comparación
      final hoyFormato = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

      print('📅 Buscando mantenimientos para: $hoyFormato');

      // 1️⃣ Obtener TODOS los mantenimientos
      final mantSnapshot = await _firestore
          .collection('mantenimientos')
          .get();

      print('📋 Total de mantenimientos en DB: ${mantSnapshot.docs.length}');

      // 2️⃣ Filtrar mantenimientos que sean de HOY
      final mantHoy = <QueryDocumentSnapshot>[];

      for (final doc in mantSnapshot.docs) {
        try {
          final mantenimiento = doc.data() as Map<String, dynamic>;

          // ⚠️ CORRECCIÓN CLAVE: Leer como dynamic
          final dynamic rawFechaProgramada = mantenimiento['fechaProgramada'];
          final estado = mantenimiento['estado'] as String?; // Esto sigue siendo String

          if (rawFechaProgramada == null) {
            print('⚠️ Mantenimiento ${doc.id} sin fechaProgramada');
            continue;
          }

          DateTime fechaDt;
          // Convertir Timestamp (tipo real de Firestore) a DateTime
          if (rawFechaProgramada is Timestamp) {
            fechaDt = rawFechaProgramada.toDate();
          }
          // Manejo de fallback por si los datos son antiguos o inconsistentes
          else if (rawFechaProgramada is String) {
            fechaDt = DateTime.tryParse(rawFechaProgramada) ?? DateTime.now();
          } else {
            print('⚠️ Mantenimiento ${doc.id} tiene fechaProgramada de tipo inesperado: ${rawFechaProgramada.runtimeType}');
            continue;
          }

          // Formatear la fecha del documento a 'YYYY-MM-DD' para la comparación
          final fechaSoloFecha = '${fechaDt.year}-${fechaDt.month.toString().padLeft(2, '0')}-${fechaDt.day.toString().padLeft(2, '0')}';

          print('   Verificando: $fechaSoloFecha vs $hoyFormato (Estado: $estado)');

          // Si es de hoy y no está completado
          if (fechaSoloFecha == hoyFormato && estado != 'Completado') {
            mantHoy.add(doc);
            print('   ✅ Es de HOY!');
          }
        } catch (e) {
          print('   ❌ Error verificando mantenimiento: $e');
        }
      }

      print('📋 Mantenimientos encontrados para HOY: ${mantHoy.length}');

      if (mantHoy.isEmpty) {
        print('✅ No hay mantenimientos programados para hoy');
        return;
      }

      // 3️⃣ Para cada mantenimiento de hoy, actualizar el vehículo
      for (final doc in mantHoy) {
        try {
          final mantenimiento = doc.data() as Map<String, dynamic>;
          final vehiculoId = mantenimiento['vehiculoId'] as String?;
          final estado = mantenimiento['estado'] as String?;

          if (vehiculoId == null || vehiculoId.isEmpty) {
            print('⚠️ Mantenimiento sin vehiculoId: ${doc.id}');
            continue;
          }

          print('🔧 Procesando vehículo: $vehiculoId (Estado mant: $estado)');

          // Obtener estado actual del vehículo
          final vehiculoDoc = await _firestore
              .collection('vehiculos')
              .doc(vehiculoId)
              .get();

          if (vehiculoDoc.exists) {
            final estadoActual = vehiculoDoc['estado'] as String?;
            print('   → Estado actual del vehículo: $estadoActual');

            // Si el vehículo NO está en mantenimiento, cambiar a "En mantenimiento"
            if (estadoActual != 'En mantenimiento' && estado != 'Completado') {
              await _firestore
                  .collection('vehiculos')
                  .doc(vehiculoId)
                  .update({
                'estado': 'En mantenimiento',
                'fechaUltimaActualizacion': FieldValue.serverTimestamp(),
              });

              print('✅ ¡Vehículo $vehiculoId CAMBIÓ A "En mantenimiento"!');
            } else if (estadoActual == 'En mantenimiento') {
              print('ℹ️ Vehículo $vehiculoId ya está en mantenimiento');
            }
          } else {
            print('⚠️ Vehículo no encontrado: $vehiculoId');
          }
        } catch (e) {
          print('❌ Error procesando mantenimiento: $e');
        }
      }

      // 4️⃣ Verificar mantenimientos completados
      await _revertirVehiculosCompletados();

    } catch (e) {
      print('❌ Error en verificarMantenimientosHoy: $e');
    }
  }

  /// 🔄 Revertir vehículos a "Activo" después de completar mantenimiento
  static Future<void> _revertirVehiculosCompletados() async {
    try {
      print('🔄 Verificando mantenimientos completados...');

      final completadosSnapshot = await _firestore
          .collection('mantenimientos')
          .where('estado', isEqualTo: 'Completado')
          .get();

      print('Mantenimientos completados encontrados: ${completadosSnapshot.docs.length}');

      for (final doc in completadosSnapshot.docs) {
        try {
          final mantenimiento = doc.data() as Map<String, dynamic>;
          final vehiculoId = mantenimiento['vehiculoId'] as String?;

          if (vehiculoId == null || vehiculoId.isEmpty) continue;

          // Obtener estado actual del vehículo
          final vehiculoDoc = await _firestore
              .collection('vehiculos')
              .doc(vehiculoId)
              .get();

          if (vehiculoDoc.exists && vehiculoDoc['estado'] == 'En mantenimiento') {
            // Cambiar a "Activo"
            await _firestore
                .collection('vehiculos')
                .doc(vehiculoId)
                .update({
              'estado': 'Activo',
              'fechaUltimaActualizacion': FieldValue.serverTimestamp(),
            });

            print('✅ Vehículo $vehiculoId CAMBIÓ A "Activo" (mantenimiento completado)');
          }
        } catch (e) {
          print('❌ Error revertiendo vehículo: $e');
        }
      }
    } catch (e) {
      print('❌ Error en _revertirVehiculosCompletados: $e');
    }
  }
}