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

  test('recovers from invalid pairs the way browsers do (WHATWG euc-kr)', () {
    // Unassigned symbol cell 0xA5 0xAB: both bytes become one U+FFFD; the
    // ASCII byte after it is read normally (a Python-style decoder would
    // re-read 0xAB 0x41 as 첔 instead).
    expect(decodeEucKr([0xA5, 0xAB, 0x41]), '\ufffdA');
    // Unassigned row 0xAD with a non-ASCII trail: consumed together.
    expect(decodeEucKr([0xAD, 0xA1, 0x41]), '\ufffdA');
    // A lead followed by an ASCII byte: only the lead is dropped.
    expect(decodeEucKr([0xB0, 0x20, 0x41]), '\ufffd A');
  });

  test('passes ASCII through and marks invalid sequences', () {
    expect(decodeEucKr('abc 123'.codeUnits), 'abc 123');
    expect(decodeEucKr([0x41, 0xB0]), 'A\ufffd');
    expect(decodeEucKr([0xA1, 0x20, 0x42]), '\ufffdB'.replaceFirst('B', ' B'));
  });
}
