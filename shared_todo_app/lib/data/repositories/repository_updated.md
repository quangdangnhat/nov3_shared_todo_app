Nov 11, 2025 - quangdn:
- BEFORE (Not Testable):
dartclass TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client; // Hard-coded!
}
- AFTER (Fully Testable):
dartclass TaskRepository {
  final SupabaseClient _supabase;
  
  TaskRepository({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client; // Injectable!
}