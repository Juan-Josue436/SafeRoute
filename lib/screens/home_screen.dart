import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeRoute"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
            Positioned(
              top: 15,
              right: 15,
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("SafeRoute", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Tu camino seguro", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Mapa Principal"),
              onTap: () => context.pop(),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text("Seleccionar Ruta"),
              onTap: () {
                context.pop();
                context.push('/routes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text("Reportar Incidencia"),
              onTap: () {
                context.pop();
                context.push('/report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text("Mis Guardianes"),
              onTap: () {
                context.pop();
                context.push('/guardians');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Configuración"),
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safe_route_app.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 35),
                  ),
                ],
              ),
            ],
          ),

          // --- NUEVO RECUADRO DE ESTADO DE LA RUTA ---
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), // Fondo semi-transparente
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Estado de la Ruta",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 5),
                  _LegendItem(color: Colors.green, text: "Seguro", icon: Icons.verified_user),
                  _LegendItem(color: Colors.amber, text: "Medio Seguro", icon: Icons.warning_amber),
                  _LegendItem(color: Colors.red, text: "No Recomendable", icon: Icons.block),
                ],
              ),
            ),
          ),

          // Botón para centrar GPS
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: _determinePosition,
              child: const Icon(Icons.gps_fixed),
            ),
          ),
          // Botón de Reportar
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/report'),
              label: const Text("Reportar"),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: Colors.orange,
              // Asegúrate de que este botón no tape el nuevo recuadro
            ),
          ),
        ],
      ),
    );
  }
}

// --- NUEVO WIDGET AUXILIAR PARA LA LEYENDA ---
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final IconData icon;

  const _LegendItem({required this.color, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}