import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 IMPORTANTE
import 'firebase_options.dart';

// Páginas del dashboard
import 'pages/dashboard_page.dart';
import 'pages/clients_page.dart';
import 'pages/containers_page.dart';

// Páginas de auth
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SSCRMApp());
}

class SSCRMApp extends StatelessWidget {
  const SSCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Storage CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
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
        '/dashboard': (context) => const DashboardShell(),
      },
    );
  }
}

/// Este widget es tu layout de antes con NavigationRail + páginas
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ClientsPage(),
    ContainersPage(),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir del CRM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Storage Garage CRM'),
        elevation: 0,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
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
            ],
            // 👇 Botón de SALIR abajo del todo
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Salir',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}
