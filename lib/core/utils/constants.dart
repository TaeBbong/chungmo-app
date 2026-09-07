abstract class Constants {
  static const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// Preference key marking the intro carousel as seen.
  static const String onboardingDoneKey = 'onboarding_done';

  /// Preference key marking the home coach mark tour as seen. Versioned:
  /// bump the suffix when the tour gains steps so users who already saw an
  /// older tour get the new steps once after updating.
  static const String tourDoneKey = 'tutorial_done_v2';

  /// Pre-versioning tour key; its presence identifies a user who saw the
  /// original 3-step tour before [tourDoneKey] existed.
  static const String legacyTourDoneKey = 'is_first';

  /// App Group shared with the iOS Share Extension and the widget
  /// extensions; the `home_widget` store lives under it on iOS.
  static const String appGroupId = 'group.com.taebbong.chungmoapp';

  /// Keys of the home screen widget's shared store. Written by
  /// HomeWidgetService, read by the native widget renderers — keep them in
  /// sync with ChungmoWidget.swift and ChungmoWidgetProvider.kt.
  static const String widgetHasScheduleKey = 'widget_has_schedule';
  static const String widgetCoupleKey = 'widget_couple';
  static const String widgetDateTextKey = 'widget_date_text';
  static const String widgetLocationKey = 'widget_location';
  static const String widgetDateMillisKey = 'widget_date_millis';

  /// Path of the widget's background photo, written by `HomeWidget.saveImage`
  /// (absent when the schedule has no genuine thumbnail).
  static const String widgetImageKey = 'widget_image';

  /// Gemini model used by every Firebase AI Logic call (invitation parsing
  /// and the pay recommendation).
  static const String geminiModel = 'gemini-2.5-flash';

  /// Policy pages served from the project's Firebase Hosting site
  /// (`hosting/public`), replacing the former public Notion pages.
  static const String privacyUrl = "https://chung-mo.web.app/privacy";
  static const String termsUrl = "https://chung-mo.web.app/terms";
  static const String defaultThumbnail =
      "https://img.freepik.com/free-vector/bride-groom-getting-married-illustration_23-2148404918.jpg";
}
