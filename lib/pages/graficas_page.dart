import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// misma paleta que el resto
const morado = Color(0xFFA18CD1);
const azul = Color(0xFF758EB7);

enum _PeriodFilter { week, month }

class GraficasPage extends StatefulWidget {
  const GraficasPage({super.key});

  @override
  State<GraficasPage> createState() => _GraficasPageState();
}

class _GraficasPageState extends State<GraficasPage> {
  _PeriodFilter _period = _PeriodFilter.week;

  String _labelForPeriod(_PeriodFilter p) {
    switch (p) {
      case _PeriodFilter.week:
        return 'Semana actual';
      case _PeriodFilter.month:
        return 'Mes actual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Streams en tiempo real
    final containersStream =
        FirebaseFirestore.instance.collection('containers').snapshots();
    final usersStream =
        FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Gráficas y reportes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Visualiza tus contenedores, membresías y estados de pago con datos en tiempo real.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Selector de periodo (semana / mes)
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Periodo:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<_PeriodFilter>(
                  value: _period,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor:
                      isDark ? const Color(0xFF1C1F2A) : Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: _PeriodFilter.week,
                      child: Text('Semana actual'),
                    ),
                    DropdownMenuItem(
                      value: _PeriodFilter.month,
                      child: Text('Mes actual'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _period = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 Datos en tiempo real
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: containersStream,
                builder: (context, contSnap) {
                  if (contSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!contSnap.hasData) {
                    return const Center(
                      child: Text('No se pudieron cargar los contenedores.'),
                    );
                  }

                  // Rangos de fechas según periodo
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final startOfWeek =
                      today.subtract(Duration(days: today.weekday - 1));
                  final startOfMonth = DateTime(now.year, now.month, 1);

                  bool inRange(DateTime? date) {
                    if (date == null) return true; // si no hay createdAt, lo contamos
                    if (_period == _PeriodFilter.week) {
                      return !date.isBefore(startOfWeek);
                    } else {
                      return !date.isBefore(startOfMonth);
                    }
                  }

                  final contDocs = contSnap.data!.docs;

                  int ocupados = 0;
                  int libres = 0;
                  int totalContenedoresPeriodo = 0;

                  for (final doc in contDocs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    DateTime? created;
                    final raw = data['createdAt'];
                    if (raw is Timestamp) {
                      created = raw.toDate();
                    }

                    if (!inRange(created)) continue;

                    totalContenedoresPeriodo++;

                    final status = (data['status'] ?? false) == true;
                    if (status) {
                      ocupados++;
                    } else {
                      libres++;
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: usersStream,
                    builder: (context, usersSnap) {
                      if (usersSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!usersSnap.hasData) {
                        return const Center(
                          child: Text('No se pudieron cargar los clientes.'),
                        );
                      }

                      final usersDocs = usersSnap.data!.docs;

                      int mensual = 0;
                      int anual = 0;

                      int pagosPagados = 0;
                      int pagosPendientes = 0;
                      int pagosCancelados = 0;
                      int totalClientesPeriodo = 0;

                      for (final doc in usersDocs) {
                        final data =
                            doc.data() as Map<String, dynamic>? ?? {};

                        DateTime? created;
                        final raw = data['createdAt'];
                        if (raw is Timestamp) {
                          created = raw.toDate();
                        }

                        if (!inRange(created)) continue;

                        totalClientesPeriodo++;

                        final membresia =
                            (data['membresia'] ?? '').toString().toLowerCase();
                        if (membresia == 'mensual') {
                          mensual++;
                        } else if (membresia == 'anual') {
                          anual++;
                        }

                        final estado =
                            (data['estadoPago'] ?? '').toString().toLowerCase();
                        if (estado == 'pagado') {
                          pagosPagados++;
                        } else if (estado == 'pendiente') {
                          pagosPendientes++;
                        } else if (estado == 'cancelado') {
                          pagosCancelados++;
                        }
                      }

                      final isWide =
                          MediaQuery.of(context).size.width > 900;

                      final charts = [
                        _ocupacionContenedoresCard(
                          context,
                          ocupados: ocupados,
                          libres: libres,
                        ),
                        _membresiasCard(
                          context,
                          mensual: mensual,
                          anual: anual,
                        ),
                        _estadoPagosCard(
                          context,
                          pagados: pagosPagados,
                          pendientes: pagosPendientes,
                          cancelados: pagosCancelados,
                        ),
                      ];

                      final reportCard = _reportCard(
                        context,
                        periodoLabel: _labelForPeriod(_period),
                        totalContenedores: totalContenedoresPeriodo,
                        ocupados: ocupados,
                        libres: libres,
                        totalClientes: totalClientesPeriodo,
                        mensual: mensual,
                        anual: anual,
                        pagados: pagosPagados,
                        pendientes: pagosPendientes,
                        cancelados: pagosCancelados,
                      );

                      if (isWide) {
                        return Column(
                          children: [
                            // Gráficas
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 1.4,
                                children: charts,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Reporte
                            reportCard,
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: charts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (_, i) => charts[i],
                              ),
                            ),
                            const SizedBox(height: 16),
                            reportCard,
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD 1: Ocupación de contenedores (barras)
  Widget _ocupacionContenedoresCard(
    BuildContext context, {
    required int ocupados,
    required int libres,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = ocupados + libres;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: morado.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.stacked_bar_chart_rounded,
                    color: morado,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ocupación de contenedores',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Relación entre contenedores ocupados y libres en el periodo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin datos de contenedores.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    )
                  : _barChart(
                      context,
                      segments: [
                        _Segment(
                          label: 'Ocupados',
                          value: ocupados,
                          color: morado,
                        ),
                        _Segment(
                          label: 'Libres',
                          value: libres,
                          color: Colors.grey,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD 2: Clientes por membresía (barras)
  Widget _membresiasCard(
    BuildContext context, {
    required int mensual,
    required int anual,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = mensual + anual;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: azul.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: azul,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clientes por tipo de membresía',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Distribución entre membresía mensual y anual en el periodo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin datos de clientes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    )
                  : _barChart(
                      context,
                      segments: [
                        _Segment(
                          label: 'Mensual',
                          value: mensual,
                          color: azul,
                        ),
                        _Segment(
                          label: 'Anual',
                          value: anual,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD 3: Estado de pagos (barras)
  Widget _estadoPagosCard(
    BuildContext context, {
    required int pagados,
    required int pendientes,
    required int cancelados,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = pagados + pendientes + cancelados;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE6C77).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Color(0xFFEE6C77),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estado de pagos de clientes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Distribución entre pagados, pendientes y cancelados en el periodo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin datos de estado de pago.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    )
                  : _barChart(
                      context,
                      segments: [
                        _Segment(
                          label: 'Pagados',
                          value: pagados,
                          color: Colors.green,
                        ),
                        _Segment(
                          label: 'Pendientes',
                          value: pendientes,
                          color: Colors.amber,
                        ),
                        _Segment(
                          label: 'Cancelados',
                          value: cancelados,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔸 Gráfico de BARRAS VERTICALES simple y bonito
  Widget _barChart(
    BuildContext context, {
    required List<_Segment> segments,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (segments.isEmpty) {
      return Center(
        child: Text(
          'Sin datos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      );
    }

    int maxValue = 0;
    for (final seg in segments) {
      if (seg.value > maxValue) maxValue = seg.value;
    }
    if (maxValue == 0) {
      return Center(
        child: Text(
          'Sin datos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final seg in segments) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Valor arriba de la barra
                        Text(
                          seg.value.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Barra
                        Flexible(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 90 *
                                  (seg.value / maxValue
                                      .clamp(0.0, double.infinity)),
                              decoration: BoxDecoration(
                                color: seg.color.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: seg.color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Etiqueta
                        Text(
                          seg.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (seg != segments.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Card de reporte resumen
  Widget _reportCard(
    BuildContext context, {
    required String periodoLabel,
    required int totalContenedores,
    required int ocupados,
    required int libres,
    required int totalClientes,
    required int mensual,
    required int anual,
    required int pagados,
    required int pendientes,
    required int cancelados,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporte del $periodoLabel',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _reportLine(
              icon: Icons.inventory_2_rounded,
              color: morado,
              title:
                  'Contenedores en el periodo: $totalContenedores (Ocupados: $ocupados, Libres: $libres)',
            ),
            const SizedBox(height: 6),
            _reportLine(
              icon: Icons.people_alt_rounded,
              color: azul,
              title:
                  'Clientes en el periodo: $totalClientes (Mensual: $mensual, Anual: $anual)',
            ),
            const SizedBox(height: 6),
            _reportLine(
              icon: Icons.payments_rounded,
              color: const Color(0xFFEE6C77),
              title:
                  'Pagos → Pagados: $pagados, Pendientes: $pendientes, Cancelados: $cancelados',
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportLine({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

/// Modelo interno para cada barra
class _Segment {
  final String label;
  final int value;
  final Color color;

  _Segment({
    required this.label,
    required this.value,
    required this.color,
  });
}
