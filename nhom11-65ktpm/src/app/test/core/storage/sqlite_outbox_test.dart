import 'dart:convert';
import 'dart:io';

import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:chailish/core/storage/database_helper.dart';
import 'package:chailish/core/storage/sqlite_outbox.dart';
import 'package:chailish/core/contracts/outbox.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SQLiteOutbox', () {
    late DatabaseHelper databaseHelper;
    late SecureStorageService storage;
    late List<http.Request> sent;
    late ApiClient api;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});

      databaseHelper = DatabaseHelper(
        databaseOpener: () {
          return databaseFactory.openDatabase(inMemoryDatabasePath);
        },
      );

      storage = SecureStorageService(const FlutterSecureStorage());

      sent = [];

      api = ApiClient(
        baseUrl: 'http://x/api',
        storage: storage,
        client: MockClient((request) async {
          sent.add(request);

          final events = jsonDecode(request.body)['events'] as List;

          return http.Response(
            jsonEncode({
              'accepted': events.length,
              'duplicates': 0,
              'xp_total': events.length,
              'current_streak': 1,
              'longest_streak': 1,
            }),
            200,
          );
        }),
      );
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    test('enqueue lưu dữ liệu vào SQLite', () async {
      final outbox = SQLiteOutbox(databaseHelper, api);

      await outbox.enqueue(
        OutboxItem(
          kind: 'event',
          payload: {'id': 'event-1', 'type': 'study_session'},
        ),
      );

      expect(await outbox.pendingCount(), 1);

      final db = await databaseHelper.database;
      final rows = await db.query('sync_outbox');

      expect(rows.length, 1);
      expect(rows.first['id'], isNotEmpty);
      expect(rows.first['kind'], 'event');

      final payload = jsonDecode(rows.first['payload'] as String);

      expect(payload['id'], 'event-1');

      outbox.dispose();
    });

    test('event được gửi lên API và xóa sau khi thành công', () async {
      await storage.saveToken('token');

      final outbox = SQLiteOutbox(databaseHelper, api);

      await outbox.enqueue(
        OutboxItem(
          kind: 'event',
          payload: {'id': 'event-2', 'type': 'study_session'},
        ),
      );

      await outbox.flush();

      expect(sent, isNotEmpty);
      expect(sent.first.url.path, '/api/events');
      expect(sent.first.headers['Authorization'], 'Bearer token');
      expect(await outbox.pendingCount(), 0);

      outbox.dispose();
    });

    test('chưa đăng nhập thì dữ liệu vẫn được giữ lại', () async {
      final outbox = SQLiteOutbox(databaseHelper, api);

      await outbox.enqueue(
        OutboxItem(kind: 'event', payload: {'id': 'event-3'}),
      );

      await outbox.flush();

      expect(sent, isEmpty);
      expect(await outbox.pendingCount(), 1);

      outbox.dispose();
    });

    test('kind chưa hỗ trợ vẫn được giữ trong hàng đợi', () async {
      await storage.saveToken('token');

      final outbox = SQLiteOutbox(databaseHelper, api);

      await outbox.enqueue(
        OutboxItem(kind: 'writing_attempt', payload: {'id': 'writing-1'}),
      );

      await outbox.flush();

      expect(sent, isEmpty);
      expect(await outbox.pendingCount(), 1);

      outbox.dispose();
    });

    test('API thất bại thì dữ liệu vẫn được giữ lại', () async {
      await storage.saveToken('token');

      final failingApi = ApiClient(
        baseUrl: 'http://x/api',
        storage: storage,
        client: MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Server error'}), 500);
        }),
      );

      final outbox = SQLiteOutbox(databaseHelper, failingApi);

      await outbox.enqueue(
        OutboxItem(kind: 'event', payload: {'id': 'event-4'}),
      );

      await outbox.flush();

      expect(await outbox.pendingCount(), 1);

      final db = await databaseHelper.database;
      final rows = await db.query('sync_outbox');

      expect(rows.first['attempts'], greaterThan(0));

      outbox.dispose();
    });

    test(
      'dữ liệu Outbox vẫn tồn tại sau khi đóng và mở lại database',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('chailish_test_');

        final dbPath = p.join(tempDir.path, 'outbox_test.db');

        DatabaseHelper? firstHelper;
        DatabaseHelper? secondHelper;
        SQLiteOutbox? firstOutbox;
        SQLiteOutbox? secondOutbox;

        try {
          // Mở database lần thứ nhất.
          firstHelper = DatabaseHelper(
            databaseOpener: () {
              return databaseFactory.openDatabase(dbPath);
            },
          );

          firstOutbox = SQLiteOutbox(firstHelper, api);

          // Lưu một sự kiện chưa đồng bộ.
          await firstOutbox.enqueue(
            OutboxItem(kind: 'event', payload: {'id': 'persistent-event'}),
          );

          // Chờ flush tự động hoàn tất.
          await firstOutbox.flush();

          expect(await firstOutbox.pendingCount(), 1);

          firstOutbox.dispose();
          firstOutbox = null;

          // Đóng database lần thứ nhất.
          await firstHelper.close();
          firstHelper = null;

          // Mở lại đúng file database cũ.
          secondHelper = DatabaseHelper(
            databaseOpener: () {
              return databaseFactory.openDatabase(dbPath);
            },
          );

          secondOutbox = SQLiteOutbox(secondHelper, api);

          // Dữ liệu phải vẫn còn sau khi mở lại.
          expect(await secondOutbox.pendingCount(), 1);

          final db = await secondHelper.database;
          final rows = await db.query('sync_outbox');

          expect(rows.length, 1);
          expect(rows.first['id'], isNotEmpty);
          expect(rows.first['kind'], 'event');

          final payload = jsonDecode(rows.first['payload'] as String);

          expect(payload['id'], 'persistent-event');
        } finally {
          firstOutbox?.dispose();
          secondOutbox?.dispose();

          await firstHelper?.close();
          await secondHelper?.close();

          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}
