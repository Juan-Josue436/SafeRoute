import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- MODELO CON SOPORTE PARA JSON ---
class Guardian {
  final String name;
  final String phoneNumber;

  Guardian({required this.name, required this.phoneNumber});

  Map<String, dynamic> toJson() => {'name': name, 'phoneNumber': phoneNumber};

  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
    name: json['name'],
    phoneNumber: json['phoneNumber'],
  );
}

// Lista global (ahora se cargará desde el disco)
List<Guardian> globalGuardians = [];

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardians(); // Cargar al iniciar
  }

  // --- FUNCIÓN: CARGAR DE LA MEMORIA ---
  Future<void> _loadGuardians() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedData = prefs.getStringList('saved_guardians');

    if (savedData != null) {
      setState(() {
        globalGuardians = savedData
            .map((item) => Guardian.fromJson(jsonDecode(item)))
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  // --- FUNCIÓN: GUARDAR EN LA MEMORIA ---
  Future<void> _saveGuardians() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dataToSave = globalGuardians
        .map((g) => jsonEncode(g.toJson()))
        .toList();
    await prefs.setStringList('saved_guardians', dataToSave);
  }

  void _addGuardian() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        globalGuardians.add(Guardian(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
        ));
      });
      _saveGuardians(); // Guardar cambios
      _nameController.clear();
      _phoneController.clear();
      Navigator.pop(context);
    }
  }

  void _deleteGuardian(int index) {
    setState(() {
      globalGuardians.removeAt(index);
    });
    _saveGuardians(); // Guardar cambios tras eliminar
  }

  // --- INTERFAZ (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Guardianes"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : globalGuardians.isEmpty
          ? const Center(child: Text("No tienes contactos guardados."))
          : ListView.builder(
        itemCount: globalGuardians.length,
        itemBuilder: (context, index) {
          final guardian = globalGuardians[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(guardian.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(guardian.phoneNumber),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteGuardian(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text("Agregar Guardián"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Guardián"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: _addGuardian, child: const Text("Guardar")),
        ],
      ),
    );
  }
}