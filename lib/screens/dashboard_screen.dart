import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import '../models/indicator_model.dart';
import '../widgets/indicador_card.dart';
import '../widgets/refresh_button.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'comparar_screen.dart';
import 'buscar_screen.dart'; //

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Indicator>> _indicadoresStream;
  bool _isReloading = false;

  late User _user;
  String userName = "";
  String userEmail = "";
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _indicadoresStream = _firestoreService.getIndicators('centro_madrid');
    _user = FirebaseAuth.instance.currentUser!;
    userEmail = _user.email ?? "No disponible";
    _loadUserData();

    AdaptiveTheme.getThemeMode().then((mode) {
      setState(() {
        _isDarkMode = mode == AdaptiveThemeMode.dark;
      });
    });
  }

  Future<void> _reloadIndicators() async {
    setState(() {
      _isReloading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _indicadoresStream = _firestoreService.getIndicators('centro_madrid');
      _isReloading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Datos actualizados'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    final appUser = await _firestoreService.getUserByUID(_user.uid);
    if (!mounted) return;
    if (appUser != null) {
      setState(() {
        userName = appUser.nombre;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _toggleTheme(bool isDark) {
    if (isDark) {
      AdaptiveTheme.of(context).setDark();
    } else {
      AdaptiveTheme.of(context).setLight();
    }
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                userName,
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                userEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1A237E)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF1A237E)),
            ),
            SwitchListTile(
              title: Text(
                'Modo oscuro',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              secondary: Icon(Icons.brightness_6, color: theme.iconTheme.color),
              value: _isDarkMode,
              onChanged: _toggleTheme,
            ),
            ListTile(
              title: Text(
                'Pantalla comparativa',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              leading: Icon(Icons.compare, color: theme.iconTheme.color),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompararScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              leading: Icon(Icons.logout, color: theme.iconTheme.color),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: theme.appBarTheme.foregroundColor,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 35,
              ), // <-- Añado padding derecho
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // <-- Alinear extremos
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Builder(
                              builder:
                                  (context) => IconButton(
                                    icon: const Icon(Icons.menu, size: 20),
                                    onPressed:
                                        () => Scaffold.of(context).openDrawer(),
                                    color: const Color(0xFF1A237E),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Buscar',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BuscarScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: RefreshButton(
                onPressed: _reloadIndicators,
                isLoading: _isReloading,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Indicator>>(
              stream: _indicadoresStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isReloading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error cargando indicadores: ${snapshot.error}',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  );
                }

                final indicadores = snapshot.data ?? [];

                if (indicadores.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay indicadores disponibles.',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: indicadores.length,
                  itemBuilder: (context, index) {
                    final indicador = indicadores[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: IndicadorCard(indicador: indicador),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
