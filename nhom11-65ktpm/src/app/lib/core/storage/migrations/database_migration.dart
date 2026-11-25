import 'package:sqflite/sqflite.dart' as sqflite;

/// Hợp đồng chung cho một migration SQLite.
abstract class DatabaseMigration {
  /// Số thứ tự duy nhất của migration.
  int get version;

  /// Mô tả ngắn về migration.
  String get description;

  /// Thực hiện thay đổi cấu trúc database.
  Future<void> up(sqflite.DatabaseExecutor db);
}
