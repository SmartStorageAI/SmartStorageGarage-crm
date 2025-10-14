import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/dashboard_page.dart';
import 'pages/clients_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SSCRMApp());
}

class SSCRMApp extends StatefulWidget {
  const SSCRMApp({super.key});

  @override
  State<SSCRMApp> createState() => _SSCRMAppState();
}

class _SSCRMAppState extends State<SSCRMApp> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ClientsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Storage CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: Scaffold(
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
              ],
            ),
            Expanded(
              child: pages[selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
