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

  /// Upper bound on the decoded raster (25MP ≈ 100MB of RGBA). Checked
  /// against the header before decoding: share-sheet bytes are external
  /// input, and a crafted or gigantic image would otherwise allocate an
  /// unbounded raster — isolates share process memory, so `compute` is no
  /// protection against that. Sized for the bake-plus-resize peak of two
  /// rasters (~200MB transient) staying survivable on low-memory devices;
  /// real invitations (screenshots, ≤12MP phone photos) sit far below it.
  static const int maxDecodePixels = 25 * 1000 * 1000;

  static Future<InvitationImage> downscale(InvitationImage image) =>
      compute(downscaleSync, image);

  /// The isolate entry point. Public only for tests — production code goes
  /// through [downscale].
  @visibleForTesting
  static InvitationImage downscaleSync(InvitationImage image) {
    img.Decoder? decoder;
    img.DecodeInfo? info;
    try {
      decoder = img.findDecoderForData(image.bytes);
      // Header-only parse: dimensions without allocating the raster.
      info = decoder?.startDecode(image.bytes);
    } catch (_) {
      // The format probes throw on truncated garbage instead of returning
      // null; treated like any undecodable input below.
      info = null;
    }
    // No decoder / undecodable header passes through on purpose: iOS
    // shares arrive as HEIC, which package:image cannot decode but Gemini
    // accepts — rejecting here would break those entirely.
    if (decoder == null || info == null) return image;
    if (info.width * info.height > maxDecodePixels) {
      // A decodable format declaring an absurd raster is refused before
      // any upload; the cubit surfaces this as an unreadable invitation.
      throw const FormatException('image exceeds the decode pixel limit');
    }
    if (info.width <= maxDimension && info.height <= maxDimension) {
      // Small enough already; re-encoding would only cost quality, and
      // knowing it from the header skips the decode entirely.
      return image;
    }
    img.Image? decoded;
    try {
      decoded = decoder.decodeFrame(0);
      // A phone photo stores its rotation as an EXIF tag (a portrait shot
      // is a landscape frame + orientation 6). copyResize bakes that in
      // before resizing, so the long side must be judged on the baked
      // frame or the 1600px contract breaks for portrait photos.
      if (decoded != null) decoded = img.bakeOrientation(decoded);
    } catch (_) {
      // A header that parsed but pixels that do not: pass through and let
      // Gemini's own error handling decide.
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
