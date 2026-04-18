import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_route_app/screens/home_screen.dart';
import 'package:safe_route_app/screens/profile_screen.dart';
import 'package:safe_route_app/screens/report_screen.dart';
import 'package:safe_route_app/screens/guardians_screen.dart';
import 'package:safe_route_app/screens/route_selection_screen.dart';

void main() => runApp(const SafeRouteApp());

// Configuración de las rutas
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/routes', builder: (context, state) => const RouteSelectionScreen()),
    GoRoute(path: '/report', builder: (context, state) => const ReportScreen()),
    GoRoute(path: '/guardians', builder: (context, state) => const GuardiansScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);

class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SafeRoute',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
      ),
      routerConfig: _router,
    );
  }
}