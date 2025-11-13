import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock class for SupabaseClient
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock class for SupabaseQueryBuilder
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Mock class for PostgrestFilterBuilder
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

/// Mock class for PostgrestTransformBuilder
class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder {}

/// Mock class for GoTrueClient (for auth)
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock class for AuthResponse
class MockAuthResponse extends Mock implements AuthResponse {}

/// Mock class for User
class MockUser extends Mock implements User {}

/// Mock class for Session
class MockSession extends Mock implements Session {}
