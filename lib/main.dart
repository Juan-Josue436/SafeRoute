import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importación de tus pantallas
import 'package:safe_route_app/screens/home_screen.dart';
import 'package:safe_route_app/screens/profile_screen.dart';
import 'package:safe_route_app/screens/report_screen.dart';
import 'package:safe_route_app/screens/guardians_screen.dart';
import 'package:safe_route_app/screens/route_selection_screen.dart';
// Asegúrate de crear estos archivos para el login y registro
import 'package:safe_route_app/screens/login_screen.dart';
import 'package:safe_route_app/screens/register_screen.dart';

void main() async {
  // 1. Necesario para inicializar Firebase antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Firebase
  await Firebase.initializeApp();

  runApp(const SafeRouteApp());
}

// Configuración de las rutas
final GoRouter _router = GoRouter(
  // 3. Lógica de inicio: si no hay usuario, va a login. Si hay, va a home.
  initialLocation: FirebaseAuth.instance.currentUser == null ? '/login' : '/',

  routes: [
    // Rutas de Autenticación
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // Rutas Principales
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
        // Estilo global para botones para que se vea profesional
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}