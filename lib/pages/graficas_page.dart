import 'package:flutter/material.dart';

// misma paleta que el resto
const morado = Color(0xFFA18CD1);
const azul = Color(0xFF758EB7);

class GraficasPage extends StatelessWidget {
  const GraficasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              'Explora el comportamiento de tus contenedores y clientes con visualizaciones.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  final charts = [
                    _chartCard(
                      context,
                      title: 'Ocupación de contenedores',
                      subtitle: 'Relación entre contenedores ocupados y libres.',
                      icon: Icons.stacked_bar_chart_rounded,
                      accent: morado,
                    ),
                    _chartCard(
                      context,
                      title: 'Clientes por tipo de membresía',
                      subtitle: 'Distribución entre membresía mensual y anual.',
                      icon: Icons.pie_chart_outline_rounded,
                      accent: azul,
                    ),
                    _chartCard(
                      context,
                      title: 'Pagos pendientes por mes',
                      subtitle: 'Tendencia de pagos sin completar.',
                      icon: Icons.show_chart_rounded,
                      accent: const Color(0xFFEE6C77),
                    ),
                  ];

                  if (isWide) {
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.4,
                      children: charts,
                    );
                  } else {
                    return ListView.separated(
                      itemCount: charts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, i) => charts[i],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            // Header con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
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
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Placeholder de gráfica
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (isDark ? Colors.white24 : Colors.black12),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.12),
                      accent.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aquí puedes agregar tu gráfica\n(barra, línea, pastel, etc.)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
