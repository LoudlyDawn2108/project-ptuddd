import 'dart:convert';
import 'dart:io';

import 'package:chailish/features/pronunciation/engine/offline_pronunciation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chạy engine chấm offline (#13) qua toàn bộ bộ test case dùng chung (#16).
///
/// Dữ liệu: `nhom11-65ktpm/data/pronunciation/test_cases.json` (định dạng: mục 5
/// `docs/hop-dong-du-lieu.md`). Thêm ca mới (ví dụ Hoa bổ sung ở #22) chỉ cần sửa
/// file JSON, không phải sửa file test này.
///
/// `error_syllables` = chỉ số các âm tiết mà engine ghi nhận có lỗi (`errors` không rỗng),
/// kể cả lỗi nhẹ vẫn tô xanh như nhầm zh → z.
const _casesPath = '../../data/pronunciation/test_cases.json';

void main() {
  final file = File(_casesPath);
  if (!file.existsSync()) {
    test('test_cases.json tồn tại', () => fail('Không tìm thấy $_casesPath'));
    return;
  }
  final cases = (jsonDecode(file.readAsStringSync()) as List).cast<Map<String, dynamic>>();

  test('bộ test case có dữ liệu và id không trùng', () {
    expect(cases, isNotEmpty);
    final ids = cases.map((c) => c['id']).toList();
    expect(ids.toSet().length, ids.length, reason: 'id bị trùng: $ids');
  });

  final engine = OfflinePronunciationEngine();

  group('OfflinePronunciationEngine × test_cases.json', () {
    for (final c in cases) {
      final id = c['id'] as String;
      final ref = c['reference'] as Map<String, dynamic>;
      final exp = c['expected'] as Map<String, dynamic>;
      final note = c['note'] ?? '';

      test('$id: $note', () async {
        final res = await engine.assess(
          referenceHanzi: ref['hanzi'] as String,
          referencePinyin: ref['pinyin'] as String,
          recognizedPinyin: c['spoken_pinyin'] as String,
        );

        final min = (exp['min_overall'] as num).toDouble();
        final max = (exp['max_overall'] as num).toDouble();
        expect(res.overall, inInclusiveRange(min, max),
            reason: '$id: overall=${res.overall}, cần trong [$min, $max]');

        final errorIdx = [
          for (var i = 0; i < res.syllables.length; i++)
            if (res.syllables[i].errors.isNotEmpty) i,
        ];
        final expectedIdx = (exp['error_syllables'] as List).cast<int>();
        expect(errorIdx, expectedIdx,
            reason: '$id: âm tiết lỗi=$errorIdx, cần $expectedIdx '
                '(${res.syllables.map((s) => '${s.hanzi}:${s.errors.map((e) => e.name).join('+')}').join(' ')})');
      });
    }
  });
}
