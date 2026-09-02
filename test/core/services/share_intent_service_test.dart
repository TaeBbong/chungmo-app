import 'package:chungmo/core/services/share_intent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  group('ShareIntentServiceImpl.toInvitation', () {
    test('returns null for an empty share', () {
      expect(ShareIntentServiceImpl.toInvitation(const []), isNull);
    });

    test('maps an image share with its mime type', () {
      final SharedInvitation? invitation =
          ShareIntentServiceImpl.toInvitation([
        SharedMediaFile(
          path: '/cache/shared.png',
          type: SharedMediaType.image,
          mimeType: 'image/png',
        ),
      ]);

      expect(invitation?.type, SharedInvitationType.image);
      expect(invitation?.value, '/cache/shared.png');
      expect(invitation?.mimeType, 'image/png');
    });

    test('maps a url share onto the link parser', () {
      final SharedInvitation? invitation =
          ShareIntentServiceImpl.toInvitation([
        SharedMediaFile(
          path: 'https://invitation.example.com/card',
          type: SharedMediaType.url,
        ),
      ]);

      expect(invitation?.type, SharedInvitationType.link);
      expect(invitation?.value, 'https://invitation.example.com/card');
    });

    test('re-classifies a bare URL shared as plain text onto the link parser',
        () {
      final SharedInvitation? invitation =
          ShareIntentServiceImpl.toInvitation([
        SharedMediaFile(
          path: 'https://invitation.example.com/card',
          type: SharedMediaType.text,
        ),
      ]);

      expect(invitation?.type, SharedInvitationType.link);
    });

    test('keeps invitation prose on the text parser', () {
      const String sms = '10월 24일 토요일 오후 1시 그랜드홀에서 결혼합니다. '
          'https://invitation.example.com/card 에서 확인하세요';

      final SharedInvitation? invitation = ShareIntentServiceImpl.toInvitation([
        SharedMediaFile(path: sms, type: SharedMediaType.text),
      ]);

      // Whitespace means it is a message containing a link, not a bare URL.
      expect(invitation?.type, SharedInvitationType.text);
      expect(invitation?.value, sms);
    });

    test('ignores unsupported media types', () {
      for (final SharedMediaType type in [
        SharedMediaType.video,
        SharedMediaType.file,
      ]) {
        expect(
          ShareIntentServiceImpl.toInvitation(
              [SharedMediaFile(path: '/cache/x', type: type)]),
          isNull,
          reason: type.name,
        );
      }
    });
  });
}
