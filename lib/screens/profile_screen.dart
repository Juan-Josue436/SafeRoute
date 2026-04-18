import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cabecera con foto y nombre
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
                const Text(
                  "Usuario SafeRoute",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  "usuario@ejemplo.com",
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sección de Estadísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("12", "Rutas Seguras"),
                _buildStatItem("5", "Reportes"),
                _buildStatItem("3", "Guardianes"),
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
                _buildProfileOption(Icons.logout, "Cerrar Sesión", color: Colors.red),
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

  Widget _buildProfileOption(IconData icon, String title, {Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}