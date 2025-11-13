import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock class for SupabaseClient
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock class for SupabaseQueryBuilder
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Stub class for PostgrestFilterBuilder that allows flexible chaining
class StubPostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final dynamic _returnValue;

  StubPostgrestFilterBuilder(this._returnValue);

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) =>
      this;

  @override
  PostgrestFilterBuilder<PostgrestList> gte(String column, Object value) =>
      this;

  @override
  PostgrestFilterBuilder<PostgrestList> lt(String column, Object value) =>
      this;

  @override
  PostgrestFilterBuilder<PostgrestList> filter(
          String column, String operator, dynamic value) =>
      this;

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      StubPostgrestTransformBuilder(_returnValue);

  @override
  Future<PostgrestList> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) async {
    return _returnValue as PostgrestList;
  }
}

/// Stub class for PostgrestTransformBuilder that returns the expected value
class StubPostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  final dynamic _returnValue;

  StubPostgrestTransformBuilder(this._returnValue);

  @override
  PostgrestTransformBuilder<PostgrestMap> single() =>
      StubPostgrestTransformBuilderMap(_returnValue);

  @override
  Future<PostgrestList> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) async {
    return _returnValue as PostgrestList;
  }
}

/// Stub class for PostgrestTransformBuilder with Map return (for .single())
class StubPostgrestTransformBuilderMap extends Fake
    implements PostgrestTransformBuilder<PostgrestMap> {
  final dynamic _returnValue;

  StubPostgrestTransformBuilderMap(this._returnValue);

  @override
  Future<PostgrestMap> then<R>(
    FutureOr<R> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) async {
    return _returnValue as PostgrestMap;
  }
}

/// Mock class for GoTrueClient (for auth)
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock class for AuthResponse
class MockAuthResponse extends Mock implements AuthResponse {}

/// Mock class for User
class MockUser extends Mock implements User {}

/// Mock class for Session
class MockSession extends Mock implements Session {}
