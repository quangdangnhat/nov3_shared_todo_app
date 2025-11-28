import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeofenceService {
  static const double radiusInMeters = 100.0;

  // --- IMPOSTAZIONE COOLDOWN (Tempo di attesa tra notifiche) ---
  // Metti 'minutes: 1' per testare, 'hours: 24' per la produzione
  static const Duration _cooldown = Duration(hours: 5);

  final Distance _distance = const Distance();
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- MODIFICA 1: Usiamo una Map per ricordare QUANDO abbiamo avvisato ---
  final Map<String, DateTime> _lastNotificationTimes = {};

  Future<void> initialize() async {
    // Inizializzazione notifiche locali se necessaria (qui non usata per DB strategy)
  }

  Future<void> checkProximity(Position userPos, List<Task> tasks) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    for (var task in tasks) {
      if (task.latitude == null || task.longitude == null) continue;
      if (task.status == 'Done') continue;

      // Calcolo distanza
      final double distance = _distance.as(
        LengthUnit.Meter,
        LatLng(userPos.latitude, userPos.longitude),
        LatLng(task.latitude!, task.longitude!),
      );

      if (distance <= radiusInMeters) {
        // --- MODIFICA 2: Controllo Locale del Cooldown ---
        // Se abbiamo avvisato di recente (in RAM), saltiamo SENZA chiamare il DB
        // Questo risparmia chiamate inutili a Supabase ogni secondo.
        if (_shouldSkipLocalCheck(task.id)) {
          continue;
        }

        // Se siamo qui, è passato tempo sufficiente localmente.
        // Proviamo a creare la notifica nel DB.
        await _createDatabaseNotification(userId, task);
      }
    }
  }

  /// Verifica se dobbiamo saltare il controllo basandoci sulla memoria RAM
  bool _shouldSkipLocalCheck(String taskId) {
    if (_lastNotificationTimes.containsKey(taskId)) {
      final lastTime = _lastNotificationTimes[taskId]!;
      final timeDiff = DateTime.now().difference(lastTime);

      // Se è passato meno tempo del cooldown, SALTA.
      if (timeDiff < _cooldown) {
        return true;
      }
    }
    return false;
  }

  Future<void> _createDatabaseNotification(String userId, Task task) async {
    try {
      // 1. CHECK DB: Controllo di sicurezza lato server
      // Serve nel caso l'utente abbia riavviato l'app (perdendo la memoria RAM)
      final thresholdTime = DateTime.now().subtract(_cooldown);

      final existingRecent = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('task_id', task.id)
          .gte('created_at', thresholdTime.toIso8601String())
          .maybeSingle();

      // Se esiste già una notifica recente nel DB, aggiorniamo la nostra RAM e usciamo
      if (existingRecent != null) {
        _lastNotificationTimes[task.id] =
            DateTime.now(); // Resetta timer locale
        return;
      }

      // 2. INSERIMENTO
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'task_id': task.id,
        'title': 'Complete the task: ${task.title}, in ${task.placeName}',
        'is_read': false,
      });

      // 3. AGGIORNAMENTO RAM
      // Segniamo che abbiamo appena inviato una notifica
      _lastNotificationTimes[task.id] = DateTime.now();

      print("🔔 Notifica creata per: ${task.placeName}");
    } catch (e) {
      print("Notification error: $e");
    }
  }
}
