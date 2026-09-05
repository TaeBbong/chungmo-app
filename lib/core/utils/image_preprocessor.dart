import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/invitation_image.dart';

/// Downscales invitation images before they are sent to Gemini.
///
/// The gallery/camera path already resizes natively
/// (`ImagePicker.pickImage(maxWidth: 1600, imageQuality: 85)`), but images
/// arriving through the share sheet come in at their original size — a
/// KakaoTalk capture can be several MB. Re-encoding them to the same spec
/// cuts upload time and model input cost without hurting parse quality.
///
/// Decoding and re-encoding a large image takes hundreds of milliseconds of
/// pure CPU, so the work runs in a background isolate via [compute]; the
/// analyze animation keeps its frame budget on the main isolate.
abstract class ImagePreprocessor {
  /// Longest allowed side, matching the picker path's `maxWidth`.
  static const int maxDimension = 1600;

  /// JPEG quality, matching the picker path's `imageQuality`.
  static const int jpegQuality = 85;

  /// Upper bound on the decoded raster (~50MP ≈ 200MB of RGBA). Checked
  /// against the header before decoding: share-sheet bytes are external
  /// input, and a crafted or gigantic image would otherwise allocate an
  /// unbounded raster — isolates share process memory, so `compute` is no
  /// protection against that.
  static const int maxDecodePixels = 50 * 1000 * 1000;

  static Future<InvitationImage> downscale(InvitationImage image) =>
      compute(downscaleSync, image);

  /// The isolate entry point. Public only for tests — production code goes
  /// through [downscale].
  @visibleForTesting
  static InvitationImage downscaleSync(InvitationImage image) {
    img.Image? decoded;
    try {
      final img.Decoder? decoder = img.findDecoderForData(image.bytes);
      // Header-only parse: dimensions without allocating the raster.
      final img.DecodeInfo? info = decoder?.startDecode(image.bytes);
      if (decoder == null || info == null) return image;
      if (info.width * info.height > maxDecodePixels) {
        // Refuse to decode; the original bytes pass through and the
        // parser's own limits deal with them, same as before this step.
        return image;
      }
      if (info.width <= maxDimension && info.height <= maxDimension) {
        // Small enough already; re-encoding would only cost quality, and
        // knowing it from the header skips the decode entirely.
        return image;
      }
      decoded = decoder.decodeFrame(0);
      // A phone photo stores its rotation as an EXIF tag (a portrait shot
      // is a landscape frame + orientation 6). copyResize bakes that in
      // before resizing, so the long side must be judged on the baked
      // frame or the 1600px contract breaks for portrait photos.
      if (decoded != null) decoded = img.bakeOrientation(decoded);
    } catch (_) {
      // The format probes throw on truncated garbage instead of returning
      // null; either way undecodable input passes through untouched and
      // Gemini's own error handling decides.
      decoded = null;
    }
    if (decoded == null) return image;
    final bool wide = decoded.width >= decoded.height;
    final img.Image resized = img.copyResize(
      decoded,
      width: wide ? maxDimension : null,
      height: wide ? null : maxDimension,
      // A box filter: 2-3x shrinks sample every source pixel, keeping the
      // invitation's small text readable where linear would alias it.
      interpolation: img.Interpolation.average,
    );
    return InvitationImage(
      bytes: img.encodeJpg(resized, quality: jpegQuality),
      mimeType: 'image/jpeg',
    );
  }
}
