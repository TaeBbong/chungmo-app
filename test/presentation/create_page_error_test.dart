/// What the create page tells the user when a parse fails.
///
/// The distinction this file guards is the one the 2026-10 outage exposed:
/// a service refusal is not something the user can fix by trying again, and
/// saying "다시 시도해주세요" to it sent one user through nine attempts in
/// ten minutes (#72).
library;

import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/core/services/notification_service.dart';
import 'package:chungmo/core/services/preferences_checker.dart';
import 'package:chungmo/core/services/share_intent_service.dart';
import 'package:chungmo/data/sources/local/app_preferences_local_source.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/entities/schedule_draft.dart';
import 'package:chungmo/domain/exceptions.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/pages/create_page.dart';
import 'package:flutter/material.dart';
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
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async => null;
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

  late MockAnalyzeLinkUsecase analyze;

  setUp(() {
    analyze = MockAnalyzeLinkUsecase();

    final MockWatchAllSchedulesUsecase watch = MockWatchAllSchedulesUsecase();
    when(watch.execute())
        .thenAnswer((_) => Stream<List<Schedule>>.value(const []));

    final MockNotificationService notify = MockNotificationService();
    when(notify.getLocalNotificationPlugin())
        .thenReturn(_FakeLocalNotifications());

    getIt.registerSingleton<AnalyzeLinkUsecase>(analyze);
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

  /// Submits a link whose parse fails with [error], and settles the page.
  Future<void> submitFailing(WidgetTester tester, Object error) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    when(analyze.execute(any)).thenThrow(error);

    await tester.pumpWidget(const MaterialApp(home: CreatePage()));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'https://invite.test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a service refusal does not ask the user to try again',
      (tester) async {
    await submitFailing(
        tester, const RemoteUnavailableException('credits are depleted'));

    expect(find.text('지금은 분석할 수 없어요.'), findsOneWidget);
    expect(find.text('다시 시도해주세요.'), findsNothing,
        reason: 'retrying cannot succeed while the service is refusing');
    expect(find.text('청첩장 정보를 찾지 못했어요.'), findsNothing,
        reason: 'the invitation was never read, so it is not at fault');
  });

  testWidgets('an unreadable invitation still blames the input',
      (tester) async {
    await submitFailing(
        tester, const FormatException('no datetime in the answer'));

    expect(find.text('청첩장 정보를 찾지 못했어요.'), findsOneWidget);
    expect(find.text('지금은 분석할 수 없어요.'), findsNothing);
  });

  testWidgets('an unclassified failure still suggests a retry', (tester) async {
    // The branch that must survive: a transient fault is the one case where
    // trying again is genuinely the right advice.
    await submitFailing(tester, Exception('something else went wrong'));

    expect(find.text('다시 시도해주세요.'), findsOneWidget);
    expect(find.text('지금은 분석할 수 없어요.'), findsNothing);
  });

  testWidgets('an incomplete parse keeps offering the manual draft',
      (tester) async {
    await submitFailing(
        tester,
        const IncompleteScheduleException(ScheduleDraft(
          link: 'https://invite.test',
          groom: '유하준',
          bride: '남가은',
        )));

    expect(find.text('청첩장 정보를 찾지 못했어요.'), findsOneWidget);
    expect(find.text('지금은 분석할 수 없어요.'), findsNothing);
  });
}
