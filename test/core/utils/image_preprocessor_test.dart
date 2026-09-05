import 'dart:typed_data';

import 'package:chungmo/core/utils/image_preprocessor.dart';
import 'package:chungmo/domain/entities/invitation_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Encodes a solid-color PNG of the given size, standing in for a capture.
Uint8List buildPng({required int width, required int height}) {
  return img.encodePng(img.Image(width: width, height: height));
}

/// A PNG signature plus a valid IHDR chunk declaring [width]x[height], with
/// no pixel data — enough for a header-only parse, hostile as a full decode.
Uint8List buildPngHeader({required int width, required int height}) {
  final BytesBuilder b = BytesBuilder();
  b.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ByteData ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6) // RGBA
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final Uint8List typeAndData = Uint8List.fromList(
      [...'IHDR'.codeUnits, ...ihdr.buffer.asUint8List()]);
  b.add((ByteData(4)..setUint32(0, 13)).buffer.asUint8List());
  b.add(typeAndData);
  b.add((ByteData(4)..setUint32(0, _crc32(typeAndData))).buffer.asUint8List());
  return b.toBytes();
}

int _crc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (final int byte in bytes) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

void main() {
  group('ImagePreprocessor.downscaleSync', () {
    test('shrinks a wide oversized image to the max width as JPEG', () {
      final InvitationImage result = ImagePreprocessor.downscaleSync(
        InvitationImage(
          bytes: buildPng(width: 3200, height: 1600),
          mimeType: 'image/png',
        ),
      );

      final img.Image decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, ImagePreprocessor.maxDimension);
      expect(decoded.height, 800);
      expect(result.mimeType, 'image/jpeg');
    });

    test('shrinks a tall image by its height instead', () {
      final InvitationImage result = ImagePreprocessor.downscaleSync(
        InvitationImage(
          bytes: buildPng(width: 1000, height: 2000),
          mimeType: 'image/png',
        ),
      );

      final img.Image decoded = img.decodeImage(result.bytes)!;
      expect(decoded.height, ImagePreprocessor.maxDimension);
      expect(decoded.width, 800);
    });

    test('passes a small image through untouched — no quality loss', () {
      final InvitationImage input = InvitationImage(
        bytes: buildPng(width: 800, height: 600),
        mimeType: 'image/png',
      );

      final InvitationImage result = ImagePreprocessor.downscaleSync(input);

      expect(identical(result, input), isTrue);
    });

    test('refuses to decode an image whose header declares too many pixels',
        () {
      // A hand-built PNG header claiming 60000x60000 (~3.6 gigapixels).
      // Only the header is parsed; actually decoding it would allocate an
      // unbounded raster from external bytes.
      final InvitationImage input = InvitationImage(
        bytes: buildPngHeader(width: 60000, height: 60000),
        mimeType: 'image/png',
      );

      expect(identical(ImagePreprocessor.downscaleSync(input), input), isTrue);
    });

    test('passes undecodable bytes through for the parser to reject', () {
      final InvitationImage input = InvitationImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'image/jpeg',
      );

      expect(identical(ImagePreprocessor.downscaleSync(input), input), isTrue);
    });
  });

  test('downscale runs the same logic through a background isolate',
      () async {
    final InvitationImage result = await ImagePreprocessor.downscale(
      InvitationImage(
        bytes: buildPng(width: 2000, height: 2000),
        mimeType: 'image/png',
      ),
    );

    expect(img.decodeImage(result.bytes)!.width,
        ImagePreprocessor.maxDimension);
  });
}
