import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Para el minimapa
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'route_selection_screen.dart'; // Para acceder a globalReports

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _selectedLocation; // Aquí guardamos el punto tocado
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  // Obtenemos la ubicación actual solo para centrar el mapa al inicio
  Future<void> _setInitialLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _enviarReporte() async {
    if (_descriptionController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Descripción y ubicación son obligatorias")),
      );
      return;
    }

    setState(() => _isSending = true);

    // Guardamos el reporte con la ubicación elegida en el mapa
    globalReports.add(IncidentReport(
      position: _selectedLocation!,
      type: _descriptionController.text,
      icon: Icons.report_problem,
      color: Colors.redAccent,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reporte guardado en el mapa")),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ubicación del Incidente")),
      body: Column(
        children: [
          // --- MINIMAPA INTERACTIVO ---
          SizedBox(
            height: 250, // Tamaño del mapa
            child: _selectedLocation == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation!,
                initialZoom: 16,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point; // Actualizamos el punto al tocar
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safe_route_app.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(Icons.location_searching, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Toca el mapa para ajustar el punto exacto del reporte.",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "¿Qué sucede?",
                    hintText: "Ej. Alumbrado descompuesto...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _enviarReporte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: const Text("Confirmar y Enviar"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}