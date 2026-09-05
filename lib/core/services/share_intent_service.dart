import 'package:injectable/injectable.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/string_extension.dart';

/// The parser input a share resolves to.
enum SharedInvitationType { link, text, image }

/// One invitation shared into chungmo from another app's share sheet,
/// normalized onto the three parser inputs.
class SharedInvitation {
  final SharedInvitationType type;

  /// The URL or raw text; a local file path for [SharedInvitationType.image].
  final String value;
  final String? mimeType;

  const SharedInvitation({
    required this.type,
    required this.value,
    this.mimeType,
  });
}

/// Receives "공유 → 청모" payloads handed over by the OS share sheet
/// (ACTION_SEND on Android, the Share Extension on iOS).
abstract class ShareIntentService {
  /// The share that launched the app, if any. Consuming it clears the
  /// platform buffer so a restart does not replay the same share.
  Future<SharedInvitation?> consumeInitialShare();

  /// Shares arriving while the app is already running.
  Stream<SharedInvitation> get shares;
}

@LazySingleton(as: ShareIntentService)
class ShareIntentServiceImpl implements ShareIntentService {
  @override
  Future<SharedInvitation?> consumeInitialShare() async {
    final List<SharedMediaFile> media =
        await ReceiveSharingIntent.instance.getInitialMedia();
    final SharedInvitation? share = toInvitation(media);
    if (share != null) {
      await ReceiveSharingIntent.instance.reset();
    }
    return share;
  }

  @override
  Stream<SharedInvitation> get shares => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(toInvitation)
      .where((invitation) => invitation != null)
      .cast<SharedInvitation>();

  /// Normalizes a platform share. Only the first item matters — the share
  /// sheet activation rules accept a single invitation. Static so the
  /// mapping stays unit-testable without platform channels.
  static SharedInvitation? toInvitation(List<SharedMediaFile> media) {
    if (media.isEmpty) return null;
    final SharedMediaFile file = media.first;
    switch (file.type) {
      case SharedMediaType.image:
        return SharedInvitation(
          type: SharedInvitationType.image,
          value: file.path,
          mimeType: file.mimeType,
        );
      case SharedMediaType.url:
        return SharedInvitation(
          type: SharedInvitationType.link,
          value: file.path,
        );
      case SharedMediaType.text:
        // Android hands a bare shared URL over as plain text, so the
        // link-vs-text split is re-checked here, like the home input field.
        return SharedInvitation(
          type: file.path.isHttpUrl
              ? SharedInvitationType.link
              : SharedInvitationType.text,
          value: file.path,
        );
      case SharedMediaType.video:
      case SharedMediaType.file:
        // Not parseable invitations; the activation rules should already
        // keep these out of the share sheet.
        return null;
    }
  }

}
