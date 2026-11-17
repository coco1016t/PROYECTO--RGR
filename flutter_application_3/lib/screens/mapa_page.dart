import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LugarMapa {
  final String nombre;
  final String descripcion;
  final LatLng coordenadas;
  final Color color;
  final IconData icono;

  LugarMapa({
    required this.nombre,
    required this.descripcion,
    required this.coordenadas,
    required this.color,
    required this.icono,
  });
}

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final LatLng centroQueretaro = const LatLng(20.5888, -100.3899);
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();

  final List<LugarMapa> _lugares = [
    LugarMapa(
      nombre: 'Centro de Querétaro',
      descripcion: 'Ubicación de referencia para la práctica.',
      coordenadas: const LatLng(20.5888, -100.3899),
      color: const Color(0xFFEF4444),
      icono: Icons.location_on,
    ),
    LugarMapa(
      nombre: 'Plaza de Armas',
      descripcion: 'Espacio histórico y cultural del centro de la ciudad.',
      coordenadas: const LatLng(20.6184, -100.3889),
      color: const Color(0xFF3B82F6),
      icono: Icons.place,
    ),
    LugarMapa(
      nombre: 'Parque de la República',
      descripcion: 'Zona de descanso y reunión comunitaria.',
      coordenadas: const LatLng(20.5807, -100.3923),
      color: const Color(0xFF10B981),
      icono: Icons.park,
    ),
    LugarMapa(
      nombre: 'Biblioteca Central',
      descripcion: 'Lugar de interés de la comunidad con lectura y cultura.',
      coordenadas: const LatLng(20.5921, -100.3958),
      color: const Color(0xFF8B5CF6),
      icono: Icons.local_library,
    ),
    LugarMapa(
      nombre: 'Museo de Arte',
      descripcion: 'Centro cultural con exposiciones temporales y permanentes.',
      coordenadas: const LatLng(20.5978, -100.3835),
      color: const Color(0xFFF59E0B),
      icono: Icons.museum,
    ),
    LugarMapa(
      nombre: 'Escuela de Ingeniería',
      descripcion: 'Campus educativo de la región.',
      coordenadas: const LatLng(20.5942, -100.4047),
      color: const Color(0xFFEC4899),
      icono: Icons.school,
    ),
  ];

  void _mostrarInformacion(String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioLugar() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar nueva ubicación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del lugar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _latitudController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _longitudController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nombreController.clear();
                _latitudController.clear();
                _longitudController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nombre = _nombreController.text.trim();
                final latitud = double.tryParse(_latitudController.text.trim());
                final longitud = double.tryParse(_longitudController.text.trim());

                if (nombre.isEmpty || latitud == null || longitud == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos con valores válidos.'),
                    ),
                  );
                  return;
                }

                if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las coordenadas están fuera del rango válido.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  _lugares.add(
                    LugarMapa(
                      nombre: nombre,
                      descripcion: 'Ubicación agregada por el usuario.',
                      coordenadas: LatLng(latitud, longitud),
                      color: const Color(0xFF14B8A6),
                      icono: Icons.add_location_alt_rounded,
                    ),
                  );
                });

                _nombreController.clear();
                _latitudController.clear();
                _longitudController.clear();
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _lugares
        .map(
          (lugar) => Marker(
            point: lugar.coordenadas,
            width: 50,
            height: 60,
            child: GestureDetector(
              onTap: () => _mostrarInformacion(lugar.nombre, lugar.descripcion),
              child: Icon(
                lugar.icono,
                color: lugar.color,
                size: 40,
              ),
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lugares de mi comunidad'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioLugar,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nueva ubicación'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centroQueretaro,
          initialZoom: 14,
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_application_3',
          ),
          MarkerLayer(markers: markers),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
