import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_todo_app/data/repositories/task_repository.dart';

/// Modello per i dati di localizzazione restituiti dal dialog
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
  final String? taskId; // Nullable: se null, non fa update ma ritorna i dati
  final TaskRepository? taskRepository; // Nullable: richiesto solo per update
  final VoidCallback? onPlaceUpdated;

  const MapDialog({
    super.key,
    this.taskId,
    this.taskRepository,
    this.onPlaceUpdated,
  });

  /// Costruttore per modalità UPDATE (task esistente)
  const MapDialog.forUpdate({
    super.key,
    required String taskId,
    required TaskRepository taskRepository,
    this.onPlaceUpdated,
  })  : taskId = taskId,
        taskRepository = taskRepository;

  /// Costruttore per modalità CREATE (nuovo task)
  const MapDialog.forCreate({super.key})
      : taskId = null,
        taskRepository = null,
        onPlaceUpdated = null;

  bool get isCreateMode => taskId == null;

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  LatLng? _currentPosition;
  LatLng? _selectedLocation;
  String _selectedPlaceName = "Ricerca posizione...";

  bool _isLoadingMap = true;
  bool _isSaving = false;
  bool _isGettingAddress = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = userLatLng;
          _selectedLocation = userLatLng;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(userLatLng, 16.0);
        });
      }

      await _getAddress(userLatLng);
    } catch (e) {
      if (mounted) {
        setState(() => _selectedPlaceName = "Posizione GPS non trovata");
      }
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS disattivato.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permessi negati.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permessi negati per sempre.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _isGettingAddress = true;
      _selectedPlaceName = "Ricerca indirizzo in corso...";
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
          if (parts.length > 2) {
            foundAddress = "${parts[0]}, ${parts[1]}";
          }
        }
      }
    } catch (e) {
      debugPrint("Errore connessione: $e");
    }

    if (mounted) {
      setState(() {
        if (foundAddress.isNotEmpty) {
          _selectedPlaceName = foundAddress;
        } else {
          _selectedPlaceName =
              "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        }
        _isGettingAddress = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddress(position);
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isSaving = true);

    try {
      final locationData = LocationData(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        placeName: _selectedPlaceName,
      );

      if (widget.isCreateMode) {
        // Modalità CREATE: ritorna i dati senza salvare
        if (mounted) {
          Navigator.of(context).pop(locationData);
        }
      } else {
        // Modalità UPDATE: salva e poi chiudi
        await widget.taskRepository!.updateTask(
          taskId: widget.taskId!,
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          placeName: locationData.placeName,
        );

        if (mounted) {
          widget.onPlaceUpdated?.call();
          Navigator.of(context).pop(locationData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Luogo salvato!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double dialogWidth = size.width > 600 ? 500 : size.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        width: dialogWidth,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isGettingAddress
                        ? const Text(
                            "Sto chiedendo a OpenStreetMap...",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          )
                        : Text(
                            _selectedPlaceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            // BODY: FLUTTER MAP
            Expanded(
              child: _isLoadingMap
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentPosition ?? const LatLng(41.9028, 12.4964),
                        initialZoom: 16.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),

            // FOOTER
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isGettingAddress
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text("Wait...",
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isCreateMode
                              ? "SELECT A POSITION"
                              : "CONFIRM POSITION"),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "© OpenStreetMap contributors",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
