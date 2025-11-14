import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Misma paleta del resto del CRM
const morado = Color(0xFFA18CD1);
const azul = Color(0xFF758EB7);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Streams en tiempo real
    final usersStream =
        FirebaseFirestore.instance.collection('users').snapshots();
    final containersStream =
        FirebaseFirestore.instance.collection('containers').snapshots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 NUEVO BANNER SUPERIOR
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [morado, azul],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: isWide ? 26 : 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenida a Smart Storage Garage CRM',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Visualiza de un vistazo cuántos clientes tienes, cuántos contenedores están ocupados y los pagos pendientes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 🔹 Métricas
                StreamBuilder<QuerySnapshot>(
                  stream: usersStream,
                  builder: (context, usersSnap) {
                    if (usersSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!usersSnap.hasData) {
                      return const Text(
                          'No se pudieron cargar los datos de clientes.');
                    }

                    final usersDocs = usersSnap.data!.docs;

                    // Total clientes
                    final totalClientes = usersDocs.length;

                    // Pagos pendientes: estadoPago == 'pendiente'
                    final pagosPendientes = usersDocs.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final estado = (data['estadoPago'] ?? '')
                          .toString()
                          .toLowerCase();
                      return estado == 'pendiente';
                    }).length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: containersStream,
                      builder: (context, contSnap) {
                        if (contSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!contSnap.hasData) {
                          return const Text(
                              'No se pudieron cargar los datos de contenedores.');
                        }

                        final contDocs = contSnap.data!.docs;

                        // Contenedores ocupados: status == true
                        final contOcupados = contDocs.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};
                          return (data['status'] ?? false) == true;
                        }).length;

                        // 🔹 Tarjetas
                        final cards = [
                          _buildStatCard(
                            context,
                            title: 'Clientes activos',
                            value: totalClientes.toString(),
                            icon: Icons.people_alt_rounded,
                            accent: morado,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Contenedores ocupados',
                            value: contOcupados.toString(),
                            icon: Icons.inventory_2_rounded,
                            accent: azul,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Pagos pendientes',
                            value: pagosPendientes.toString(),
                            icon: Icons.pending_actions_rounded,
                            accent: const Color(0xFFEE6C77),
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 24),
                                cards[i],
                              ],
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 16),
                                cards[i],
                              ],
                            ],
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔸 Tarjeta de métrica
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
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
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Iconito dentro de pill
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
