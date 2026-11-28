import 'package:chailish/core/storage/database_helper.dart';
import 'package:chailish/core/storage/migrations/core_migrations.dart';
import 'package:chailish/core/storage/migrations/migration_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    late DatabaseHelper databaseHelper;

    setUp(() {
      databaseHelper = DatabaseHelper(
        databaseOpener: () {
          return databaseFactory.openDatabase(inMemoryDatabasePath);
        },
      );
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    test('có thể mở database', () async {
      final db = await databaseHelper.database;

      expect(db.isOpen, true);
    });

    test('có thể tạo bảng, thêm và đọc dữ liệu', () async {
      final db = await databaseHelper.database;

      await db.execute('''
        CREATE TABLE test_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      await db.insert('test_items', {'name': 'ChaiLish'});

      final results = await db.query('test_items');

      expect(results.length, 1);
      expect(results.first['name'], 'ChaiLish');
    });


    test('migration tự động tạo bảng local_events', () async {
      final db = await databaseHelper.database;

      // Kiểm tra bảng local_events đã được tạo.
      final tables = await db.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name = 'local_events'
      ''');

      expect(tables.length, 1);

      // Kiểm tra các cột của bảng.
      final columns = await db.rawQuery(
        'PRAGMA table_info(local_events)',
      );

      final columnNames = columns.map((column) => column['name']).toSet();

      expect(
        columnNames,
        containsAll(['id', 'payload', 'occurred_at']),
      );
    });


    test('migration tự động tạo bảng sync_outbox', () async {
      final db = await databaseHelper.database;

      final tables = await db.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name = 'sync_outbox'
      ''');

      expect(tables.length, 1);

      final columns = await db.rawQuery('PRAGMA table_info(sync_outbox)');

      final columnNames = columns.map((column) => column['name']).toSet();

      expect(
        columnNames,
        containsAll(['id', 'kind', 'payload', 'created_at', 'attempts']),
      );
    });

    test('migration không tạo bản ghi lịch sử trùng khi chạy lại', () async {
      final db = await databaseHelper.database;

      final migrationManager = MigrationManager(coreMigrations);

      // Chạy migration thêm một lần nữa.
      await migrationManager.migrate(db);

      final result = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM schema_migrations',
      );

expect(result.first['total'], 2);
    });

    test('sử dụng lại kết nối database đã mở', () async {
      final firstDatabase = await databaseHelper.database;
      final secondDatabase = await databaseHelper.database;

      expect(identical(firstDatabase, secondDatabase), true);
    });

    test('nhiều yêu cầu mở database đồng thời chỉ mở một kết nối', () async {
      var openCount = 0;

      final concurrentHelper = DatabaseHelper(
        databaseOpener: () async {
          openCount++;

          // Tạo khoảng chờ để mô phỏng mở database chậm.
          await Future<void>.delayed(const Duration(milliseconds: 50));

          return databaseFactory.openDatabase(inMemoryDatabasePath);
        },
      );

      try {
        final databases = await Future.wait([
          concurrentHelper.database,
          concurrentHelper.database,
          concurrentHelper.database,
        ]);

        expect(openCount, 1);
        expect(identical(databases[0], databases[1]), true);
        expect(identical(databases[1], databases[2]), true);
      } finally {
        await concurrentHelper.close();
      }
    });

    test('có thể đóng database', () async {
      final db = await databaseHelper.database;

      await databaseHelper.close();

      expect(db.isOpen, false);
    });
  });
}
