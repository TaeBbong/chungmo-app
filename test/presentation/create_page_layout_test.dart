import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/core/services/preferences_checker.dart';
import 'package:chungmo/core/services/share_intent_service.dart';
import 'package:chungmo/core/services/tutorial_manager.dart';
import 'package:chungmo/data/sources/local/app_preferences_local_source.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/core/services/notification_service.dart';
import 'package:chungmo/presentation/pages/create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

/// Marks both tour keys as seen so the coach mark never overlays the test.
class _FakePrefsSource extends Fake implements AppPreferencesLocalSource {
  @override
  Future<bool> containsKey(String key) async => true;
}

/// Answers "the app was not launched from a notification".
class _FakeLocalNotifications extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails()
      async => null;
}

/// No shares arrive during the test.
class _FakeShareIntentService extends Fake implements ShareIntentService {
  @override
  Stream<SharedInvitation> get shares => const Stream.empty();

  @override
  Future<SharedInvitation?> consumeInitialShare() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWatchAllSchedulesUsecase watch;

  setUp(() {
    watch = MockWatchAllSchedulesUsecase();
    when(watch.execute()).thenAnswer((_) => Stream<List<Schedule>>.value([
          Schedule(
            link: 'https://invite.example',
            thumbnail: 'thumb',
            groom: '김민준',
            bride: '이서연',
            date: DateTime.now().add(const Duration(days: 30)),
            location: '어딘가 3층',
          ),
        ]));

    final MockNotificationService notify = MockNotificationService();
    when(notify.getLocalNotificationPlugin())
        .thenReturn(_FakeLocalNotifications());

    getIt.registerSingleton<AnalyzeLinkUsecase>(MockAnalyzeLinkUsecase());
    getIt.registerSingleton<AnalyzeImageUsecase>(MockAnalyzeImageUsecase());
    getIt.registerSingleton<AnalyzeTextUsecase>(MockAnalyzeTextUsecase());
    getIt.registerSingleton<SaveScheduleUsecase>(MockSaveScheduleUsecase());
    getIt.registerSingleton<NotificationService>(notify);
    getIt.registerSingleton<WatchAllSchedulesUsecase>(watch);
    getIt.registerSingleton<AnalyticsService>(const NoopAnalyticsService());
    getIt.registerSingleton<PreferencesChecker>(
        PreferencesChecker(_FakePrefsSource()));
    getIt.registerSingleton<ShareIntentService>(_FakeShareIntentService());
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// A clipboard with content mounts the paste chip — the tallest variant
  /// of the empty state, and the one the keyboard squeezes hardest.
  void mockClipboardWithText(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.hasStrings') {
          return <String, dynamic>{'value': true};
        }
        return null;
      },
    );
  }

  Future<void> pumpSqueezed(
    WidgetTester tester, {
    required Size logicalSize,
    required double keyboardInset,
    double textScale = 1.0,
  }) async {
    const double dpr = 3.0;
    tester.view.physicalSize = logicalSize * dpr;
    tester.view.devicePixelRatio = dpr;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset * dpr);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    mockClipboardWithText(tester);

    await tester.pumpWidget(const MaterialApp(home: CreatePage()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
      'empty home does not overflow when the keyboard shrinks the body '
      '(Galaxy S20+, Samsung keyboard, paste chip visible)', (tester) async {
    await pumpSqueezed(tester,
        logicalSize: const Size(384, 853), keyboardInset: 320);

    expect(tester.takeException(), isNull,
        reason: 'the empty-state column must fit or scroll, not overflow');
  });

  testWidgets(
      'empty home does not overflow on a small phone with large fonts',
      (tester) async {
    await pumpSqueezed(tester,
        logicalSize: const Size(360, 740),
        keyboardInset: 300,
        textScale: 1.3);

    expect(tester.takeException(), isNull,
        reason: 'the empty-state column must fit or scroll, not overflow');
  });
}
