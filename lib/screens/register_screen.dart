import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña

  Future<void> _register() async {
    // Validaciones básicas
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      _showSnackBar("Ingresa un correo válido y al menos 6 caracteres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Intento de creación de usuario
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si el registro es exitoso, navegamos al Home
      if (mounted) context.go('/');

    } on FirebaseAuthException catch (e) {
      // Errores específicos de Firebase
      String errorMessage = "Error en el registro";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Este correo ya está registrado.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "El formato del correo no es válido.";
      } else if (e.code == 'weak-password') {
        errorMessage = "La contraseña es muy débil.";
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      // Este bloque captura el error de "PigeonUserDetails" si las librerías fallan
      debugPrint("Error técnico detectado: $e");

      // Si el log dice que el usuario se creó (como vimos en tu .txt),
      // intentamos navegar aunque la librería haya dado ese error de tipos.
      if (FirebaseAuth.instance.currentUser != null) {
        if (mounted) context.go('/');
      } else {
        _showSnackBar("Error de conexión con el servidor");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Crear Cuenta"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(Icons.person_add_rounded, size: 90, color: Colors.blueAccent),
            const SizedBox(height: 10),
            const Text(
              "Únete a SafeRoute",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Campo de Correo
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de Contraseña
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Contraseña",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 40),

            // Botón de Registro
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("REGISTRARSE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}