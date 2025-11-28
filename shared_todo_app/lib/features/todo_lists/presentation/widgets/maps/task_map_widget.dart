import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/services/map/geofence_service.dart';

// Importa i tuoi file
class TaskMapWidget extends StatefulWidget {
  const TaskMapWidget({super.key});

  @override
  State<TaskMapWidget> createState() => _TaskMapWidgetState();
}

class _TaskMapWidgetState extends State<TaskMapWidget> {
  final TaskRepository _taskRepository = TaskRepository();
  final GeofenceService _geofenceService = GeofenceService();

  List<Task> _tasks = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  /// Inizializza tutto: Notifiche, Permessi GPS, Task dal DB
  Future<void> _initializeMapData() async {
    await _geofenceService.initialize();

    // 1. Chiedi permessi GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Ottieni posizione iniziale
    final position = await Geolocator.getCurrentPosition();

    // 3. Scarica i task (Qui inizializzi i tasks!)
    final tasks = await _taskRepository.getActiveTasks();

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _tasks = tasks;
        _isLoading = false;
      });
    }

    // 4. Avvia ascolto spostamenti per le notifiche
    _startListeningLocation();
  }

  void _startListeningLocation() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Controlla ogni 10 metri
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      // Aggiorna posizione UI
      if (mounted) setState(() => _currentPosition = position);

      // Controlla raggio d'azione
      _geofenceService.checkProximity(position, _tasks);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Ferma il GPS quando chiudi il dialog
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentPosition == null) {
      return const SizedBox(
          height: 300, child: Center(child: CircularProgressIndicator()));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          // Centra la mappa sull'utente
          initialCenter:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.app', // Metti il tuo package name
          ),

          // 1. Cerchi (Raggio d'azione)
          CircleLayer(
            circles: _tasks
                .map((task) {
                  if (task.latitude == null || task.longitude == null)
                    return null;
                  return CircleMarker(
                    point: LatLng(task.latitude!, task.longitude!),
                    color: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: GeofenceService.radiusInMeters, // 100 metri
                  );
                })
                .whereType<CircleMarker>()
                .toList(),
          ),

          // 2. Marker (Pin dei Task)
          MarkerLayer(
            markers: _tasks
                .map((task) {
                  if (task.latitude == null || task.longitude == null)
                    return null;
                  return Marker(
                    point: LatLng(task.latitude!, task.longitude!),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  );
                })
                .whereType<Marker>()
                .toList(),
          ),

          // 3. Marker Utente (Dove sono io)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                width: 40,
                height: 40,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.blueAccent, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
