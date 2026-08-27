/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'dart:typed_data';

/// A wedding invitation captured as an image, e.g. a KakaoTalk screenshot
/// picked from the gallery or a photo taken with the camera.
///
/// [mimeType] must be one of the image types Gemini accepts
/// (image/jpeg, image/png, image/webp, image/heic, image/heif).
class InvitationImage {
  final Uint8List bytes;
  final String mimeType;

  const InvitationImage({required this.bytes, this.mimeType = 'image/jpeg'});
}
