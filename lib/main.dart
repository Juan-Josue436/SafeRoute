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
import 'package:safe_route_app/screens/login_screen.dart';
import 'package:safe_route_app/screens/register_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SafeRouteApp());
}

// CONFIGURACIÓN DE RUTAS REACTIVA
final GoRouter _router = GoRouter(
  initialLocation: '/',
  // ESCUCHA LOS CAMBIOS DE AUTH (Login/Logout)
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // 1. Si no está logueado y no está en login/register, mándalo a /login
    if (!loggedIn && !isLoggingIn) return '/login';

    // 2. Si ya está logueado e intenta ir a login/register, mándalo al Home
    if (loggedIn && isLoggingIn) return '/';

    // De lo contrario, no redirigir a ningún lado
    return null;
  },

  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/routes', builder: (context, state) => const RouteSelectionScreen()),
    GoRoute(path: '/report', builder: (context, state) => const ReportScreen()),
    GoRoute(path: '/guardians', builder: (context, state) => const GuardiansScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);

// CLASE AUXILIAR PARA QUE GOROUTER ESCUCHE A FIREBASE
// Cópiala tal cual debajo de tu _router

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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