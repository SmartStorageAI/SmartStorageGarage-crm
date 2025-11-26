import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Páginas del dashboard
import 'pages/dashboard_page.dart';
import 'pages/clients_page.dart';
import 'pages/containers_page.dart';
import 'pages/graficas_page.dart'; // 👈 NUEVA
import 'pages/monitoreo_page.dart';

// Páginas de auth
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

// 🎨 Colores que usas en login / tablas
const morado = Color(0xFFA18CD1);
const azul = Color(0xFF758EB7);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SSCRMApp());
}

/// Ahora SSCRMApp es Stateful para poder guardar el ThemeMode
class SSCRMApp extends StatefulWidget {
  const SSCRMApp({super.key});

  @override
  State<SSCRMApp> createState() => _SSCRMAppState();
}

class _SSCRMAppState extends State<SSCRMApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF10141B),
    );

    return MaterialApp(
      title: 'Smart Storage CRM',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/login',
      routes: {
        // LOGIN
        '/login': (context) => LoginPage(
          onLoginSuccess: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          onGoToSignup: () {
            Navigator.pushReplacementNamed(context, '/signup');
          },
        ),

        // SIGNUP
        '/signup': (context) => SignupPage(
          onSignupSuccess: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          onGoToLogin: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),

        // DASHBOARD SHELL (layout con el NavigationRail)
        '/dashboard': (context) => DashboardShell(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
      },
    );
  }
}

/// Layout principal con barra lateral + páginas
class DashboardShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const DashboardShell({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ClientsPage(),
    ContainersPage(),
    GraficasPage(), // 👈 NUEVA PÁGINA
    MonitoreoPage(),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          // 👇 SIEMPRE claro, sin importar el tema
          backgroundColor: const Color(0xFFF5F7FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Cabecera morada
              Container(
                decoration: const BoxDecoration(
                  color: morado,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Mensaje
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  '¿Quieres salir del CRM?',
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),

              // 🔹 Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azul,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Barra lateral con degradado
          Container(
            width: 130,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [morado, azul],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              groupAlignment: -1.0,
              labelType: NavigationRailLabelType.all,

              // Iconos y textos en negro
              selectedIconTheme: const IconThemeData(
                color: Colors.black87,
                size: 26,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.black54,
                size: 24,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: const TextStyle(color: Colors.black54),

              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Inicio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Clientes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage),
                  label: Text('Contenedores'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Gráficas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('Monitoreo'),
                ),
              ],

              // 🔹 Toggle de tema + botón salir
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón de modo claro/oscuro
                    IconButton(
                      tooltip: widget.isDarkMode
                          ? 'Cambiar a modo claro'
                          : 'Cambiar a modo oscuro',
                      icon: Icon(
                        widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: const Color.fromARGB(106, 0, 0, 0),
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Salir',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 Contenido principal
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
