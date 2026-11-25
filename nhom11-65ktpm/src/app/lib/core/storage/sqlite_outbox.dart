import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../contracts/outbox.dart';
import '../network/api_client.dart';
import 'database_helper.dart';

/// Outbox thật: lưu hàng đợi xuống SQLite để không mất dữ liệu
/// khi người dùng tắt hoặc khởi động lại ứng dụng.
class SQLiteOutbox implements Outbox {
  final DatabaseHelper _databaseHelper;
  final ApiClient _api;

  final StreamController<int> _changes = StreamController<int>.broadcast();

  Future<void>? _running;

  SQLiteOutbox(this._databaseHelper, this._api);

  @override
  Stream<int> get pendingChanges => _changes.stream;

  @override
  Future<int> pendingCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_outbox',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> enqueue(OutboxItem item) async {
    final db = await _databaseHelper.database;

    await db.insert('sync_outbox', {
      'id': item.id,
      'kind': item.kind,
      'payload': jsonEncode(item.payload),
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'attempts': item.attempts,
    });

    _changes.add(await pendingCount());

    // Lưu thành công rồi mới thử đồng bộ.
    unawaited(flush());
  }

  @override
  Future<void> flush() {
    return _running ??= _flush().whenComplete(() {
      _running = null;
    });
  }

  Future<void> _flush() async {
    final db = await _databaseHelper.database;

    // Chưa đăng nhập thì giữ nguyên dữ liệu.
    if ((await _api.storage.getToken()) == null) {
      return;
    }

    // Chỉ xử lý kind event vì API /events đã được xác minh.
    // Các kind khác tiếp tục nằm trong hàng đợi.
    while (true) {
      final rows = await db.query(
        'sync_outbox',
        where: 'kind = ?',
        whereArgs: ['event'],
        orderBy: 'created_at ASC',
        limit: 200,
      );

      if (rows.isEmpty) {
        return;
      }

      final ids = <String>[];
      final events = <Map<String, dynamic>>[];

      try {
        for (final row in rows) {
          ids.add(row['id'] as String);

          events.add(
            Map<String, dynamic>.from(
              jsonDecode(row['payload'] as String) as Map,
            ),
          );
        }
      } catch (e) {
        debugPrint('SQLiteOutbox: Dữ liệu Outbox không hợp lệ: $e');
        return;
      }

      // Gửi API. Nếu thất bại, giữ lại dữ liệu và dừng lượt flush.
      try {
        await _api.post('/events', body: {'events': events});
      } catch (e) {
        await db.transaction((txn) async {
          for (final id in ids) {
            await txn.rawUpdate(
              '''
              UPDATE sync_outbox
              SET attempts = attempts + 1
              WHERE id = ?
              ''',
              [id],
            );
          }
        });

        debugPrint(
          'SQLiteOutbox: Chưa gửi được ${ids.length} sự kiện. '
          'Dữ liệu vẫn được giữ lại. Lỗi: $e',
        );

        return;
      }

      // API đã thành công: xóa cả lô trong một transaction.
      // Nếu xóa thất bại, giữ dữ liệu và không tăng attempts.
      try {
        await db.transaction((txn) async {
          for (final id in ids) {
            await txn.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
          }
        });

        _changes.add(await pendingCount());
      } catch (e) {
        debugPrint(
          'SQLiteOutbox: API đã nhận dữ liệu nhưng xóa hàng đợi '
          'thất bại. Có thể cần thử lại. Lỗi: $e',
        );

        return;
      }

      // Tiếp tục lấy lô tiếp theo cho đến khi hết event.
    }
  }

  /// Đóng stream khi provider bị hủy.
  void dispose() {
    unawaited(_changes.close());
  }
}
