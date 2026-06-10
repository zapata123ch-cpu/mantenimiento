class DocumentoModel {
  final String? id;
  final String idUsuario;
  final String tipoDocumento; // DNI, Licencia, Certificado de Inducción, Otros
  final String nombreArchivo;
  final String rutaArchivo;
  final String urlDocumento; // URL del documento almacenado
  final DateTime fechaCarga;
  final DateTime? fechaVencimiento;
  final String estado; // activo, vencido, pendiente_revision
  final String? observaciones;

  DocumentoModel({
    this.id,
    required this.idUsuario,
    required this.tipoDocumento,
    required this.nombreArchivo,
    required this.rutaArchivo,
    required this.urlDocumento,
    required this.fechaCarga,
    this.fechaVencimiento,
    this.estado = 'pendiente_revision',
    this.observaciones,
  });

  // Convertir desde JSON
  factory DocumentoModel.fromJson(Map<String, dynamic> json) {
    return DocumentoModel(
      id: json['id'] as String?,
      idUsuario: json['idUsuario'] as String,
      tipoDocumento: json['tipoDocumento'] as String,
      nombreArchivo: json['nombreArchivo'] as String,
      rutaArchivo: json['rutaArchivo'] as String,
      urlDocumento: json['urlDocumento'] as String,
      fechaCarga: DateTime.parse(json['fechaCarga'] as String),
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      estado: json['estado'] as String? ?? 'pendiente_revision',
      observaciones: json['observaciones'] as String?,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idUsuario': idUsuario,
      'tipoDocumento': tipoDocumento,
      'nombreArchivo': nombreArchivo,
      'rutaArchivo': rutaArchivo,
      'urlDocumento': urlDocumento,
      'fechaCarga': fechaCarga.toIso8601String(),
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'estado': estado,
      'observaciones': observaciones,
    };
  }

  // Copiar con cambios
  DocumentoModel copyWith({
    String? id,
    String? idUsuario,
    String? tipoDocumento,
    String? nombreArchivo,
    String? rutaArchivo,
    String? urlDocumento,
    DateTime? fechaCarga,
    DateTime? fechaVencimiento,
    String? estado,
    String? observaciones,
  }) {
    return DocumentoModel(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      urlDocumento: urlDocumento ?? this.urlDocumento,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  // Verificar si está vencido
  bool get estaVencido {
    if (fechaVencimiento == null) return false;
    return DateTime.now().isAfter(fechaVencimiento!);
  }

  // Días para vencimiento
  int? get diasParaVencimiento {
    if (fechaVencimiento == null) return null;
    return fechaVencimiento!.difference(DateTime.now()).inDays;
  }
}