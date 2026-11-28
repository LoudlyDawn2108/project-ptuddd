
import 'database_migration.dart';
import 'create_sync_outbox_migration.dart';
import 'create_local_events_migration.dart';

final List<DatabaseMigration> coreMigrations = [
  CreateSyncOutboxMigration(),
  CreateLocalEventsMigration(),
];
