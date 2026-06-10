import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminReportesController extends ChangeNotifier {
  List<Map<String, dynamic>> data = [];
  bool loading = true;

  List<String> vehiculoOptions = ['Todos'];

  // Filtros manejados por el controlador
  String selectedTipo = 'Todos';
  String selectedEstado = 'Todos';
  String selectedVehiculo = 'Todos';
  String selectedVehiculoNorm = '';
  DateTime? selectedFrom;
  DateTime? selectedTo;

  // Debugging
  final bool enableDebug = true;

  AdminReportesController();

  /// Carga los mantenimientos y resuelve las placas de vehículo.
  /// Si [forceResolve] es true, intentará resolver de nuevo aunque ya existan opciones.
  Future<void> loadData({bool forceResolve = false}) async {
    loading = true;
    notifyListeners();

    try {
      if (enableDebug) debugPrint('[RPT] Cargando mantenimientos...');
      final snap = await FirebaseFirestore.instance.collection('mantenimientos').get();
      data = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data() as Map);
        m['_docId'] = d.id;
        return m;
      }).toList();

      // --- RECOLECTAR CANDIDATOS DE RESOLUCIÓN ---
      final Set<DocumentReference> docRefsToResolve = {};
      final Set<String> stringIdsToResolve = {};
      final Set<String> placaCandidates = {}; // strings que podrían ser placas
      final Map<String, dynamic> originalVehReferences = {}; // docId -> original veh field

      final candidateFields = <String>[
        'vehiculo',
        'vehiculoRef',
        'vehiculo_id',
        'vehiculoId',
        'idVehiculo',
        'id_vehiculo',
        'vehiculoDocument',
        'vehRef',
        'vehicle',
        'vehicleRef',
      ];

      for (final m in data) {
        final docId = m['_docId'] as String;
        dynamic veh;
        // Buscar en campos candidatos
        for (final f in candidateFields) {
          if (m.containsKey(f)) {
            veh = m[f];
            break;
          }
        }
        // Si no se encontró en campos candidatos, usar 'vehiculo' original (si existe)
        veh ??= m['vehiculo'];

        originalVehReferences[docId] = veh;

        if (veh == null) {
          // nada para resolver en este documento
          continue;
        }

        // DocumentReference
        if (veh is DocumentReference) {
          docRefsToResolve.add(veh);
          continue;
        }

        // String: puede ser path (colec/id), id, o placa
        if (veh is String) {
          final s = veh.trim();
          if (s.isEmpty) continue;

          if (s.contains('/')) {
            // Puede ser un path; intentar construir DocumentReference
            try {
              final path = s.startsWith('/') ? s.substring(1) : s;
              final ref = FirebaseFirestore.instance.doc(path);
              docRefsToResolve.add(ref);
              continue;
            } catch (_) {
              // si falla, tratar como posible placa o id
            }
          }

          // Si parece largo (>=20), probablemente sea un doc id (uid-like)
          if (s.length >= 20) {
            stringIdsToResolve.add(s);
          } else {
            // Corto: podría ser placa (ej: "ABC123") o id corto
            // Guardamos en ambas estructuras para intentar ambas resoluciones
            placaCandidates.add(s);
            stringIdsToResolve.add(s);
          }
          continue;
        }

        // Map: buscar claves comunes adentro
        if (veh is Map<String, dynamic>) {
          // Intentar extraer DocumentReference dentro del map
          try {
            // Si el map fue guardado como referencia serializada ("path")
            if (veh.containsKey('path') && veh['path'] is String) {
              final path = (veh['path'] as String).trim();
              if (path.isNotEmpty) {
                final ref = FirebaseFirestore.instance.doc(path.startsWith('/') ? path.substring(1) : path);
                docRefsToResolve.add(ref);
                continue;
              }
            }
          } catch (_) {}

          final keysForId = ['id', 'idVehiculo', 'vehiculoId', 'vehiculo_id', 'vehicleId'];
          bool found = false;
          for (final k in keysForId) {
            if (veh.containsKey(k) && veh[k] != null) {
              final val = veh[k].toString().trim();
              if (val.isNotEmpty) {
                if (val.contains('/')) {
                  try {
                    final ref = FirebaseFirestore.instance.doc(val.startsWith('/') ? val.substring(1) : val);
                    docRefsToResolve.add(ref);
                  } catch (_) {
                    stringIdsToResolve.add(val);
                  }
                } else {
                  if (val.length >= 20) stringIdsToResolve.add(val);
                  else {
                    // corto: puede ser placa
                    placaCandidates.add(val);
                    stringIdsToResolve.add(val);
                  }
                }
                found = true;
                break;
              }
            }
          }
          if (found) continue;

          // Si tiene campo de placa embebida
          final placaRoot = (veh['placa'] ?? veh['plate'] ?? veh['license'] ?? '').toString().trim();
          if (placaRoot.isNotEmpty) {
            placaCandidates.add(placaRoot);
            continue;
          }
        }

        // Otros tipos ignorados (se intentará fallback posterior)
      }

      if (enableDebug) {
        debugPrint('[RPT] docRefsToResolve=${docRefsToResolve.length} stringIdsToResolve=${stringIdsToResolve.length} placaCandidates=${placaCandidates.length}');
      }

      // --- RESOLVER DocumentReference(s) directamente ---
      final Map<String, String> resolvedByRefPathOrId = {}; // key: ref.path or ref.id -> placa
      if (docRefsToResolve.isNotEmpty) {
        if (enableDebug) debugPrint('[RPT] Resolviendo ${docRefsToResolve.length} DocumentReference(s) de vehiculos...');
        final futures = docRefsToResolve.map((ref) async {
          try {
            final doc = await ref.get();
            if (doc.exists) {
              final v = doc.data() as Map<String, dynamic>? ?? {};
              final placa = (v['placa'] ?? v['plate'] ?? v['license'] ?? '').toString().trim();
              if (placa.isNotEmpty) {
                resolvedByRefPathOrId[ref.path] = placa;
                resolvedByRefPathOrId[ref.id] = placa;
              } else {
                if (enableDebug) debugPrint('[RPT] Ref ${ref.path} existe pero no tiene campo "placa" conocido');
              }
            } else {
              if (enableDebug) debugPrint('[RPT] Ref ${ref.path} no existe');
            }
          } catch (e) {
            if (enableDebug) debugPrint('[RPT] Error leyendo DocumentReference ${ref.path}: $e');
          }
        }).toList();
        await Future.wait(futures);
      }

      // --- RESOLVER stringIdsToResolve en colección 'vehiculos' (y variantes) ---
      final Map<String, String> idToPlaca = {};
      if (stringIdsToResolve.isNotEmpty) {
        if (enableDebug) debugPrint('[RPT] Intentando resolver ${stringIdsToResolve.length} IDs en coleccion(es) de vehiculos...');

        // Si el id corresponde directamente a un doc en 'vehiculos' (o variantes), leemos.
        final possibleCollections = ['vehiculos', 'vehiculo', 'vehicles', 'vehicle', 'vehículos'];

        final futures = <Future>[];
        for (final id in stringIdsToResolve) {
          for (final col in possibleCollections) {
            futures.add(Future(() async {
              try {
                final doc = await FirebaseFirestore.instance.collection(col).doc(id).get();
                if (doc.exists) {
                  final v = doc.data() as Map<String, dynamic>? ?? {};
                  final placa = (v['placa'] ?? v['plate'] ?? v['license'] ?? '').toString().trim();
                  if (placa.isNotEmpty) {
                    idToPlaca[id] = placa;
                    if (enableDebug) debugPrint('[RPT] Resuelto id "$id" en coleccion "$col" => placa="$placa"');
                  }
                }
              } catch (e) {
                if (enableDebug) debugPrint('[RPT] Error leyendo $col/$id : $e');
              }
            }));
          }
        }
        await Future.wait(futures);
      }

      // --- RESOLVER placaCandidates buscando por campo 'placa' en colecciones posibles ---
      final Map<String, String> placaFoundByQuery = {}; // placa->placa (confirmación) o placa->docId
      if (placaCandidates.isNotEmpty) {
        if (enableDebug) debugPrint('[RPT] Buscando ${placaCandidates.length} candidatas a placa en colecciones de vehiculo...');
        final possibleCollections = ['vehiculos', 'vehiculo', 'vehicles', 'vehicle', 'vehículos'];

        final futures = <Future>[];
        for (final placa in placaCandidates) {
          for (final col in possibleCollections) {
            futures.add(Future(() async {
              try {
                // Primero intentamos igualdad directa por 'placa', 'plate' o 'license'
                final q1 = await FirebaseFirestore.instance.collection(col).where('placa', isEqualTo: placa).limit(1).get();
                if (q1.docs.isNotEmpty) {
                  final doc = q1.docs.first;
                  final p = (doc.data()['placa'] ?? placa).toString().trim();
                  placaFoundByQuery[placa] = p;
                  if (enableDebug) debugPrint('[RPT] Encontrada placa "$placa" en $col -> ${doc.id}');
                  return;
                }
                final q2 = await FirebaseFirestore.instance.collection(col).where('plate', isEqualTo: placa).limit(1).get();
                if (q2.docs.isNotEmpty) {
                  final doc = q2.docs.first;
                  final p = (doc.data()['plate'] ?? placa).toString().trim();
                  placaFoundByQuery[placa] = p;
                  if (enableDebug) debugPrint('[RPT] Encontrada plate "$placa" en $col -> ${doc.id}');
                  return;
                }
                final q3 = await FirebaseFirestore.instance.collection(col).where('license', isEqualTo: placa).limit(1).get();
                if (q3.docs.isNotEmpty) {
                  final doc = q3.docs.first;
                  final p = (doc.data()['license'] ?? placa).toString().trim();
                  placaFoundByQuery[placa] = p;
                  if (enableDebug) debugPrint('[RPT] Encontrada license "$placa" en $col -> ${doc.id}');
                  return;
                }
              } catch (e) {
                if (enableDebug) debugPrint('[RPT] Error buscando placa "$placa" en $col : $e');
              }
            }));
          }
        }
        await Future.wait(futures);
      }

      // --- ASIGNAR placaDisplay y normalizar a cada mantenimiento ---
      final Set<String> placasSet = {};

      for (final m in data) {
        String placaDisplay = 'Sin Placa';
        final String docId = m['_docId'];
        final veh = originalVehReferences[docId];

        bool resolved = false;

        try {
          // 1) Si veh es DocumentReference
          if (veh is DocumentReference) {
            final placa = resolvedByRefPathOrId[veh.path] ?? resolvedByRefPathOrId[veh.id];
            if (placa != null && placa.isNotEmpty) {
              placaDisplay = placa;
              resolved = true;
            }
          }

          // 2) Si veh es String
          else if (veh is String) {
            final s = veh.trim();
            if (s.contains('/')) {
              final key = s.startsWith('/') ? s.substring(1) : s;
              final placa = resolvedByRefPathOrId[key] ?? resolvedByRefPathOrId[s] ?? idToPlaca[s];
              if (placa != null && placa.isNotEmpty) {
                placaDisplay = placa;
                resolved = true;
              } else {
                // Intentar leer el doc path en tiempo de ejecución como fallback
                try {
                  final ref = FirebaseFirestore.instance.doc(key);
                  final doc = await ref.get();
                  if (doc.exists) {
                    final v = doc.data() as Map<String, dynamic>? ?? {};
                    final p = (v['placa'] ?? v['plate'] ?? v['license'] ?? '').toString().trim();
                    if (p.isNotEmpty) {
                      placaDisplay = p;
                      resolved = true;
                    }
                  }
                } catch (_) {}
              }
            } else {
              // s sin '/' puede ser id o placa corta
              final placaFromId = idToPlaca[s] ?? resolvedByRefPathOrId[s];
              if (placaFromId != null && placaFromId.isNotEmpty) {
                placaDisplay = placaFromId;
                resolved = true;
              } else {
                // comprobar si s fue detectada como placa candidata y encontrada por query
                final placaFromQuery = placaFoundByQuery[s];
                if (placaFromQuery != null && placaFromQuery.isNotEmpty) {
                  placaDisplay = placaFromQuery;
                  resolved = true;
                }
              }
            }
          }

          // 3) Si veh es Map
          else if (veh is Map<String, dynamic>) {
            final placaRoot = (veh['placa'] ?? veh['plate'] ?? veh['license'] ?? '').toString().trim();
            if (placaRoot.isNotEmpty) {
              placaDisplay = placaRoot;
              resolved = true;
            } else {
              // intentar extraer id dentro del map
              final keysForId = ['id', 'idVehiculo', 'vehiculoId', 'vehiculo_id'];
              for (final k in keysForId) {
                if (veh.containsKey(k) && (veh[k] != null)) {
                  final val = veh[k].toString().trim();
                  if (val.isNotEmpty) {
                    final placaFromId = idToPlaca[val] ?? resolvedByRefPathOrId[val] ?? placaFoundByQuery[val];
                    if (placaFromId != null && placaFromId.isNotEmpty) {
                      placaDisplay = placaFromId;
                      resolved = true;
                      break;
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          if (enableDebug) debugPrint('[RPT] Error intentando resolver placa para doc=$docId: $e');
        }

        // 4) Fallback: placa en el propio documento de mantenimiento
        if (!resolved) {
          final placaRoot = (m['placa'] ?? m['plate'] ?? m['license'] ?? '').toString().trim();
          if (placaRoot.isNotEmpty) {
            placaDisplay = placaRoot;
            resolved = true;
          } else {
            // última oportunidad: si el documento tiene algún string corto que parezca placa, tratar de usarlo
            for (final k in m.keys) {
              final v = m[k];
              if (v is String && v.length <= 10 && RegExp(r'[A-Za-z0-9]').hasMatch(v)) {
                // no sobrescribimos si ya se resolvió
                // (esto es heurístico y no siempre correcto)
                placaDisplay = v;
                break;
              }
            }
          }
        }

        if (placaDisplay.isEmpty) placaDisplay = 'Sin Placa';

        m['_placa_display'] = placaDisplay;
        m['_placa_norm'] = _normalizePlaca(placaDisplay);

        if (placaDisplay.isNotEmpty && placaDisplay != 'Sin Placa') {
          placasSet.add(placaDisplay);
        }

        if (enableDebug) {
          debugPrint('[RPT][loadData] doc=$docId => placaDisplay="${m['_placa_display']}" placaNorm="${m['_placa_norm']}" resolved=${placaDisplay != 'Sin Placa'}');
        }
      }

      // --- Construir lista final de opciones de placa ---
      final sorted = placasSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final newOptions = ['Todos', ...sorted];

      // Solo notificar si cambió (o si se forza)
      if (forceResolve || !listEquals(newOptions, vehiculoOptions)) {
        vehiculoOptions = newOptions;
        // Asegurar que el filtro actual siga siendo válido
        selectedVehiculo = vehiculoOptions.contains(selectedVehiculo) ? selectedVehiculo : 'Todos';
        selectedVehiculoNorm = selectedVehiculo == 'Todos' ? '' : _normalizePlaca(selectedVehiculo);
      }

      if (enableDebug) {
        debugPrint('[RPT] vehiculoOptions: ${vehiculoOptions.join(', ')}');
        debugPrint('[RPT] selectedVehiculo="$selectedVehiculo" selectedVehiculoNorm="$selectedVehiculoNorm"');
      }
    } catch (e) {
      if (enableDebug) debugPrint('[RPT] Error loading data: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // UTILIDADES
  double _safeToDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s) ?? 0.0;
  }

  String _normalizeEstado(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s == 'completado' || s == 'completado.' || s == 'finalizado' || s == 'terminado') return 'Completado';
    return 'No completado';
  }

  String _normalizeTipo(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.contains('prevent')) return 'Preventivo';
    if (s.contains('correct')) return 'Correctivo';
    if (s.isEmpty) return 'Sin tipo';
    return 'Otro Tipo';
  }

  String _normalizePlaca(String? placa) {
    if (placa == null) return '';
    final cleaned = placa.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
    return cleaned;
  }

  // FILTRADO con debug detallado
  List<Map<String, dynamic>> filteredData({
    String? tipo,
    String? estado,
    String? vehiculo,
    DateTime? from,
    DateTime? to,
  }) {
    final tipoFilter = (tipo ?? selectedTipo).trim();
    final estadoFilter = (estado ?? selectedEstado).trim();
    final vehiculoFilterDisplay = (vehiculo ?? selectedVehiculo).trim();
    final fromFilter = from ?? selectedFrom;
    final toFilter = to ?? selectedTo;
    final vehiculoFilterNorm = _normalizePlaca(vehiculoFilterDisplay);

    if (enableDebug) {
      debugPrint('[RPT][filteredData] tipo="$tipoFilter" estado="$estadoFilter" vehDisplay="$vehiculoFilterDisplay" vehNorm="$vehiculoFilterNorm" from=$fromFilter to=$toFilter');
    }

    return data.where((m) {
      final List<String> reasonsOut = [];

      // 1. Tipo
      final tipoNorm = _normalizeTipo(m['tipoMantenimiento']);
      if (tipoFilter != 'Todos' && tipoNorm != tipoFilter) {
        reasonsOut.add('tipo no coincide (registro="$tipoNorm" filtro="$tipoFilter")');
      }

      // 2. Estado
      final estadoNorm = _normalizeEstado(m['estado']);
      if (reasonsOut.isEmpty && estadoFilter != 'Todos' && estadoNorm != estadoFilter) {
        reasonsOut.add('estado no coincide (registro="$estadoNorm" filtro="$estadoFilter")');
      }

      // 3. Vehículo
      if (reasonsOut.isEmpty && vehiculoFilterDisplay != 'Todos') {
        final placaNorm = (m['_placa_norm'] as String?) ?? _normalizePlaca(_getPlaca(m) ?? '');
        if (placaNorm != vehiculoFilterNorm) {
          reasonsOut.add('placa no coincide (registro="$placaNorm" filtro="$vehiculoFilterNorm")');
        }
      }

      // 4. Fecha (Manejo seguro de Timestamp/String)
      DateTime? fecha;
      final raw = m['fechaProgramada'];
      if (raw is Timestamp) fecha = raw.toDate();
      else if (raw is String) fecha = DateTime.tryParse(raw);

      if (reasonsOut.isEmpty && fecha == null && (fromFilter != null || toFilter != null)) {
        reasonsOut.add('fecha null fuera de rango');
      }
      if (reasonsOut.isEmpty && fecha != null && !_fechaEnRango(fecha, fromFilter, toFilter)) {
        reasonsOut.add('fecha fuera de rango (fecha=$fecha)');
      }

      final include = reasonsOut.isEmpty;

      if (enableDebug) {
        debugPrint('[RPT][filter] doc=${m['_docId']} placaDisplay="${m['_placa_display']}" placaNorm="${m['_placa_norm']}" tipoNorm="$tipoNorm" include=$include ${include ? '' : 'reasons=${reasonsOut.join('; ')}'}');
      }

      return include;
    }).toList();
  }

  bool _fechaEnRango(DateTime fecha, DateTime? from, DateTime? to) {
    if (from != null) {
      final f = DateTime(from.year, from.month, from.day);
      if (fecha.isBefore(f)) return false;
    }
    if (to != null) {
      final t = DateTime(to.year, to.month, to.day, 23, 59, 59);
      if (fecha.isAfter(t)) return false;
    }
    return true;
  }

  int get totalMantenimientosAll => data.length;
  double get totalCostosAll => data.fold(0.0, (s, e) => s + _safeToDouble(e['precio']));
  double computeTotalCost(List<Map<String, dynamic>> rows) => rows.fold(0.0, (s, e) => s + _safeToDouble(e['precio']));

  Map<String, Map<String, int>> mantenimientosPorTipoYEstado({String? tipo, String? estado, String? vehiculo, DateTime? from, DateTime? to}) {
    final rows = filteredData(tipo: tipo, estado: estado, vehiculo: vehiculo, from: from, to: to);
    final Map<String, Map<String, int>> map = {
      'Preventivo': {'Completado': 0, 'No completado': 0},
      'Correctivo': {'Completado': 0, 'No completado': 0},
    };
    for (var m in rows) {
      final tipoKey = _normalizeTipo(m['tipoMantenimiento']);
      final estadoKey = _normalizeEstado(m['estado']);
      if (tipoKey == 'Preventivo' || tipoKey == 'Correctivo') {
        if (!map.containsKey(tipoKey)) map[tipoKey] = {'Completado': 0, 'No completado': 0};
        map[tipoKey]![estadoKey] = (map[tipoKey]![estadoKey] ?? 0) + 1;
      }
    }
    return map;
  }

  List<double> tendencia7diasValues({String? tipo, String? estado, String? vehiculo, DateTime? from, DateTime? to}) {
    final rows = filteredData(tipo: tipo, estado: estado, vehiculo: vehiculo, from: from, to: to);
    final now = DateTime.now();
    final Map<int, int> conteo = {for (int i = 0; i < 7; i++) i: 0};
    for (var m in rows) {
      final raw = m['fechaProgramada'];
      DateTime? fecha;
      if (raw is Timestamp) fecha = raw.toDate();
      else if (raw is String) fecha = DateTime.tryParse(raw);

      if (fecha == null) continue;

      final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
      final todayDia = DateTime(now.year, now.month, now.day);

      final diff = todayDia.difference(fechaDia).inDays;

      if (diff >= 0 && diff <= 6) {
        final index = 6 - diff;
        conteo[index] = (conteo[index] ?? 0) + 1;
      }
    }
    return List.generate(7, (i) => (conteo[i] ?? 0).toDouble());
  }

  void setTipoFilter(String tipo) {
    selectedTipo = tipo;
    notifyListeners();
  }

  void setEstadoFilter(String estado) {
    selectedEstado = estado;
    notifyListeners();
  }

  void setVehiculoFilter(String vehiculoDisplay) {
    selectedVehiculo = vehiculoDisplay;
    selectedVehiculoNorm = vehiculoDisplay == 'Todos' ? '' : _normalizePlaca(vehiculoDisplay);
    if (enableDebug) debugPrint('[RPT] setVehiculoFilter => "$selectedVehiculo" norm="$selectedVehiculoNorm"');
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    selectedFrom = from;
    selectedTo = to;
    notifyListeners();
  }

  void clearFilters() {
    selectedTipo = 'Todos';
    selectedEstado = 'Todos';
    selectedVehiculo = 'Todos';
    selectedVehiculoNorm = '';
    selectedFrom = null;
    selectedTo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Extrae placa: ahora solo prioriza el campo ya resuelto
  String? _getPlaca(Map<String, dynamic> m) {
    // Prioriza el campo que se resolvió en loadData
    final pd = (m['_placa_display'] as String?) ?? '';
    if (pd.isNotEmpty && pd != 'Sin Placa') return pd;

    // Fallback: intenta extraer directamente del documento si _placa_display falló
    try {
      final veh = m['vehiculo'];
      if (veh is Map<String, dynamic>) {
        final placa = (veh['placa'] ?? veh['plate'] ?? veh['license'] ?? '').toString().trim();
        if (placa.isNotEmpty) return placa;
      } else if (veh is String) {
        if (veh.trim().isNotEmpty) return veh.trim();
      }

      final placaRoot = (m['placa'] ?? m['plate'] ?? m['license'] ?? '').toString().trim();
      if (placaRoot.isNotEmpty) return placaRoot;
      return null;
    } catch (e) {
      if (enableDebug) debugPrint('[RPT] Error extrayendo placa: $e');
      return null;
    }
  }

  void dumpFirstRecords([int n = 10]) {
    final take = data.length < n ? data.length : n;
    for (int i = 0; i < take; i++) {
      final m = data[i];
      debugPrint('[RPT][dump] doc=${m['_docId']} placaDisplay="${m['_placa_display']}" placaNorm="${m['_placa_norm']}" tipo="${m['tipoMantenimiento']}" estado="${m['estado']}" fecha="${m['fechaProgramada']}" vehField="${m['vehiculo'] ?? 'null'}"');
    }
  }
}