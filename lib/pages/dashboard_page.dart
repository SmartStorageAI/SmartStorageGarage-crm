import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/client.dart'; // 👈 tu modelo de clientes

// Misma paleta que todo el CRM
const morado = Color(0xFFA18CD1);
const azul = Color(0xFF758EB7);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Modelo simple para los resultados de búsqueda
class _SearchResult {
  final String titulo;
  final String subtitulo;
  final String tipo; // 'Cliente' o 'Contenedor';

  _SearchResult({
    required this.titulo,
    required this.subtitulo,
    required this.tipo,
  });
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<_SearchResult> _results = [];

  // 🔍 Llamada a Firestore para buscar en users + containers
  Future<void> _performSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchQuery = '';
        _results = [];
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final containersSnap =
          await FirebaseFirestore.instance.collection('containers').get();

      final List<_SearchResult> temp = [];

      // Buscar en clientes
      for (final doc in usersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final nombre = (data['nombre'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        if (nombre.toLowerCase().contains(q) ||
            email.toLowerCase().contains(q)) {
          temp.add(
            _SearchResult(
              titulo: nombre,
              subtitulo: email.isEmpty ? 'Cliente' : email,
              tipo: 'Cliente',
            ),
          );
        }
      }

      // Buscar en contenedores
      for (final doc in containersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final nombre = (data['nombre'] ?? '').toString();
        final cliente = (data['cliente'] ?? '').toString();
        if (nombre.toLowerCase().contains(q) ||
            cliente.toLowerCase().contains(q)) {
          temp.add(
            _SearchResult(
              titulo: nombre.isEmpty ? 'Contenedor' : nombre,
              subtitulo:
                  cliente.isEmpty ? 'Contenedor' : 'Cliente: $cliente',
              tipo: 'Contenedor',
            ),
          );
        }
      }

      setState(() {
        _results = temp;
      });
    } catch (e) {
      setState(() {
        _results = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Streams para las métricas (TIEMPO REAL)
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
                // 🔹 BANNER SUPERIOR
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
                        'Visualiza de un vistazo tus clientes, contenedores y pagos pendientes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔍 BARRA DE BÚSQUEDA
                TextField(
                  controller: _searchCtrl,
                  onChanged: _performSearch,   // se actualiza mientras escribes
                  onSubmitted: _performSearch, // y también al dar Enter
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente o contenedor...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                                _results = [];
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: morado, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                ),

                // 🔍 RESULTADOS DE BÚSQUEDA
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _isSearching
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _results.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No se encontraron resultados para tu búsqueda.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resultados (${_results.length}):',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._results.map((r) {
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              r.tipo == 'Cliente'
                                                  ? morado.withOpacity(0.2)
                                                  : azul.withOpacity(0.2),
                                          child: Icon(
                                            r.tipo == 'Cliente'
                                                ? Icons.person
                                                : Icons.storage,
                                            size: 18,
                                            color: r.tipo == 'Cliente'
                                                ? morado
                                                : azul,
                                          ),
                                        ),
                                        title: Text(r.titulo),
                                        subtitle: Text(r.subtitulo),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (r.tipo == 'Cliente'
                                                    ? morado
                                                    : azul)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            r.tipo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: r.tipo == 'Cliente'
                                                  ? morado
                                                  : azul,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 16),

                // 🔹 MÉTRICAS EN TIEMPO REAL
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

                    // Usamos tu modelo Client para evitar errores de campos
                    final clientes = usersDocs
                        .map((d) => Client.fromDoc(d))
                        .toList();

                    // Total clientes
                    final totalClientes = clientes.length;

                    // Pagos pendientes: clientes con estado "pendiente"
                    final pagosPendientes = clientes
                        .where((c) =>
                            c.estadoPago.toLowerCase() == 'pendiente')
                        .length;

                    // Con base en la LISTA de contenedores por cliente
                    final contenedoresPagados = clientes
                        .where((c) =>
                            c.estadoPago.toLowerCase() == 'pagado')
                        .fold<int>(
                            0,
                            (prev, c) =>
                                prev + (c.contenedores.length));

                    final contenedoresCancelados = clientes
                        .where((c) =>
                            c.estadoPago.toLowerCase() == 'cancelado')
                        .fold<int>(
                            0,
                            (prev, c) =>
                                prev + (c.contenedores.length));

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

                        // 🔹 Creamos todas las tarjetas
                        final cards = <Widget>[
                          _buildStatCard(
                            context,
                            title: 'Clientes activos',
                            value: totalClientes.toString(),
                            icon: Icons.people_alt_rounded,
                            accent: morado,
                            primary: true,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Contenedores ocupados',
                            value: contOcupados.toString(),
                            icon: Icons.inventory_2_rounded,
                            accent: azul,
                            primary: true,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Pagos pendientes',
                            value: pagosPendientes.toString(),
                            icon: Icons.pending_actions_rounded,
                            accent: const Color(0xFFEE6C77),
                            primary: true,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Contenedores pagados',
                            value: contenedoresPagados.toString(),
                            icon: Icons.check_circle_outline,
                            accent: Colors.green,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Contenedores cancelados',
                            value: contenedoresCancelados.toString(),
                            icon: Icons.cancel_outlined,
                            accent: Colors.redAccent,
                          ),
                        ];

                        Widget cardsLayout;
                        if (isWide) {
                          cardsLayout = Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                cards[i],
                              ],
                            ],
                          );
                        } else {
                          cardsLayout = Column(
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 16),
                                cards[i],
                              ],
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: cardsLayout,
                        );
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

  // 🔸 Tarjeta de métrica (sin textos extra)
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    bool primary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Compactas para que entren 5 en una fila
    final double width = primary ? 200 : 195;

    return Card(
      margin: EdgeInsets.zero,
      elevation: primary ? 8 : 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: SizedBox(
        width: width,
        height: 115, // misma altura para todas
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(primary ? 0.16 : 0.10),
                accent.withOpacity(primary ? 0.03 : 0.015),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Iconito dentro de pill
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
