import 'dart:convert';
import 'dart:io';

import 'package:chungmo/core/utils/euc_kr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes the vectors produced by a reference CP949 codec', () {
    // Symbols, common Hangul, UHC-extension Hangul, Hanja and 300 random
    // syllables, encoded with Python's cp949 codec.
    final vectors = jsonDecode(
        File('test/core/utils/euc_kr_vectors.json').readAsStringSync()) as List;
    for (final v in vectors) {
      final bytes = (v['bytes'] as List).cast<int>();
      expect(decodeEucKr(bytes), v['text'], reason: 'vector: ${v['text']}');
    }
  });

  test('passes ASCII through and marks invalid sequences', () {
    expect(decodeEucKr('abc 123'.codeUnits), 'abc 123');
    expect(decodeEucKr([0x41, 0xB0]), 'A\ufffd');
    expect(decodeEucKr([0xA1, 0x20, 0x42]), '\ufffdB'.replaceFirst('B', ' B'));
  });
}
