import 'dart:convert';
import 'dart:io';

import 'package:chailish/core/contracts/lesson_repository.dart';
import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _lesson({
  int serverId = 7,
  int contentVersion = 1,
  String id = 'hsk1-greetings-01',
  String level = 'HSK1',
  int order = 1,
  String title = 'Chào hỏi cơ bản',
}) => {
  'serverId': serverId,
  'schemaVersion': 1,
  'contentVersion': contentVersion,
  'id': id,
  'level': level,
  'order': order,
  'title': title,
  'topic': 'chào hỏi',
  'description': 'Làm quen với lời chào.',
  'vocabulary': [
    {
      'id': 'ni-hao',
      'hanzi': '你好',
      'pinyin': 'nǐ hǎo',
      'hanViet': 'nhĩ hảo',
      'meaningVi': 'xin chào',
      'example': {'hanzi': '你好！', 'pinyin': 'Nǐ hǎo!', 'meaningVi': 'Xin chào!'},
    },
  ],
  'grammarPoints': [],
  'aiScenario': {
    'aiRole': 'Bạn mới',
    'learnerRole': 'Người học',
    'situation': 'Gặp nhau lần đầu.',
    'openingLine': '你好！',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('loads lessons, sorts by level rank, and applies since_version updates', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      baseUrl: 'http://example.test/api',
      storage: SecureStorageService(const FlutterSecureStorage()),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.queryParameters['since_version'] == '0') {
          return http.Response(
            jsonEncode([
              _lesson(serverId: 20, id: 'hsk2-family-01', level: 'HSK2', order: 1, title: 'HSK2'),
              _lesson(serverId: 7, id: 'hsk1-greetings-01', level: 'HSK1', order: 1),
              _lesson(serverId: 1, id: 'pinyin-tones-01', level: 'PINYIN', order: 1, title: 'Pinyin'),
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode([
            _lesson(
              serverId: 7,
              contentVersion: 2,
              title: 'Chào hỏi cơ bản mới',
            ),
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiLessonRepository(api);

    final initial = await repository.lessons();
    expect(initial.map((l) => l.level).toList(), ['PINYIN', 'HSK1', 'HSK2']);
    expect(initial[1].id, 7);
    expect(initial[1].code, 'hsk1-greetings-01');
    expect(initial[1].words.single.key, 'hsk1-greetings-01/ni-hao');
    expect(requests[0].url.queryParameters['since_version'], '0');

    final updated = await repository.lessons();
    expect(updated[1].title, 'Chào hỏi cơ bản mới');
    expect(requests[1].url.queryParameters['since_version'], '1');
    expect((await repository.lessonById(7))?.title, 'Chào hỏi cơ bản mới');
    expect(requests.length, 2);
  });

  test('lessonById caches hit without advancing since_version cursor', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      baseUrl: 'http://example.test/api',
      storage: SecureStorageService(const FlutterSecureStorage()),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/404')) {
          return http.Response(jsonEncode({'detail': 'not found'}), 404);
        }
        if (request.url.path.endsWith('/7')) {
          return http.Response(
            jsonEncode(_lesson(serverId: 7, contentVersion: 2)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode([
            _lesson(serverId: 7, contentVersion: 2),
            _lesson(serverId: 8, id: 'hsk1-family-02', order: 2, contentVersion: 1),
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiLessonRepository(api);

    expect((await repository.lessonById(7))?.id, 7);
    expect(await repository.lessonById(404), isNull);

    final all = await repository.lessons();
    expect(requests.last.url.queryParameters['since_version'], '0');
    expect(all.map((l) => l.id).toList(), [7, 8]);
  });

  test('falls back to AssetLessonRepository when offline and cache is empty', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test/api',
      storage: SecureStorageService(const FlutterSecureStorage()),
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    final repository = ApiLessonRepository(api, fallback: AssetLessonRepository());

    final lessons = await repository.lessons();
    expect(lessons, isNotEmpty);
    expect(lessons.first.code, 'hsk1-greetings-01');
  });

  test('returns cached lessons when server becomes unreachable after initial load', () async {
    var online = true;
    final api = ApiClient(
      baseUrl: 'http://example.test/api',
      storage: SecureStorageService(const FlutterSecureStorage()),
      client: MockClient((_) async {
        if (!online) throw const SocketException('offline');
        return http.Response(
          jsonEncode([_lesson(serverId: 7, contentVersion: 1)]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = ApiLessonRepository(api);

    final first = await repository.lessons();
    expect(first.single.id, 7);

    online = false;
    final cached = await repository.lessons();
    expect(cached.single.id, 7);
  });
}
