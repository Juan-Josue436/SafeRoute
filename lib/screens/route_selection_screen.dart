import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

// --- MODELOS DE DATOS ---

class IncidentReport {
  final LatLng position;
  final String type;
  final IconData icon;
  final Color color;
  IncidentReport({required this.position, required this.type, required this.icon, required this.color});
}

List<IncidentReport> globalReports = [
  IncidentReport(position: LatLng(20.385, -101.775), type: "Zona sin luz", icon: Icons.flashlight_off, color: Colors.purple),
  IncidentReport(position: LatLng(20.390, -101.780), type: "Asalto reportado", icon: Icons.warning, color: Colors.red),
];

class RouteOption {
  final List<LatLng> points;
  final String duration;
  final String type;
  final Color color;
  final int riskLevel; // Nueva propiedad para medir el riesgo
  RouteOption({required this.points, required this.duration, required this.type, required this.color, required this.riskLevel});
}

// --- PANTALLA PRINCIPAL ---

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  List<RouteOption> _allRoutes = [];
  RouteOption? _selectedRoute;

  bool _isLoading = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initPreciseLocation();
  }

  // --- ALGORITMO DE ESCANEO DE RIESGOS ---
  int _calculateRouteRisk(List<LatLng> points) {
    int riskPoints = 0;
    // Umbral de cercanía (aprox. 100 metros)
    const double threshold = 0.001;

    for (var point in points) {
      for (var report in globalReports) {
        double distance = (point.latitude - report.position.latitude).abs() +
            (point.longitude - report.position.longitude).abs();
        if (distance < threshold) {
          riskPoints++;
        }
      }
    }
    return riskPoints;
  }

  Future<void> _initPreciseLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 15);
    } catch (e) {
      debugPrint("Error GPS: $e");
    }
  }

  Future<void> _searchAndRoute() async {
    if (_searchController.text.isEmpty || _currentLocation == null) return;
    setState(() { _isLoading = true; _allRoutes = []; _selectedRoute = null; });

    try {
      final query = Uri.encodeComponent(_searchController.text);
      final geoRes = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'),
        headers: {'User-Agent': 'SafeRouteApp/1.0'},
      );
      final geoData = json.decode(geoRes.body);

      if (geoData.isNotEmpty) {
        _destinationLocation = LatLng(double.parse(geoData[0]['lat']), double.parse(geoData[0]['lon']));

        final routeUrl = 'https://router.project-osrm.org/route/v1/foot/'
            '${_currentLocation!.longitude},${_currentLocation!.latitude};'
            '${_destinationLocation!.longitude},${_destinationLocation!.latitude}'
            '?overview=full&geometries=geojson&alternatives=true';

        final routeRes = await http.get(Uri.parse(routeUrl));
        final routeData = json.decode(routeRes.body);

        if (routeData['routes'] != null) {
          List<RouteOption> tempRoutes = [];

          for (var route in routeData['routes']) {
            List coords = route['geometry']['coordinates'];
            List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();
            int minutes = (route['duration'].toDouble() / 60).round();

            // Analizamos la seguridad de esta opción específica
            int riskCount = _calculateRouteRisk(points);

            tempRoutes.add(RouteOption(
              points: points,
              duration: "$minutes min",
              riskLevel: riskCount,
              type: riskCount == 0 ? "Ruta Segura" : "Ruta con $riskCount riesgos",
              color: riskCount == 0 ? Colors.green : (riskCount < 2 ? Colors.orange : Colors.red),
            ));
          }

          // Ordenamos: Las rutas con menos riesgos aparecen primero
          tempRoutes.sort((a, b) => a.riskLevel.compareTo(b.riskLevel));

          setState(() { _allRoutes = tempRoutes; });
          _mapController.move(_destinationLocation!, 14);
        }
      }
    } catch (e) {
      debugPrint("Error de red: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text("ALERTA SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Enviando tu ubicación actual a tus contactos de confianza (Guardianes)..."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text("CONFIRMAR AYUDA", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_isNavigating ? "Navegación Segura" : "SafeRoute"),
        backgroundColor: _isNavigating ? Colors.redAccent : Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (!_isNavigating)
            IconButton(
              icon: const Icon(Icons.account_circle, size: 30),
              onPressed: () => context.push('/profile'),
            ),
        ],
      ),
      floatingActionButton: _isNavigating
          ? null
          : FloatingActionButton.extended(
        heroTag: "btn_report",
        onPressed: () async {
          await context.push('/report');
          setState(() {});
        },
        label: const Text("Reportar Peligro"),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: Colors.redAccent,
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation!, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safe_route_app.app',
              ),
              // DIBUJAR TODAS LAS RUTAS
              if (_allRoutes.isNotEmpty)
                PolylineLayer(
                  polylines: _allRoutes.map((route) => Polyline(
                    points: route.points,
                    color: _isNavigating
                        ? (_selectedRoute == route ? route.color : Colors.transparent)
                        : (route.color.withOpacity(0.6)), // Opacidad para ver todas
                    strokeWidth: _selectedRoute == route ? 8 : 5,
                  )).toList(),
                ),
              MarkerLayer(
                markers: [
                  ...globalReports.map((report) => Marker(
                    point: report.position,
                    width: 40, height: 40,
                    child: Icon(report.icon, color: report.color, size: 30),
                  )),
                  Marker(point: _currentLocation!, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)),
                  if (_destinationLocation != null)
                    Marker(point: _destinationLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 45)),
                ],
              ),
            ],
          ),

          // BARRA DE BÚSQUEDA
          if (!_isNavigating)
            Positioned(
              top: 20, left: 15, right: 15,
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: "¿A dónde quieres ir?",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _searchAndRoute(),
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                        icon: const Icon(Icons.directions, color: Colors.blueAccent),
                        onPressed: _searchAndRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_isNavigating)
            Positioned(
              top: 85, left: 20,
              child: FloatingActionButton.small(
                heroTag: "btn_guardians",
                backgroundColor: Colors.white,
                onPressed: () => context.push('/guardians'),
                child: const Icon(Icons.shield, color: Colors.blueAccent),
              ),
            ),

          // PANEL INFERIOR CON COMPARATIVA DE RIESGO
          if (_allRoutes.isNotEmpty && !_isNavigating)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 15),
                    const Text("Analizador de Seguridad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 15),
                    ..._allRoutes.map((route) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRoute = route;
                            _isNavigating = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: route.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: route.color.withOpacity(0.3), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: route.color,
                                radius: 22,
                                child: Icon(route.riskLevel == 0 ? Icons.shield : Icons.warning_amber_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(route.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(
                                      route.riskLevel == 0
                                          ? "Sin peligros reportados cerca"
                                          : "Evita zonas con reportes activos",
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [BoxShadow(color: route.color.withOpacity(0.2), blurRadius: 4)]),
                                child: Text(route.duration, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: route.color)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          if (_isNavigating) ...[
            Positioned(
              bottom: 30, right: 20,
              child: FloatingActionButton.large(
                heroTag: "sos_panic",
                backgroundColor: Colors.red,
                onPressed: _triggerSOS,
                child: const Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
            ),
            Positioned(
              bottom: 30, left: 20,
              child: FloatingActionButton.extended(
                heroTag: "stop_nav",
                backgroundColor: Colors.black87,
                onPressed: () => setState(() { _isNavigating = false; _selectedRoute = null; }),
                label: const Text("Finalizar"),
                icon: const Icon(Icons.stop),
              ),
            ),
          ],
        ],
      ),
    );
  }
}