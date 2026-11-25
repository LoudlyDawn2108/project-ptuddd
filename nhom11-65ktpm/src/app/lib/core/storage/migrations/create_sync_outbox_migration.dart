import 'package:sqflite/sqflite.dart' as sqflite;

import 'database_migration.dart';

/// Tạo bảng lưu các dữ liệu đang chờ đồng bộ lên server.
class CreateSyncOutboxMigration implements DatabaseMigration {
  @override
  int get version => 1;

  @override
  String get description => 'Create sync_outbox table';

  @override
  Future<void> up(sqflite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at
      ON sync_outbox(created_at)
    ''');
  }
}
