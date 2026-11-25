import 'database_migration.dart';
import 'create_sync_outbox_migration.dart';

final List<DatabaseMigration> coreMigrations = [CreateSyncOutboxMigration()];
