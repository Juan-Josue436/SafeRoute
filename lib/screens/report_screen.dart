import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

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
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng initialPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = initialPoint;
      });
      _getAddressFromCoords(initialPoint);
    } catch (e) {
      // Ubicación por defecto si falla el GPS (ej. CDMX)
      _selectedLocation = const LatLng(19.4326, -99.1332);
    }
  }

  // --- FUNCIÓN MODIFICADA PARA CROWDSOURCING CON FIREBASE ---
  Future<void> _enviarReporte() async {
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Obtener el usuario actual
      final user = FirebaseAuth.instance.currentUser;

      // 2. Enviar a Cloud Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'title': _titleController.text.trim(),
        'description': _detailsController.text.trim(),
        'address': _addressController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'timestamp': FieldValue.serverTimestamp(), // Hora del servidor
        'userId': user?.uid,
        'userEmail': user?.email,
        'status': 'active', // Para poder moderar reportes después
        'votes': 0, // Para validación de la comunidad
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Reporte comunitario publicado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Regresar al mapa
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al subir el reporte: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalles del Reporte")),
      body: SingleChildScrollView(
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
                        width: 40,
                        height: 40,
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
                  TextField(
                    controller: _addressController,
                    readOnly: true,
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

                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "¿Qué problema es?",
                      hintText: "Ej. Asalto, Calle sin luz, Acoso...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _detailsController,
                    maxLines: 3,
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
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
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