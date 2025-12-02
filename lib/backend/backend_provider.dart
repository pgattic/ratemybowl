import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/local_sqlite_backend.dart';
import 'package:rate_my_bowl/backend/supabase_backend.dart';

const bool kUseSupabaseBackend = bool.fromEnvironment(
  'USE_SUPABASE',
  defaultValue: true,
);

BackendAdapter get backendAdapter => kUseSupabaseBackend
    ? SupabaseBackend.instance
    : LocalSqliteBackend.instance;

Future<void> initializeBackend() async {
  await backendAdapter.initialize();
}
