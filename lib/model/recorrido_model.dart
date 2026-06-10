class Recorrido {
  final String id;
  final String conductorId;
  final String vehiculoId;
  final DateTime fecha;
  final int kmInicial;
  final int kmFinal;
  final int distancia; // calculado automáticamente
  final String? observaciones;
  final String estado; // "Pendiente", "Completado"

  Recorrido({
    required this.id,
    required this.conductorId,
    required this.vehiculoId,
    required this.fecha,
    required this.kmInicial,
    required this.kmFinal,
    required this.distancia,
    this.observaciones,
    this.estado = "Completado",
  });

  // Convertir a JSON para enviar a Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conductorId': conductorId,
      'vehiculoId': vehiculoId,
      'fecha': fecha.toIso8601String(),
      'kmInicial': kmInicial,
      'kmFinal': kmFinal,
      'distancia': distancia,
      'observaciones': observaciones ?? '',
      'estado': estado,
    };
  }

  // Convertir desde JSON (desde Firebase)
  factory Recorrido.fromJson(Map<String, dynamic> json) {
    final kmInicial = json['kmInicial'] as int? ?? 0;
    final kmFinal = json['kmFinal'] as int? ?? 0;
    final distancia = (kmFinal - kmInicial).abs();

    return Recorrido(
      id: json['id'] as String? ?? '',
      conductorId: json['conductorId'] as String? ?? '',
      vehiculoId: json['vehiculoId'] as String? ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      kmInicial: kmInicial,
      kmFinal: kmFinal,
      distancia: distancia,
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] as String? ?? 'Completado',
    );
  }

  // Copiar con cambios
  Recorrido copyWith({
    String? id,
    String? conductorId,
    String? vehiculoId,
    DateTime? fecha,
    int? kmInicial,
    int? kmFinal,
    int? distancia,
    String? observaciones,
    String? estado,
  }) {
    final newKmInicial = kmInicial ?? this.kmInicial;
    final newKmFinal = kmFinal ?? this.kmFinal;
    final newDistancia = (newKmFinal - newKmInicial).abs();

    return Recorrido(
      id: id ?? this.id,
      conductorId: conductorId ?? this.conductorId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fecha: fecha ?? this.fecha,
      kmInicial: newKmInicial,
      kmFinal: newKmFinal,
      distancia: newDistancia,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
    );
  }
}