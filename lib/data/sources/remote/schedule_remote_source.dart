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
}
