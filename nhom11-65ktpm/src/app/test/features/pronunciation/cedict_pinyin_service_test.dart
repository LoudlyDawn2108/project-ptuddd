import 'package:chailish/core/contracts/lesson_repository.dart';
import 'package:chailish/core/contracts/models/lesson.dart';
import 'package:chailish/features/pronunciation/engine/cedict_pinyin_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLessonRepo implements LessonRepository {
  @override
  Future<List<Lesson>> lessons() async => [];

  @override
  Future<Lesson?> lessonById(int id) async => null;

  @override
  Future<Lesson?> lessonByCode(String code) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CedictPinyinService service;

  setUp(() {
    service = CedictPinyinService(_FakeLessonRepo());
  });

  group('CedictPinyinService toPinyin & normalization', () {
    test('converts basic words accurately', () async {
      final p1 = await service.toPinyin('你好');
      expect(p1, 'nǐ hǎo');

      final p2 = await service.toPinyin('谢谢');
      expect(p2, 'xiè xie');

      final p3 = await service.toPinyin('老师');
      expect(p3, 'lǎo shī');
    });

    test('normalizes numbers and punctuation', () async {
      final p = await service.toPinyin('你好！123');
      expect(p, 'nǐ hǎo yī bǎi èr shí sān');
    });

    test('reads integers by value, not digit by digit (#12)', () {
      String n(String s) => CedictPinyinService.normalize(s);
      expect(n('0'), '零');
      expect(n('7'), '七');
      expect(n('10'), '十');
      expect(n('15'), '十五');
      expect(n('20'), '二十');
      expect(n('23'), '二十三');
      expect(n('100'), '一百');
      expect(n('105'), '一百零五');
      expect(n('110'), '一百一十');
      expect(n('1005'), '一千零五');
      expect(n('1010'), '一千零一十');
      expect(n('2026'), '两千零二十六');
      expect(n('2000'), '两千');
      expect(n('20000'), '两万');
      expect(n('22000'), '两万两千');
      expect(n('200'), '二百');
      expect(n('10000'), '一万');
      expect(n('10010'), '一万零一十');
      expect(n('35000'), '三万五千');
      expect(n('我23岁'), '我二十三岁');
      expect(n('3.5'), '三点五');
    });

    test('keeps digit-by-digit reading for phone numbers and leading zeros (#12)', () {
      expect(CedictPinyinService.normalize('0912345678'), '零九一二三四五六七八');
      expect(CedictPinyinService.normalize('007'), '零零七');
    });

    test('reads numbers by context: year, date, time, phone, section (review PR #73)', () {
      String n(String s) => CedictPinyinService.normalize(s);
      // Năm đọc từng chữ số
      expect(n('2026年'), '二零二六年');
      expect(n('我1998年出生'), '我一九九八年出生');
      expect(n('10年'), '十年'); // "10 năm" vẫn là số đếm
      // Ngày
      expect(n('2026-11-28'), '二零二六年十一月二十八日');
      expect(n('2026/1/5'), '二零二六年一月五日');
      // Giờ
      expect(n('10:30'), '十点三十分');
      expect(n('10:05'), '十点零五分');
      expect(n('2:00'), '两点');
      expect(n('8:15:20'), '八点十五分二十秒');
      // Số điện thoại / mã số có dấu "-" hoặc khoảng trắng
      expect(n('091-234-5678'), '零九一二三四五六七八');
      expect(n('0912 345 678'), '零九一二三四五六七八');
      // Số mục, phiên bản, thập phân
      expect(n('第1.2课'), '第一点二课');
      expect(n('1.2.3'), '一点二点三');
      expect(n('3.14'), '三点一四');
    });

    test('year and time convert to the expected pinyin (review PR #73)', () async {
      expect(await service.toPinyin('2026年'), 'èr líng èr liù nián');
      expect(await service.toPinyin('2:30'), 'liǎng diǎn sān shí fēn');
    });

    test('23 converts to pinyin èr shí sān (#12)', () async {
      expect(await service.toPinyin('23'), 'èr shí sān');
    });

    test('converts words outside lessons using CC-CEDICT compact', () async {
      // Các từ ngoài bài học 1-3
      final p1 = await service.toPinyin('猫');
      expect(p1, 'māo');

      final p2 = await service.toPinyin('狗');
      expect(p2, 'gǒu');

      final p3 = await service.toPinyin('喝茶');
      expect(p3, 'hē chá');

      final p4 = await service.toPinyin('苹果');
      expect(p4, 'píng guǒ');

      final p5 = await service.toPinyin('火车');
      expect(p5, 'huǒ chē');
    });

    test('converts 便 as biàn, and 便宜 as piányi', () async {
      final p1 = await service.toPinyin('便');
      expect(p1, 'biàn');

      final p2 = await service.toPinyin('便宜');
      expect(p2, 'pián yi');
    });

    test('falls back to character-by-character lookup for unknown compounds', () async {
      // Cụm từ ghép chưa có trong từ điển: tra theo từng chữ đơn "看" + "猫"
      final p = await service.toPinyin('看猫');
      expect(p, 'kàn māo');
    });
  });

  group('CedictPinyinService tone sandhi rules (biến điệu)', () {
    test('3-3 sandhi: first tone 3 changes to tone 2 when applySandhi is true', () async {
      // Without sandhi
      final raw = await service.toPinyin('你好', applySandhi: false);
      expect(raw, 'nǐ hǎo');

      // With sandhi
      final sandhi = await service.toPinyin('你好', applySandhi: true);
      expect(sandhi, 'ní hǎo');

      final s2 = await service.toPinyin('水饺', applySandhi: true);
      expect(s2, 'shuí jiǎo');
    });

    test('bu sandhi: 不 before tone 4 becomes bú, between duplicate verbs becomes bu', () async {
      // Đứng trước thanh 4: bú
      final b1 = await service.toPinyin('不是', applySandhi: true);
      expect(b1, 'bú shì');

      // Đứng trước thanh khác (thanh 1, 2, 3): giữ nguyên bù
      final b2 = await service.toPinyin('不行', applySandhi: true);
      expect(b2.split(' ').first, 'bù');

      // Ở giữa động từ lặp lại: bu (thanh nhẹ)
      final b3 = await service.toPinyin('想不想', applySandhi: true);
      expect(b3, 'xiǎng bu xiǎng');
    });

    test('yi sandhi: 一 before tone 4 becomes yí, before tone 1-3 becomes yì, between verbs becomes yi', () async {
      // Đứng trước thanh 4: yí
      final y1 = await service.toPinyin('一共', applySandhi: true);
      expect(y1, 'yí gòng');

      // 一个: 个 là thanh 4 → yí gè (#12)
      expect(await service.toPinyin('一个', applySandhi: true), 'yí gè');
      expect(await service.toPinyin('一个', applySandhi: false), 'yī gè');

      // Đứng trước thanh 1: yì
      final y2 = await service.toPinyin('一天', applySandhi: true);
      expect(y2, 'yì tiān');

      // Ở giữa động từ lặp lại: yi
      final y3 = await service.toPinyin('看一看', applySandhi: true);
      expect(y3, 'kàn yi kàn');
    });
  });

  group('Helper methods: tones & tone stripping', () {
    test('getToneNumber extracts correct tone 1..5', () {
      expect(service.getToneNumber('mā'), 1);
      expect(service.getToneNumber('má'), 2);
      expect(service.getToneNumber('mǎ'), 3);
      expect(service.getToneNumber('mà'), 4);
      expect(service.getToneNumber('ma'), 5);
    });

    test('removeToneMarks strips all diacritics', () {
      expect(service.removeToneMarks('nǐ'), 'ni');
      expect(service.removeToneMarks('hǎo'), 'hao');
      expect(service.removeToneMarks('lǚ'), 'lü');
    });
  });
}
