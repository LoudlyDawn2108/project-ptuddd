import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'migrations/core_migrations.dart';
import 'migrations/migration_manager.dart';

/// Hàm mở database có thể thay thế khi chạy kiểm thử.
typedef DatabaseOpener = Future<sqflite.Database> Function();

class DatabaseHelper {
  /// Hàm mở database tùy chọn, chủ yếu dùng trong kiểm thử.
  final DatabaseOpener? databaseOpener;

  /// Kết nối database hiện tại.
  sqflite.Database? _database;

  /// Future khởi tạo dùng chung để tránh mở database đồng thời.
  Future<sqflite.Database>? _opening;

  DatabaseHelper({this.databaseOpener});

  /// Lấy kết nối database.
  /// Nếu chưa mở thì mở mới và chạy migration.
  Future<sqflite.Database> get database {
    final current = _database;

    if (current != null && current.isOpen) {
      return Future.value(current);
    }

    return _opening ??= _openDatabase().whenComplete(() {
      _opening = null;
    });
  }

  Future<sqflite.Database> _openDatabase() async {
    final opener = databaseOpener;

    final db = opener != null ? await opener() : await _openDefaultDatabase();

    try {
      final migrationManager = MigrationManager(coreMigrations);
      await migrationManager.migrate(db);

      _database = db;
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<sqflite.Database> _openDefaultDatabase() async {
    final directory = await sqflite.getDatabasesPath();
    final databasePath = '$directory/chailish.db';

    return sqflite.openDatabase(databasePath, version: 1);
  }

  /// Đóng kết nối database.
  Future<void> close() async {
    final opening = _opening;

    if (opening != null) {
      try {
        await opening;
      } catch (_) {
        // Bỏ qua lỗi khởi tạo để vẫn có thể đóng helper.
      }
    }

    final db = _database;
    _database = null;

    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}

/// Provider dùng chung trong ứng dụng.
final databaseProvider = Provider<DatabaseHelper>((ref) {
  final helper = DatabaseHelper();

  ref.onDispose(() {
    unawaited(helper.close());
  });

  return helper;
});
