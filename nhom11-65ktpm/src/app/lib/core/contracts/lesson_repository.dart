import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../network/api_client.dart';
import 'fake_implementation.dart';
import 'models/lesson.dart';

/// Nguồn bài học + từ vựng. Chủ sở hữu: **Hoa** (#18 API, #19 màn hình, #23 cache offline).
///
/// Bản giả đọc các bài mẫu trong `assets/dev/lessons/` (bản sao của `data/lessons/`).
/// Bản thật gọi `GET /api/lessons?since_version=` với cache RAM (sẽ nối SQLite khi #23 xong).
abstract class LessonRepository {
  /// Mọi bài, sắp theo cấp độ rồi thứ tự.
  Future<List<Lesson>> lessons();

  Future<Lesson?> lessonById(int id);

  Future<Lesson?> lessonByCode(String code) async {
    for (final l in await lessons()) {
      if (l.code == code) return l;
    }
    return null;
  }
}

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  if (AppConfig.fakeData) return AssetLessonRepository();
  return ApiLessonRepository(
    ref.watch(apiClientProvider),
    fallback: AssetLessonRepository(),
  );
});

class AssetLessonRepository extends LessonRepository with FakeImplementation {
  static const _dir = 'assets/dev/lessons/';
  final AssetBundle _bundle;
  List<Lesson>? _cache;

  AssetLessonRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  @override
  Future<List<Lesson>> lessons() async {
    if (_cache != null) return _cache!;
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final files = manifest.listAssets().where((p) => p.startsWith(_dir) && p.endsWith('.json')).toList();
    final raws = <Map<String, dynamic>>[
      for (final f in files) jsonDecode(await _bundle.loadString(f)) as Map<String, dynamic>,
    ];
    raws.sort((a, b) {
      final lv = (a['level'] as String? ?? '').compareTo(b['level'] as String? ?? '');
      return lv != 0 ? lv : (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0);
    });
    // Id = thứ tự nạp, trùng với id mà seed_dev.py tạo trên CSDL mới.
    return _cache = [for (var i = 0; i < raws.length; i++) Lesson.fromJson(raws[i], id: i + 1)];
  }

  @override
  Future<Lesson?> lessonById(int id) async {
    for (final l in await lessons()) {
      if (l.id == id) return l;
    }
    return null;
  }
}

class ApiLessonRepository extends LessonRepository {
  static const _levelOrder = ['PINYIN', 'HSK1', 'HSK2'];

  final ApiClient _api;
  final LessonRepository? _fallback;
  final Map<int, Lesson> _cache = {};
  int _contentVersion = 0;

  ApiLessonRepository(this._api, {LessonRepository? fallback}) : _fallback = fallback;

  static int _levelRank(String level) {
    final index = _levelOrder.indexOf(level);
    return index < 0 ? _levelOrder.length : index;
  }

  List<Lesson> _sortedCache() {
    final lessons = _cache.values.toList()
      ..sort((a, b) {
        final rankCmp = _levelRank(a.level).compareTo(_levelRank(b.level));
        if (rankCmp != 0) return rankCmp;
        final levelCmp = a.level.compareTo(b.level);
        if (levelCmp != 0) return levelCmp;
        final orderCmp = a.order.compareTo(b.order);
        return orderCmp != 0 ? orderCmp : a.id.compareTo(b.id);
      });
    return lessons;
  }

  Lesson _parseLesson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Bản ghi bài học từ API không hợp lệ.');
    }
    final serverId = raw['serverId'];
    if (serverId is! int) {
      throw const FormatException('Bài học từ API thiếu serverId hợp lệ.');
    }
    return Lesson.fromJson(raw, id: serverId);
  }

  @override
  Future<List<Lesson>> lessons() async {
    try {
      final response = await _api.get('/lessons?since_version=$_contentVersion');
      if (response is! List) {
        throw const FormatException('API bài học phải trả về một danh sách.');
      }

      for (final item in response) {
        final lesson = _parseLesson(item);
        _cache[lesson.id] = lesson;
        if (lesson.contentVersion > _contentVersion) {
          _contentVersion = lesson.contentVersion;
        }
      }
      return _sortedCache();
    } on NetworkException catch (error) {
      return _offlineLessonsOrRethrow(error);
    } on ApiException catch (error) {
      return _offlineLessonsOrRethrow(error);
    } on http.ClientException catch (error) {
      return _offlineLessonsOrRethrow(error);
    }
  }

  Future<List<Lesson>> _offlineLessonsOrRethrow(Object error) async {
    if (_cache.isNotEmpty) return _sortedCache();
    if (_fallback != null) {
      debugPrint('LessonRepository: không gọi được API ($error), dùng dữ liệu cục bộ.');
      return _fallback.lessons();
    }
    throw error;
  }

  @override
  Future<Lesson?> lessonById(int id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    try {
      final response = await _api.get('/lessons/$id');
      final lesson = _parseLesson(response);
      _cache[lesson.id] = lesson;
      return lesson;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      if (_fallback != null) {
        debugPrint('LessonRepository: lỗi API bài $id ($error), dùng dữ liệu cục bộ.');
        return _fallback.lessonById(id);
      }
      rethrow;
    } on NetworkException catch (error) {
      if (_fallback != null) {
        debugPrint('LessonRepository: mất mạng bài $id ($error), dùng dữ liệu cục bộ.');
        return _fallback.lessonById(id);
      }
      rethrow;
    } on http.ClientException catch (error) {
      if (_fallback != null) {
        debugPrint('LessonRepository: lỗi kết nối bài $id ($error), dùng dữ liệu cục bộ.');
        return _fallback.lessonById(id);
      }
      rethrow;
    }
  }
}
