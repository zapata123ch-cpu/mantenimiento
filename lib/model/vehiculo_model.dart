class Vehiculo {
  final String? id;
  final String placa;
  final String marca;
  final String modelo;
  final int ano;
  final String color;

  // 🔹 ÚNICOS CAMPOS VÁLIDOS AHORA
  final List<String> conductores;
  final List<String> conductoresUIDs;

  final String estado;
  final int kilometrajeAcumulado;

  final Map<String, String>? documentosBase64;
  final List<String> documentos;

  final DateTime? fechaRegistro;

  Vehiculo({
    this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.color,
    this.conductores = const [],
    this.conductoresUIDs = const [],
    required this.estado,
    required this.kilometrajeAcumulado,
    this.documentosBase64,
    this.documentos = const [],
    this.fechaRegistro,
  });

  factory Vehiculo.fromMap(Map<String, dynamic> map, String docId) {
    // NOMBRES
    List<String> nombres = [];
    if (map['conductores'] is List) {
      nombres = List<String>.from(map['conductores']);
    }

    // UIDs
    List<String> uids = [];
    if (map['conductoresUIDs'] is List) {
      uids = List<String>.from(map['conductoresUIDs']);
    }

    return Vehiculo(
      id: docId,
      placa: map['placa'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      ano: map['ano'] ?? 0,
      color: map['color'] ?? '',
      conductores: nombres,
      conductoresUIDs: uids,
      estado: map['estado'] ?? 'Activo',
      kilometrajeAcumulado: map['kilometrajeAcumulado'] ?? 0,
      documentosBase64:
      map['documentosBase64'] != null ? Map<String, String>.from(map['documentosBase64']) : {},
      documentos: map['documentos'] != null ? List<String>.from(map['documentos']) : [],
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'color': color,
      'conductores': conductores,
      'conductoresUIDs': conductoresUIDs,
      'estado': estado,
      'kilometrajeAcumulado': kilometrajeAcumulado,
      'documentosBase64': documentosBase64,
      'documentos': documentos,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
    };
  }
}
