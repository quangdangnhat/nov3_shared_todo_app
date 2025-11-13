import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestClient extends Mock implements PostgrestClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

/// Mock Postgrest Filter Builder
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

/// Mock Postgrest Builder
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}

/// Mock Postgrest Transform Builder
class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder {}

/// ✨ ADDED FOR TaskRepository TESTING ✨
/// Mock Supabase Query Builder
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Mock Supabase Stream Builder  
class MockSupabaseStreamBuilder extends Mock
    implements SupabaseStreamBuilder {}