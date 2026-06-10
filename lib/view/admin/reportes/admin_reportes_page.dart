import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import 'package:carmanten/controller/reportes_controller.dart';

class AdminReportesPage extends StatefulWidget {
  const AdminReportesPage({super.key});

  @override
  State<AdminReportesPage> createState() => _AdminReportesPageState();
}

class _AdminReportesPageState extends State<AdminReportesPage> {
  late final AdminReportesController controller;

  final List<String> tipoOptions = ['Todos', 'Preventivo', 'Correctivo'];
  final List<String> estadoOptions = ['Todos', 'Completado', 'No completado'];

  @override
  void initState() {
    super.initState();
    controller = AdminReportesController();
    controller.addListener(_onControllerChanged);
    controller.loadData();
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  // helpers
  double _safeToDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _normalizeEstado(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s == 'completado' || s == 'completado.' || s == 'finalizado' || s == 'terminado') return 'Completado';
    return 'No completado';
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedFrom ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) controller.setDateRange(picked, controller.selectedTo);
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedTo ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) controller.setDateRange(controller.selectedFrom, picked);
  }

  void _clearFilters() => controller.clearFilters();

  // PDF generation (uses controller.filteredData)
  Future<void> generarPDF({
    String? tipo,
    String? estado,
    String? vehiculo,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = controller.filteredData(tipo: tipo, estado: estado, vehiculo: vehiculo, from: from, to: to);
    final formatter = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final f = from ?? controller.selectedFrom;
    final t = to ?? controller.selectedTo;
    final headerFechaRange = (f == null && t == null)
        ? 'Todas las fechas'
        : '${f != null ? formatter.format(f) : '...'} - ${t != null ? formatter.format(t) : '...'}';
    final tipoUsed = tipo ?? controller.selectedTipo;
    final estadoUsed = estado ?? controller.selectedEstado;
    final vehiculoUsed = vehiculo ?? controller.selectedVehiculo;
    final totalItems = rows.length;
    final totalCost = controller.computeTotalCost(rows);

    final pdf = pw.Document();

    // ONLY CHANGE: replace "Estado" column with "Piezas Cambiadas" and use piezasCambiadas field
    final tableHeaders = ['Placa', 'Tipo', 'Fecha', 'Piezas Cambiadas', 'Costo'];

    final tableData = rows.map((m) {
      DateTime? fecha;
      final raw = m['fechaProgramada'];
      if (raw is String) fecha = DateTime.tryParse(raw);
      if (raw is Timestamp) fecha = raw.toDate();
      final fechaStr = fecha != null ? formatter.format(fecha) : '';
      final tipoStr = (m['tipoMantenimiento'] ?? '').toString();

      // Read piezasCambiadas from DB and format it safely (supports String, bool, List, Map, etc.)
      final dynamic piezasRaw = m['piezasCambiadas'];
      String piezasStr = '';
      try {
        if (piezasRaw == null) {
          piezasStr = '';
        } else if (piezasRaw is String) {
          piezasStr = piezasRaw;
        } else if (piezasRaw is bool) {
          piezasStr = piezasRaw ? 'Sí' : 'No';
        } else if (piezasRaw is List) {
          piezasStr = piezasRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
        } else if (piezasRaw is Map) {
          piezasStr = piezasRaw.entries.map((e) => '${e.key}:${e.value}').join(', ');
        } else {
          piezasStr = piezasRaw.toString();
        }
      } catch (_) {
        piezasStr = piezasRaw?.toString() ?? '';
      }

      final placaStr = (m['_placa_display'] as String?) ?? 'Sin Placa';
      final costo = 'S/ ${_safeToDouble(m['precio']).toStringAsFixed(2)}';
      return [placaStr, tipoStr, fechaStr, piezasStr, costo];
    }).toList();

    final headerBg = pw.BoxDecoration(color: PdfColors.teal800);
    final titleStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final subtitleStyle = pw.TextStyle(fontSize: 8, color:  PdfColor.fromInt(0xB3FFFFFF));
    final statTitle = pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF616161));
    final statValue = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) {
          return pw.Container(
            decoration: headerBg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('REPORTE DE MANTENIMIENTOS', style: titleStyle),
                pw.SizedBox(height: 4),
                pw.Text('Tipo: $tipoUsed  |  Estado: $estadoUsed  |  Vehículo: $vehiculoUsed', style: subtitleStyle),
                pw.Text('Fechas: $headerFechaRange', style: subtitleStyle),
                pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}', style: subtitleStyle),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          );
        },
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfStatBox(
                'Total registros',
                '$totalItems',
                statTitle,
                statValue,
              ),

              pw.SizedBox(width: 16), // 🔹 Mayor separación

              _pdfStatBox(
                'Costo total',
                'S/ ${totalCost.toStringAsFixed(2)}',
                statTitle,
                statValue,
              ),

              pw.SizedBox(width: 16), // 🔹 Mayor separación

              _pdfStatBox(
                'Filtro placa',
                vehiculoUsed,
                statTitle,
                statValue,
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
            child: pw.Table.fromTextArray(
              headers: tableHeaders,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: PdfColors.teal800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              data: tableData,
              oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.7),
              },
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Totales por tipo (filtrados):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          _buildTotalsByType(rows),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reporte_mantenimientos_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await file.readAsBytes(), filename: file.path.split('/').last);
  }

  pw.Widget _pdfStatBox(String title, String value, pw.TextStyle titleStyle, pw.TextStyle valueStyle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: 150,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: titleStyle),
        pw.SizedBox(height: 4),
        pw.Text(value, style: valueStyle),
      ]),
    );
  }

  pw.Widget _buildTotalsByType(List<Map<String, dynamic>> rows) {
    final Map<String, double> costByType = {};
    final Map<String, int> countByType = {};

    for (var m in rows) {
      final tipo = (m['tipoMantenimiento'] ?? 'Sin tipo').toString();
      final precio = _safeToDouble(m['precio']);
      costByType[tipo] = (costByType[tipo] ?? 0) + precio;
      countByType[tipo] = (countByType[tipo] ?? 0) + 1;
    }

    final List<pw.Widget> items = [];
    costByType.forEach((tipo, costo) {
      items.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(tipo, style: const pw.TextStyle(fontSize: 9)),
          pw.Text('${countByType[tipo] ?? 0}  |  S/ ${costo.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
        ]),
      ));
    });

    if (items.isEmpty) return pw.Text('No hay registros con los filtros aplicados.', style: const pw.TextStyle(fontSize: 9));

    return pw.Column(children: items);
  }

  Widget _buildFilterRow({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(fontSize: 13)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(icon, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _card(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- NUEVO: totales de precio por tipo -----------------
  Map<String, double> _costsByType(List<Map<String, dynamic>> rows) {
    final Map<String, double> costs = {'Preventivo': 0.0, 'Correctivo': 0.0};
    for (var m in rows) {
      final tipo = (m['tipoMantenimiento'] ?? 'Sin tipo').toString().trim();
      final precio = _safeToDouble(m['precio']);
      if (tipo.toLowerCase().startsWith('prevent')) {
        costs['Preventivo'] = costs['Preventivo']! + precio;
      } else if (tipo.toLowerCase().startsWith('correct')) {
        costs['Correctivo'] = costs['Correctivo']! + precio;
      } else {
        // Si hay otros tipos, se pueden sumar a uno de los dos o ignorar. Por ahora ignoramos.
      }
    }
    return costs;
  }

  String _formatCurrency(double v) => 'S/ ${v.toStringAsFixed(2)}';
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Defensive: ensure the controller exists and has options; keep using loading guard
    if (controller.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Current safe selected values (in case controller.selectedX is stale / not in options)
    final safeSelectedTipo = tipoOptions.contains(controller.selectedTipo) ? controller.selectedTipo : 'Todos';
    final safeSelectedEstado = estadoOptions.contains(controller.selectedEstado) ? controller.selectedEstado : 'Todos';
    final vehiculoOptions = controller.vehiculoOptions.isNotEmpty ? controller.vehiculoOptions : ['Todos'];
    final safeSelectedVehiculo = vehiculoOptions.contains(controller.selectedVehiculo) ? controller.selectedVehiculo : 'Todos';

    final dateFormatter = DateFormat('dd/MM/yyyy');

    // --- NUEVO: calculamos totales de precio por tipo usando los datos filtrados ---
    final filteredRowsForPrices = controller.filteredData(
      tipo: safeSelectedTipo,
      estado: safeSelectedEstado,
      vehiculo: safeSelectedVehiculo,
      from: controller.selectedFrom,
      to: controller.selectedTo,
    );
    final costs = _costsByType(filteredRowsForPrices);
    final preventivoCost = costs['Preventivo'] ?? 0.0;
    final correctivoCost = costs['Correctivo'] ?? 0.0;
    final maxCost = [preventivoCost, correctivoCost].reduce((a, b) => a > b ? a : b);
    final maxYPriceBar = (maxCost <= 0) ? 1.0 : (maxCost * 1.15); // margen 15%
    final interval = (maxYPriceBar / 4).clamp(1.0, double.infinity);
    // -----------------------------------------------------------------------------------

    final mp = controller.mantenimientosPorTipoYEstado(
      tipo: safeSelectedTipo,
      estado: safeSelectedEstado,
      vehiculo: safeSelectedVehiculo,
      from: controller.selectedFrom,
      to: controller.selectedTo,
    );
    if (!mp.containsKey('Preventivo')) mp['Preventivo'] = {'Completado': 0, 'No completado': 0};
    if (!mp.containsKey('Correctivo')) mp['Correctivo'] = {'Completado': 0, 'No completado': 0};

    final allValues = [...mp['Preventivo']!.values, ...mp['Correctivo']!.values];
    final maxBar = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0;
    final maxYBar = (maxBar + 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Mantenimiento'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // FILTROS UI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Filtros para Reportes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 18),

                  // Tipo / Estado
                  Row(children: [
                    Expanded(
                      child: Row(children: [
                        const Text('Tipo: ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: safeSelectedTipo,
                            items: tipoOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) {
                              if (v != null) controller.setTipoFilter(v);
                            },
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(children: [
                        const Text('Estado: ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: safeSelectedEstado,
                            items: estadoOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) {
                              if (v != null) controller.setEstadoFilter(v);
                            },
                          ),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Vehículo (Placa) Dropdown - defensive value
                  Row(children: [
                    const Text('Vehículo (Placa): ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: safeSelectedVehiculo,
                        items: vehiculoOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) {
                          if (v != null) controller.setVehiculoFilter(v);
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Fecha Desde / Hasta y limpiar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFilterRow(
                        label: 'Desde',
                        value: controller.selectedFrom != null ? dateFormatter.format(controller.selectedFrom!) : '...',
                        onTap: _pickFromDate,
                        icon: Icons.calendar_today,
                      ),
                      _buildFilterRow(
                        label: 'Hasta',
                        value: controller.selectedTo != null ? dateFormatter.format(controller.selectedTo!) : '...',
                        onTap: _pickToDate,
                        icon: Icons.calendar_today,
                      ),
                      Tooltip(
                        message: 'Limpiar Filtros',
                        child: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearFilters,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Generar reporte PDF
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar Reporte PDF', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        try {
                          // Use the safe selected values when generating PDF
                          await generarPDF(
                            tipo: safeSelectedTipo,
                            estado: safeSelectedEstado,
                            vehiculo: safeSelectedVehiculo,
                            from: controller.selectedFrom,
                            to: controller.selectedTo,
                          );
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
                        }
                      },
                    ),
                  )
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // KPIs
            Row(children: [
              _card('Mantenimientos', controller.totalMantenimientosAll.toString()),
              const SizedBox(width: 12),
              _card('Costo Total', 'S/ ${controller.totalCostosAll.toStringAsFixed(2)}'),
            ]),

            const SizedBox(height: 30),

            // --- REEMPLAZO: gráfico de precios por tipo (Preventivo vs Correctivo) HORIZONTAL ---
            const Align(alignment: Alignment.centerLeft, child: Text('Pago por tipo de mantenimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
              // altura suficiente para 2 barras + ticks
              height: 122,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bars
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final barAreaWidth = constraints.maxWidth - 120; // reservar espacio para labels
                      final maxVal = maxCost <= 0 ? 1.0 : maxCost;
                      // función auxiliar para construir cada fila de barra
                      Widget buildBarRow(String label, double value, Color color) {
                        final fraction = (maxVal == 0) ? 0.0 : (value / maxVal).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: fraction,
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        alignment: Alignment.centerLeft,
                                        child: Text(_formatCurrency(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildBarRow('Preventivo', preventivoCost, Colors.teal),
                          buildBarRow('Correctivo', correctivoCost, Colors.orange.shade700),
                          const Spacer(),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Align(alignment: Alignment.centerLeft, child: Text('Mantenimientos por tipo y estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal))),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
              height: 280,
              child: BarChart(
                BarChartData(
                  maxY: maxYBar,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barsSpace: 6, barRods: [
                      BarChartRodData(toY: mp['Preventivo']?['Completado']?.toDouble() ?? 0, color: Colors.green.shade600, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
                      BarChartRodData(toY: mp['Preventivo']?['No completado']?.toDouble() ?? 0, color: Colors.red.shade600, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
                    ]),
                    BarChartGroupData(x: 1, barsSpace: 6, barRods: [
                      BarChartRodData(toY: mp['Correctivo']?['Completado']?.toDouble() ?? 0, color: Colors.green.shade600, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
                      BarChartRodData(toY: mp['Correctivo']?['No completado']?.toDouble() ?? 0, color: Colors.red.shade600, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 11)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Preventivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                        case 1:
                          return const Text('Correctivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                        default:
                          return const Text('');
                      }
                    })),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, horizontalInterval: 1),
                ),
              ),
            ),

            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_legendItem(Colors.green.shade600, 'Completados'), const SizedBox(width: 20), _legendItem(Colors.red.shade600, 'No completados')]),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // getters (si se usan en otras partes)
  double get maxYBar {
    final mp = controller.mantenimientosPorTipoYEstado(tipo: controller.selectedTipo, estado: controller.selectedEstado, vehiculo: controller.selectedVehiculo, from: controller.selectedFrom, to: controller.selectedTo);
    final all = [...mp['Preventivo']!.values, ...mp['Correctivo']!.values];
    final maxBar = all.isNotEmpty ? all.reduce((a, b) => a > b ? a : b) : 0;
    return (maxBar + 1).toDouble();
  }
}