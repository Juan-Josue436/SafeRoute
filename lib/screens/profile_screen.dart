import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Función para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/login'); // Redirige al login y limpia el historial
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual de Firebase
    final user = FirebaseAuth.instance.currentUser;

    // Extraemos el nombre del correo (lo que está antes del @)
    String displayName = user?.email?.split('@')[0] ?? "Usuario";
    // Capitalizamos la primera letra
    displayName = displayName[0].toUpperCase() + displayName.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cabecera dinámica
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Colors.blueAccent),
                ),
                const SizedBox(height: 15),
                Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? "sin-correo@ejemplo.com",
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sección de Estadísticas Reales (Usando Streams)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("0", "Rutas"), // Placeholder

                // Contador de Reportes Reales
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('userId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatItem(count.toString(), "Reportes");
                  },
                ),

                // Contador de Guardianes Reales
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('guardians')
                      .where('addedBy', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatItem(count.toString(), "Guardianes");
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Opciones de Configuración
          Expanded(
            child: ListView(
              children: [
                _buildProfileOption(Icons.history, "Historial de Rutas"),
                _buildProfileOption(Icons.notifications, "Ajustes de Alertas"),
                _buildProfileOption(Icons.privacy_tip, "Privacidad y Datos"),
                _buildProfileOption(Icons.help, "Centro de Ayuda"),
                const Divider(),
                _buildProfileOption(
                  Icons.logout,
                  "Cerrar Sesión",
                  color: Colors.red,
                  onTap: () => _logout(context), // Llamamos a la función de cerrar sesión
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {Color color = Colors.black87, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {},
    );
  }
}