import 'package:chailish/core/contracts/speech_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickChineseLocale (#11)', () {
    test('ưu tiên zh-CN / cmn-Hans', () {
      expect(pickChineseLocale(['en_US', 'zh_TW', 'zh_CN']), 'zh_CN');
      expect(pickChineseLocale(['vi-VN', 'cmn-Hans-CN']), 'cmn-Hans-CN');
    });

    test('không có zh-CN thì dùng locale tiếng Trung khác', () {
      expect(pickChineseLocale(['en-US', 'zh-TW']), 'zh-TW');
    });

    test('máy không có gói tiếng Trung trả null, không lấy locale đầu tiên', () {
      expect(pickChineseLocale(['en-US', 'vi-VN']), isNull);
    });

    test('máy không liệt kê locale thì vẫn thử zh-CN', () {
      expect(pickChineseLocale([]), 'zh-CN');
    });
  });
}
