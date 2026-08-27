import 'dart:typed_data';

import '../../models/schedule/schedule_model.dart';

abstract class ScheduleRemoteSource {
  Future<ScheduleModel> fetchScheduleFromServer(String url);

  /// Parse a wedding invitation image (e.g. a KakaoTalk screenshot).
  ///
  /// The returned model's `link` is a synthetic `image://<hash>` id derived
  /// from the image bytes, since image invitations have no URL.
  Future<ScheduleModel> fetchScheduleFromImage(
      Uint8List bytes, String mimeType);

  /// Parse pasted invitation text (e.g. an SMS or KakaoTalk message).
  ///
  /// The returned model's `link` is a synthetic `text://<hash>` id derived
  /// from the text, since pasted invitations have no URL.
  Future<ScheduleModel> fetchScheduleFromText(String text);
}
