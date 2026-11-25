import 'package:sqflite/sqflite.dart' as sqflite;

import 'database_migration.dart';

/// Quản lý việc thực thi các migration SQLite.
class MigrationManager {
  final List<DatabaseMigration> migrations;

  MigrationManager(this.migrations);

  /// Tạo bảng lịch sử và chạy các migration chưa được áp dụng.
  Future<void> migrate(sqflite.Database db) async {
    // Kiểm tra phiên bản migration có bị trùng hay không.
    final versions = migrations.map((item) => item.version).toList();

    if (versions.toSet().length != versions.length) {
      throw StateError('Migration version bị trùng.');
    }

    if (versions.any((version) => version <= 0)) {
      throw StateError('Migration version phải lớn hơn 0.');
    }

    // Sắp xếp migration theo thứ tự tăng dần.
    final orderedMigrations = [...migrations]
      ..sort((a, b) => a.version.compareTo(b.version));

    // Tạo bảng ghi nhận những migration đã chạy.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        description TEXT NOT NULL,
        applied_at TEXT NOT NULL
      )
    ''');

    // Lấy danh sách migration đã chạy.
    final appliedRows = await db.query(
      'schema_migrations',
      columns: ['version'],
    );

    final appliedVersions = appliedRows
        .map((row) => row['version'] as int)
        .toSet();

    // Chỉ chạy những migration chưa được áp dụng.
    for (final migration in orderedMigrations) {
      if (appliedVersions.contains(migration.version)) {
        continue;
      }

      await db.transaction((txn) async {
        await migration.up(txn);

        await txn.insert('schema_migrations', {
          'version': migration.version,
          'description': migration.description,
          'applied_at': DateTime.now().toUtc().toIso8601String(),
        });
      });
    }
  }
}
