import 'package:flutter/material.dart';

class AsignarVehiculoView extends StatelessWidget {
  const AsignarVehiculoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Vehículo')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Pantalla para asignar o cambiar vehículo a un conductor. Muestra lista de vehículos disponibles y permite vincular conductor-vehículo con validación de asignaciones existentes.'),
          ],
        ),
      ),
    );
  }
}