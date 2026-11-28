import 'dart:convert';
import 'package:flutter/services.dart';

import '../../../../core/contracts/lesson_repository.dart';
import '../../../../core/contracts/speech_services.dart';

/// Bộ chuyển đổi Hán tự sang Pinyin và xử lý biến điệu theo CC-CEDICT.
/// Chủ sở hữu: Khanh (#12)
class CedictPinyinService implements PinyinService {
  final LessonRepository _lessons;
  Map<String, String>? _dict;

  CedictPinyinService(this._lessons);

  static const List<String> _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  /// Đọc từng chữ số (dùng cho số điện thoại, số có 0 ở đầu, phần thập phân).
  static String _readDigits(String digits) => digits.split('').map((d) => _digits[int.parse(d)]).join();

  /// Đọc số 0..9999 theo giá trị: 23 → 二十三, 105 → 一百零五, 1010 → 一千零一十.
  /// [omitLeadingOneTen]: 10..19 đứng đầu đọc 十… thay vì 一十… (sau 万 thì giữ 一十).
  static String _readUnder10000(int n, {bool omitLeadingOneTen = true}) {
    if (n == 0) return _digits[0];
    const units = ['千', '百', '十', ''];
    final parts = [n ~/ 1000, n ~/ 100 % 10, n ~/ 10 % 10, n % 10];
    final out = StringBuffer();
    var started = false;
    var zeroPending = false;
    for (var k = 0; k < 4; k++) {
      final d = parts[k];
      if (d == 0) {
        if (started) zeroPending = true;
        continue;
      }
      if (zeroPending) {
        out.write(_digits[0]);
        zeroPending = false;
      }
      if (units[k] == '十' && d == 1 && !started && omitLeadingOneTen) {
        out.write('十');
      } else {
        out.write('${_digits[d]}${units[k]}');
      }
      started = true;
    }
    return out.toString();
  }

  /// Đọc số nguyên theo cách nói tiếng Trung (#12).
  /// Số có 0 ở đầu (mã, số điện thoại) hoặc dài hơn 8 chữ số thì đọc từng chữ số.
  static String readNumber(String digits) {
    if ((digits.length > 1 && digits.startsWith('0')) || digits.length > 8) {
      return _readDigits(digits);
    }
    final n = int.parse(digits);
    if (n < 10000) return _readUnder10000(n);
    final high = n ~/ 10000;
    final low = n % 10000;
    final out = StringBuffer('${_readUnder10000(high)}万');
    if (low > 0) {
      if (low < 1000) out.write(_digits[0]);
      out.write(_readUnder10000(low, omitLeadingOneTen: false));
    }
    return out.toString();
  }

  static String normalize(String input) {
    var text = input.trim();
    // Số thập phân: 3.5 → 三点五
    text = text.replaceAllMapped(
      RegExp(r'(\d+)\.(\d+)'),
      (m) => '${readNumber(m[1]!)}点${_readDigits(m[2]!)}',
    );
    text = text.replaceAllMapped(RegExp(r'\d+'), (m) => readNumber(m[0]!));
    final punctRegex = RegExp(r"""[，。！？、；：“”‘’（）《》〈〉【】…—.,!?;:()\[\]"'\-]""");
    return text.replaceAll(punctRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _ensureLoaded() async {
    if (_dict != null) return;
    final dict = <String, String>{};

    // 1. Nạp từ điển CC-CEDICT Compact từ asset
    try {
      final jsonStr = await rootBundle.loadString('assets/data/cc_cedict_compact.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawDict = data['dictionary'] as Map<String, dynamic>?;
      if (rawDict != null) {
        rawDict.forEach((k, v) {
          dict[k] = (v as String).toLowerCase().trim();
        });
      }
    } catch (_) {
      // Fallback khi chạy unit test thuần túy không có asset bundle
    }

    // 2. Bổ sung từ vựng từ các bài học
    try {
      final allLessons = await _lessons.lessons();
      for (final l in allLessons) {
        for (final w in l.words) {
          dict[w.hanzi] = w.pinyin.toLowerCase().trim();
        }
      }
    } catch (_) {}

    // 3. Fallback tích hợp sẵn đảm bảo luôn có đủ từ vựng cơ bản và từng chữ đơn
    final fallbackDict = {
      '你好': 'nǐ hǎo', '您好': 'nín hǎo', '谢谢': 'xiè xie', '不客气': 'bú kè qi',
      '再见': 'zài jiàn', '对不起': 'duì bu qǐ', '没关系': 'méi guān xi', '请问': 'qǐng wèn',
      '中国': 'zhōng guó', '北京': 'běi jīng', '汉语': 'hàn yǔ', '老师': 'lǎo shī',
      '学生': 'xué sheng', '朋友': 'péng you', '爸爸': 'bà ba', '妈妈': 'mā ma',
      '今天': 'jīn tiān', '明天': 'míng tiān', '昨天': 'zuó tiān', '现在': 'xiàn zài',
      '喜欢': 'xǐ huan', '认识': 'rèn shi', '高兴': 'gāo xìng', '喝水': 'hē shuǐ',
      '吃米饭': 'chī mǐ fàn', '看书': 'kàn shū', '去学校': 'qù xué xiào',
      '买东西': 'mǎi dōng xi', '打电话': 'dǎ diàn huà', '听音乐': 'tīng yīn yuè',
      '一共': 'yī gòng', '一天': 'yī tiān', '不是': 'bù shì', '不用': 'bù yòng',
      '猫': 'māo', '狗': 'gǒu', '茶': 'chá', '喝茶': 'hē chá', '苹果': 'píng guǒ',
      '火车': 'huǒ chē', '水饺': 'shuǐ jiǎo', '饺子': 'jiǎo zi', '便宜': 'pián yi',
      '几': 'jǐ', '什么': 'shén me', '多少': 'duō shao', '怎么': 'zěn me',
      '一': 'yī', '二': 'èr', '三': 'sān', '四': 'sì', '五': 'wǔ',
      '六': 'liù', '七': 'qī', '八': 'bā', '九': 'jiǔ', '十': 'shí',
      '好': 'hǎo', '大': 'dà', '小': 'xiǎo', '多': 'duō', '少': 'shǎo',
      '冷': 'lěng', '热': 'rè', '快': 'kuài', '慢': 'màn',
      '我': 'wǒ', '你': 'nǐ', '他': 'tā', '她': 'tā', '我们': 'wǒmen',
      '是': 'shì', '有': 'yǒu', '在': 'zài', '不': 'bù', '没': 'méi',
      '想': 'xiǎng', '能': 'néng', '会': 'huì', '可以': 'kěyǐ', '做': 'zuò',
      '天': 'tiān', '年': 'nián', '起': 'qǐ', '看': 'kàn', '个': 'gè', '岁': 'suì',
    };
    fallbackDict.forEach((k, v) {
      dict.putIfAbsent(k, () => v);
    });

    _dict = dict;
  }

  @override
  Future<String> toPinyin(String hanzi, {bool applySandhi = false}) async {
    await _ensureLoaded();
    final clean = normalize(hanzi);
    final dict = _dict!;
    final hanziList = <String>[];
    final pinyinList = <String>[];

    var i = 0;
    while (i < clean.length) {
      if (clean[i] == ' ') {
        i++;
        continue;
      }

      var matched = false;
      // Khớp từ dài nhất trước (từ 4 chữ xuống 1 chữ)
      for (var len = 4; len >= 1; len--) {
        if (i + len <= clean.length) {
          final sub = clean.substring(i, i + len);
          final p = dict[sub];
          if (p != null) {
            final syls = p.split(RegExp(r'\s+'));
            if (syls.length == sub.length) {
              for (var k = 0; k < sub.length; k++) {
                hanziList.add(sub[k]);
                pinyinList.add(syls[k]);
              }
            } else {
              for (var k = 0; k < sub.length; k++) {
                final ch = sub[k];
                hanziList.add(ch);
                pinyinList.add(dict[ch] ?? (k < syls.length ? syls[k] : '?'));
              }
            }
            i += len;
            matched = true;
            break;
          }
        }
      }

      // Nếu không khớp cụm từ, tra theo từng chữ đơn
      if (!matched) {
        final ch = clean[i];
        final p = dict[ch];
        hanziList.add(ch);
        pinyinList.add(p ?? (RegExp(r'[\u4e00-\u9fff]').hasMatch(ch) ? '?' : ch));
        i++;
      }
    }

    if (applySandhi) {
      _applySandhiRules(hanziList, pinyinList);
    }

    return pinyinList.join(' ');
  }

  void _applySandhiRules(List<String> hanziList, List<String> pinyinList) {
    if (hanziList.length != pinyinList.length) return;
    final n = hanziList.length;

    // 1. Biến điệu hai thanh 3 liền nhau: thanh 3 trước chuyển sang thanh 2
    for (var i = 0; i < n - 1; i++) {
      final p1 = pinyinList[i];
      final p2 = pinyinList[i + 1];
      if (_hasTone3(p1) && _hasTone3(p2)) {
        pinyinList[i] = _changeToTone2(p1);
      }
    }

    // 2. Biến điệu chữ 不:
    // - Đứng trước thanh 4: đọc thành bú (thanh 2)
    // - Ở giữa cấu trúc lặp lại động từ (A 不 A): đọc thanh nhẹ bu
    for (var i = 0; i < n; i++) {
      if (hanziList[i] == '不') {
        if (i > 0 && i < n - 1 && hanziList[i - 1] == hanziList[i + 1]) {
          pinyinList[i] = 'bu';
        } else if (i < n - 1 && _hasTone4(pinyinList[i + 1])) {
          pinyinList[i] = 'bú';
        }
      }
    }

    // 3. Biến điệu chữ 一:
    // - Ở giữa cấu trúc lặp lại động từ (A 一 A): đọc thanh nhẹ yi
    // - Đứng trước thanh 4: đọc thành yí (thanh 2)
    // - Đứng trước thanh 1, 2, 3: đọc thành yì (thanh 4)
    for (var i = 0; i < n; i++) {
      if (hanziList[i] == '一') {
        if (i > 0 && i < n - 1 && hanziList[i - 1] == hanziList[i + 1]) {
          pinyinList[i] = 'yi';
        } else if (i < n - 1) {
          final next = pinyinList[i + 1];
          if (_hasTone4(next)) {
            pinyinList[i] = 'yí';
          } else if (_hasTone1(next) || _hasTone2(next) || _hasTone3(next)) {
            pinyinList[i] = 'yì';
          }
        }
      }
    }
  }

  bool _hasTone1(String p) => RegExp(r'[āēīōūǖ]').hasMatch(p);
  bool _hasTone2(String p) => RegExp(r'[áéíóúǘ]').hasMatch(p);
  bool _hasTone3(String p) => RegExp(r'[ǎěǐǒǔǚ]').hasMatch(p);
  bool _hasTone4(String p) => RegExp(r'[àèìòùǜ]').hasMatch(p);

  int getToneNumber(String p) {
    if (_hasTone1(p)) return 1;
    if (_hasTone2(p)) return 2;
    if (_hasTone3(p)) return 3;
    if (_hasTone4(p)) return 4;
    return 5;
  }

  String _changeToTone2(String p) {
    return p
        .replaceAll('ǎ', 'á')
        .replaceAll('ě', 'é')
        .replaceAll('ǐ', 'í')
        .replaceAll('ǒ', 'ó')
        .replaceAll('ǔ', 'ú')
        .replaceAll('ǚ', 'ǘ');
  }

  String removeToneMarks(String p) {
    return p
        .replaceAll(RegExp(r'[āáǎà]'), 'a')
        .replaceAll(RegExp(r'[ēéěè]'), 'e')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ōóǒò]'), 'o')
        .replaceAll(RegExp(r'[ūúǔù]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜ]'), 'ü');
  }
}
