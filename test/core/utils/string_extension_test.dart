import 'dart:typed_data';

import 'package:chungmo/core/utils/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isHttpUrl', () {
    test('accepts http and https URLs with a host', () {
      expect('https://mcard.example.com/w/abc'.isHttpUrl, isTrue);
      expect('http://example.com'.isHttpUrl, isTrue);
    });

    test('rejects synthetic keys, plain text and schemeless input', () {
      expect('image://12345'.isHttpUrl, isFalse);
      expect('text://67890'.isHttpUrl, isFalse);
      expect('manual://1700000000000'.isHttpUrl, isFalse);
      expect('철수와 영희가 결혼합니다 https://x.com'.isHttpUrl, isFalse);
      expect('example.com/no-scheme'.isHttpUrl, isFalse);
      expect(''.isHttpUrl, isFalse);
    });
  });

  group('hashBytes', () {
    test('is deterministic and content-sensitive', () async {
      final Uint8List a = Uint8List.fromList(List.generate(1024, (i) => i % 251));
      final Uint8List sameAsA = Uint8List.fromList(a);
      final Uint8List b = Uint8List.fromList(a)..[0] = 42;

      expect(await a.hashBytes, await sameAsA.hashBytes);
      expect(await a.hashBytes, isNot(await b.hashBytes));
    });

    test('fits the positive 32-bit range used for schedule keys', () async {
      final int hash = await Uint8List.fromList([1, 2, 3]).hashBytes;
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThan(1 << 31));
    });
  });
}
