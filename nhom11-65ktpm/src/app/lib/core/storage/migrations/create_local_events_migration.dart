
import 'package:sqflite/sqflite.dart' as sqflite;

import 'database_migration.dart';

/// Tạo bảng lưu lịch sử sự kiện học tập trên thiết bị.
class CreateLocalEventsMigration implements DatabaseMigration {
  @override
  int get version => 2;

  @override
  String get description => 'Create local_events table';

  @override
  Future<void> up(sqflite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_events (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        occurred_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_local_events_occurred_at
      ON local_events(occurred_at)
    ''');
  }
}
