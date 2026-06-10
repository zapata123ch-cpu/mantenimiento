class Notificacion {
  final String titulo;
  final String descripcion;
  final String icono;
  final String fecha;

  Notificacion({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.fecha,
  });

  factory Notificacion.fromFirestore(Map<String, dynamic> data) {
    return Notificacion(
      titulo: data['titulo'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      icono: data['icono'] as String? ?? '',
      fecha: data['fecha'] as String? ?? '',
    );
  }
}
