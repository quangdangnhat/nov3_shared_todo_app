import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Pacchetto OSM
import 'package:latlong2/latlong.dart';      // Pacchetto coordinate
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_todo_app/data/repositories/task_repository.dart';


class MapDialog extends StatefulWidget {
  final String taskId;
  final TaskRepository taskRepository;

  const MapDialog({
    super.key,
    required this.taskId,
    required this.taskRepository,
  });

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  // Usiamo LatLng di 'latlong2', non di Google Maps
  LatLng? _currentPosition;
  LatLng? _selectedLocation;
  String _selectedPlaceName = "Ricerca posizione...";
  
  bool _isLoadingMap = true;
  bool _isSaving = false;
  bool _isGettingAddress = false;
  
  // Controller per muovere la mappa programmaticamente
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
        // Spostiamo la mappa sulla posizione utente
        // Nota: _mapController deve essere pronto, quindi aspettiamo un frame
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
      if (permission == LocationPermission.denied) return Future.error('Permessi negati.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Permessi negati per sempre.');

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // --- GEOCODING GRATUITO (Nominatim / OpenStreetMap) ---
  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _isGettingAddress = true;
      _selectedPlaceName = "Ricerca indirizzo in corso...";
    });

    String foundAddress = "";

    try {
      // URL di Nominatim (Servizio gratuito di OSM)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );

      //debugPrint("🌍 Chiamata OSM: $url");

      // ⚠️ IMPORTANTE: Nominatim richiede un User-Agent valido
      final response = await http.get(url, headers: {
        'User-Agent': 'com.example.mytaskapp', // Metti qui il nome del tuo package
        'Accept-Language': 'it', // Richiediamo risposta in Italiano
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Nominatim restituisce un oggetto 'address' molto dettagliato
        if (data['display_name'] != null) {
           // 'display_name' è l'indirizzo completo. 
           // Spesso è molto lungo, possiamo prendere solo parti specifiche se vuoi.
           foundAddress = data['display_name'];
           
           // Esempio di pulizia (opzionale): Prendiamo solo i primi 2 pezzi della virgola
           List<String> parts = foundAddress.split(',');
           if (parts.length > 2) {
             foundAddress = "${parts[0]}, ${parts[1]}";
           }
        }
      } else {
        debugPrint("⚠️ OSM Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔴 Errore connessione: $e");
    }

    if (mounted) {
      setState(() {
        if (foundAddress.isNotEmpty) {
          _selectedPlaceName = foundAddress;
        } else {
          _selectedPlaceName = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
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

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isSaving = true);

    try {
      // Nota: LatLng di OSM è double, quindi va bene per il tuo DB
      await widget.taskRepository.updateTask(
        taskId: widget.taskId,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        placeName: _selectedPlaceName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Luogo salvato!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
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
                  const Icon(Icons.location_on, color: Colors.blue), // Blu per differenziare da Google
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isGettingAddress
                        ? const Text("Sto chiedendo a OpenStreetMap...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                        : Text(
                            _selectedPlaceName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            // BODY: FLUTTER MAP (OSM)
            Expanded(
              child: _isLoadingMap
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition ?? const LatLng(41.9028, 12.4964),
                        initialZoom: 16.0,
                        onTap: _onMapTap, // Gestisce il click
                      ),
                      children: [
                        // 1. LAYER DELLE TILE (La grafica della mappa)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app', // IMPORTANTE
                        ),
                        // 2. LAYER DEI MARKER (Il puntatore)
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
                  onPressed: (_isLoadingMap || _isSaving || _isGettingAddress || _selectedLocation == null) 
                      ? null 
                      : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue, // Stile OSM
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isGettingAddress
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 10),
                            Text("Attendi...", style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("CONFERMA POSIZIONE"),
                ),
              ),
            ),
            
            // CREDIT (Richiesto dalla licenza OSM)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text("© OpenStreetMap contributors", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}