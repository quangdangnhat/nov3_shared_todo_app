import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/services/map/geofence_service.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String placeName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });
}

class MapDialog extends StatefulWidget {
  final String? taskId;
  final TaskRepository? taskRepository;
  final VoidCallback? onPlaceUpdated;

  final double? initialLat;
  final double? initialLong;

  // --- MODIFICA 1: Aggiungiamo il titolo ---
  final String? currentTitle;

  const MapDialog({
    super.key,
    this.taskId,
    this.taskRepository,
    this.onPlaceUpdated,
    this.initialLat,
    this.initialLong,
    this.currentTitle,
  });

  const MapDialog.forUpdate({
    super.key,
    required String taskId,
    required TaskRepository taskRepository,
    this.onPlaceUpdated,
    required double? currentLat,
    required double? currentLong,
    required String currentTitle, // Richiesto nell'update
  })  : taskId = taskId,
        taskRepository = taskRepository,
        initialLat = currentLat,
        initialLong = currentLong,
        currentTitle = currentTitle;

  const MapDialog.forCreate({super.key})
      : taskId = null,
        taskRepository = null,
        onPlaceUpdated = null,
        initialLat = null,
        initialLong = null,
        currentTitle = null;

  bool get isCreateMode => taskId == null;

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  final GeofenceService _geofenceService = GeofenceService();
  late final TaskRepository _repo = widget.taskRepository ?? TaskRepository();

  List<Task> _existingTasks = [];
  StreamSubscription<Position>? _positionStream;

  LatLng? _currentPosition;
  LatLng? _selectedLocation;
  String _selectedPlaceName = "Tocca la mappa per scegliere...";

  bool _isLoadingMap = true;
  bool _isSaving = false;
  bool _isGettingAddress = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLong != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLong!);
      _selectedPlaceName = "Posizione salvata";
    } else {
      _selectedLocation = null;
    }
    _initializeData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _geofenceService.initialize();
      Position position = await _determinePosition();
      LatLng userLatLng = LatLng(position.latitude, position.longitude);
      final tasks = await _repo.getActiveTasks();

      if (mounted) {
        setState(() {
          _currentPosition = userLatLng;
          _existingTasks = tasks;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedLocation != null) {
            _mapController.move(_selectedLocation!, 16.0);
            _getAddress(_selectedLocation!);
          } else {
            _mapController.move(userLatLng, 16.0);
          }
        });
      }
      _startLiveTracking();
    } catch (e) {
      if (mounted)
        setState(() => _selectedPlaceName = "GPS non trovato o Errore: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _startLiveTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Notifica ogni 10 metri di spostamento
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (mounted) {
        // 1. Aggiorniamo la posizione visiva (pallino blu)
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // 2. --- REINSERIAMO IL CONTROLLO QUI ---
        // Ora è sicuro farlo perché GeofenceService ha il cooldown interno.
        // Se è passato meno di 1 minuto, il service bloccherà tutto subito (RAM check).
        // Se è passato più di 1 minuto, il service lascerà passare e creerà la notifica.
        _geofenceService.checkProximity(position, _existingTasks);
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS disattivato.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Permessi negati.');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Permessi negati per sempre.');
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _isGettingAddress = true;
      _selectedPlaceName = "Recupero indirizzo...";
    });
    String foundAddress = "";
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'com.example.mytaskapp',
        'Accept-Language': 'it',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          foundAddress = data['display_name'];
          List<String> parts = foundAddress.split(',');
          if (parts.length > 2) foundAddress = "${parts[0]}, ${parts[1]}";
        }
      }
    } catch (e) {
      debugPrint("Errore connessione: $e");
    }

    if (mounted) {
      setState(() {
        if (foundAddress.isNotEmpty)
          _selectedPlaceName = foundAddress;
        else
          _selectedPlaceName =
              "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        _isGettingAddress = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() => _selectedLocation = position);
    _getAddress(position);
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isSaving = true);

    try {
      // 1. Raccogliamo i dati della nuova posizione scelta
      final locationData = LocationData(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        placeName: _selectedPlaceName, // <-- Qui il nome c'è (es. "Via Roma")
      );

      if (widget.isCreateMode) {
        if (mounted) Navigator.of(context).pop(locationData);
      } else {
        // 2. Salviamo nel DB
        await widget.taskRepository!.updateTask(
          taskId: widget.taskId!,
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          placeName: locationData.placeName,
        );

        // 3. Controllo Prossimità Immediato (FIX HERE)
        final currentPos = await Geolocator.getCurrentPosition();

        // Creiamo un task temporaneo con TUTTI i dati aggiornati
        final updatedTaskCheck = Task(
          id: widget.taskId!,
          folderId: '',
          // Usiamo il titolo passato o un placeholder se manca
          title: widget.currentTitle ?? 'Task Aggiornato',
          priority: '',
          status: '',
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),

          // --- FIX FONDAMENTALE ---
          // Passiamo le coordinate E il nome del posto appena trovati
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          placeName: locationData.placeName, // <-- ORA NON È PIÙ NULL!
        );

        // Ricostruiamo la lista per il controllo
        final tasksToCheck =
            _existingTasks.where((t) => t.id != widget.taskId).toList();
        tasksToCheck.add(updatedTaskCheck);

        // Lanciamo il controllo
        await _geofenceService.checkProximity(currentPos, tasksToCheck);

        if (mounted) {
          widget.onPlaceUpdated?.call();
          Navigator.of(context).pop(locationData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Luogo aggiornato!"),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... IL RESTO DEL METODO BUILD RIMANE IDENTICO A PRIMA ...
    // Copia il metodo build dalla risposta precedente, non è cambiato nulla nella UI
    // ma per completezza, assicurati di avere il pulsante _confirmLocation collegato.
    final size = MediaQuery.of(context).size;
    final double dialogWidth = size.width > 600 ? 500 : size.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        width: dialogWidth,
        height: size.height * 0.8,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16.0)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isGettingAddress
                        ? const Text("Sto chiedendo a OpenStreetMap...",
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey))
                        : Text(_selectedPlaceName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop())
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingMap
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ??
                            _currentPosition ??
                            const LatLng(41.9028, 12.4964),
                        initialZoom: 16.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mytaskapp'),
                        CircleLayer(
                          circles: _existingTasks
                              .map((task) {
                                if (task.id == widget.taskId) return null;
                                if (task.latitude == null ||
                                    task.longitude == null) return null;
                                return CircleMarker(
                                  point:
                                      LatLng(task.latitude!, task.longitude!),
                                  color: Colors.blue.withOpacity(0.15),
                                  borderStrokeWidth: 1,
                                  borderColor: Colors.blue,
                                  radius: GeofenceService.radiusInMeters,
                                  useRadiusInMeter: true,
                                );
                              })
                              .whereType<CircleMarker>()
                              .toList(),
                        ),
                        MarkerLayer(
                          markers: _existingTasks
                              .map((task) {
                                if (task.id == widget.taskId) return null;
                                if (task.latitude == null ||
                                    task.longitude == null) return null;
                                return Marker(
                                    point:
                                        LatLng(task.latitude!, task.longitude!),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(Icons.circle,
                                        color: Colors.blueGrey, size: 15));
                              })
                              .whereType<Marker>()
                              .toList(),
                        ),
                        if (_currentPosition != null)
                          MarkerLayer(markers: [
                            Marker(
                                point: _currentPosition!,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.person_pin_circle,
                                    color: Colors.blueAccent, size: 40))
                          ]),
                        if (_selectedLocation != null)
                          MarkerLayer(markers: [
                            Marker(
                                point: _selectedLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(Icons.location_pin,
                                    size: 50, color: Colors.red))
                          ]),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoadingMap ||
                          _isSaving ||
                          _isGettingAddress ||
                          _selectedLocation == null)
                      ? null
                      : _confirmLocation,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: _isGettingAddress
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 10),
                              Text("Wait...",
                                  style: TextStyle(color: Colors.white))
                            ])
                      : _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(widget.isCreateMode
                              ? "SELECT A POSITION"
                              : "CONFIRM POSITION"),
                ),
              ),
            ),
            const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text("© OpenStreetMap contributors",
                    style: TextStyle(fontSize: 10, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
