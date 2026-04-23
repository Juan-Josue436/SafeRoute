import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'route_selection_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _titleController = TextEditingController(); // Título/Tipo
  final TextEditingController _detailsController = TextEditingController(); // POR QUÉ se reporta
  final TextEditingController _addressController = TextEditingController(); // Dirección automática

  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isSending = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  // Obtener dirección a partir de coordenadas (Reverse Geocoding)
  Future<void> _getAddressFromCoords(LatLng point) async {
    setState(() => _isGeocoding = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'SafeRouteApp/1.0'});
      final data = json.decode(response.body);

      setState(() {
        _addressController.text = data['display_name'] ?? "${point.latitude}, ${point.longitude}";
      });
    } catch (e) {
      _addressController.text = "${point.latitude}, ${point.longitude}";
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  Future<void> _setInitialLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    LatLng initialPoint = LatLng(position.latitude, position.longitude);
    setState(() {
      _selectedLocation = initialPoint;
    });
    _getAddressFromCoords(initialPoint);
  }

  Future<void> _enviarReporte() async {
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      return;
    }

    setState(() => _isSending = true);

    // Concatenamos título y detalles para el marcador
    String fullDescription = "${_titleController.text}: ${_detailsController.text}";

    globalReports.add(IncidentReport(
      position: _selectedLocation!,
      type: fullDescription,
      icon: Icons.report_problem,
      color: Colors.redAccent,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reporte comunitario publicado con éxito")),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalles del Reporte")),
      body: SingleChildScrollView( // Para que el teclado no tape los campos
        child: Column(
          children: [
            // --- MINIMAPA ---
            SizedBox(
              height: 200,
              child: _selectedLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation!,
                  initialZoom: 16,
                  onTap: (tapPosition, point) {
                    setState(() => _selectedLocation = point);
                    _getAddressFromCoords(point);
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
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CUADRO DE UBICACIÓN (AUTOPREDICHO)
                  TextField(
                    controller: _addressController,
                    readOnly: true, // No se edita a mano, se llena con el mapa
                    decoration: InputDecoration(
                      labelText: "Ubicación seleccionada",
                      prefixIcon: const Icon(Icons.map_outlined),
                      suffixIcon: _isGeocoding ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CUADRO DE TÍTULO
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "¿Qué problema es?",
                      hintText: "Ej. Asalto, Calle sin luz, Acoso...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CUADRO DE DETALLES ADICIONALES
                  TextField(
                    controller: _detailsController,
                    maxLines: 3, // Más espacio para explicar
                    decoration: InputDecoration(
                      labelText: "Descripción detallada",
                      hintText: "Explica qué sucedió o por qué es peligroso este lugar...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _enviarReporte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.cloud_upload),
                    label: const Text("PUBLICAR REPORTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}